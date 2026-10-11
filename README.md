# TerraformDSL

A Chef like Ruby DSL that renders Terraform (HCL) configuration.

HCL is a fine configuration language, but it is not a programming language. This gem lets
you describe Terraform blocks in Ruby, with loops, helper methods and everything else Ruby
gives you, and renders them as `terraform fmt` formatted HCL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'terraform_dsl'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install terraform_dsl

## Usage

```ruby
require 'terraform_dsl'

stack = TerraformDSL.stack do
  resource 'aws_vpc', 'main' do
    cidr_block '10.0.0.0/16'
    instance_tenancy 'dedicated'
    tags Name: 'main'
  end

  resource 'aws_subnet', 'public' do
    vpc_id :'aws_vpc.main.id'
    cidr_block :'cidrsubnet(aws_vpc.main.cidr_block, 8, 1)'
    lifecycle do
      precondition do
        condition :'aws_vpc.main.enable_dns_support'
        error_message 'DNS support must be enabled'
      end
    end
  end
end

puts stack
```

The code above produces:

```hcl
resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "dedicated"
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  lifecycle {
    precondition {
      condition     = aws_vpc.main.enable_dns_support
      error_message = "DNS support must be enabled"
    }
  }
}
```

### Rules

Inside a block, every method call is either an **attribute** (when given arguments) or a
**nested block** (when given a Ruby block). Nested blocks can carry labels, so
`backend 'local' do ... end` renders `backend "local" { ... }`. Any nested block Terraform
knows works this way: `lifecycle`, `precondition`, `postcondition`, `validation`, `dynamic`,
`content`, `provisioner`, `connection`, `assert`, `required_providers`, and so on.

Ruby values map to HCL values:

| Ruby                   | HCL                                   |
|------------------------|---------------------------------------|
| `'text'`               | `"text"`, escaped as needed           |
| `"multi\nline\n"`      | `<<-EOT` heredoc (string ends in `\n`)|
| `:'aws_vpc.main.id'`   | raw expression `aws_vpc.main.id`      |
| `:string`, `:'list(string)'` | type expression                 |
| `1`, `1.5`, `true`     | `1`, `1.5`, `true`                    |
| `nil`                  | `null`                                |
| `[80, 443]`            | `[80, 443]` list                      |
| `{ Name: 'main' }`     | `{ Name = "main" }` map attribute     |

So a Hash argument gives a map **attribute** (`tags = { ... }`) while a Ruby block gives a
nested **block** (`lifecycle { ... }`). Symbols are written verbatim, which is how you
reference resources, variables, functions and types.

### Top level blocks

| DSL                                  | HCL                               |
|--------------------------------------|-----------------------------------|
| `terraform do ... end`               | `terraform { }`                   |
| `provider 'aws' do ... end`          | `provider "aws" { }`              |
| `variable 'name' do ... end`         | `variable "name" { }`             |
| `locals do ... end`                  | `locals { }`                      |
| `tfmodule 'vpc' do ... end`          | `module "vpc" { }`                |
| `data 'aws_ami', 'web' do ... end`   | `data "aws_ami" "web" { }`        |
| `resource 'aws_vpc', 'main' do ... end` | `resource "aws_vpc" "main" { }` |
| `output 'id' do ... end`             | `output "id" { }`                 |
| `moved do ... end`                   | `moved { }`                       |
| `import do ... end`                  | `import { }`                      |
| `removed do ... end`                 | `removed { }`                     |
| `check 'health' do ... end`          | `check "health" { }`              |
| `ephemeral 'random_password', 'db' do ... end` | `ephemeral "random_password" "db" { }` |
| `action 'aws_lambda_invoke', 'x' do ... end`   | `action "aws_lambda_invoke" "x" { }`   |

`module` is a Ruby keyword, hence `tfmodule`. `datasource` is kept as an alias of `data`.

### Using Ruby inside blocks

Blocks are evaluated with `instance_eval`, so local variables, constants and top level
helper methods are all available inside them:

```ruby
def ami_for(region)
  AMIS.fetch(region)
end

stack = TerraformDSL.stack do
  REGIONS.each do |region|
    resource 'aws_instance', "web_#{region}" do
      ami ami_for(region)
      instance_type 'm1.small'
    end
  end
end
```

Nearly every name works as an attribute, including Ruby method names such as `hash`,
`method`, `format` or `test`. The exceptions are `class`, `inspect`, `to_s` and a few other
basics a Ruby object needs, plus private Kernel methods that you would expect to keep working
inside a block, such as `puts`, `p`, `raise`, `require`, `lambda` or `loop`. Methods of a
surrounding class are not reachable from inside a block because `self` is the block.

Ruby keywords such as `alias` cannot be called bare, so use the assignment form:
`self.alias = 'west'`.

Each block class can also be used on its own:

```ruby
TerraformDSL::Resource.new('aws_vpc', 'main') { cidr_block '10.0.0.0/16' }.to_tf
```

### JSON output

A stack also renders in
[Terraform JSON syntax](https://developer.hashicorp.com/terraform/language/syntax/json),
for writing a `.tf.json` file:

```ruby
stack.to_json   # pretty printed JSON string
stack.to_h      # the same as a Hash
```

Symbols become `"${...}"` template strings, except where JSON syntax wants a plain reference
string: a variable's `type`, `provider`, `providers`, `depends_on`, `ignore_changes`,
`replace_triggered_by`, and the addresses in `moved`, `import` and `removed` blocks. Repeated
blocks, such as two `provider "aws"` blocks or two `ingress` blocks, become arrays.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run `rake` to
run RuboCop and the tests. You can also run `bin/console` for an interactive prompt.

When the `terraform` binary is on the PATH the test suite also checks the generated
configuration with `terraform fmt -check` and `terraform validate`.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new
version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and tags, and push the `.gem`
file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/tlopo-ruby/terraform-dsl. This project is intended to be a safe, welcoming
space for collaboration, and contributors are expected to adhere to the
[Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TerraformDSL project's codebases, issue trackers, chat rooms and
mailing lists is expected to follow the
[code of conduct](https://github.com/tlopo-ruby/terraform-dsl/blob/master/CODE_OF_CONDUCT.md).
