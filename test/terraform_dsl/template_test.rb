# frozen_string_literal: true

require 'test_helper'

class TerraformDSL::TemplateTest < Minitest::Test
  T = TerraformDSL::Template

  def test_scalars
    assert_equal '"s"', T.value('s')
    assert_equal '1', T.value(1)
    assert_equal '1.5', T.value(1.5)
    assert_equal 'true', T.value(true)
    assert_equal 'false', T.value(false)
    assert_equal 'null', T.value(nil)
  end

  def test_symbols_are_raw_expressions
    assert_equal 'aws_vpc.main.id', T.value(:'aws_vpc.main.id')
    assert_equal 'map(string)', T.value(:'map(string)')
  end

  def test_strings_are_escaped
    assert_equal '"say \"hi\""', T.value('say "hi"')
    assert_equal '"a\\\\b"', T.value('a\\b')
    assert_equal '"line1\nline2"', T.value("line1\nline2")
    assert_equal '"tab\t"', T.value("tab\t")
    assert_equal '"${var.x}"', T.value('${var.x}')
  end

  def test_strings_ending_with_newline_become_heredocs
    expected = <<~HCL.chomp
      <<-EOT
          #!/bin/bash
            echo hi

          exit 0
        EOT
    HCL
    assert_equal expected, T.value("#!/bin/bash\n  echo hi\n\nexit 0\n", 1)
  end

  def test_lists
    assert_equal '[]', T.value([])
    assert_equal "[\n  1,\n  \"b\",\n  c\n]", T.value([1, 'b', :c])
    assert_equal "[\n    1\n  ]", T.value([1], 1)
  end

  def test_maps
    assert_equal '{}', T.value({})
    assert_equal "{\n  a = 1\n}", T.value({ a: 1 })
    assert_equal "{\n  us-east-1 = \"x\"\n}", T.value({ 'us-east-1' => 'x' })
    assert_equal "{\n  \"a key\" = 1\n  \"1a\"    = 2\n}", T.value({ 'a key' => 1, '1a' => 2 })
  end

  def test_nested_collections_and_alignment
    expected = <<~HCL.chomp
      {
        a    = 1
        bbbb = "x"
        list = [
          80,
          443
        ]
        c = {
          d = null
        }
        eeeeee = true
        f      = []
      }
    HCL
    value = { a: 1, bbbb: 'x', list: [80, 443], c: { d: nil }, eeeeee: true, f: [] }
    assert_equal expected, T.value(value)
  end
end
