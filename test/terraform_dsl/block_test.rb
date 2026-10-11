# frozen_string_literal: true

require 'test_helper'

# A top level method, as a user would define one next to their stack.
def block_test_helper(arg)
  "helped #{arg}"
end

class TerraformDSL::BlockTest < Minitest::Test
  def test_attributes_and_nested_blocks
    block = TerraformDSL::Resource.new('aws_vpc', 'main') do
      cidr_block '10.0.0.0/16'
      tags do
        Name 'main'
      end
    end

    assert_equal 'aws_vpc', block.__type__
    assert_equal ['main'], block.__labels__
    assert_equal({ 'cidr_block' => '10.0.0.0/16' }, block.__attrs__)
    assert_equal 'tags', block.__blocks__.first.__type__
    assert_equal '10.0.0.0/16', block.cidr_block
    assert_nil block.unknown
  end

  def test_assignment_syntax_and_multiple_arguments
    block = TerraformDSL::Block.new('b') do
      self.name = 'x'
      values 'a', 'b'
    end

    assert_equal({ 'name' => 'x', 'values' => %w[a b] }, block.__attrs__)
  end

  def test_ruby_method_names_can_be_attributes
    names = %w[hash method send format test display tap then clone dup extend]
    block = TerraformDSL::Block.new('b') { names.each { |n| __send__(n, 'v') } }

    assert_equal names, block.__attrs__.keys
  end

  def test_top_level_helpers_and_outer_locals_work
    suffix = 'y'
    block = TerraformDSL::Block.new('b') { value "#{block_test_helper('x')}#{suffix}" }

    assert_equal 'helped xy', block.value
  end

  def test_does_not_pretend_to_respond_to_everything
    block = TerraformDSL::Block.new('b')

    refute_respond_to block, :to_ary
    refute_respond_to block, :anything
    assert_respond_to block, :to_tf
  end

  def test_nested_block_header_quotes_labels_but_not_the_name
    block = TerraformDSL::Terraform.new { backend('s3') { bucket 'b' } }

    assert_equal <<~HCL, block.to_tf
      terraform {
        backend "s3" {
          bucket = "b"
        }
      }
    HCL
  end

  def test_to_s_is_the_hcl
    block = TerraformDSL::Locals.new { a 1 }
    assert_equal block.to_tf, block.to_s
    assert_equal "hcl: #{block.to_tf}", "hcl: #{block}"
  end
end
