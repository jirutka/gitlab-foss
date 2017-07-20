require 'asciidoctor'
require 'asciidoctor/converter/html5'
require "asciidoctor-plantuml"

module Gitlab
  # Parser/renderer for the AsciiDoc format that uses Asciidoctor and filters
  # the resulting HTML through HTML pipeline filters.
  module Asciidoc
    DEFAULT_ADOC_ATTRS = [
      'showtitle', 'idprefix=user-content-', 'idseparator=-', 'env=gitlab',
      'env-gitlab', 'source-highlighter=html-pipeline', 'icons=font',
      'sectanchors'
    ].freeze

    # Public: Converts the provided Asciidoc markup into HTML.
    #
    # input         - the source text in Asciidoc format
    # context       - a Hash with the template context:
    #                 :commit
    #                 :project
    #                 :project_wiki
    #                 :requested_path
    #                 :ref
    # asciidoc_opts - a Hash of options to pass to the Asciidoctor converter
    #
    def self.render(input, context, asciidoc_opts = {})
      asciidoc_opts.reverse_merge!(
        safe: :secure,
        backend: :gitlab_html5,
        attributes: []
      )
      asciidoc_opts[:attributes].unshift(*DEFAULT_ADOC_ATTRS)

      context[:pipeline] = :ascii_doc

      plantuml_setup

      html = ::Asciidoctor.convert(input, asciidoc_opts)
      html = Banzai.render(html, context)
      html = Banzai.post_process(html, context)
      html.html_safe
    end

    def self.plantuml_setup
      Asciidoctor::PlantUml.configure do |conf|
        conf.url = current_application_settings.plantuml_url
        conf.svg_enable = current_application_settings.plantuml_enabled
        conf.png_enable = current_application_settings.plantuml_enabled
        conf.txt_enable = false
      end
    end

    class Html5Converter < Asciidoctor::Converter::Html5Converter
      extend Asciidoctor::Converter::Config

      register_for 'gitlab_html5'

      def stem(node)
        return super unless node.style.to_sym == :latexmath

        %(<pre#{id_attribute(node)} data-math-style="display"><code>#{node.content}</code></pre>)
      end

      def inline_quoted(node)
        return super unless node.type.to_sym == :latexmath

        %(<code#{id_attribute(node)} data-math-style="inline">#{node.text}</code>)
      end

      private

      def id_attribute(node)
        node.id ? %( id="#{node.id}") : nil
      end
    end
  end
end
