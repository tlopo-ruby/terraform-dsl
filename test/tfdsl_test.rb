# frozen_string_literal: true

require 'test_helper'
require 'tfdsl'

class TFDSLTest < Minitest::Test
  def test_legacy_namespace_is_an_alias
    assert_same TerraformDSL, TFDSL
    assert_equal "locals {\n  a = 1\n}\n", TFDSL.stack { locals { a 1 } }.to_s
  end
end
