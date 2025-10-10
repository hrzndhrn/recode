defmodule Recode.Timestamp do
  @moduledoc false

  # A helper for timestamps.
  #
  # `for_file/1` returns `0` for a non-existing file and for files where
  # `stat/2` returns another error tuple.

  @spec for_file(Path.t()) :: integer()
  def for_file(path) do
    case File.stat(path, time: :posix) do
      {:ok, %{mtime: timestamp}} -> timestamp
      {:error, _reason} -> 0
    end
  end
end
