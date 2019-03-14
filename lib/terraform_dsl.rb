require 'terraform_dsl/version'
require 'yaml'
require 'erb'

# Terraform DSL
module TerraformDSL
  LIB_DIR = "#{__dir__}/terraform_dsl/".freeze

  require "#{LIB_DIR}/template"
  require "#{LIB_DIR}/formatter"
  require "#{LIB_DIR}/block"
  require "#{LIB_DIR}/resource"
  require "#{LIB_DIR}/variable"
  require "#{LIB_DIR}/output"
  require "#{LIB_DIR}/data_source"
  require "#{LIB_DIR}/provider"
  require "#{LIB_DIR}/tfmodule"
  require "#{LIB_DIR}/locals"
  require "#{LIB_DIR}/stack"
end
