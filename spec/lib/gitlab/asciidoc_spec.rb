# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

module Gitlab
  RSpec.describe Asciidoc do
    include FakeBlobHelpers

    before do
      allow_any_instance_of(ApplicationSetting).to receive(:current).and_return(::ApplicationSetting.create_from_defaults)
    end

    context "without project" do
      let(:input) { '<b>ascii</b>' }
      let(:context) { {} }
      let(:html) { 'H<sub>2</sub>O' }

      it "converts the input using Asciidoctor and default options" do
        expected_asciidoc_opts = {
            safe: :secure,
            backend: :gitlab_html5,
            attributes: described_class::DEFAULT_ADOC_ATTRS.merge({ "kroki-server-url" => nil }),
            extensions: be_a(Proc)
        }

        expect(Asciidoctor).to receive(:convert)
          .with(input, expected_asciidoc_opts).and_return(html)

        expect(render(input, context)).to eq(html)
      end

      context "with asciidoc_opts" do
        it "merges the options with default ones" do
          expected_asciidoc_opts = {
              safe: :secure,
              backend: :gitlab_html5,
              attributes: described_class::DEFAULT_ADOC_ATTRS.merge({ "kroki-server-url" => nil }),
              extensions: be_a(Proc)
          }

          expect(Asciidoctor).to receive(:convert)
            .with(input, expected_asciidoc_opts).and_return(html)

          render(input, context)
        end
      end

      context "with requested path" do
        input = <<~ADOC
          Document name: {docname}.
        ADOC

        it "ignores {docname} when not available" do
          expect(render(input, {})).to include(input.strip)
        end

        [
          ['/',                   '',       'root'],
          ['README',              'README', 'just a filename'],
          ['doc/api/',            '',       'a directory'],
          ['doc/api/README.adoc', 'README', 'a complete path']
        ].each do |path, basename, desc|
          it "sets {docname} for #{desc}" do
            expect(render(input, { requested_path: path })).to include(": #{basename}.")
          end
        end
      end

      context "XSS" do
        items = {
          'link with extra attribute' => {
            input: 'link:mylink"onmouseover="alert(1)[Click Here]',
            output: "<div>\n<p><a href=\"mylink\">Click Here</a></p>\n</div>"
          },
          'link with unsafe scheme' => {
              input: 'link:data://danger[Click Here]',
              output: "<div>\n<p><a>Click Here</a></p>\n</div>"
          },
          'image with onerror' => {
            input: 'image:https://localhost.com/image.png[Alt text" onerror="alert(7)]',
            output: "<div>\n<p><span><a class=\"no-attachment-icon\" href=\"https://localhost.com/image.png\" target=\"_blank\" rel=\"noopener noreferrer\"><img src=\"data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==\" alt='Alt text\" onerror=\"alert(7)' decoding=\"async\" class=\"lazy\" data-src=\"https://localhost.com/image.png\"></a></span></p>\n</div>"
          }
        }

        items.each do |name, data|
          it "does not convert dangerous #{name} into HTML" do
            expect(render(data[:input], context)).to include(data[:output])
          end
        end

        # `stub_feature_flags method` runs AFTER declaration of `items` above.
        # So the spec in its current implementation won't pass.
        # Move this test back to the items hash when removing `use_cmark_renderer` feature flag.
        it "does not convert dangerous fenced code with inline script into HTML" do
          input = '```mypre"><script>alert(3)</script>'
          output = "<div>\n<div>\n<div class=\"gl-relative markdown-code-block js-markdown-code\">\n<pre class=\"code highlight js-syntax-highlight language-plaintext\" lang=\"plaintext\" data-canonical-lang=\"mypre\" v-pre=\"true\"><code></code></pre>\n<copy-code></copy-code>\n</div>\n</div>\n</div>"

          expect(render(input, context)).to include(output)
        end

        it 'does not allow locked attributes to be overridden' do
          input = <<~ADOC
            {counter:max-include-depth:1234}
            <|-- {max-include-depth}
          ADOC

          expect(render(input, {})).not_to include('1234')
        end
      end

      context "images" do
        it "does lazy load and link image" do
          input = 'image:https://localhost.com/image.png[]'
          output = "<div>\n<p><span><a class=\"no-attachment-icon\" href=\"https://localhost.com/image.png\" target=\"_blank\" rel=\"noopener noreferrer\"><img src=\"data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==\" alt=\"image\" decoding=\"async\" class=\"lazy\" data-src=\"https://localhost.com/image.png\"></a></span></p>\n</div>"
          expect(render(input, context)).to include(output)
        end

        it "does not automatically link image if link is explicitly defined" do
          input = 'image:https://localhost.com/image.png[link=https://gitlab.com]'
          output = "<div>\n<p><span><a href=\"https://gitlab.com\" rel=\"nofollow noreferrer noopener\" target=\"_blank\"><img src=\"data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==\" alt=\"image\" decoding=\"async\" class=\"lazy\" data-src=\"https://localhost.com/image.png\"></a></span></p>\n</div>"
          expect(render(input, context)).to include(output)
        end
      end

      context 'with admonition' do
        it 'preserves classes' do
          input = <<~ADOC
            NOTE: An admonition paragraph, like this note, grabs the reader’s attention.
          ADOC

          output = <<~HTML
            <div class="admonitionblock">
            <table>
            <tr>
            <td class="icon">
            <i class="fa icon-note" title="Note"></i>
            </td>
            <td>
            An admonition paragraph, like this note, grabs the reader’s attention.
            </td>
            </tr>
            </table>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with passthrough' do
        it 'removes non heading ids' do
          input = <<~ADOC
            ++++
            <h2 id="foo">Title</h2>
            ++++
          ADOC

          output = <<~HTML
            <h2>Title</h2>
          HTML

          expect(render(input, context)).to include(output.strip)
        end

        it 'removes non footnote def ids' do
          input = <<~ADOC
            ++++
            <div id="def">Footnote definition</div>
            ++++
          ADOC

          output = <<~HTML
            <div>Footnote definition</div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end

        it 'removes non footnote ref ids' do
          input = <<~ADOC
            ++++
            <a id="ref">Footnote reference</a>
            ++++
          ADOC

          output = <<~HTML
            <a>Footnote reference</a>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with footnotes' do
        it 'preserves ids and links' do
          input = <<~ADOC
            This paragraph has a footnote.footnote:[This is the text of the footnote.]
          ADOC

          output = <<~HTML
            <div>
            <p>This paragraph has a footnote.<sup>[<a id="_footnoteref_1" href="#_footnotedef_1" title="View footnote.">1</a>]</sup></p>
            </div>
            <div>
            <hr>
            <div id="_footnotedef_1">
            <a href="#_footnoteref_1">1</a>. This is the text of the footnote.
            </div>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with section anchors' do
        it 'preserves ids and links' do
          input = <<~ADOC
            = Title

            == First section

            This is the first section.

            == Second section

            This is the second section.

            == Thunder ⚡ !

            This is the third section.
          ADOC

          output = <<~HTML
            <h1>Title</h1>
            <div>
            <h2 id="user-content-first-section">
            <a class="anchor" href="#user-content-first-section"></a>First section</h2>
            <div>
            <div>
            <p>This is the first section.</p>
            </div>
            </div>
            </div>
            <div>
            <h2 id="user-content-second-section">
            <a class="anchor" href="#user-content-second-section"></a>Second section</h2>
            <div>
            <div>
            <p>This is the second section.</p>
            </div>
            </div>
            </div>
            <div>
            <h2 id="user-content-thunder">
            <a class="anchor" href="#user-content-thunder"></a>Thunder ⚡ !</h2>
            <div>
            <div>
            <p>This is the third section.</p>
            </div>
            </div>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with xrefs' do
        it 'preserves ids' do
          input = <<~ADOC
            Learn how to xref:cross-references[use cross references].

            [[cross-references]]A link to another location within an AsciiDoc document or between AsciiDoc documents is called a cross reference (also referred to as an xref).
          ADOC

          output = <<~HTML
            <div>
            <p>Learn how to <a href="#cross-references">use cross references</a>.</p>
            </div>
            <div>
            <p><a id="user-content-cross-references"></a>A link to another location within an AsciiDoc document or between AsciiDoc documents is called a cross reference (also referred to as an xref).</p>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with checklist' do
        it 'preserves classes' do
          input = <<~ADOC
            * [x] checked
            * [ ] not checked
          ADOC

          output = <<~HTML
            <div>
            <ul class="checklist">
            <li>
            <p><i class="fa fa-check-square-o"></i> checked</p>
            </li>
            <li>
            <p><i class="fa fa-square-o"></i> not checked</p>
            </li>
            </ul>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with marks' do
        it 'preserves classes' do
          input = <<~ADOC
            Werewolves are allergic to #cassia cinnamon#.

            Did the werewolves read the [.small]#small print#?

            Where did all the [.underline.small]#cores# run off to?

            We need [.line-through]#ten# make that twenty VMs.

            [.big]##O##nce upon an infinite loop.
          ADOC

          output = <<~HTML
            <div>
            <p>Werewolves are allergic to <mark>cassia cinnamon</mark>.</p>
            </div>
            <div>
            <p>Did the werewolves read the <span class="small">small print</span>?</p>
            </div>
            <div>
            <p>Where did all the <span class="underline small">cores</span> run off to?</p>
            </div>
            <div>
            <p>We need <span class="line-through">ten</span> make that twenty VMs.</p>
            </div>
            <div>
            <p><span class="big">O</span>nce upon an infinite loop.</p>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with fenced block' do
        it 'highlights syntax' do
          input = <<~ADOC
            ```js
            console.log('hello world')
            ```
          ADOC

          output = <<~HTML
            <div>
            <div>
            <div class="gl-relative markdown-code-block js-markdown-code">
            <pre class="code highlight js-syntax-highlight language-javascript" lang="javascript" data-canonical-lang="js" v-pre="true"><code><span id="LC1" class="line" lang="javascript"><span class="nx">console</span><span class="p">.</span><span class="nx">log</span><span class="p">(</span><span class="dl">'</span><span class="s1">hello world</span><span class="dl">'</span><span class="p">)</span></span></code></pre>
            <copy-code></copy-code>
            </div>
            </div>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with listing block' do
        it 'highlights syntax' do
          input = <<~ADOC
            [source,c++]
            .class.cpp
            ----
            #include <stdio.h>

            for (int i = 0; i < 5; i++) {
              std::cout<<"*"<<std::endl;
            }
            ----
          ADOC

          output = <<~HTML
            <div>
            <div>class.cpp</div>
            <div>
            <div class="gl-relative markdown-code-block js-markdown-code">
            <pre class="code highlight js-syntax-highlight language-cpp" lang="cpp" data-canonical-lang="c++" v-pre="true"><code><span id="LC1" class="line" lang="cpp"><span class="cp">#include</span> <span class="cpf">&lt;stdio.h&gt;</span></span>
            <span id="LC2" class="line" lang="cpp"></span>
            <span id="LC3" class="line" lang="cpp"><span class="k">for</span> <span class="p">(</span><span class="kt">int</span> <span class="n">i</span> <span class="o">=</span> <span class="mi">0</span><span class="p">;</span> <span class="n">i</span> <span class="o">&lt;</span> <span class="mi">5</span><span class="p">;</span> <span class="n">i</span><span class="o">++</span><span class="p">)</span> <span class="p">{</span></span>
            <span id="LC4" class="line" lang="cpp">  <span class="n">std</span><span class="o">::</span><span class="n">cout</span><span class="o">&lt;&lt;</span><span class="s">"*"</span><span class="o">&lt;&lt;</span><span class="n">std</span><span class="o">::</span><span class="n">endl</span><span class="p">;</span></span>
            <span id="LC5" class="line" lang="cpp"><span class="p">}</span></span></code></pre>
            <copy-code></copy-code>
            </div>
            </div>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with stem block' do
        it 'does not apply syntax highlighting' do
          input = <<~ADOC
            [stem]
            ++++
            \sqrt{4} = 2
            ++++
          ADOC

          output = "<div>\n<div>\n\\$ qrt{4} = 2\\$\n</div>\n</div>"

          expect(render(input, context)).to include(output)
        end
      end

      context 'external links' do
        it 'adds the `rel` attribute to the link' do
          output = render('link:https://google.com[Google]', context)

          expect(output).to include('rel="nofollow noreferrer noopener"')
        end
      end

      context 'LaTex code' do
        it 'adds class js-render-math to the output' do
          input = <<~MD
            :stem: latexmath

            [stem]
            ++++
            \sqrt{4} = 2
            ++++

            another part

            [latexmath]
            ++++
            \beta_x \gamma
            ++++

            stem:[2+2] is 4
          MD

          expect(render(input, context)).to include('<pre data-math-style="display" class="code math js-render-math"><code>eta_x gamma</code></pre>')
          expect(render(input, context)).to include('<p><code data-math-style="inline" class="code math js-render-math">2+2</code> is 4</p>')
        end
      end

      context 'outfilesuffix' do
        it 'defaults to adoc' do
          output = render("Inter-document reference <<README.adoc#>>", context)

          expect(output).to include("a href=\"README.adoc\"")
        end
      end

      context 'with mermaid diagrams' do
        it 'adds class js-render-mermaid to the output' do
          input = <<~MD
            [mermaid]
            ....
            graph LR
                A[Square Rect] -- Link text --> B((Circle))
                A --> C(Round Rect)
                B --> D{Rhombus}
                C --> D
            ....
          MD

          output = <<~HTML
            <pre data-mermaid-style="display" class="js-render-mermaid">graph LR
                A[Square Rect] -- Link text --&gt; B((Circle))
                A --&gt; C(Round Rect)
                B --&gt; D{Rhombus}
                C --&gt; D</pre>
          HTML

          expect(render(input, context)).to include(output.strip)
        end

        it 'applies subs in diagram block' do
          input = <<~MD
            :class-name: AveryLongClass

            [mermaid,subs=+attributes]
            ....
            classDiagram
            Class01 <|-- {class-name} : Cool
            ....
          MD

          output = <<~HTML
            <pre data-mermaid-style="display" class="js-render-mermaid">classDiagram
            Class01 &lt;|-- AveryLongClass : Cool</pre>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end

      context 'with Kroki enabled' do
        before do
          allow_any_instance_of(ApplicationSetting).to receive(:kroki_enabled).and_return(true)
          allow_any_instance_of(ApplicationSetting).to receive(:kroki_url).and_return('https://kroki.io')
        end

        it 'converts a graphviz diagram to image' do
          input = <<~ADOC
            [graphviz]
            ....
            digraph G {
              Hello->World
            }
            ....
          ADOC

          output = <<~HTML
            <div>
            <div>
            <a class="no-attachment-icon" href="https://kroki.io/graphviz/svg/eNpLyUwvSizIUHBXqOZSUPBIzcnJ17ULzy_KSeGqBQCEzQka" target="_blank" rel="noopener noreferrer"><img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" alt="Diagram" decoding="async" class="lazy" data-src="https://kroki.io/graphviz/svg/eNpLyUwvSizIUHBXqOZSUPBIzcnJ17ULzy_KSeGqBQCEzQka"></a>
            </div>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end

        it 'does not convert a blockdiag diagram to image' do
          input = <<~ADOC
            [blockdiag]
            ....
            blockdiag {
              Kroki -> generates -> "Block diagrams";
              Kroki -> is -> "very easy!";

              Kroki [color = "greenyellow"];
              "Block diagrams" [color = "pink"];
              "very easy!" [color = "orange"];
            }
            ....
          ADOC

          output = <<~HTML
            <div>
            <div>
            <pre>blockdiag {
              Kroki -&gt; generates -&gt; "Block diagrams";
              Kroki -&gt; is -&gt; "very easy!";

              Kroki [color = "greenyellow"];
              "Block diagrams" [color = "pink"];
              "very easy!" [color = "orange"];
            }</pre>
            </div>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end

        it 'does not allow kroki-plantuml-include to be overridden' do
          input = <<~ADOC
            [plantuml, test="{counter:kroki-plantuml-include:/etc/passwd}", format="png"]
            ....
            class BlockProcessor

            BlockProcessor <|-- {counter:kroki-plantuml-include}
            ....
          ADOC

          output = <<~HTML
            <div>
            <div>
            <a class=\"no-attachment-icon\" href=\"https://kroki.io/plantuml/png/eNpLzkksLlZwyslPzg4oyk9OLS7OL-LiQuUr2NTo6ipUJ-eX5pWkFlllF-VnZ-oW5CTmlZTm5uhm5iXnlKak1gIABQEb8A==\" target=\"_blank\" rel=\"noopener noreferrer\"><img src=\"data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==\" alt=\"Diagram\" decoding=\"async\" class=\"lazy\" data-src=\"https://kroki.io/plantuml/png/eNpLzkksLlZwyslPzg4oyk9OLS7OL-LiQuUr2NTo6ipUJ-eX5pWkFlllF-VnZ-oW5CTmlZTm5uhm5iXnlKak1gIABQEb8A==\"></a>
            </div>
            </div>
          HTML

          expect(render(input, {})).to include(output.strip)
        end

        it 'does not allow kroki-server-url to be overridden' do
          input = <<~ADOC
            [plantuml, test="{counter:kroki-server-url:evilsite}", format="png"]
            ....
            class BlockProcessor

            BlockProcessor
            ....
          ADOC

          expect(render(input, {})).not_to include('evilsite')
        end
      end

      context 'with Kroki and BlockDiag (additional format) enabled' do
        before do
          allow_any_instance_of(ApplicationSetting).to receive(:kroki_enabled).and_return(true)
          allow_any_instance_of(ApplicationSetting).to receive(:kroki_url).and_return('https://kroki.io')
          allow_any_instance_of(ApplicationSetting).to receive(:kroki_formats_blockdiag).and_return(true)
        end

        it 'converts a blockdiag diagram to image' do
          input = <<~ADOC
            [blockdiag]
            ....
            blockdiag {
              Kroki -> generates -> "Block diagrams";
              Kroki -> is -> "very easy!";

              Kroki [color = "greenyellow"];
              "Block diagrams" [color = "pink"];
              "very easy!" [color = "orange"];
            }
            ....
          ADOC

          output = <<~HTML
            <div>
            <div>
            <a class="no-attachment-icon" href="https://kroki.io/blockdiag/svg/eNpdzDEKQjEQhOHeU4zpPYFoYesRxGJ9bwghMSsbUYJ4d10UCZbDfPynolOek0Q8FsDeNCestoisNLmy-Qg7R3Blcm5hPcr0ITdaB6X15fv-_YdJixo2CNHI2lmK3sPRA__RwV5SzV80ZAegJjXSyfMFptc71w==" target="_blank" rel="noopener noreferrer"><img src="data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==" alt="Diagram" decoding="async" class="lazy" data-src="https://kroki.io/blockdiag/svg/eNpdzDEKQjEQhOHeU4zpPYFoYesRxGJ9bwghMSsbUYJ4d10UCZbDfPynolOek0Q8FsDeNCestoisNLmy-Qg7R3Blcm5hPcr0ITdaB6X15fv-_YdJixo2CNHI2lmK3sPRA__RwV5SzV80ZAegJjXSyfMFptc71w=="></a>
            </div>
            </div>
          HTML

          expect(render(input, context)).to include(output.strip)
        end
      end
    end

    context 'with project' do
      let(:context) do
        {
          commit:         commit,
          project:        project,
          ref:            ref,
          requested_path: requested_path
        }
      end

      let(:commit)         { project.commit(ref) }
      let(:project)        { create(:project, :repository) }
      let(:ref)            { 'asciidoc' }
      let(:requested_path) { '/' }

      context 'include directive' do
        subject(:output) { render(input, context) }

        let(:input) { "Include this:\n\ninclude::#{include_path}[]" }

        before do
          current_file = requested_path
          current_file += 'README.adoc' if requested_path.end_with? '/'

          create_file(current_file, "= AsciiDoc\n")
        end

        def many_includes(target)
          Array.new(10, "include::#{target}[]").join("\n")
        end

        context 'cyclic imports' do
          before do
            create_file('doc/api/a.adoc', many_includes('b.adoc'))
            create_file('doc/api/b.adoc', many_includes('a.adoc'))
          end

          let(:include_path) { 'a.adoc' }
          let(:requested_path) { 'doc/api/README.md' }

          it 'completes successfully' do
            is_expected.to include('<p>Include this:</p>')
          end
        end

        context 'with path to non-existing file' do
          let(:include_path) { 'not-exists.adoc' }

          it 'renders Unresolved directive placeholder' do
            is_expected.to include("<strong>[ERROR: include::#{include_path}[] - unresolved directive]</strong>")
          end
        end

        shared_examples :invalid_include do
          let(:include_path) { 'dk.png' }

          before do
            allow(project.repository).to receive(:blob_at).and_return(blob)
          end

          it 'does not read the blob' do
            expect(blob).not_to receive(:data)
          end

          it 'renders Unresolved directive placeholder' do
            is_expected.to include("<strong>[ERROR: include::#{include_path}[] - unresolved directive]</strong>")
          end
        end

        context 'with path to a binary file' do
          let(:blob) { fake_blob(path: 'dk.png', binary: true) }

          include_examples :invalid_include
        end

        context 'with path to file in external storage' do
          let(:blob) { fake_blob(path: 'dk.png', lfs: true) }

          before do
            allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
            project.update_attribute(:lfs_enabled, true)
          end

          include_examples :invalid_include
        end

        context 'with path to a textual file' do
          let(:include_path) { 'sample.adoc' }

          before do
            create_file(file_path, "Content from #{include_path}")
          end

          shared_examples :valid_include do
            [
              ['/doc/sample.adoc',  'doc/sample.adoc',     'absolute path'],
              ['sample.adoc',       'doc/api/sample.adoc', 'relative path'],
              ['./sample.adoc',     'doc/api/sample.adoc', 'relative path with leading ./'],
              ['../sample.adoc',    'doc/sample.adoc',     'relative path to a file up one directory'],
              ['../../sample.adoc', 'sample.adoc',         'relative path for a file up multiple directories']
            ].each do |include_path_, file_path_, desc|
              context "the file is specified by #{desc}" do
                let(:include_path) { include_path_ }
                let(:file_path) { file_path_ }

                it 'includes content of the file' do
                  is_expected.to include('<p>Include this:</p>')
                  is_expected.to include("<p>Content from #{include_path}</p>")
                end
              end
            end
          end

          context 'when requested path is a file in the repo' do
            let(:requested_path) { 'doc/api/README.adoc' }

            include_examples :valid_include

            context 'without a commit (only ref)' do
              let(:commit) { nil }

              include_examples :valid_include
            end
          end

          context 'when requested path is a directory in the repo' do
            let(:requested_path) { 'doc/api/' }

            include_examples :valid_include

            context 'without a commit (only ref)' do
              let(:commit) { nil }

              include_examples :valid_include
            end
          end
        end

        context 'when repository is passed into the context' do
          let(:wiki_repo) { project.wiki.repository }
          let(:include_path) { 'wiki_file.adoc' }

          before do
            project.create_wiki
            context.merge!(repository: wiki_repo)
          end

          context 'when the file exists' do
            before do
              create_file(include_path, 'Content from wiki', repository: wiki_repo)
            end

            it { is_expected.to include('<p>Content from wiki</p>') }
          end

          context 'when the file does not exist' do
            it { is_expected.to include("[ERROR: include::#{include_path}[] - unresolved directive]") }
          end
        end

        context 'recursive includes with relative paths' do
          let(:input) do
            <<~ADOC
              Source: requested file

              include::doc/README.adoc[]

              include::license.adoc[]
            ADOC
          end

          before do
            create_file 'doc/README.adoc', <<~ADOC
              Source: doc/README.adoc

              include::../license.adoc[]

              include::api/hello.adoc[]
            ADOC
            create_file 'license.adoc', <<~ADOC
              Source: license.adoc
            ADOC
            create_file 'doc/api/hello.adoc', <<~ADOC
              Source: doc/api/hello.adoc

              include::./common.adoc[]
            ADOC
            create_file 'doc/api/common.adoc', <<~ADOC
              Source: doc/api/common.adoc
            ADOC
          end

          it 'includes content of the included files recursively' do
            expect(output.gsub(/<[^>]+>/, '').gsub(/\n\s*/, "\n").strip).to eq <<~ADOC.strip
              Source: requested file
              Source: doc/README.adoc
              Source: license.adoc
              Source: doc/api/hello.adoc
              Source: doc/api/common.adoc
              Source: license.adoc
            ADOC
          end
        end

        def create_file(path, content, repository: project.repository)
          repository.create_file(project.creator, path, content,
            message: "Add #{path}", branch_name: 'asciidoc')
        end
      end
    end

    def render(*args)
      described_class.render(*args)
    end
  end
end
