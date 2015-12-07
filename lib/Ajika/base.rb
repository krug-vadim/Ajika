require 'mail'
require 'fileutils'

module Ajika
  CONSTRAINT_REGEXP = /^if_(\w+)$/
  # Execution context for classic style (top-level) applications. All
  # DSL methods executed on main are delegated to this class.
  #
  # The Application class should not be subclassed, unless you want to
  # inherit all settings, routes, handlers, and error pages from the
  # top-level. Subclassing Ajika::Base is highly recommended for
  # modular applications.
  class Category
    attr_reader :name

    def initialize name
      @name = name
      @constraints = {}
    end

    def add_constraint(name, *constraint)
      puts "adding constraint #{name}: #{constraint.inspect}"
      if constraint.is_a? String
        @constraints[name] = lambda { |mail| mail.send(name.to_sym) == constraint }
      elsif constraint.is_a? Array
        @constraints[name] = lambda { |mail| mail.send(name.to_sym) == constraint }
      elsif constraint.is_a? Regexp
        @constraints[name] = lambda { |mail| mail.send(name.to_sym) =~ constraint }
      elsif constraint.is_a? Proc
        @constraints[name] = lambda { |mail| constraint.call(mail.send(name.to_sym)) }
      end
    end

    def parse data
      valid = @constraints.inject(true) do |product, constraint|
        print "checking #{constraint[0]}... "
        test = constraint[-1].call(data)
        product &= test
        puts (test ? 'OK' : 'Fail')
        product
      end

      puts "#{name} is #{valid}"
    end
  end

  class Application
    module DSL
      def category name
        @categories ||= []
        @categories << Category.new(name)
        yield self if block_given?
      end

      def collect_multipart(part)
        if part.multipart?
          part.parts.map { |p| collect_multipart(p) }.join
        else
          part.body if part.content_type.start_with?('text/plain')
        end
      end

      def run data
        mail = Mail.new(data)

        @categories.each do |category|
          puts "Trying #{category.name}..."
          category.parse(mail)
        end
      end

      def method_missing(*args, &block)
        puts args.inspect

        if args.first =~ CONSTRAINT_REGEXP
          puts "we need check #{$1}"
          @categories[-1].add_constraint $1, *args[1..-1]
        end
      end
    end

    class << self
      include DSL
    end
  end
end
