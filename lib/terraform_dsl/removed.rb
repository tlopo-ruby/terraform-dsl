# frozen_string_literal: true

module TerraformDSL
  class Removed < Block
    KEYWORD = 'removed'
    STATIC_REFS = (Block::STATIC_REFS + %w[from]).freeze
  end
end
