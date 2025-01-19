defmodule Mix.Tasks.Backup do
  @moduledoc """
  Creates and restores a backup of the current project.
  """
  use Mix.Task

  @dirs ["priv", "config", "lib", "test"]
  @inputs "{#{Enum.join(@dirs, ",")}}/**/*"
  @backup "backup.bin"

  @impl Mix.Task
  @spec run(list()) :: no_return()
  def run([]) do
    @inputs
    |> Path.wildcard(match_dot: true)
    |> Enum.reject(&File.dir?/1)
    |> Enum.into(%{}, fn path -> {path, File.read!(path)} end)
    |> backup()
  end

  def run(["--restore"]) do
    Mix.shell().info("Restoring files from #{@backup}")

    Enum.each(@dirs, fn dir -> File.rm_rf!(dir) end)

    files = @backup |> File.read!() |> :erlang.binary_to_term()

    Enum.each(files, fn {path, data} ->
      IO.puts("restoring #{path}")
      path |> Path.dirname() |> File.mkdir_p!()
      File.write!(path, data)
    end)
  end

  def run(_) do
    Mix.raise("Invalid arguments, expected: mix backup [--restore]")
  end

  defp backup(files) do
    data = :erlang.term_to_binary(files, compressed: 9)
    File.write!(@backup, data)
    Mix.shell().info("backup saved to #{@backup}")
  end
end
