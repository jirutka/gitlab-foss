# frozen_string_literal: true

module Gitlab
  module GitalyClient
    class RefService
      include Gitlab::EncodingHelper

      TAGS_SORT_KEY = {
        'name' => Gitaly::FindAllTagsRequest::SortBy::Key::REFNAME,
        'updated' => Gitaly::FindAllTagsRequest::SortBy::Key::CREATORDATE
      }.freeze

      TAGS_SORT_DIRECTION = {
        'asc' => Gitaly::SortDirection::ASCENDING,
        'desc' => Gitaly::SortDirection::DESCENDING
      }.freeze

      # 'repository' is a Gitlab::Git::Repository
      def initialize(repository)
        @repository = repository
        @gitaly_repo = repository.gitaly_repository
        @storage = repository.storage
      end

      def branches
        request = Gitaly::FindAllBranchesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_all_branches, request, timeout: GitalyClient.fast_timeout)
        consume_find_all_branches_response(response)
      end

      def remote_branches(remote_name)
        request = Gitaly::FindAllRemoteBranchesRequest.new(repository: @gitaly_repo, remote_name: remote_name)
        response = GitalyClient.call(@storage, :ref_service, :find_all_remote_branches, request, timeout: GitalyClient.medium_timeout)
        consume_find_all_remote_branches_response(remote_name, response)
      end

      def merged_branches(branch_names = [])
        request = Gitaly::FindAllBranchesRequest.new(
          repository: @gitaly_repo,
          merged_only: true,
          merged_branches: branch_names.map { |s| encode_binary(s) }
        )
        response = GitalyClient.call(@storage, :ref_service, :find_all_branches, request, timeout: GitalyClient.fast_timeout)
        consume_find_all_branches_response(response)
      end

      def default_branch_name
        request = Gitaly::FindDefaultBranchNameRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_default_branch_name, request, timeout: GitalyClient.fast_timeout)
        Gitlab::Git.branch_name(response.name)
      end

      def branch_names
        request = Gitaly::FindAllBranchNamesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_all_branch_names, request, timeout: GitalyClient.fast_timeout)
        consume_refs_response(response) { |name| Gitlab::Git.branch_name(name) }
      end

      def tag_names
        request = Gitaly::FindAllTagNamesRequest.new(repository: @gitaly_repo)
        response = GitalyClient.call(@storage, :ref_service, :find_all_tag_names, request, timeout: GitalyClient.fast_timeout)
        consume_refs_response(response) { |name| Gitlab::Git.tag_name(name) }
      end

      def count_tag_names
        tag_names.count
      end

      def count_branch_names
        branch_names.count
      end

      def local_branches(sort_by: nil, pagination_params: nil)
        request = Gitaly::FindLocalBranchesRequest.new(repository: @gitaly_repo, pagination_params: pagination_params)
        request.sort_by = sort_local_branches_by_param(sort_by) if sort_by
        response = GitalyClient.call(@storage, :ref_service, :find_local_branches, request, timeout: GitalyClient.fast_timeout)
        consume_find_local_branches_response(response)
      end

      def tags(sort_by: nil, pagination_params: nil)
        request = Gitaly::FindAllTagsRequest.new(repository: @gitaly_repo, pagination_params: pagination_params)
        request.sort_by = sort_tags_by_param(sort_by) if sort_by

        response = GitalyClient.call(@storage, :ref_service, :find_all_tags, request, timeout: GitalyClient.medium_timeout)
        consume_tags_response(response)
      end

      def ref_exists?(ref_name)
        request = Gitaly::RefExistsRequest.new(repository: @gitaly_repo, ref: encode_binary(ref_name))
        response = GitalyClient.call(@storage, :ref_service, :ref_exists, request, timeout: GitalyClient.fast_timeout)
        response.value
      rescue GRPC::InvalidArgument => e
        raise ArgumentError, e.message
      end

      def find_branch(branch_name)
        request = Gitaly::FindBranchRequest.new(
          repository: @gitaly_repo,
          name: encode_binary(branch_name)
        )

        response = GitalyClient.call(@repository.storage, :ref_service, :find_branch, request, timeout: GitalyClient.medium_timeout)
        branch = response.branch
        return unless branch

        target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
        Gitlab::Git::Branch.new(@repository, encode!(branch.name.dup), branch.target_commit.id, target_commit)
      end

      def find_tag(tag_name)
        return if tag_name.blank?

        request = Gitaly::FindTagRequest.new(
          repository: @gitaly_repo,
          tag_name: encode_binary(tag_name)
        )

        response = GitalyClient.call(@repository.storage, :ref_service, :find_tag, request, timeout: GitalyClient.medium_timeout)
        tag = response.tag
        return unless tag

        Gitlab::Git::Tag.new(@repository, tag)
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error&.error
        when :tag_not_found
          raise Gitlab::Git::UnknownRef, "tag does not exist: #{tag_name}"
        else
          # When this is not a know structured error we simply re-raise the exception.
          raise e
        end
      end

      def delete_refs(refs: [], except_with_prefixes: [])
        request = Gitaly::DeleteRefsRequest.new(
          repository: @gitaly_repo,
          refs: refs.map { |r| encode_binary(r) },
          except_with_prefix: except_with_prefixes.map { |r| encode_binary(r) }
        )

        response = GitalyClient.call(@repository.storage, :ref_service, :delete_refs, request, timeout: GitalyClient.medium_timeout)

        raise Gitlab::Git::Repository::GitError, response.git_error if response.git_error.present?
      rescue GRPC::BadStatus => e
        detailed_error = GitalyClient.decode_detailed_error(e)

        case detailed_error&.error
        when :invalid_format
          raise Gitlab::Git::InvalidRefFormatError, "references have an invalid format: #{detailed_error.invalid_format.refs.join(",")}"
        when :references_locked
          raise Gitlab::Git::ReferencesLockedError
        else
          raise e
        end
      end

      # Limit: 0 implies no limit, thus all tag names will be returned
      def tag_names_contains_sha(sha, limit: 0)
        request = Gitaly::ListTagNamesContainingCommitRequest.new(
          repository: @gitaly_repo,
          commit_id: sha,
          limit: limit
        )

        response = GitalyClient.call(@storage, :ref_service, :list_tag_names_containing_commit, request, timeout: GitalyClient.medium_timeout)
        consume_ref_contains_sha_response(response, :tag_names)
      end

      # Limit: 0 implies no limit, thus all tag names will be returned
      def branch_names_contains_sha(sha, limit: 0)
        request = Gitaly::ListBranchNamesContainingCommitRequest.new(
          repository: @gitaly_repo,
          commit_id: sha,
          limit: limit
        )

        response = GitalyClient.call(@storage, :ref_service, :list_branch_names_containing_commit, request, timeout: GitalyClient.medium_timeout)
        consume_ref_contains_sha_response(response, :branch_names)
      end

      def get_tag_messages(tag_ids)
        request = Gitaly::GetTagMessagesRequest.new(repository: @gitaly_repo, tag_ids: tag_ids)
        messages = Hash.new { |h, k| h[k] = +''.b }
        current_tag_id = nil

        response = GitalyClient.call(@storage, :ref_service, :get_tag_messages, request, timeout: GitalyClient.fast_timeout)
        response.each do |rpc_message|
          current_tag_id = rpc_message.tag_id if rpc_message.tag_id.present?

          messages[current_tag_id] << rpc_message.message
        end

        messages
      end

      def get_tag_signatures(tag_ids)
        request = Gitaly::GetTagSignaturesRequest.new(repository: @gitaly_repo, tag_revisions: tag_ids)
        response = GitalyClient.call(@repository.storage, :ref_service, :get_tag_signatures, request, timeout: GitalyClient.fast_timeout)

        signatures = Hash.new { |h, k| h[k] = [+''.b, +''.b] }
        current_tag_id = nil

        response.each do |message|
          message.signatures.each do |tag_signature|
            current_tag_id = tag_signature.tag_id if tag_signature.tag_id.present?

            signatures[current_tag_id].first << tag_signature.signature
            signatures[current_tag_id].last << tag_signature.content
          end
        end

        signatures
      rescue GRPC::InvalidArgument => ex
        raise ArgumentError, ex
      end

      def list_refs(patterns = [Gitlab::Git::BRANCH_REF_PREFIX])
        request = Gitaly::ListRefsRequest.new(
          repository: @gitaly_repo,
          patterns: patterns
        )

        response = GitalyClient.call(@storage, :ref_service, :list_refs, request, timeout: GitalyClient.fast_timeout)
        consume_list_refs_response(response)
      end

      def pack_refs
        request = Gitaly::PackRefsRequest.new(repository: @gitaly_repo)

        GitalyClient.call(@storage, :ref_service, :pack_refs, request, timeout: GitalyClient.long_timeout)
      end

      def find_refs_by_oid(oid:, limit:)
        request = Gitaly::FindRefsByOIDRequest.new(repository: @gitaly_repo, sort_field: :refname, oid: oid, limit: limit)

        response = GitalyClient.call(@storage, :ref_service, :find_refs_by_oid, request, timeout: GitalyClient.medium_timeout)
        response&.refs&.to_a
      end

      private

      def consume_refs_response(response)
        response.flat_map { |message| message.names.map { |name| yield(name) } }
      end

      def consume_list_refs_response(response)
        response.flat_map(&:references)
      end

      def sort_local_branches_by_param(sort_by)
        sort_by = 'name' if sort_by == 'name_asc'

        enum_value = Gitaly::FindLocalBranchesRequest::SortBy.resolve(sort_by.upcase.to_sym)
        raise ArgumentError, "Invalid sort_by key `#{sort_by}`" unless enum_value

        enum_value
      end

      def sort_tags_by_param(sort_by)
        match = sort_by.match(/^(?<key>name|updated)_(?<direction>asc|desc)$/)

        return unless match

        Gitaly::FindAllTagsRequest::SortBy.new(
          key: TAGS_SORT_KEY[match[:key]],
          direction: TAGS_SORT_DIRECTION[match[:direction]]
        )
      end

      def consume_find_local_branches_response(response)
        response.flat_map do |message|
          message.branches.map do |gitaly_branch|
            Gitlab::Git::Branch.new(
              @repository,
              encode!(gitaly_branch.name.dup),
              gitaly_branch.commit_id,
              commit_from_local_branches_response(gitaly_branch)
            )
          end
        end
      end

      def consume_find_all_branches_response(response)
        response.flat_map do |message|
          message.branches.map do |branch|
            target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target)
            Gitlab::Git::Branch.new(@repository, branch.name, branch.target.id, target_commit)
          end
        end
      end

      def consume_find_all_remote_branches_response(remote_name, response)
        remote_name += '/' unless remote_name.ends_with?('/')

        response.flat_map do |message|
          message.branches.map do |branch|
            target_commit = Gitlab::Git::Commit.decorate(@repository, branch.target_commit)
            branch_name = branch.name.sub(remote_name, '')
            Gitlab::Git::Branch.new(@repository, branch_name, branch.target_commit.id, target_commit)
          end
        end
      end

      def consume_tags_response(response)
        response.flat_map do |message|
          message.tags.map { |gitaly_tag| Gitlab::Git::Tag.new(@repository, gitaly_tag) }
        end
      end

      def commit_from_local_branches_response(response)
        # Git messages have no encoding enforcements. However, in the UI we only
        # handle UTF-8, so basically we cross our fingers that the message force
        # encoded to UTF-8 is readable.
        message = response.commit_subject.dup.force_encoding('UTF-8')

        # NOTE: For ease of parsing in Gitaly, we have only the subject of
        # the commit and not the full message. This is ok, since all the
        # code that uses `local_branches` only cares at most about the
        # commit message.
        # TODO: Once gitaly "takes over" Rugged consider separating the
        # subject from the message to make it clearer when there's one
        # available but not the other.
        hash = {
          id: response.commit_id,
          message: message,
          authored_date: Time.at(response.commit_author.date.seconds),
          author_name: response.commit_author.name.dup,
          author_email: response.commit_author.email.dup,
          committed_date: Time.at(response.commit_committer.date.seconds),
          committer_name: response.commit_committer.name.dup,
          committer_email: response.commit_committer.email.dup
        }

        Gitlab::Git::Commit.decorate(@repository, hash)
      end

      def consume_ref_contains_sha_response(stream, collection_name)
        stream.each_with_object([]) do |response, array|
          encoded_names = response.send(collection_name).map { |b| Gitlab::Git.ref_name(b) } # rubocop:disable GitlabSecurity/PublicSend
          array.concat(encoded_names)
        end
      end

      def invalid_ref!(message)
        raise Gitlab::Git::Repository::InvalidRef, message
      end
    end
  end
end
