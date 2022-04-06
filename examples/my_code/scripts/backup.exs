defmodule Backup do
  @inputs "{lib,test}/**/*"
  @backup "scripts/backup.bin"

  alias Mix.Generator
  alias Mix.Shell

  def run([]) do
    @inputs
    |> Path.wildcard()
    |> Enum.reject(&File.dir?/1)
    |> Enum.into(%{}, fn path -> {path, File.read!(path)} end)
    |> backup()
  end

  def run(["restore"]) do
    Shell.IO.info("restoring form backup #{@backup}")

    files = @backup |> File.read!() |> :erlang.binary_to_term()

    Enum.each(files, fn {path, data} ->
      Generator.create_file(path, data)
    end)
  end

  def run(argv) do
    raise "Unknown args #{inspect(argv)}"
  end

  defp backup(files) do
    data = :erlang.term_to_binary(files, compressed: 9)
    Generator.create_file(@backup, data, force: true)
  end
end

Backup.run(System.argv())
