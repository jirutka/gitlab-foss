# frozen_string_literal: true

module Banzai
  module Filter
    class AsciiDocPostProcessingFilter < HTML::Pipeline::Filter
      CSS_MATH   = '[data-math-style]'
      XPATH_MATH = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_MATH).freeze
      CSS_MERM   = '[data-mermaid-style]'
      XPATH_MERM = Gitlab::Utils::Nokogiri.css_to_xpath(CSS_MERM).freeze
      XPATH_ROUGE = Gitlab::Utils::Nokogiri.css_to_xpath('.rouge.highlight > code').freeze

      def call
        doc.xpath(XPATH_MATH).each do |node|
          node.set_attribute('class', 'code math js-render-math')
        end

        doc.xpath(XPATH_MERM).each do |node|
          node.set_attribute('class', 'js-render-mermaid')
        end

        doc.xpath(XPATH_ROUGE).each do |code|
          lang = code.attr('data-lang')
          pre = code.parent

          code.remove_attribute('data-lang')
          code.remove_attribute('class')

          pre.set_attribute('class', "code highlight js-syntax-highlight language-#{lang}")
          pre.set_attribute('lang', lang)
          pre.set_attribute('v-pre', 'true')
        end

        doc
      end
    end
  end
end
