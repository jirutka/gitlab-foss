require 'asciidoctor'
require 'asciidoctor/converter/html5'
require 'asciidoctor/extensions'
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
    # context       - :commit, :project, :ref, :requested_path
    #
    def self.render(input, context)
      extensions = proc do
        include_processor GitlabIncludeProcessor.new(context)
      end

      asciidoc_opts = { safe: :server,
                        backend: :gitlab_html5,
                        attributes: DEFAULT_ADOC_ATTRS,
                        extensions: extensions }

      context[:pipeline] = :ascii_doc

      plantuml_setup

      html = ::Asciidoctor.convert(input, asciidoc_opts)
      html = Banzai.render(html, context)
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

    # Asciidoctor extension for processing includes (macro include::[]) within
    # documents inside the same repository.
    class GitlabIncludeProcessor < Asciidoctor::Extensions::IncludeProcessor
      def initialize(context, config = {})
        super(config)

        @context = context
        @repository = context[:project].try(:repository)

        # Note: Asciidoctor calls #freeze on extensions, so we can't set new
        # instance variables after initialization.
        @cache = {
          uri_types: {}
        }
      end

      def process(doc, reader, target, attributes)
        return reader unless @repository.try(:exists?)

        # Resolve relative target path against the requested path (path of the
        # file user wants to see), or against path of the currently processed
        # include if processing nested include (i.e. A includes B,
        # B includes C, ...).
        base_path = reader.include_stack.empty? ? requested_path : reader.file
        path = resolve_relative_path(target, base_path)

        blob = @repository.blob_at(ref, path)
        error = if blob.nil?
                  'Unresolved path'
                elsif !blob.readable_text?
                  'File not readable'
                elsif reader.exceeded_max_depth?
                  'Maximum depth exceeded'
                end
        if error
          reader.replace_line("*[ERROR: include::#{target}[] - #{error}]*")
        else
          reader.push_include(blob.data, path, target, 1, attributes)
        end

        reader
      end

      protected

      # Resolves the given relative path of file in repository into canonical
      # path based on the specified base_path.
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
      # Returns a String
      def resolve_relative_path(path, base_path)
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

        parts.push(path).join('/')
      end

      def current_commit
        @cache[:current_commit] ||= @context[:commit] || @repository.commit(ref)
      end

      def ref
        @context[:ref] || @context[:project].default_branch
      end

      def requested_path
        @cache[:requested_path] ||= Addressable::URI.unescape(@context[:requested_path])
      end

      def uri_type(path)
        @cache[:uri_types][path] ||= current_commit.uri_type(path)
      end
    end
  end
end
