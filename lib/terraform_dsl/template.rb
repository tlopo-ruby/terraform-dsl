module TerraformDSL
  # Collection of small templates to be used on to_s / to_str of blocks
  module Template
    module_function

    def list(name, value)
      template = <<-TEXT.gsub(/^ {4}/, '')
      <%=name%> = [
        <%-value.each_with_index do |v,index| -%>
          "<%=v%>"<%=index != value.size - 1 ? ',' : '' %>
        <%-end-%>
      ]
      TEXT
      ERB.new(template, nil, '-').result(binding).strip
    end

    def map(name, value)
      template = <<-TEXT.gsub(/^ {4}/, '')
      <%=name%> = {
        <%-value.each_with_index do |(k,v),index| -%>
          <%=k%> = <%=v%><%=index != value.size - 1 ? ',' : '' %>
        <%-end-%>
      }
      TEXT
      ERB.new(template, nil, '-').result(binding).strip
    end

    def child_block(value)
      labels = value.__labels__.nil? ? [] : value.__labels__
      labels_str = labels.map { |l| %("#{l}") }.join ' '
      template = <<-TEXT.gsub(/^ {4}/, '')
      <%=value.__type__%> <%=labels_str%> {
          <%=value.to_tf.strip%>
      }
      TEXT
      ERB.new(template, nil, '-').result(binding).strip
    end

    def value(name, value)
      template = <<-TEXT.gsub(/^ {4}/, '')
      <%=name%> = "<%=value%>"
      TEXT
      ERB.new(template, nil, '-').result(binding).strip
    end
  end
end
