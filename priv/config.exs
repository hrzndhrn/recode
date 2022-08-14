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
    {Task.Specs, only: :visible, exclude: "test/**/*.{ex,exs}"},
    {Task.TestFileExt, []},
    {Task.SameLine, run: false}
  ]
]
