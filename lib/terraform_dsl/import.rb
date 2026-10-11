# frozen_string_literal: true

module TerraformDSL
  class Import < Block
    KEYWORD = 'import'
    STATIC_REFS = (Block::STATIC_REFS + %w[to]).freeze
  end
end
