# frozen_string_literal: true

module TerraformDSL
  # A terraform configuration block: https://developer.hashicorp.com/terraform/language/syntax/configuration
  #
  # Inside the DSL block every bare method call becomes either an attribute
  # (when called with arguments) or a nested block (when called with a Ruby
  # block). Subclasses set KEYWORD to the top-level block keyword.
  class Block
    KEYWORD = nil
    # Arguments that take static references, which JSON syntax wants as plain
    # strings rather than "${...}" expressions. Subclasses extend the list.
    STATIC_REFS = %w[provider providers depends_on ignore_changes replace_triggered_by].freeze

    # Ruby methods a Block keeps. Everything else Object provides is undefined
    # so that it can be used as an attribute name (class, hash, method, ...).
    KEEP = %i[instance_eval instance_exec class is_a? kind_of? instance_of? respond_to? object_id
              __send__ __id__ equal? == != ! inspect to_s freeze frozen? nil?].freeze
    (instance_methods - KEEP).each { |m| undef_method m }
    # Private Kernel methods that are plausible attribute names.
    %i[format test select open system].each { |m| undef_method m }

    attr_accessor :__type__, :__labels__
    attr_reader :__attrs__, :__blocks__

    def initialize(type = nil, *labels, &block)
      @__type__ = type
      @__labels__ = labels
      @__attrs__ = {}
      @__blocks__ = []
      instance_eval(&block) if block
    end

    def method_missing(name, *args, &block)
      name = name.to_s.chomp('=')
      return (@__blocks__ << Block.new(name, *args, &block)).last if block
      return @__attrs__[name] if args.empty?

      @__attrs__[name] = args.size == 1 ? args.first : args
    end

    def respond_to_missing?(_name, _include_private = false)
      false
    end

    def to_tf
      "#{Formatter.format(self)}\n"
    end

    # The block body in Terraform JSON syntax: attributes plus nested blocks
    # keyed by type and labels.
    def to_h
      body = @__attrs__.to_h do |name, value|
        [name, JsonSyntax.value(value, static: self.class::STATIC_REFS.include?(name))]
      end
      @__blocks__.each { |child| JsonSyntax.insert(body, [child.__type__, *child.__labels__], child.to_h) }
      body
    end

    def to_s
      to_tf
    end
  end
end
