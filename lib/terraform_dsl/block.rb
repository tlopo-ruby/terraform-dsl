module TerraformDSL
  # This class is the representation of terraform configuration block
  # https://www.terraform.io/docs/configuration/
  class Block
    attr_reader :__type__, :__labels__
    @@formatter = Formatter.new
    def initialize(&block)
      @__blocks__ = []
      instance_eval(&block) if block_given?
    end

    def method_missing(method_name, *args, &block)
      super if [:respond_to_missing?].include? method_name
      method = method_name.to_s.gsub(/=$/, '')

      if block_given?
        r = Block.new
        r.__type__ = method
        r.__labels__ = args
        @__blocks__ << r
        return r.instance_eval(&block)
      end

      return instance_variable_set "@#{method}", *args unless args.empty?
      return instance_variable_get "@#{method}" if args.empty?
    end

    def respond_to_missing?(_method_name, _include_private = true)
      true
    end

    def to_tf
      @@formatter.format self
    end

    def to_str
      to_tf
    end

    def to_s
      to_tf
    end
  end
end
