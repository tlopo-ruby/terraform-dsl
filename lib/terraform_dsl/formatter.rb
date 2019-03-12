module TerraformDSL
  # Class responsible for formatting the string representation of terraform blocks
  class Formatter
    def kind(cls)
      kinds = {
        Resource => 'resource',
        Variable => 'variable',
        DataSource => 'data',
        Output => 'output'
      }
      kinds[cls]
    end

    def format(tf_block)
      @depth ||= 0
      str = []

      if @depth.zero?
        str << first_line(tf_block)
        close = true
      end

      str << local_vars(tf_block) unless local_vars(tf_block).empty?

      str << child_blocks(tf_block) unless tf_block.__blocks__.empty?

      str[1..-1] = str[1..-1].map { |line| line.gsub(/^/, ' ' * 4) }
      str << "}\n\n" if close
      str.join("\n")
    end

    private

    def first_line(tf_block)
      labels = tf_block.__labels__.nil? ? [] : tf_block.__labels__
      labels_str = labels.map { |l| %("#{l}") }.join ' '
      kind = kind tf_block.class
      %(#{kind} "#{tf_block.__type__}" #{labels_str} {)
    end

    def local_vars(tf_block)
      str = ''
      tf_block.instance_variables.sort.each do |var_name|
        next if var_name =~ /@__/

        var = tf_block.instance_variable_get var_name
        var_name = var_name.to_s.delete('@')
        str << Template.list(var_name, var) if var.class == Array
        str << Template.map(var_name, var) if var.class == Hash
        str << Template.value(var_name, var) unless [Array, Hash].include? var.class
      end
      str
    end

    def child_blocks(tf_block)
      p [tf_block]
      str = ''
      tf_block.__blocks__.each do |b|
        @depth += 1
        child =  Template.child_block b
        indent = ' ' * 4
        child = child.gsub(/^/, indent) if @depth > 1
        str << child
        @depth -= 1
      end
      str
    end
  end
end