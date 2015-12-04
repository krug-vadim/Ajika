module Ajika
  # Execution context for classic style (top-level) applications. All
  # DSL methods executed on main are delegated to this class.
  #
  # The Application class should not be subclassed, unless you want to
  # inherit all settings, routes, handlers, and error pages from the
  # top-level. Subclassing Ajika::Base is highly recommended for
  # modular applications.
  class Application
    module DSL
      def category name
        puts name
        yield self if block_given?
      end

      def run data
        puts "RUN!"
      end

      def method_missing(*args, &block)
        puts args.inspect
        super if !(args.first =~ /^if_(\w+)$/)
        @actions ||= []
        @actions << [args, block]
        puts "actions: #{@actions}"
      end
    end

    class << self
      include DSL
    end
  end
end