alias Recode.Task

[
  version: "0.5.3",
  # Can also be set/reset with "--autocorrect"/"--no-autocorrect".
  autocorrect: true,
  # With "--dry" no changes will be written to the files.
  # Can also be set/reset with "--dry"/"--no-dry".
  # If dry is true then verbose is also active.
  dry: false,
  # Can also be set/reset with "--verbose"/"--no-verbose".
  verbose: false,
  # Can be overwriten by calling `mix recode "lib/**/*.ex"`.
  inputs: ["{mix,.formatter}.exs", "{apps,config,lib,test}/**/*.{ex,exs}"],
  formatter: {Recode.Formatter, []},
  tasks: [
    # Tasks could be added by a tuple of the tasks module name and an options
    # keyword list. A task can be deactived by `active: false`. The execution of
    # a deactivated task can be forced by calling `mix recode --task ModuleName`.
    {Task.AliasExpansion, []},
    {Task.AliasOrder, []},
    {Task.EnforceLineLength, active: false},
    {Task.FilterCount, []},
    {Task.PipeFunOne, []},
    {Task.SinglePipe, []},
    {Task.Specs, exclude: "test/**/*.{ex,exs}", config: [only: :visible]},
    {Task.TestFileExt, []},
    {Task.UnusedVariable, active: false}
  ]
]
