module TerraformDSL
  # Collection of small templates to be used on to_s / to_str of blocks
  module Template
    module_function

    def list(name, value)
      template = <<-TEXT.gsub(/^ {6}/, '')
      <%=name%> = [
      <%-value.each_with_index do |v,index| -%>
          "<%=v%>"<%=index != value.size - 1 ? ',' : '' %>
      <%-end-%>
      ]
      TEXT
      ERB.new(template, nil, '-').result(binding).strip
    end

    def map(name, value)
      template = <<-TEXT.gsub(/^ {6}/, '')
      <%=name%> = {
      <%-value.each do |k,v| -%>
          <%=k%> = "<%=v%>"
      <%-end-%>
      }
      TEXT
      ERB.new(template, nil, '-').result(binding).strip
    end

    def child_block(value)
      labels = value.__labels__.nil? ? [] : value.__labels__
      labels_str = labels.map { |l| %("#{l}") }.join ' '
      type = value.__type__.nil? ? '' : %( #{value.__type__} )
      template = <<-TEXT.gsub(/^ {6}/, '')
      <%=type%><%=labels_str%> {
      <%- unless value.to_s.empty? -%>
      <%=value.to_tf.strip.gsub(/^/,'    ')%>
      <%- end -%>
      }
      TEXT
      ERB.new(template, nil, '-').result(binding).strip
    end

    def value(name, value)
      template = <<-TEXT.gsub(/^ {6}/, '')
      <%=name%> = "<%=value%>"
      TEXT
      ERB.new(template, nil, '-').result(binding).strip
    end
  end
end
