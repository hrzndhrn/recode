# Recode
[![Hex.pm: version](https://img.shields.io/hexpm/v/recode.svg?style=flat-square)](https://hex.pm/packages/recode)
[![GitHub: CI status](https://img.shields.io/github/workflow/status/hrzndhrn/recode/CI?style=flat-square)](https://github.com/hrzndhrn/recode/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://github.com/hrzndhrn//blob/main/LICENSE.md)

A linter with autocorrection and a refactoring tool.

`recode` is an experimental project to play around with the great
[`sourceror`](https://github.com/doorgan/sourceror) package by @doorgan.

This library is still under development, breaking changes are expected.
The same is true for `sourceror` and most of `recode`'s functionality is based
on `sourceror`.

For now, `recode` corrects only a few things:

* `AliasExpansion` expands multi aliases
* `AliasOrder` orders aliases alphabetically
* `Format` runs the Elixir formatter
* `PipeFunOne` adds `()` to one arity functions in pipes
* `SinglePipe` corrects single pipes
* `TestFileExt` renames test file extensions to `*.exs`

It is also possible to run `recode` in a none-autocorect mode to just lint your
code.

## Installation

The package can be installed by adding `recode` to your list of dependencies
in `mix.exs`:

```elixir
  def deps do
    [
      {:recode, "~> 0.3", only: :dev}
    ]
  end
```

`Recode` requires Elixir 1.13.0 or higher. If you add `recode` to a project that
supports lower Elixir versions you could add recode as following:
```elixir
  def deps do
    [
      # your deps
    ] ++ recode()
  end

  defp recode() do
    case Version.match?(System.version(), "~> 1.13") do
      true -> [{:recode, "~> 0.3", only: :dev]}]
      false -> []
    end
  end
```

Documentation can be found at [https://hexdocs.pm/recode](https://hexdocs.pm/recode).

## Usage

To start with Foo a configuration file is needed.

```sh
mix recode.gen.config
```

This mix task generates the config file `.recode.exs`.

```elixir
alias Recode.Task

[
  version: "0.3.0",
  # Can also be set/reset with "--autocorrect"/"--no-autocorrect".
  autocorrect: true,
  # With "--dry" no changes will be written to the files.
  # Can also be set/reset with "--dry"/"--no-dry".
  # If dry is true then verbose is also active.
  dry: false,
  # Can also be set/reset with "--verbose"/"--no-verbose".
  verbose: false,
  # Can be overwriten by calling `mix recode "lib/**/*.ex"`.
  inputs: ["{config,lib,test}/**/*.{ex,exs}"],
  formatter: {Recode.Formatter, []},
  tasks: [
    # Tasks could be added by a tuple of the tasks module name and an options
    # keyword list. A task can be deactived by `active: false`. The execution of
    # a deactivated task can be forced by calling `mix recode --task ModuleName`.
    {Task.AliasExpansion, []},
    {Task.AliasOrder, []},
    {Task.EnforceLineLength, active: false},
    {Task.PipeFunOne, []},
    {Task.SinglePipe, []},
    {Task.Specs, exclude: "test/**/*.{ex,exs}", config: [only: :visible]},
    {Task.TestFileExt, []},
    {Task.UnusedVariable, active: false}
  ]
]
```

### `mix recode`

This mix tasks runs the linter with autocorrection. The switch `--dry` prevents
the update of the files and shows all changes in the console.

```
> cd examples/my_code
> mix recode --dry
Found 13 files, including 2 scripts.
...........................................................................................
 File: lib/my_code.ex
[Specs 15/3] Functions should have a @spec type specification.

 File: lib/my_code/alias_expansion.ex
Updates: 1
Changed by: AliasExpansion
1 1   |defmodule MyCode.AliasExpansion do
2   - |  alias MyCode.{PipeFunOne, SinglePipe}
  2 + |  alias MyCode.PipeFunOne
  3 + |  alias MyCode.SinglePipe
3 4   |
4 5   |  def foo(x) do
   ...|
[Specs 5/3] Functions should have a @spec type specification.

 File: lib/my_code/alias_order.ex
Updates: 2
Changed by: AliasOrder, AliasExpansion
     ...|
12 12   |
13 13   |defmodule Mycode.AliasOrder do
14    - |  alias MyCode.SinglePipe
   14 + |  alias MyCode.Echo
   15 + |  alias MyCode.Foxtrot
15 16   |  alias MyCode.PipeFunOne
16    - |  alias MyCode.{Foxtrot, Echo}
   17 + |  alias MyCode.SinglePipe
17 18   |
18 19   |  @doc false
     ...|

 File: lib/my_code/fun.ex
Updates: 1
Changed by: Format
     ...|
 2  2   |  @moduledoc false
 3  3   |
 4    - |
 5    - |
 6    - |
 7    - |
 8    - |
 9  4   |  def noop(x), do: x
10  5   |end
     ...|

 File: lib/my_code/multi.ex
Updates: 2
Changed by: SinglePipe, PipeFunOne
     ...|
 7  7   |
 8  8   |  def pipe(x) do
 9    - |    x |> double |> double()
    9 + |    x |> double() |> double()
10 10   |  end
11 11   |
12 12   |  def single(x) do
13    - |    x |> double()
   13 + |    double(x)
14 14   |  end
15 15   |
     ...|

 File: lib/my_code/pipe_fun_one.ex
Updates: 1
Changed by: PipeFunOne
     ...|
 5  5   |
 6  6   |  def pipe(x) do
 7    - |    x |> double |> double()
    7 + |    x |> double() |> double()
 8  8   |  end
 9  9   |end
     ...|

 File: lib/my_code/same_line.ex
[Specs 2/3] Functions should have a @spec type specification.

 File: lib/my_code/singel_pipe.ex
Updates: 1
Changed by: SinglePipe
     ...|
 5  5   |
 6  6   |  def single_pipe(x) do
 7    - |    x |> double()
    7 + |    double(x)
 8  8   |  end
 9  9   |
10    - |  def reverse(a), do: a |> Enum.reverse()
   10 + |  def reverse(a), do: Enum.reverse(a)
11 11   |end
12 12   |

 File: test/my_code_test.exs
Updates: 1
Changed by: TestFileExt
Moved from: test/my_code_test.ex
```

The switch `--no-autocorrect` runs the linter without any file changes.

```
> cd examples/my_code
> mix recode --no-autocorrect
Found 11 files, including 2 scripts.
.............................................................................
 File: lib/my_code.ex
[Specs 15/3] Functions should have a @spec type specification.

 File: lib/my_code/alias_expansion.ex
[AliasExpansion 2/3] Avoid multi aliases.
[Specs 4/3] Functions should have a @spec type specification.

 File: lib/my_code/alias_order.ex
[AliasOrder 15/3] The alias `MyCode.PipeFunOne` is not alphabetically ordered among its group
[AliasOrder 16/3] The alias `MyCode` is not alphabetically ordered among its group
[AliasOrder 16/26] The alias `Echo` is not alphabetically ordered among its multi group
[AliasExpansion 16/3] Avoid multi aliases.

 File: lib/my_code/fun.ex
[Format -/-] The file is not formatted.

 File: lib/my_code/multi.ex
[PipeFunOne 9/7] Use parentheses for one-arity functions in pipes.
[SinglePipe 13/7] Use a function call when a pipeline is only one function long.

 File: lib/my_code/pipe_fun_one.ex
[PipeFunOne 7/7] Use parentheses for one-arity functions in pipes.

 File: lib/my_code/singel_pipe.ex
[SinglePipe 7/7] Use a function call when a pipeline is only one function long.
[SinglePipe 10/25] Use a function call when a pipeline is only one function long.

 File: test/my_code_test.ex
[TestFileExt -/-] The file must be renamed to test/my_code_test.exs so that ExUnit can find it.
```

## Differences to Credo

`recode` was started as a plugin for `credo`. Unfortunately it was not possible
to implement autocorrection as a plugin because the traversation of the code does
not support changing the code.



Maybe some code lines from `recode` could be used as inspiration for `credo`
to bring the autocorrect feature to `credo`.

Other differences:

* `recode` requiers Elixir 1.13, `credo` requiers Elixir 1.7
* `recode` has autocorrection
* `credo` has much more checkers
* `credo` is faster
* `credo` has more features
