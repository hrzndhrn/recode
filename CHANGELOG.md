# Changelog

## 0.4.0 - 2022/09/07

+ Add option `-` to `mix recode` to read from stdin.
+ Add `Recode.Task.UnusedVariable`.
+ Update `Recode.Task.SinglePipe`. Some false positives are fixed.
+ Update `Recode.Task.PipeFunOne`. Some false positives are fixed.
+ The modules `Recode.Project`, `Recode.Source`, and etc moving to the package
  [`rewrite`](https://github.com/hrzndhrn/rewrite).
+ Catch exceptions raised in tasks and output a  warning for each exception.


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
