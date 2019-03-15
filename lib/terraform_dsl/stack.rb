module TerraformDSL
  # This class is the representation of a terraform stack, or in another words
  # is a collection of terraform configuration blocks
  class Stack
    def initialize(&block)
      @objects = []
      instance_eval(&block) if block_given?
    end

    %w[Provider Variable Locals TFModule DataSource Resource Output Terraform].each do |word|
      define_method word.downcase do |type = '', *labels, &b|
        cls = Object.const_get "TerraformDSL::#{word}"
        w = cls.new
        w.__type__ = type
        w.__labels__ = labels
        @objects << w
        w.instance_eval(&b) unless b.nil?
      end
    end

    def to_s
      @objects.each_with_object('') { |o, str| str << o }
    end
  end
end
