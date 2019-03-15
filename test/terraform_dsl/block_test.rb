require 'test_helper'

class TerraformDSL::BlockTest < Minitest::Test
  def test_it_responds_to_missing_for_anything
    tfblock = TerraformDSL::Block.new
    tfblock.class.send :public, :respond_to_missing?
    assert_equal true, tfblock.respond_to_missing?(:whatever)
  end
end
