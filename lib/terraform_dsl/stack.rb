module TerraformDSL
  # This class is the representation of a terraform stack, or in another words
  # is a collection of terraform configuration blocks
  class Stack
    def initialize(&block)
      %w[providers variables locals tfmodules datasources resources outputs].each do |word|
        instance_variable_set "@#{word}", []
      end
      instance_eval(&block) if block_given?
    end

    %w[Provider Variable Locals TFModule DataSource Resource Output].each do |word|
      define_method word.downcase do |type = '', *labels, &b|
        cls = Object.const_get "TerraformDSL::#{word}"
        w = cls.new
        w.__type__ = type
        w.__labels__ = labels
        var_name = "@#{word.downcase}"
        var_name += 's' unless var_name[-1] == 's'
        instance_variable_get(var_name) << w
        w.instance_eval(&b) unless b.nil?
      end
    end

    def to_s
      str = ''
      %w[providers variables locals tfmodules datasources resources outputs].each do |word|
        instance_variable_get("@#{word}").each { |var| str << var }
      end
      str
    end
  end
end
