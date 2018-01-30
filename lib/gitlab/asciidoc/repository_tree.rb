# frozen_string_literal: true

module Gitlab
  module Asciidoc
    class RepositoryTree

      def initialize(context)
        @context = context
        @repository = context[:repository] || context[:project]&.repository
        @cache = {
          uri_types: {}
        }
      end

      # Resolves the given path of file in repository into canonical path
      # based on the specified base_path (defaults to requested_path).
      #
      # Examples:
      #
      #   # File in the same directory as the current path
      #   resolve_relative_path("users.adoc", "doc/api/README.adoc")
      #   # => "doc/api/users.adoc"
      #
      #   # File in the same directory, which is also the current path
      #   resolve_relative_path("users.adoc", "doc/api")
      #   # => "doc/api/users.adoc"
      #
      #   # Going up one level to a different directory
      #   resolve_relative_path("../update/7.14-to-8.0.adoc", "doc/api/README.adoc")
      #   # => "doc/update/7.14-to-8.0.adoc"
      #
      # Returns a String, or nil if files does not exist
      def resolve_relative_path(path, base_path = nil)
        base_path ||= requested_path

        return unless @repository.try(:exists?)
        return base_path if path.empty?
        return path unless base_path
        return path[1..-1] if path.start_with?('/')

        parts = base_path.split('/')
        parts.pop if uri_type(base_path) != :tree

        path = path.sub(/\A\.\//, '')

        while path.start_with?('../')
          parts.pop
          path.sub!('../', '')
        end
        path = parts.push(path).join('/')

        path if file_exist? path
      end

      def file_exist?(filename)
        Gitlab::Git::Blob.find(@repository, ref, filename)
      end

      # Returns a String
      def read_blob(filename)
        blob = @repository&.blob_at(ref, filename)

        raise 'Blob not found' unless blob
        raise 'File is not readable' unless blob.readable_text?

        blob.data
      end

      private

      def current_commit
        @cache[:current_commit] ||= @context[:commit] || @repository&.commit(ref)
      end

      def ref
        @context[:ref] || repository&.root_ref
      end

      def requested_path
        @cache[:requested_path] ||= Addressable::URI.unescape(@context[:requested_path])
      end

      def uri_type(path)
        @cache[:uri_types][path] ||= current_commit&.uri_type(path)
      end
    end
  end
end
