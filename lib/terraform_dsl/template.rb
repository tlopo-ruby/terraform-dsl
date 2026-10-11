# frozen_string_literal: true

module TerraformDSL
  # Renders Ruby values as HCL values.
  #
  #   String  -> "quoted"  (heredoc when it ends with a newline)
  #   Symbol  -> raw expression, e.g. :'aws_vpc.main.id' or :string
  #   Numeric, true, false -> as is
  #   nil     -> null
  #   Array   -> [ ... ]
  #   Hash    -> { key = value }
  module Template
    module_function

    IDENTIFIER = /\A[A-Za-z_][\w-]*\z/.freeze
    ESCAPES = { '"' => '\"', '\\' => '\\\\', "\n" => '\n', "\r" => '\r', "\t" => '\t' }.freeze

    def value(value, depth = 0)
      case value
      when Hash then map(value, depth)
      when Array then list(value, depth)
      when String then string(value, depth)
      when nil then 'null'
      else value.to_s # Symbol (raw expression), Numeric, true, false
      end
    end

    def string(str, depth = 0)
      return heredoc(str, depth) if str.end_with?("\n")

      %("#{str.gsub(/["\\\n\r\t]/, ESCAPES)}")
    end

    def heredoc(str, depth)
      pad = INDENT * depth
      "<<-EOT\n#{str.gsub(/^(?!$)/, pad + INDENT)}#{pad}EOT"
    end

    def list(array, depth)
      return '[]' if array.empty?

      pad = INDENT * depth
      items = array.map { |v| "#{pad}#{INDENT}#{value(v, depth + 1)}" }
      "[\n#{items.join(",\n")}\n#{pad}]"
    end

    def map(hash, depth)
      return '{}' if hash.empty?

      pad = INDENT * depth
      items = hash.map { |k, v| [key(k), value(v, depth + 1)] }
      "{\n#{assignments(items, pad + INDENT).join("\n")}\n#{pad}}"
    end

    # Renders [name, value] pairs as "name = value" lines, aligning the equals
    # signs the way terraform fmt does: consecutive single-line values share a
    # column, a multi-line value ({ or [) breaks the run and is not aligned.
    def assignments(pairs, pad)
      pairs.slice_when { |a, b| multiline?(a[1]) || multiline?(b[1]) }.flat_map do |run|
        width = run.map { |name, _| name.size }.max
        run.map { |name, value| "#{pad}#{name.ljust(width)} = #{value}" }
      end
    end

    def multiline?(value)
      value.start_with?("{\n", "[\n")
    end

    def key(key)
      key = key.to_s
      key.match?(IDENTIFIER) ? key : string(key)
    end
  end
end
