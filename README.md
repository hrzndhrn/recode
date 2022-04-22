# Recode

A linter with autocorrection and a refactoring tool.

`recode` is an experimental project to play around with the great
[`sourceror`](https://github.com/doorgan/sourceror) package.

This library is still under development, breaking changes are expected.
The same is true for `sourceror` and most of `recode`'s functionality is based
on `sourceror`.

For now, `recode` reformats the code in some cases where the Elixir formatter
doesn't make any changes (see Usage below).

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

## Differences to Credo
