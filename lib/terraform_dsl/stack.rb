# frozen_string_literal: true

module TerraformDSL
  # A collection of top level terraform blocks, rendered as one .tf file.
  class Stack
    BLOCKS = {
      terraform: Terraform, provider: Provider, variable: Variable, locals: Locals,
      tfmodule: TFModule, datasource: DataSource, resource: Resource, output: Output,
      moved: Moved, import: Import, removed: Removed, check: Check,
      ephemeral: Ephemeral, action: Action
    }.freeze

    def initialize(&block)
      @objects = []
      instance_eval(&block) if block
    end

    BLOCKS.each do |name, cls|
      define_method(name) do |type = nil, *labels, &block|
        @objects << cls.new(type, *labels, &block)
        @objects.last
      end
    end
    alias data datasource

    def to_s
      @objects.map(&:to_tf).join("\n")
    end
  end
end
