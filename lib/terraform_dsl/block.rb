module TerraformDSL
  # This class is the representation of terraform configuration block
  # https://www.terraform.io/docs/configuration/
  class Block
    attr_reader :__type__, :__labels__
    def initialize(&block)
      @__blocks__ = []
      instance_eval(&block) if block_given?
    end

    def method_missing(method_name, *args, &block)
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

      super
    end

    def respond_to_missing?(*args)
      super
    end

    def to_str
      Formatter.new.format self
    end
  end
end
