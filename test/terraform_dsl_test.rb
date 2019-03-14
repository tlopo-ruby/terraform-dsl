require 'test_helper'

class TerraformDSLTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::TerraformDSL::VERSION
  end
end
