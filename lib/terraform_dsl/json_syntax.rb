# frozen_string_literal: true

module TerraformDSL
  # Helpers for rendering blocks in Terraform JSON syntax:
  # https://developer.hashicorp.com/terraform/language/syntax/json
  module JsonSyntax
    module_function

    # Symbols (raw HCL expressions) become "${...}" template strings, or bare
    # strings for static references such as depends_on or a variable's type.
    def value(obj, static: false)
      case obj
      when Hash then obj.to_h { |k, v| [k.to_s, value(v, static: static)] }
      when Array then obj.map { |v| value(v, static: static) }
      when Symbol then static ? obj.to_s : "${#{obj}}"
      else obj
      end
    end

    # Stores body under the nested keys. A repeated key turns into an array of
    # bodies, which is how JSON syntax represents repeated blocks.
    def insert(hash, keys, body)
      key, *rest = keys.map(&:to_s)
      return insert(hash[key] ||= {}, rest, body) unless rest.empty?

      hash[key] = case (existing = hash[key])
                  when nil then body
                  when Array then existing + [body]
                  else [existing, body]
                  end
    end
  end
end
