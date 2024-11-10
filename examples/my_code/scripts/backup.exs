defmodule Backup do
  @inputs "{priv,config,lib,test}/**/*"
  @backup "scripts/backup.bin"

  def run([]) do
    @inputs
    |> Path.wildcard(match_dot: true)
    |> Enum.reject(&File.dir?/1)
    |> Enum.into(%{}, fn path -> {path, File.read!(path)} end)
    |> backup()
  end

  def run(["restore"]) do
    IO.puts("restoring form backup #{@backup}")

    Enum.each(["lib", "test", "config", "priv"], fn dir -> File.rm_rf!(dir) end)

    files = @backup |> File.read!() |> :erlang.binary_to_term()

    Enum.each(files, fn {path, data} ->
      IO.puts("restoring #{path}")
      path |> Path.dirname() |> File.mkdir_p!()
      File.write!(path, data)
    end)
  end

  def run(argv) do
    raise "Unknown args #{inspect(argv)}"
  end

  defp backup(files) do
    data = :erlang.term_to_binary(files, compressed: 9)
    File.write!(@backup, data)
    IO.puts("backup saved to #{@backup}")
  end
end

Backup.run(System.argv())
