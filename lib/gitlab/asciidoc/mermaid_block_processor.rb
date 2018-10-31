module Gitlab
  module Asciidoc

    # Mermaid block that just wraps the content in
    # `<pre><code class="js-reader/mermaid">...</code></pre>`, so GitLab
    # renders it using Mermaid on the client-side.
    class MermaidBlockProcessor < Asciidoctor::Extensions::BlockProcessor
      use_dsl
      named :mermaid
      on_context [:listing, :literal, :open]
      parse_content_as :raw

      def process(parent, reader, attrs)
        subs = parent.resolve_block_subs(
          attrs.delete('subs') || '',
          Asciidoctor::Substitutors::BASIC_SUBS,
          'mermaid',
        )
        html = <<~HTML
          <code class="js-render-mermaid">
          #{parent.apply_subs(reader.source, subs)}
          </code>
        HTML
        create_block parent, :literal, html, attrs, subs: nil
      end
    end
  end
end
