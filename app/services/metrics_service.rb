# frozen_string_literal: true

class MetricsService
  def prometheus_metrics_text
    return unless Gitlab::CurrentSettings.prometheus_metrics_enabled

    Prometheus::Client::Formats::Text.marshal_multiprocess(multiprocess_metrics_path)
  end

  def metrics_text
    prometheus_metrics_text
  end

  private

  def multiprocess_metrics_path
    ::Prometheus::Client.configuration.multiprocess_files_dir
  end
end
