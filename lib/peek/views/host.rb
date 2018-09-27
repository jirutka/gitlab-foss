module Peek
  module Views
    class Host < View
      def results
        { hostname: Gitlab::Environment.hostname }
      end
    end if defined?(View)
  end
end
