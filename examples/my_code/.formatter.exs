[
  # plugins: [],
  # plugins: [Recode.FormatterPlugin],
  # plugins: [FreedomFormatter],
  plugins: [FreedomFormatter, Recode.FormatterPlugin],
  trailing_comma: true,
  # recode: [
  #   tasks: [
  #     {Recode.Task.PipeFunOne, []},
  #     {Recode.Task.SinglePipe, []}
  #   ]
  # ],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}", "priv/**/*.json"],
  locals_without_parens: [noop: 1],
  subdirectories: ["priv/*/migrations"],
]
