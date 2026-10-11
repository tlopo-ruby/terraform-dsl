# frozen_string_literal: true

module TerraformDSL
  class Moved < Block
    KEYWORD = 'moved'
    STATIC_REFS = (Block::STATIC_REFS + %w[from to]).freeze
  end
end
