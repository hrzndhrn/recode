# Changelog

## 0.8.0 - dev

+ Use `Rewrite` version `~> 1.0`.
+ Add callback and default implementation `Recode.Task.update_source/3`.
+ Add callback and default implementation `Recode.Task.new_issue/1` and 
  `Recode.Task.new_issue/2`. 
+ Rename `Recode.Task.TestFileExt` to `Recode.Task.TestFile`.
+ Update `mix recode.update.config` to remove deprecated tasks.
+ Add a manifest file to store information about the files processed.
+ Add silent mode with flag `--silent`.
+ Fix `Recode.Task.LocalsWithoutParens`.

## 0.7.5 - 2025/09/30

+ Ignore missing sub formatters when reading dot-formatters. 

## 0.7.4 - 2025/09/20

+ Update to `rewrite` 1.1.2

## 0.7.3 - 2024/07/25

+ Add config for preformatter.
+ Add `Recode.Task.UnnecessaryIfUnless`
+ Add `Recode.Task.LocalsWithoutParens`
+ Add `Recode.Task.Moduledoc`
+ Fix `Recode.Task.Tags`

## 0.7.2 - 2024/02/10

+ Fix `Recode.AST.alias_info` fot `alias __MODULE__, as: MyModule`.

## 0.7.1 - 2024/01/09

+ Fix bug in `Recode.Task.Tags`.

## 0.7.0 - 2024/01/07

+ Refactor formatter and use `Escape`.
+ Add switch `--color` to mix task recode.
+ Add option `color` to config.
+ Run recode tasks async.
+ Remove `Recode.StopWatch`
+ Refactor `Recode.FormatterPlugin`
+ Improve config validation.

## 0.6.5 - 2023/10/09

+ Start `:recode` appliations in `mix recode` task.

## 0.6.4 - 2023/09/15

+ Fix `exclude_plugins` arg.

## 0.6.3 - 2023/09/15

+ Fix `Recode.FormatterPlugin`.
+ Add switch `--debug` (for now undocumented).

## 0.6.2 - 2023/09/04

+ Fix runner impl for `mix format`.
+ Fix typos.

## 0.6.1 - 2023/08/27

+ Use `rewrite` version `~> 0.8`.

## 0.6.0 - 2023/08/26

+ Add `Recode.Task.Dbg`.
+ Add `Recode.Task.FilterCount`.
+ Add `Recode.Task.IOInspect`.
+ Add `Recode.Task.Nesting`.
+ Add `Recode.Task.TagFIXME`.
+ Add `Recode.Task.TagTODO`.
+ Add mix task `recode.help`.
+ Add mix task `recode.update.config`.
+ Use switch `--task` multiple times.
+ Refactor `RecodeCase`
+ Add some minor fixes for `Recode.Task.AliasOrder`.
+ Fix file count output.
+ Add callback `init/1` to `Recode.Task`.
+ Add validation of `task` and `config` in `Mix.Tasks.Recode`

## 0.5.2 - 2023/07/17

+ Bump `rewrite` to 0.7.0.

## 0.5.1 - 2023/05/19

+ Fix `Recode.Task.AliasExpansion`

## 0.5.0 - 2023/05/05

+ Add `Recode.FormatterPlugin`

## 0.4.4 - 2023/03/17

+ Refactor `Recode.Task.EnforceLineLength`.
+ Add `Recode.Runner.run/3`.
+ Fix `Recode.Task.AliasOrder`
+ Add dir `apps` to the default config.

## 0.4.3 - 2023/02/04

+ Refactor recode formatter task.

## 0.4.2 - 2022/12/10

+ Fixing file exclusion.

## 0.4.1 - 2022/11/05

+ Remove unnecessary compile call
+ Fix handling of multiple input files

## 0.4.0 - 2022/09/09

+ Add option `-` to `mix recode` to read from stdin.
+ Add `Recode.Task.UnusedVariable`.
+ Update `Recode.Task.SinglePipe`. Some false positives are fixed.
+ Update `Recode.Task.PipeFunOne`. Some false positives are fixed.
+ The modules `Recode.Project`, `Recode.Source`, and etc moving to the package
  [`rewrite`](https://github.com/hrzndhrn/rewrite).
+ Catch exceptions raised in tasks and output a  warning for each exception.
+ Remove `mix` task `recode.rename`. `Recode` gets a focus on linting and
  autocorrection with this change. The refactoring functionality will move to
  another package.


## 0.3.0 - 2022/08/28

+ Rename `Recode.Taks.SameLine` to `Recode.Task.EnforceLineLength`.

## 0.2.0 - 2022/08/21

+ Refactor config.
+ Add `Recode.Task.SameLine`.
+ Add flag `--task` to `mix recode`.

## 0.1.3 - 2022/07/26

+ Fix `Recode.Task.Rename`

## 0.1.3 - 2022/07/24

+ Fix `Recode.Task.SinglePipe`.
+ Fix bugs in `Recode.Context`.

## 0.1.2 - 2022/07/13

+ Add options `:macros` to `Recode.Task.Specs`.

## 0.1.1 - 2022/07/06

+ Bug fixes.
+ Added `recode.exs` to run `recode` with `recode`.
+ Changes to run `mix recode --dry --config recode.exs` without any update or
  issue.

## 0.1.0 - 2022/07/04

+ The very first version.
