# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'terraform_dsl/version'

Gem::Specification.new do |spec|
  spec.name          = 'terraform_dsl'
  spec.version       = TerraformDSL::VERSION
  spec.authors       = ['Tiago Lopo']
  spec.email         = ['tlopo@github.com']

  spec.summary       = 'A chef like DSL for terraform'
  spec.description   = 'A Ruby DSL that renders Terraform (HCL) configuration'
  spec.homepage      = 'https://github.com/tlopo-ruby/terraform-dsl'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|\.github)/}) }
  end
  spec.require_paths = ['lib']
end
