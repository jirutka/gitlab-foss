class MetricsService
  include Gitlab::CurrentSettings

  CHECKS = [
    Gitlab::HealthChecks::DbCheck,
    Gitlab::HealthChecks::Redis::RedisCheck,
    Gitlab::HealthChecks::Redis::CacheCheck,
    Gitlab::HealthChecks::Redis::QueuesCheck,
    Gitlab::HealthChecks::Redis::SharedStateCheck
  ].freeze

  def prometheus_metrics_text
    return unless current_application_settings[:prometheus_metrics_enabled]

    Prometheus::Client::Formats::Text.marshal_multiprocess(multiprocess_metrics_path)
  end

  def health_metrics_text
    metrics = CHECKS.flat_map(&:metrics)

    formatter.marshal(metrics)
  end

  def metrics_text
    prometheus_metrics_text.concat(health_metrics_text)
  end

  private

  def formatter
    @formatter ||= Gitlab::HealthChecks::PrometheusTextFormat.new
  end

  def multiprocess_metrics_path
    ::Prometheus::Client.configuration.multiprocess_files_dir
  end
end
