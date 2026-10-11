# frozen_string_literal: true

require 'test_helper'

class TerraformDSL::StackTest < Minitest::Test
  # Every block kind, rendered the way terraform fmt would format it.
  EXPECTED = <<~HCL
    terraform {
      required_version = ">= 1.5"
      backend "local" {
        path = "terraform.tfstate"
      }
    }

    provider "aws" {
      region = "us-east-1"
    }

    variable "images" {
      type = map(string)
      default = {
        us-east-1 = "ami-123456"
        us-east-2 = "ami-654321"
      }
      validation {
        condition     = length(var.images) > 0
        error_message = "need at least one image"
      }
    }

    variable "foo" {
    }

    locals {
      name = "web"
      ports = [
        80,
        443
      ]
    }

    module "vpc" {
      source = "./vpc"
      cidr   = "10.0.0.0/16"
    }

    data "aws_ami" "web" {
      most_recent = true
      filter {
        name = "state"
        values = [
          "available"
        ]
      }
    }

    resource "aws_instance" "web" {
      ami       = data.aws_ami.web.id
      count     = 2
      user_data = <<-EOT
        #!/bin/bash
        echo hello

        exit 0
      EOT
      tags = {
        Name = local.name
        Env  = "prod"
      }
      lifecycle {
        precondition {
          condition     = var.foo != null
          error_message = "foo is required"
        }
      }
      provisioner "local-exec" {
        command = "whoami"
      }
    }

    output "id" {
      value       = aws_instance.web[0].id
      description = "say \\"hi\\""
    }

    moved {
      from = aws_instance.old
      to   = aws_instance.web
    }

    import {
      to = aws_instance.web[1]
      id = "i-123"
    }

    removed {
      from = aws_instance.gone
      lifecycle {
        destroy = false
      }
    }

    check "health" {
      data "http" "web" {
        url = "https://example.com"
      }
      assert {
        condition     = data.http.web.status_code == 200
        error_message = "web is down"
      }
    }

    ephemeral "random_password" "db" {
      length = 16
    }

    action "aws_lambda_invoke" "notify" {
      config {
        function_name = "notify"
      }
    }
  HCL

  def self.stack
    TerraformDSL::Stack.new do
      terraform do
        required_version '>= 1.5'
        backend 'local' do
          path 'terraform.tfstate'
        end
      end

      provider 'aws' do
        region 'us-east-1'
      end

      variable 'images' do
        type :'map(string)'
        default 'us-east-1': 'ami-123456', 'us-east-2': 'ami-654321'
        validation do
          condition :'length(var.images) > 0'
          error_message 'need at least one image'
        end
      end

      variable 'foo'

      locals do
        name 'web'
        ports [80, 443]
      end

      tfmodule 'vpc' do
        source './vpc'
        cidr '10.0.0.0/16'
      end

      data 'aws_ami', 'web' do
        most_recent true
        filter do
          name 'state'
          values ['available']
        end
      end

      resource 'aws_instance', 'web' do
        ami :'data.aws_ami.web.id'
        count 2
        user_data "#!/bin/bash\necho hello\n\nexit 0\n"
        tags Name: :'local.name', Env: 'prod'
        lifecycle do
          precondition do
            condition :'var.foo != null'
            error_message 'foo is required'
          end
        end
        provisioner 'local-exec' do
          command 'whoami'
        end
      end

      output 'id' do
        value :'aws_instance.web[0].id'
        description 'say "hi"'
      end

      moved do
        from :'aws_instance.old'
        to :'aws_instance.web'
      end

      import do
        to :'aws_instance.web[1]'
        id 'i-123'
      end

      removed do
        from :'aws_instance.gone'
        lifecycle do
          destroy false
        end
      end

      check 'health' do
        data 'http', 'web' do
          url 'https://example.com'
        end
        assert do
          condition :'data.http.web.status_code == 200'
          error_message 'web is down'
        end
      end

      ephemeral 'random_password', 'db' do
        length 16
      end

      action 'aws_lambda_invoke', 'notify' do
        config do
          function_name 'notify'
        end
      end
    end
  end

  def test_stack_composition
    assert_equal EXPECTED, self.class.stack.to_s
  end

  def test_datasource_is_an_alias_of_data
    stack = TerraformDSL::Stack.new { datasource 'aws_ami', 'x' }
    assert_equal "data \"aws_ami\" \"x\" {\n}\n", stack.to_s
  end

  def test_block_methods_return_the_block
    stack = TerraformDSL::Stack.new
    block = stack.resource('null_resource', 'x') { triggers a: 1 }
    assert_instance_of TerraformDSL::Resource, block
    assert_equal({ 'triggers' => { a: 1 } }, block.__attrs__)
  end
end
