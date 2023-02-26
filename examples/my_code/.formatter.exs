[
  # plugins: [],
  plugins: [Recode.FormatterPlugin],
  # plugins: [FreedomFormatter],
  # plugins: [FreedomFormatter, Recode.FormatterPlugin],
  trailing_comma: true,
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: [noop: 1]
]
