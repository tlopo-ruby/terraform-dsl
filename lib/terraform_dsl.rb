require "terraform_dsl/version"
require 'erb'

module TerraformDSL
  LIB_DIR = "#{__dir__}/terraform_dsl/"

  require "#{LIB_DIR}/block"
  require "#{LIB_DIR}/resource"
  require "#{LIB_DIR}/variable"
  require "#{LIB_DIR}/output"
  require "#{LIB_DIR}/data_source"
  require "#{LIB_DIR}/stack"
  require "#{LIB_DIR}/template"
  require "#{LIB_DIR}/formatter"


end
