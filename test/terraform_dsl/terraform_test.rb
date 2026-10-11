# frozen_string_literal: true

require 'test_helper'
require 'tmpdir'
require 'open3'

# Runs the real terraform binary against generated configuration.
# Skipped when terraform is not on the PATH.
class TerraformDSL::TerraformTest < Minitest::Test
  def setup
    skip 'terraform not installed' unless system('terraform', 'version', out: File::NULL, err: File::NULL)
  end

  def test_stack_output_is_canonically_formatted
    in_tmp_tf(TerraformDSL::StackTest.stack.to_s) do
      terraform 'fmt', '-check', '-diff', 'main.tf'
    end
  end

  # Only the builtin terraform_data resource is used so that no provider has
  # to be downloaded.
  def test_generated_configuration_is_valid
    stack = TerraformDSL.stack do
      terraform do
        required_version '>= 1.5'
      end

      variable 'name' do
        type :string
        default 'web'
        validation do
          condition :'length(var.name) > 0'
          error_message 'name must not be empty'
        end
      end

      locals do
        tags Name: :'var.name', Count: 2, Enabled: true, Ports: [80, 443], 'odd key' => nil
        script "#!/bin/bash\necho \"hi\"\n\nexit 0\n"
      end

      resource 'terraform_data', 'web' do
        input :'local.tags'
        lifecycle do
          precondition do
            condition :'var.name != ""'
            error_message 'name is required'
          end
        end
      end

      resource 'terraform_data', 'many' do
        count 2
        input :'count.index'
      end

      moved do
        from :'terraform_data.old'
        to :'terraform_data.web'
      end

      import do
        to :'terraform_data.many[0]'
        id 'imported'
      end

      removed do
        from :'terraform_data.gone'
        lifecycle do
          destroy false
        end
      end

      check 'web' do
        assert do
          condition :'terraform_data.web.output != null'
          error_message 'no output'
        end
      end

      output 'id' do
        value :'terraform_data.web.id'
        description 'say "hi"'
      end
    end

    in_tmp_tf(stack.to_s) do
      terraform 'fmt', '-check', '-diff', 'main.tf'
      terraform 'init', '-backend=false', '-input=false'
      terraform 'validate'
    end
  end

  private

  def in_tmp_tf(hcl, &block)
    Dir.mktmpdir do |dir|
      File.write File.join(dir, 'main.tf'), hcl
      Dir.chdir(dir, &block)
    end
  end

  def terraform(*args)
    out, status = Open3.capture2e('terraform', *args)
    assert status.success?, "terraform #{args.join(' ')} failed:\n#{out}\n--- main.tf:\n#{File.read('main.tf')}"
  end
end
