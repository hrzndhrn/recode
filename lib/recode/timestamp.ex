defmodule Recode.Timestamp do
  @moduledoc false

  def for_file(path) do
    case File.stat(path, time: :posix) do
      {:ok, %{mtime: timestamp}} -> timestamp
      {:error, _reason} -> 0
    end
  end
end
