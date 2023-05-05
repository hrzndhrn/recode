defmodule FakePlugin do
  @moduledoc """
  A formatter plugin that always set `force_do_end_blocks: true`.
  """

  @behaviour Mix.Tasks.Format

  def features(_opts) do
    [sigils: [], extensions: [".ex", ".exs"]]
  end

  def format(contents, opts) do
    contents
    |> Code.format_string!(Keyword.put(opts, :force_do_end_blocks, true))
    |> IO.iodata_to_binary()
  end
end
