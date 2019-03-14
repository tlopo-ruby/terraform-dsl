$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'pry'
require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter
])

SimpleCov.minimum_coverage 95
SimpleCov.start { add_filter %r{^/test/} }

require 'terraform_dsl'
require 'terraform_dsl/formatter'
require 'minitest/autorun'
