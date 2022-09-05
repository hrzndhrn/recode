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
  inputs: ["{config,lib,test}/**/*.{ex,exs}"],
  formatter: {Recode.Formatter, []},
  tasks: [
    {Task.AliasExpansion, []},
    {Task.AliasOrder, []},
    {Task.PipeFunOne, []},
    {Task.SinglePipe, []},
    {Task.Specs, exclude: "test/**/*.{ex,exs}", config: [only: :visible]},
    {Task.TestFileExt, []},
    {Task.EnforceLineLength, active: false}
  ]
]
