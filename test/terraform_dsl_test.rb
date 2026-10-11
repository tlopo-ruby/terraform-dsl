# frozen_string_literal: true

require 'test_helper'

class TerraformDSLTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::TerraformDSL::VERSION
  end

  def test_stack_shortcut
    stack = TerraformDSL.stack { locals { a 1 } }
    assert_instance_of TerraformDSL::Stack, stack
    assert_equal "locals {\n  a = 1\n}\n", stack.to_s
  end
end
