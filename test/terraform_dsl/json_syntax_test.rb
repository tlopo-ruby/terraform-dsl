# frozen_string_literal: true

require 'test_helper'

class TerraformDSL::JsonSyntaxTest < Minitest::Test
  J = TerraformDSL::JsonSyntax

  def test_symbols_become_template_strings
    assert_equal '${aws_vpc.main.id}', J.value(:'aws_vpc.main.id')
    assert_equal({ 'a' => '${var.x}', 'b' => [1, '${var.y}'] }, J.value({ a: :'var.x', b: [1, :'var.y'] }))
  end

  def test_static_references_stay_bare
    assert_equal 'aws_vpc.main.id', J.value(:'aws_vpc.main.id', static: true)
    assert_equal({ 'aws' => 'aws.west' }, J.value({ aws: :'aws.west' }, static: true))
  end

  def test_other_values_pass_through
    assert_equal 1, J.value(1)
    assert_equal 'x', J.value('x')
    assert_equal '${var.x}', J.value('${var.x}')
    assert_nil J.value(nil)
    assert_equal true, J.value(true)
  end

  def test_insert_nests_by_keys_and_turns_repeats_into_arrays
    hash = {}
    J.insert(hash, %w[resource aws_vpc main], { 'a' => 1 })
    J.insert(hash, %w[resource aws_vpc other], { 'b' => 2 })
    J.insert(hash, %w[provider aws], { 'region' => 'x' })
    J.insert(hash, %w[provider aws], { 'region' => 'y' })
    J.insert(hash, %w[provider aws], { 'region' => 'z' })
    J.insert(hash, %w[locals], { 'c' => 3 })

    expected = {
      'resource' => { 'aws_vpc' => { 'main' => { 'a' => 1 }, 'other' => { 'b' => 2 } } },
      'provider' => { 'aws' => [{ 'region' => 'x' }, { 'region' => 'y' }, { 'region' => 'z' }] },
      'locals' => { 'c' => 3 }
    }
    assert_equal expected, hash
  end
end
