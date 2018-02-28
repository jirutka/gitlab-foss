require 'asciidoctor'
require 'asciidoctor/extensions'
require 'asciidoctor-html5s'
require "asciidoctor-plantuml"
require 'asciidoctor/include_ext/include_processor'
require 'asciidoctor/interdoc_reftext/processor'
require 'asciidoctor/rouge/treeprocessor'

module Gitlab
  # Parser/renderer for the AsciiDoc format that uses Asciidoctor and filters
  # the resulting HTML through HTML pipeline filters.
  module Asciidoc
    DEFAULT_ADOC_ATTRS = [
      'showtitle', 'idprefix=user-content-', 'idseparator=-', 'env=gitlab',
      'env-gitlab', 'source-highlighter=rouge', 'icons=font',
      'sectanchors', 'outfilesuffix=.adoc'
    ].freeze

    Asciidoctor::Extensions.register do
      treeprocessor Asciidoctor::Rouge::Treeprocessor.new(formatter_opts: {
        line_id: 'LC%i',
        highlighted_class: 'hll'
      })
    end

    # Public: Converts the provided Asciidoc markup into HTML.
    #
    # input         - the source text in Asciidoc format
    # context       - :commit, :project, :ref, :requested_path
    #
    def self.render(input, context)
      repository_tree = RepositoryTree.new(context)

      extensions = proc do
        include_processor GitlabIncludeProcessor.new(repository_tree)

        tree_processor ::Asciidoctor::InterdocReftext::Processor.new(
          resolver_class: GitlabInterdocReftextResolver,
          repository_tree: repository_tree
        )
      end

      attributes = if (project = context[:project])
        {
          'gl-commit-ref' => context[:ref] || context[:project].default_branch,
          'gl-project-namespace' => project.namespace.full_path,
          'gl-project-path' => project.full_path,
          'gl-project-title' => project.title,
          'gl-project-url' => project.web_url,
          'gl-repo-http-url' => project.http_url_to_repo,
          'gl-repo-ssh-url' => project.ssh_url_to_repo,
          'gl-server-host' => Gitlab.config.gitlab.host,
          'gl-server-url' => Gitlab.config.gitlab.base_url,
        }.map { |k, v| "#{k}=#{v}" }
      else
        []
      end

      asciidoc_opts = { safe: :server,
                        backend: :gitlab_html5,
                        attributes: DEFAULT_ADOC_ATTRS + attributes,
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

    class Html5Converter < Asciidoctor::Html5s::Converter
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

    class RepositoryTree
      def initialize(context)
        @context = context
        @repository = context[:project].try(:repository)
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
      #   resolve_file_path("users.adoc", "doc/api/README.adoc")
      #   # => "doc/api/users.adoc"
      #
      #   # File in the same directory, which is also the current path
      #   resolve_file_path("users.adoc", "doc/api")
      #   # => "doc/api/users.adoc"
      #
      #   # Going up one level to a different directory
      #   resolve_file_path("../update/7.14-to-8.0.adoc", "doc/api/README.adoc")
      #   # => "doc/update/7.14-to-8.0.adoc"
      #
      # Returns a String, or nil if files does not exist
      def resolve_file_path(path, base_path = nil)
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
      def read_file(filename)
        blob = @repository.blob_at(ref, filename)

        raise 'Blob not found' unless blob
        raise 'File is not readable' unless blob.readable_text?

        blob.data
      end

      private

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

    # Asciidoctor extension for processing includes (macro include::[]) within
    # documents inside the same repository.
    class GitlabIncludeProcessor < Asciidoctor::IncludeExt::IncludeProcessor
      # Overrides super class method.
      def initialize(repository_tree)
        super(logger: Gitlab::AppLogger)
        @repository_tree = repository_tree
      end

      protected

      # Overrides super class method.
      def resolve_target_path(target, reader)
        base_path = reader.file unless reader.include_stack.empty?
        @repository_tree.resolve_file_path(target, base_path)
      end

      # Overrides super class method.
      def read_lines(filename, selector)
        data = @repository_tree.read_file(filename)

        if selector
          data.each_line.select.with_index(1, &selector)
        else
          data
        end
      end

      # Overrides super class method.
      def unresolved_include!(target, reader)
        reader.unshift_line("*[ERROR: include::#{target}[] - unresolved directive]*")
      end
    end

    # Resolver of implicit reference text (label) for inter-document cross references.
    class GitlabInterdocReftextResolver < Asciidoctor::InterdocReftext::Resolver
      # Overrides super class method.
      def initialize(document, repository_tree:, **)
        super(document, logger: Gitlab::AppLogger, raise_exceptions: false)
        @repository_tree = repository_tree
      end

      protected

      # Overrides super class method.
      def resolve_target_path(target_path)
        @repository_tree.resolve_file_path(target_path + '.adoc')
      end

      # Overrides super class method.
      def read_file(filename)
        @repository_tree.read_file(filename).try(:each_line)
      end
    end
  end
end
