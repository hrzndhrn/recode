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

  @type manifest :: {integer(), Path.t(), [Path.t()]}

  @spec write(Rewrite.t(), keyword()) :: :ok
  def write(project, config) do
    if config[:manifest] do
      with :ok <- File.mkdir_p(Mix.Project.manifest_path()),
           :ok <- File.write(path(), content(project, config)) do
        :ok
      else
        {:error, reason} ->
          Mix.shell().error("Failed to write manifest: #{:file.format_error(reason)}")
          :ok
      end
    else
      :ok
    end
  end

  @spec read(keyword()) :: manifest() | nil
  def read(config) do
    force = Keyword.get(config, :force, false)
    manifest = Keyword.get(config, :manifest, false)

    if !force and manifest and File.exists?(path()) do
      with {:ok, content} <- File.read(path()),
           {:ok, manifest} <- to_term(content) do
        manifest
      else
        {:error, :invalid_content} ->
          Mix.shell().error("Failed to read manifest: invalid content")
          nil

        {:error, reason} ->
          Mix.shell().error("Failed to read manifest: #{:file.format_error(reason)}")
          nil
      end
    else
      nil
    end
  end

  @spec timestamp() :: integer()
  def timestamp, do: Timestamp.for_file(path())

  @spec path() :: Path.t()
  def path, do: Path.join(Mix.Project.manifest_path(), @manifest)

  defp content(project, config) do
    dry = Keyword.get(config, :dry, false)
    config_file = get_cli_opts(config, :config_file, Config.default_filename())

    files =
      project
      |> files_with_issue(dry)
      |> Enum.join("\n")

    if files == "", do: config_file, else: "#{config_file}\n#{files}"
  end

  defp to_term(content) do
    content = content |> String.trim() |> String.split("\n")

    case content do
      ["" | _files] -> {:error, :invalid_content}
      [config_file | files] -> {:ok, {timestamp(), config_file, files}}
    end
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
