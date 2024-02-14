# Recode
[![Hex.pm: version](https://img.shields.io/hexpm/v/recode.svg?style=flat-square)](https://hex.pm/packages/recode)
[![GitHub: CI status](https://img.shields.io/github/actions/workflow/status/hrzndhrn/recode/ci.yml?branch=main&style=flat-square)](https://github.com/hrzndhrn/recode/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://github.com/hrzndhrn//blob/main/LICENSE.md)

A linter with autocorrection.

`recode` is an experimental project to play around with the great
[`sourceror`](https://github.com/doorgan/sourceror) package by @doorgan.

This library is still under development, breaking changes are expected.
The same is true for `sourceror` and most of `recode`'s functionality is based
on `sourceror`.

`recode` can correct and check the following things:

```sh
> mix recode.help

Design tasks:
TagFIXME          # Checker   - Checks if there are FIXME tags in the sources.
TagTODO           # Checker   - Checks if there are TODO tags in the sources.
Readability tasks:
AliasExpansion    # Corrector - Exapnds multi aliases to separate aliases.
AliasOrder        # Corrector - Checks if aliases are sorted alphabetically.
EnforceLineLength # Corrector - Forces expressions to one line.
Format            # Corrector - Does the same as `mix format`.
PipeFunOne        # Corrector - Add parentheses to one-arity functions.
SinglePipe        # Corrector - Pipes should only be used when piping data through multiple calls.
Specs             # Checker   - Checks for specs.
Refactor tasks:
FilterCount       # Corrector - Checks calls like Enum.filter(...) |> Enum.count().
Nesting           # Checker   - Checks code nesting depth in functions and macros.
Warning tasks:
Dbg               # Corrector - There should be no calls to dbg.
IOInspect         # Corrector - There should be no calls to IO.inspect.
TestFileExt       # Corrector - Checks the file extension of test files.
UnusedVariable    # Corrector - Checks if unused variables occur.
```

It is also possible to run `recode` in a none-autocorrect mode to just lint your
code.

## Installation

The package can be installed by adding `recode` to your list of dependencies
in `mix.exs`:

```elixir
  def deps do
    [
      {:recode, "~> 0.7", only: :dev}
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
      true -> [{:recode, "~> 0.4", only: :dev}]
      false -> []
    end
  end
```

Documentation can be found at [https://hexdocs.pm/recode](https://hexdocs.pm/recode).

## Usage

To start with `recode` a configuration file is needed.

```sh
mix recode.gen.config
```

This mix task generates the config file `.recode.exs`.

```elixir
[
  version: "0.7.0",
  # Can also be set/reset with `--autocorrect`/`--no-autocorrect`.
  autocorrect: true,
  # With "--dry" no changes will be written to the files.
  # Can also be set/reset with `--dry`/`--no-dry`.
  # If dry is true then verbose is also active.
  dry: false,
  # Can also be set/reset with `--verbose`/`--no-verbose`.
  verbose: false,
  # Can be overwritten by calling `mix recode "lib/**/*.ex"`.
  inputs: ["{mix,.formatter}.exs", "{apps,config,lib,test}/**/*.{ex,exs}"],
  formatters: [Recode.CLIFormatter],
  tasks: [
    # Tasks could be added by a tuple of the tasks module name and an options
    # keyword list. A task can be deactivated by `active: false`. The execution of
    # a deactivated task can be forced by calling `mix recode --task ModuleName`.
    {Recode.Task.AliasExpansion, []},
    {Recode.Task.AliasOrder, []},
    {Recode.Task.Dbg, [autocorrect: false]},
    {Recode.Task.EnforceLineLength, [active: true, exclude: "mix.exs"]},
    {Recode.Task.FilterCount, []},
    {Recode.Task.IOInspect, [autocorrect: false]},
    {Recode.Task.Nesting, []},
    {Recode.Task.PipeFunOne, []},
    {Recode.Task.SinglePipe, []},
    {Recode.Task.Specs, [exclude: "test/**/*.{ex,exs}", config: [only: :visible]]},
    {Recode.Task.TagFIXME, [exit_code: 2]},
    {Recode.Task.TagTODO, [exit_code: 4]},
    {Recode.Task.TestFileExt, []},
    {Recode.Task.UnusedVariable, [active: false]}
  ]
]
```

If a configuration file already exists, you can use the mix task

```sh
mix recode.update.config
```

to update the configuration file.

### `mix recode`

This mix task runs the linter with autocorrection. The switch `--dry` (alias
`-d`) prevents the update of the files and shows all changes in the console.

```
> cd examples/my_code
> mix recode --dry --no-color
Read 19 files in 0.05s
!.........!........!!...............................!................!...!......
.......................!...........................!..!!..........!.........!...
..............!.!......!......!.....!......!...............!..........!...!.....
...........!!..!.!!.!..
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

File: lib/my_code/deep.ex
[Specs 2/3] Functions should have a @spec type specification.
[Nesting 6/11] The body is nested too deep (max depth: 2).

File: lib/my_code/empty.ex
Updates: 1
Changed by: Format

File: lib/my_code/multi.ex
Updates: 4
Changed by: SinglePipe, PipeFunOne, FilterCount, Format
 1  1   |defmodule MyCode.Multi do
 2    - |
 3  2   |  import MyCode.Fun
 4  3   |
     ...|
 6  5   |
 7  6   |  def pipe(x) do
 8    - |    x |> double |> double() |> dbg()
    7 + |    x |> double() |> double() |> dbg()
 9  8   |  end
10  9   |
11 10   |  def single(x) do
12    - |    x |> double()
   11 + |    double(x)
13 12   |  end
14 13   |
     ...|
19 18   |  def my_count(list) do
20 19   |    list
21    - |    |> Enum.filter(fn x -> rem(x, 2) == 0 end)
22    - |    |> Enum.count()
   20 + |    |> Enum.count(fn x -> rem(x, 2) == 0 end)
23 21   |    |> IO.inspect()
24 22   |  end
     ...|
[Specs 4/3] Functions should have a @spec type specification.
[Specs 6/3] Functions should have a @spec type specification.
[Dbg 7/34] There should be no calls to dbg.
[Specs 10/3] Functions should have a @spec type specification.
[Specs 14/3] Functions should have a @spec type specification.
[Specs 18/3] Functions should have a @spec type specification.
[IOInspect 21/8] There should be no calls to IO.inspect.

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

File: lib/my_code/single_pipe.ex
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

File: lib/my_code/tags.ex
[TagTODO 3/-] Found a tag: TODO: add docs
[TagFIXME 6/-] Found a tag: FIXME: add more functions
[Specs 7/3] Functions should have a @spec type specification.

File: lib/my_code/trailing_comma.ex
Updates: 2
Changed by: SinglePipe, Format
     ...|
 3  3   |
 4  4   |  def list do
 5    - |    [
    5 + |    Enum.reverse([
 6  6   |      100_000,
 7  7   |      200_000,
     ...|
14 14   |      900_000,
15 15   |      1_000_000,
16    - |      2_000_000,
17    - |    ] |> Enum.reverse()
   16 + |      2_000_000
   17 + |    ])
18 18   |  end
19 19   |end
     ...|

File: mix.exs
Updates: 1
Changed by: Format
     ...|
 9  9   |      start_permanent: Mix.env() == :prod,
10 10   |      deps: deps(),
11    - |      aliases: aliases(),
   11 + |      aliases: aliases()
12 12   |    ]
13 13   |  end
     ...|
16 16   |    [
17 17   |      extra_applications: [:logger],
18    - |      mod: {Recode.Application, []},
   18 + |      mod: {Recode.Application, []}
19 19   |    ]
20 20   |  end
     ...|
23 23   |    [
24 24   |      backup: ["cmd elixir ./scripts/backup.exs"],
25    - |      "backup.restore": ["cmd elixir ./scripts/backup.exs restore"],
   25 + |      "backup.restore": ["cmd elixir ./scripts/backup.exs restore"]
26 26   |    ]
27 27   |  end
     ...|
32 32   |      # dev/test
33 33   |      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
34    - |      {:freedom_formatter, "~> 2.1", only: :dev},
   34 + |      {:freedom_formatter, "~> 2.1", only: :dev}
35 35   |    ]
36 36   |  end
     ...|

File: test/my_code_test.exs
Updates: 1
Changed by: TestFileExt
Moved from: test/my_code_test.ex

Executed 244 tasks in 0.01s.
Files: 19 (.ex: 15, .exs: 4)
Moved 1 file
Updated 8 files
Found 15 issues
Finished in 0.06s.
```

The switch `--no-autocorrect` runs the linter without any file changes. In this
mode, all correctors are working as checkers.

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
[Dbg 9/32] There should be no calls to dbg.
[SinglePipe 13/7] Use a function call when a pipeline is only one function long.
[FilterCount 22/12] `Enum.count/2` is more efficient than `Enum.filter/2 |> Enum.count/1`
[IOInspect 24/8] There should be no calls to IO.inspect.

 File: lib/my_code/pipe_fun_one.ex
[PipeFunOne 7/7] Use parentheses for one-arity functions in pipes.

 File: lib/my_code/single_pipe.ex
[SinglePipe 7/7] Use a function call when a pipeline is only one function long.
[SinglePipe 10/25] Use a function call when a pipeline is only one function long.

 File: test/my_code_test.ex
[TestFileExt -/-] The file must be renamed to test/my_code_test.exs so that ExUnit can find it.

Finished in 0.05 seconds.
```

With the switch `--autocorrect` (alias `-a`), correctors that are configured
with `autocorrect: false` going into the corrections mode.

Use the switch `--task` (alias `-t`) to run a specific task. This switch can be
used multiple times.

The last two switches are helpful for the task `IOInspect` and `Dbg`. Both of
the tasks are correctors configured with `autocorrect: false` in the default
configuration. The following example shows how to run these two tasks.

```
> cd examples/my_code
> mix recode -t IOInspect -t Dbg
Found 18 files, including 3 scripts.
....................................
 File: lib/my_code/multi.ex
[Dbg 9/32] There should be no calls to dbg.
[IOInspect 24/8] There should be no calls to IO.inspect.

Finished in 0.04 seconds.
```

To delete all occurrences of `dbg` and `IO.inspect` the following call can be
used.

```
> cd examples/my_code
> mix recode -av -t IOInspect -t Dbg
Found 18 files, including 3 scripts.
....................................
 File: lib/my_code/multi.ex
Updates: 2
Changed by: Dbg, IOInspect
     ...|
 7  7   |
 8  8   |  def pipe(x) do
 9    - |    x |> double |> double() |> dbg()
    9 + |    x |> double |> double()
10 10   |  end
11 11   |
     ...|
22 22   |    |> Enum.filter(fn x -> rem(x, 2) == 0 end)
23 23   |    |> Enum.count()
24    - |    |> IO.inspect()
25 24   |  end
26 25   |end
     ...|

Finished in 0.04 seconds.
```

The `-av` stands for the switches `--autocorrect` and `--verbose`. The switch
`--verbose` causes `recode` to display all changes as a diff on the console.

### `mix format`

You can also run Recode together with `mix format` by adding
`Recode.FormatterPlugin` to your `.formatter.exs` plugins:

```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [Recode.FormatterPlugin]
]
```

If you are using [ElixirLS](https://github.com/elixir-lsp/elixir-ls), you will
need to enable `recode` for the test environment:

```elixir
  def deps do
    [
      {:recode, "~> 0.7", only: [:dev, :test]}
    ]
  end
```

### `mix recode.help`

The task `recode.help` prints all available recode-task with a short description.

The task prints the documentation for a given recode-task.

```sh
> mix recode.help Dbg
                                Recode.Task.Dbg

Calls to dbg/2 should only appear in debug sessions.

This task rewrites the code when mix recode runs with autocorrect: true.
```


## Differences to Credo

`recode` was started as a plugin for `credo`. Unfortunately it was not possible
to implement autocorrection as a plugin because Credo's traversal of the code does
not support changing the code.

Maybe some code lines from `recode` could be used as inspiration for `credo`
to bring the autocorrect feature to `credo`.

Other differences:

* `recode` requires Elixir 1.13, `credo` requires Elixir 1.7
* `recode` has autocorrection
* `credo` has much more checkers
* `credo` is faster
* `credo` has more features
