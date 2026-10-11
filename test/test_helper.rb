# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'simplecov'

SimpleCov.minimum_coverage 95
SimpleCov.start { add_filter %r{^/test/} }

require 'terraform_dsl'
require 'minitest/autorun'
