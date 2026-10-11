# frozen_string_literal: true

module TerraformDSL
  class Variable < Block
    KEYWORD = 'variable'
    STATIC_REFS = (Block::STATIC_REFS + %w[type]).freeze
  end
end
