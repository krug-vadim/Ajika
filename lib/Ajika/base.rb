require 'mail'
require 'mail-gpg'

module Ajika
  CONSTRAINT_REGEXP = /^if_([\w\?]+)$/
  ACTION_REGEXP = /^do_(\w+)$/

  class Category
    attr_reader :name

    def initialize name
      @name = name
      @constraints = {}
      @actions = {}
    end

    def make_constraint(name, constraint)
      if constraint.is_a?(String) || constraint.is_a?(Fixnum) || constraint.is_a?(Array)
        lambda { |mail| mail.send(name.to_sym) == constraint }
      elsif constraint.is_a? Regexp
        lambda { |mail| mail.send(name.to_sym) =~ constraint }
      elsif constraint.is_a?(TrueClass) || constraint.is_a?(FalseClass) || constraint.is_a?(NilClass)
        lambda { |mail| mail.send(name.to_sym) == constraint }
      elsif constraint.is_a? Proc
        lambda { |mail| constraint.call(mail.send(name.to_sym)) }
      else
        raise "Wrong constraint type: #{constraint.class}"
      end
    end

    def add_constraint(name, *constraints)
      puts "adding constraint #{name}: #{constraints.inspect}"

      @constraints[name] = lambda do |mail|
        constraints.map{ |c| make_constraint(name, c) }.inject(false) { |p,d| p |= d.call(mail) }
      end
    end

    def add_action(name, *actions)
      puts "adding action #{name}: #{actions.inspect}"

      @actions[name] = lambda do |meta, text, attachments|
        actions.each { |action| action.call(meta, text, attachments) }
        #constraints.map{ |c| make_constraint(name, c) }.inject(true) { |p,d| p &= d.call(mail) }
      end
    end

    def parse(mail, meta, text, attachments)
      valid = @constraints.inject(true) do |product, constraint|
        print "checking #{constraint[0]}... "
        test = constraint[-1].call(mail)
        product &= test
        puts (test ? 'OK' : 'Fail')
        product
      end

      puts "#{name} is #{valid}"
      return if !valid

      @actions.each do |name, action|
        puts "running action: #{name}"
        action.call(meta, text, attachments)
      end
    end
  end

  class Application
    module DSL
      def category name
        @categories ||= []
        @categories << Category.new(name)
        yield self if block_given?
      end

      def action (name, &block)
        return if !block
        puts "we need action #{name}"
        @categories[-1].add_action(name, block)
      end

      def collect_multipart(part)
        if part.multipart?
          part.parts.map { |p| collect_multipart(p) }.join
        else
          #part.body.decoded if part.content_type.start_with?('text/plain')
          part.body.decoded.force_encoding(part.charset).encode("UTF-8") if part.content_type.start_with?('text/plain')
        end
      end

      def run data
        mail = Mail.new(data)

        puts mail.signed?
        verified = mail.verify
        puts "signature(s) valid: #{verified.signature_valid?}"
        puts "message signed by: #{verified.signatures.map{|sig|sig.from}.join("\n")}"
        #raise

        meta = {:date => mail.date}
        text = collect_multipart(mail)

        attachments = {}
        mail.attachments.each do | attachment |
          if (attachment.content_type.start_with?('image/'))
            attachments[attachment.filename] = attachment.body.decoded
          end
        end

        @categories.each do |category|
          puts "Trying #{category.name}..."
          category.parse(mail, meta, text, attachments)
        end
      end

      def method_missing(*args, &block)
        puts args.inspect

        if args.first =~ CONSTRAINT_REGEXP
          puts "we need check #{$1}"
          @categories[-1].add_constraint($1, *args[1..-1])
        elsif args.first =~ ACTION_REGEXP
          puts "we need action #{$1}"
          @categories[-1].add_action($1, *args[1..-1])
        end
      end
    end

    class << self
      include DSL
    end
  end
end
