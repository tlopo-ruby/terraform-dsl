require 'test_helper'
class TerraformDSL::FormatterTest < Minitest::Test
  def new_formatter
    f = TerraformDSL::Formatter.new
    %i[first_line local_vars child_blocks].each { |method| f.class.send :public, method }
    f
  end

  def test_it_formats_stack
    expected = <<-TEXT.gsub(/^ {4}/, '')
    variable "images"  {
        default = {
            us-east-1 = "ami-123456"
            us-east-2 = "ami-654321"
        }
        type = "map"
    }

    variable "foo"  {
    }

    data "aws_ami" "web" {
        filter  {
            name = "state"
            values = [
                "available"
            ]
        }
    }

    TEXT
    stack = TerraformDSL::Stack.new do
      variable 'images' do
        type 'map'
        default(
          'us-east-1': 'ami-123456',
          'us-east-2': 'ami-654321'
        )
      end

      variable 'foo'

      datasource 'aws_ami', 'web' do
        filter do
          name 'state'
          values ['available']
        end
      end
    end

    received = stack.to_s
    assert_equal expected, received
  end
end
