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

There is also one mix task for code refactoring. The task `mix recode.rename`
renames a function and all their function calls.

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
  # Can also be set/reset with "--autocorrect"/"--no-autocorrect".
  autocorrect: true,
  # With "--dry" no changes will be written to the files.
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
    {Task.Specs, [only: :visible, exclude: "test/**/*.{ex,exs}"]},
    {Task.TestFileExt, []}
  ]
]
```

### `mix recode`

This mix tasks runs the linter with autocorrection. The switch `--dry` prevents
the update of the files and shows all changes in the console.

```
> cd examples/my_code
> mix recode --dry
Found 11 files, including 2 scripts.
.............................................................................
 File: lib/my_code.ex
[Specs 15/3] Functions should have a @spec type specification.

 File: lib/my_code/alias_expansion.ex
Updates: 1
Changed by: AliasExpansion
001   |defmodule MyCode.AliasExpansion do
002 - |  alias MyCode.{PipeFunOne, SinglePipe}
002 + |  alias MyCode.PipeFunOne
003 + |  alias MyCode.SinglePipe
004   |
005   |  def foo(x) do
[Specs 5/3] Functions should have a @spec type specification.

 File: lib/my_code/alias_order.ex
Updates: 2
Changed by: AliasOrder, AliasExpansion
012   |
013   |defmodule Mycode.AliasOrder do
014 - |  alias MyCode.SinglePipe
014 + |  alias MyCode.Echo
015 + |  alias MyCode.Foxtrot
016   |  alias MyCode.PipeFunOne
017 - |  alias MyCode.{Foxtrot, Echo}
017 + |  alias MyCode.SinglePipe
018   |
019   |  @doc false

 File: lib/my_code/fun.ex
Updates: 1
Changed by: Format
002   |  @moduledoc false
003   |
004 - |
005 - |
006 - |
007 - |
008 - |
004   |  def noop(x), do: x
005   |end

 File: lib/my_code/multi.ex
Updates: 2
Changed by: SinglePipe, PipeFunOne
007   |
008   |  def pipe(x) do
009 - |    x |> double |> double()
009 + |    x |> double() |> double()
010   |  end
011   |
012   |  def single(x) do
013 - |    x |> double()
013 + |    double(x)
014   |  end
015   |

 File: lib/my_code/pipe_fun_one.ex
Updates: 1
Changed by: PipeFunOne
005   |
006   |  def pipe(x) do
007 - |    x |> double |> double()
007 + |    x |> double() |> double()
008   |  end
009   |end

 File: lib/my_code/singel_pipe.ex
Updates: 1
Changed by: SinglePipe
005   |
006   |  def single_pipe(x) do
007 - |    x |> double()
007 + |    double(x)
008   |  end
009   |
010 - |  def reverse(a), do: a |> Enum.reverse()
010 + |  def reverse(a), do: Enum.reverse(a)
011   |end
012   |

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

### `mix recode.rename`

A mix task to rename a function and all their function calls.

```
> cd examples/my_code
> mix recode.rename --dry MyCode.SinglePipe.double dbl
Found 11 files, including 2 scripts.
...........
 File: lib/my_code/alias_expansion.ex
Updates: 1
Changed by: Rename
003   |
004   |  def foo(x) do
005 - |    SinglePipe.double(x) + PipeFunOne.double(x)
005 + |    SinglePipe.dbl(x) + PipeFunOne.double(x)
006   |  end
007   |end

 File: lib/my_code/alias_order.ex
Updates: 1
Changed by: Rename
018   |  @doc false
019   |  def foo do
020 - |    {SinglePipe.double(2), PipeFunOne.double(3)}
020 + |    {SinglePipe.dbl(2), PipeFunOne.double(3)}
021   |  end
022   |

 File: lib/my_code/singel_pipe.ex
Updates: 1
Changed by: Rename
002   |  @moduledoc false
003   |
004 - |  def double(x), do: x + x
004 + |  def dbl(x), do: x + x
005   |
006   |  def single_pipe(x) do
007 - |    x |> double()
007 + |    x |> dbl()
008   |  end
009   |
```

Refactored code should be compellable, but it is not guaranteed.

## Differences to Credo

`recode` was started as a plugin for `credo`. Unfortunately it was not possible
to implement autocorrection as a plugin because the traversation of the code does
not support changing the code.



Maybe some code lines from `recode` could be used as inspiration for `credo`
to bring the autocorrect feature to `credo`.

Other differences:

* `recode` requiers Elixir 1.12, `credo` requiers Elixir 1.7
* `recode` has autocorrection
* `credo` has much more checkers
* `credo` is faster
* `credo` has more features
