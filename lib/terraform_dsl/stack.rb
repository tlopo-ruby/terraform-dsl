module TerraformDSL
  # This class is the representation of a terraform stack, or in another words
  # is a collection of terraform configuration blocks
  class Stack
    def initialize(&block)
      @resources, @outputs, @variables, @datasources = (1..4).to_a.map { [] }
      instance_eval(&block) if block_given?
    end

    %w[Resource Output Variable DataSource].each do |word|
      define_method word.downcase do |type, *labels, &b|
        cls = Object.const_get "TerraformDSL::#{word}"
        w = cls.new
        w.__type__ = type
        w.__labels__ = labels
        instance_variable_get("@#{word.downcase}s") << w
        w.instance_eval(&b)
      end
    end

    def to_s
      str = ''
      @variables.each { |v| str << v }
      @datasources.each { |d| str << d }
      @resources.each { |r| str << r }
      @outputs.each { |o| str << o }
      str
    end
  end
end
