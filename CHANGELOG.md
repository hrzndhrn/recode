# Changelog

## 0.4.4 - unreleased

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
