# frozen_string_literal: true

module TerraformDSL
  # Renders a Block (and its nested blocks) as HCL text.
  module Formatter
    module_function

    def format(block, depth = 0)
      pad = INDENT * depth
      lines = ["#{pad}#{header(block)} {"]
      attrs = block.__attrs__.map { |name, value| [name, Template.value(value, depth + 1)] }
      lines.concat Template.assignments(attrs, pad + INDENT)
      block.__blocks__.each { |child| lines << format(child, depth + 1) }
      lines << "#{pad}}"
      lines.join("\n")
    end

    # Top level blocks:  resource "aws_vpc" "main"
    # Nested blocks:     backend "local"
    def header(block)
      keyword = block.class::KEYWORD
      name, *labels = keyword ? [keyword, block.__type__, *block.__labels__] : [block.__type__, *block.__labels__]
      [name, *labels.compact.map { |label| Template.string(label.to_s) }].join(' ')
    end
  end
end
