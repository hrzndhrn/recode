# Recode

`recode` is an experimental project to play around with the great
[`sourceror`](https://github.com/doorgan/sourceror) package.

For now, `recode` reformats the code in some cases where the Elixir formatter
doesn't make any changes (see Usage below).

## Installation

`recode` is not yet available in Hex. If you want to give it a try, you can
install the package from GitHub:

```elixir
def deps do
  [
    {:recode, git: "https://github.com/hrzndhrn/recode.git"},
  ]
end
```

## Usage

`recode` comes with two tasks to reformat code:

* Alias expansion (`alias-expansion`):
  This task expands multi-alias syntax like `alias Foo.{Bar, Baz}` into multiple
  `alias` calls. This code was taken from the
  [notebook](https://github.com/doorgan/sourceror/blob/main/notebooks/expand_multi_alias.livemd)
  in the `sourceror` repo.

* One arity functions in pipes (`pipe-fun-one`):
  The [style guide](https://github.com/christopheradams/elixir_style_guide#parentheses-pipe-operator)
  proposes to add parentheses for one-arity functions when using the pipe
  operator. This task will add such parentheses.

The mix task `mix recode` performs the changes below on all files in your project.

With `mix recode --pipe-fun-one`, `recode` will make only the changes for `pipe-fun-one`.

With `mix recode --no-pipe-fun-one`, `recode` will skip the changes for `pipe-fun-one`.

