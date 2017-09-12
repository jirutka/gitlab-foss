module Banzai
  module Pipeline
    class AsciiDocPipeline < BasePipeline
      def self.filters
        FilterArray[
          Filter::ExternalLinkFilter,
          Filter::PlantumlFilter,
          Filter::AsciiDocPostProcessingFilter
        ]
      end
    end
  end
end
