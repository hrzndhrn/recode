defmodule Recode.Manifest do
  @moduledoc false

  # Reads and writes the manifest file.
  # The manifest file starts in the first line with file name for the last used
  # config file. The following lines are files that have issues. In case of a
  # dry run, the files are updated are also in the manifest.
  #
  # Returns a tuple with {timestamp, config_file, files_with_issues} where
  # timestamp is the timestamp of the config_file.

  alias Recode.Config
  alias Recode.Timestamp
  alias Rewrite.Source

  @manifest "recode.issues"

  def write(project, config) do
    if config[:manifest] do
      File.write(path(), content(project, config))
    else
      :ok
    end
  end

  def read(config) do
    if !config[:force] and config[:manifest] do
      case File.read(path()) do
        {:ok, content} ->
          [config_file | files] = String.split(content, "\n")
          {timestamp(), config_file, files}

        _error ->
          nil
      end
    else
      nil
    end
  end

  def timestamp, do: Timestamp.for_file(path())

  def path, do: Path.join(Mix.Project.manifest_path(), @manifest)

  defp content(project, config) do
    dry = config[:dry]
    config_file = get_cli_opts(config, :config_file, Config.default_filename())

    files =
      project
      |> files_with_issue(dry)
      |> Enum.join("\n")

    """
    #{config_file}
    #{files}
    """
  end

  defp files_with_issue(project, dry) do
    Enum.reduce(project, [], fn source, acc ->
      if Source.has_issues?(source) or (dry and Source.updated?(source)) do
        [source.path | acc]
      else
        acc
      end
    end)
  end

  defp get_cli_opts(config, key, default), do: config[:cli_opts][key] || default
end
