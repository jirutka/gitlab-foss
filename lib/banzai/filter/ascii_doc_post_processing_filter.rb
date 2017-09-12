module Banzai
  module Filter
    class AsciiDocPostProcessingFilter < HTML::Pipeline::Filter
      def call
        doc.search('[data-math-style]').each do |node|
          node.set_attribute('class', 'code math js-render-math')
        end

        doc.search('.rouge.highlight > code').each do |code|
          lang = code.attr('data-lang')
          pre = code.parent

          code.remove_attribute('data-lang')
          code.remove_attribute('class')

          pre.set_attribute('class', "code highlight js-syntax-highlight #{lang}")
          pre.set_attribute('lang', lang)
          pre.set_attribute('v-pre', 'true')
        end

        doc
      end
    end
  end
end
