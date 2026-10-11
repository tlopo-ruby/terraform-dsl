# frozen_string_literal: true

require_relative 'terraform_dsl/version'

# A Chef like DSL that renders Terraform (HCL) configuration.
module TerraformDSL
  INDENT = '  '

  require_relative 'terraform_dsl/template'
  require_relative 'terraform_dsl/formatter'
  require_relative 'terraform_dsl/block'
  require_relative 'terraform_dsl/terraform'
  require_relative 'terraform_dsl/provider'
  require_relative 'terraform_dsl/variable'
  require_relative 'terraform_dsl/locals'
  require_relative 'terraform_dsl/tfmodule'
  require_relative 'terraform_dsl/data_source'
  require_relative 'terraform_dsl/resource'
  require_relative 'terraform_dsl/output'
  require_relative 'terraform_dsl/moved'
  require_relative 'terraform_dsl/import'
  require_relative 'terraform_dsl/removed'
  require_relative 'terraform_dsl/check'
  require_relative 'terraform_dsl/ephemeral'
  require_relative 'terraform_dsl/action'
  require_relative 'terraform_dsl/stack'

  # Shortcut for Stack.new
  def self.stack(&block)
    Stack.new(&block)
  end
end
