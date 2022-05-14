# Recode

A linter with autocorrection and a refactoring tool.

`recode` is an experimental project to play around with the great
[`sourceror`](https://github.com/doorgan/sourceror) package.

This library is still under development, breaking changes are expected.
The same is true for `sourceror` and most of `recode`'s functionality is based
on `sourceror`.

For now, `recode` reformats the code in some cases where the Elixir formatter
doesn't make any changes. It is also possible to run `recode` in a
none-autocorect mode to just lint your code.

Also, there is a mix task for code refactoring. At the moment it is only
possible to rename functions, replacing all function calls in the code.

## Installation

The package can be installed by adding `recode` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:recode, "~> 0.1"}
  ]
end
```

Documentation can be found at https://hexdocs.pm/recode.

## Usage

To start with `recode` we need a config file.
```shell
$ mix recode.gen.config
```
This mix task generates the config file `.recode.exs`.
```elixir
alias Recode.Task

[
  # Can also be set/reset with "--autocorrect"/"--no-autocorrect".
  autocorrect: true,
  # With "--dry" no changes will be writen to the files.
  # Can also be set/reset with "--dry"/"--no-dry".
  # If dry is true then verbose is also active.
  dry: false,
  # Can also be set/reset with "--verbose"/"--no-verbose".
  verbose: false,
  inputs: ["{config,lib,test}/**/*.{ex,exs}"],
  formatter: {Recode.Formatter, []},
  tasks: [
    {Task.AliasExpansion, []},
    {Task.AliasOrder, []},
    {Task.PipeFunOne, []},
    {Task.SinglePipe, []},
    {Task.Specs, []},
    {Task.TestFileExt, []}
  ]
]
```

### `mix recode`

### `mix recode.rename`

## Differences to Credo
