# frozen_string_literal: true

module Gitlab
  module Gfm
    ##
    # Class that unfolds local references in text.
    #
    # The initializer takes text in Markdown and project this text is valid
    # in context of.
    #
    # `unfold` method tries to find all local references and unfold each of
    # those local references to cross reference format, assuming that the
    # argument passed to this method is a project that references will be
    # viewed from (see `Referable#to_reference method).
    #
    # Examples:
    #
    # 'Hello, this issue is related to #123 and
    #  other issues labeled with ~"label"', will be converted to:
    #
    # 'Hello, this issue is related to gitlab-org/gitlab-ce#123 and
    #  other issue labeled with gitlab-org/gitlab-ce~"label"'.
    #
    # It does respect markdown lexical rules, so text in code block will not be
    # replaced, see another example:
    #
    # 'Merge request for issue #1234, see also link:
    #  http://gitlab.com/some/link/#1234, and code `puts #1234`' =>
    #
    # 'Merge request for issue gitlab-org/gitlab-ce#1234, se also link:
    #  http://gitlab.com/some/link/#1234, and code `puts #1234`'
    #
    class ReferenceRewriter
      include Gitlab::Utils::StrongMemoize

      RewriteError = Class.new(StandardError)

      def initialize(text, text_html, source_parent, current_user)
        @text = text

        # If for some reason cached html is not present it gets rendered here
        @text_html = text_html || original_html

        @source_parent = source_parent
        @current_user = current_user
        @pattern = Gitlab::ReferenceExtractor.references_pattern
      end

      def rewrite(target_parent)
        return @text unless needs_rewrite?

        @text.gsub!(@pattern) do |reference|
          unfold_reference(reference, Regexp.last_match, target_parent)
        end
      end

      def needs_rewrite?
        strong_memoize(:needs_rewrite) { @text_html.include?('data-reference-type=') }
      end

      private

      def original_html
        strong_memoize(:original_html) do
          markdown(@text)
        end
      end

      def unfold_reference(reference, match, target_parent)
        before = @text[0...match.begin(0)]
        after = @text[match.end(0)..]

        referable = find_referable(reference)
        return reference unless referable

        cross_reference = build_cross_reference(referable, target_parent)
        return reference if reference == cross_reference

        if cross_reference.nil?
          raise RewriteError, "Unspecified reference detected for #{referable.class.name}"
        end

        new_text = before + cross_reference + after
        substitution_valid?(new_text) ? cross_reference : reference
      end

      def find_referable(reference)
        extractor = Gitlab::ReferenceExtractor.new(@source_parent,
                                                   @current_user)
        extractor.analyze(reference)
        extractor.all.first
      end

      def build_cross_reference(referable, target_parent)
        if referable.respond_to?(:project)
          referable.to_reference(target_parent)
        else
          referable.to_reference(@source_parent, target_project: target_parent)
        end
      end

      def substitution_valid?(substituted)
        original_html == markdown(substituted)
      end

      def markdown(text)
        Banzai.render(text, project: @source_parent, no_original_data: true, no_sourcepos: true)
      end
    end
  end
end
