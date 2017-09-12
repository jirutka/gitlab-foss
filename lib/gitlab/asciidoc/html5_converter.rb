# frozen_string_literal: true

require 'asciidoctor-html5s'

module Gitlab
  module Asciidoc
    class Html5Converter < Asciidoctor::Html5s::Converter
      register_for 'gitlab_html5'

      # TODO: Return back "convert_" prefix after updating asciidoctor-html5s to >= 0.6.0.

      def stem(node)
        return super unless node.style.to_sym == :latexmath

        %(<pre#{id_attribute(node)} data-math-style="display"><code>#{node.content}</code></pre>)
      end

      def inline_quoted(node)
        return super unless node.type.to_sym == :latexmath

        %(<code#{id_attribute(node)} data-math-style="inline">#{node.text}</code>)
      end

      def inline_anchor(node)
        node.id = "user-content-#{node.id}" if node.id && !node.id.start_with?('user-content-')

        super(node)
      end

      private

      def id_attribute(node)
        node.id ? %( id="#{node.id}") : nil
      end
    end
  end
end
