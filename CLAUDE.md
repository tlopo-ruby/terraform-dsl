# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`terraform_dsl` is a small Ruby gem (no runtime dependencies) that renders a Chef-like Ruby DSL as
Terraform HCL text. The output is meant to be byte-identical to what `terraform fmt` produces.

## Commands

```bash
bin/setup                      # bundle install
bundle exec rake               # rubocop + full test suite (the default task, what CI runs)
bundle exec rake test          # tests only
bundle exec rubocop            # lint only (RuboCop 1.x, NewCops enabled, TargetRubyVersion 2.7)
bundle exec rubocop -a         # autocorrect safe offenses

# Single test file / single test
bundle exec ruby -Ilib -Itest test/terraform_dsl/template_test.rb
bundle exec ruby -Ilib -Itest test/terraform_dsl/block_test.rb -n test_assignment_syntax_and_multiple_arguments

bin/console                    # IRB with the gem loaded
```

SimpleCov enforces 95% minimum line coverage; the suite fails below that.

`test/terraform_dsl/terraform_test.rb` shells out to the real `terraform` binary (`fmt -check`,
`init -backend=false`, `validate`) and is skipped when `terraform` is not on the PATH. CI installs
Terraform, so locally install it too if you touch rendering. The validate fixture deliberately uses only
the builtin `terraform_data` resource so no provider download is needed.

`Gemfile.lock` is intentionally not committed. Dev dependencies live in the `Gemfile`, not the gemspec.

## Architecture

Rendering flows `Stack -> Block -> Formatter -> Template`:

- **`Block`** (`lib/terraform_dsl/block.rb`) is the whole DSL. `method_missing` turns a call with
  arguments into an entry in the ordered `@__attrs__` hash and a call with a Ruby block into a child
  `Block` in `@__blocks__` (its name is `__type__`, extra args are `__labels__`). Attribute order is
  declaration order. So that almost any HCL attribute name works, the class body **undefines every
  inherited Object method except `KEEP`**, plus a few private Kernel methods (`format`, `test`,
  `select`, `open`, `system`). Consequences: anything you need to call on a Block instance from
  library or test code (e.g. `instance_of?` for Minitest's `assert_instance_of`) must be in `KEEP`;
  and Block is a plain `Object`, not `BasicObject`, precisely so that `puts`, `raise` and top-level
  helper methods still work inside DSL blocks.
- **Marker subclasses** (`Resource`, `Variable`, `Moved`, `Check`, `Action`, ...) each only set
  `KEYWORD`. `Formatter.header` uses `block.class::KEYWORD` to decide top-level vs nested rendering:
  top-level quotes `__type__` and labels after the keyword (`resource "aws_vpc" "main"`), nested
  prints `__type__` bare and quotes only labels (`backend "local"`). Adding a Terraform top-level
  block type = new 7-line subclass file + `require_relative` in `lib/terraform_dsl.rb` + an entry in
  `Stack::BLOCKS`. Nested block kinds (`lifecycle`, `precondition`, `dynamic`, ...) need no code.
- **`Stack`** defines one method per `BLOCKS` entry and joins the blocks' `to_tf` with blank lines.
  `tfmodule` exists because `module` is a Ruby keyword; `data`/`datasource` are aliases.
- **`Formatter`** (stateless module, depth passed as a parameter) renders a block's header,
  attributes, children and closing brace with 2-space indentation.
- **`Template`** maps Ruby values to HCL: String -> quoted/escaped (heredoc `<<-EOT` when it ends
  with `\n`), **Symbol -> raw expression** (this is how references, functions and types are
  written), Numeric/true/false bare, nil -> `null`, Array/Hash recursive. A Hash argument is a map
  *attribute* (`tags = {}`); a Ruby block is a nested *block*. `Template.assignments` reproduces
  `terraform fmt`'s `=` alignment: consecutive single-line values share a column, a multi-line
  `{`/`[` value breaks the run and is itself unaligned. Blank lines inside heredocs must stay empty
  (Terraform ignores them when computing `<<-` indentation; padding them changes the value).

## Testing conventions

- `test/terraform_dsl/stack_test.rb` holds one golden `EXPECTED` string covering every block kind,
  exposed as `StackTest.stack` so `terraform_test.rb` can run `terraform fmt -check` on the same
  output. Any change to rendering must keep that fixture passing `fmt -check`; update `EXPECTED` to
  the canonical `terraform fmt` form, never the other way round.
- Fixtures must be valid Terraform 0.12+ (e.g. `provisioner`, not `provider`, inside a resource).
