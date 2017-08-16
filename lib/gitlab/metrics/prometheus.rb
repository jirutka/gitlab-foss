module Gitlab
  module Metrics
    module Prometheus
      include Gitlab::CurrentSettings
      include Gitlab::Utils::StrongMemoize

      REGISTRY_MUTEX = Mutex.new
      PROVIDER_MUTEX = Mutex.new

      def metrics_folder_present?
        return false unless prometheus_metrics_enabled?

        multiprocess_files_dir = ::Prometheus::Client.configuration.multiprocess_files_dir

        multiprocess_files_dir &&
          ::Dir.exist?(multiprocess_files_dir) &&
          ::File.writable?(multiprocess_files_dir)
      end

      def prometheus_metrics_enabled?
        strong_memoize(:prometheus_metrics_enabled) do
          prometheus_metrics_enabled_unmemoized
        end
      end

      def registry
        strong_memoize(:registry) do
          REGISTRY_MUTEX.synchronize do
            strong_memoize(:registry) do
              ::Prometheus::Client.registry
            end
          end
        end
      end

      def counter(name, docstring, base_labels = {})
        safe_provide_metric(:counter, name, docstring, base_labels)
      end

      def summary(name, docstring, base_labels = {})
        safe_provide_metric(:summary, name, docstring, base_labels)
      end

      def gauge(name, docstring, base_labels = {}, multiprocess_mode = :all)
        safe_provide_metric(:gauge, name, docstring, base_labels, multiprocess_mode)
      end

      def histogram(name, docstring, base_labels = {}, buckets = nil)
        buckets ||= ::Prometheus::Client::Histogram::DEFAULT_BUCKETS if defined?(::Prometheus::Client)
        safe_provide_metric(:histogram, name, docstring, base_labels, buckets)
      end

      private

      def safe_provide_metric(method, name, *args)
        metric = provide_metric(name)
        return metric if metric

        PROVIDER_MUTEX.synchronize do
          provide_metric(name) || registry.method(method).call(name, *args)
        end
      end

      def provide_metric(name)
        if prometheus_metrics_enabled?
          registry.get(name)
        else
          NullMetric.new
        end
      end

      def prometheus_metrics_enabled_unmemoized
        current_application_settings[:prometheus_metrics_enabled] && metrics_folder_present? || false
      end
    end
  end
end
