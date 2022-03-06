defmodule Backup do
  @inputs "{lib,test}/**/*"
  @backup "scripts/backup.bin"

  def run([]) do
    @inputs
    |> Path.wildcard()
    |> Enum.reject(&File.dir?/1)
    |> Enum.into(%{}, fn path -> {path, File.read!(path)} end)
    |> backup()
  end

  def run(["apply"]) do
    files = @backup |> File.read!() |> :erlang.binary_to_term()

    Enum.each(files, fn {path, data} ->
      File.write(path, data)
    end)
  end

  def run(argv) do
    raise "Unknown args #{inspect(argv)}"
  end

  defp backup(files) do
    data = :erlang.term_to_binary(files, compressed: 9)
    File.write!(@backup, data)
  end
end

Backup.run(System.argv())
