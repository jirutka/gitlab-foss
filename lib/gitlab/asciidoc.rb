# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor-plantuml'
require 'asciidoctor/extensions'
require 'asciidoctor/interdoc_reftext/processor'
require 'gitlab/asciidoc/html5_converter'
require 'gitlab/asciidoc/interdoc_reftext_resolver'
require 'gitlab/asciidoc/repository_tree'
require 'gitlab/asciidoc/syntax_highlighter/html_pipeline_adapter'

module Gitlab
  # Parser/renderer for the AsciiDoc format that uses Asciidoctor and filters
  # the resulting HTML through HTML pipeline filters.
  module Asciidoc
    MAX_INCLUDE_DEPTH = 5
    MAX_INCLUDES = 32
    DEFAULT_ADOC_ATTRS = {
        'showtitle' => true,
        'sectanchors' => true,
        'idprefix' => 'user-content-',
        'idseparator' => '-',
        'env' => 'gitlab',
        'env-gitlab' => '',
        'source-highlighter' => 'rouge',
        'icons' => 'font',
        'outfilesuffix' => '.adoc',
        'max-include-depth' => MAX_INCLUDE_DEPTH,
        'sectanchors' => true
    }.freeze

    # Public: Converts the provided Asciidoc markup into HTML.
    #
    # input         - the source text in Asciidoc format
    # context       - :commit, :project, :ref, :requested_path
    #
    def self.render(input, context)
      extensions = proc do
        include_processor ::Gitlab::Asciidoc::IncludeProcessor.new(context)

        tree_processor ::Asciidoctor::InterdocReftext::Processor.new(
          resolver_class: InterdocReftextResolver,
          repository_tree: RepositoryTree.new(context)
        )
      end

      attributes = if (project = context[:project])
        {
          'gl-commit-ref' => context[:ref] || context[:project].default_branch,
          'gl-pages-url' => project.pages_url,
          'gl-project-namespace' => project.namespace.full_path,
          'gl-project-path' => project.full_path,
          'gl-project-title' => project.title,
          'gl-project-url' => project.web_url,
          'gl-registry-url' => Gitlab.config.registry.host_port,
          'gl-registry-image-url' => project.container_registry_url,
          'gl-repo-http-url' => project.http_url_to_repo,
          'gl-repo-ssh-url' => project.ssh_url_to_repo,
          'gl-server-host' => Gitlab.config.gitlab.host,
          'gl-server-url' => Gitlab.config.gitlab.base_url,
          'gl-user-login' => context[:current_user]&.username,
        }.map { |k, v| "#{k}=#{v}" }
      else
        []
      end

      asciidoc_opts = { safe: :server,
                        backend: :gitlab_html5,
                        attributes: DEFAULT_ADOC_ATTRS + attributes,
                        extensions: extensions }

      context[:pipeline] = :ascii_doc
      context[:max_includes] = [MAX_INCLUDES, context[:max_includes]].compact.min

      plantuml_setup

      html = ::Asciidoctor.convert(input, asciidoc_opts)
      html = Banzai.render(html, context)
      html.html_safe
    end

    def self.plantuml_setup
      Asciidoctor::PlantUml.configure do |conf|
        conf.url = Gitlab::CurrentSettings.plantuml_url
        conf.svg_enable = Gitlab::CurrentSettings.plantuml_enabled
        conf.png_enable = Gitlab::CurrentSettings.plantuml_enabled
        conf.txt_enable = false
      end
    end
  end
end
