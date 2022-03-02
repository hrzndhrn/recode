defmodule Recode.Source do
  alias Recode.Source
  alias Recode.Source.Info
  alias Sourceror.Zipper

  defstruct [
    :id,
    :path,
    :code,
    :hash,
    :modules,
    versions: [],
    issues: []
  ]

  def new!(path) do
    code = File.read!(path)

    struct!(
      Source,
      id: make_ref(),
      path: path,
      code: code,
      hash: hash(path, code),
      modules: get_modules(code)
    )
  end

  @deprectead "will be deleted"
  def update(%Source{} = source, by, [{:zipper, {ast, _meta}}]) do
    code = Sourceror.to_string(ast)
    update(source, by, code: code)
  end

  def update(%Source{} = source, by, [{key, value}])
      when is_atom(by) and key in [:code, :path] and is_binary(value) do
    legacy = Map.fetch!(source, key)
    version = {key, by, legacy}

    case legacy == value do
      true ->
        source

      false ->
        source
        |> Map.put(key, value)
        |> update_versions(version)
        |> update_modules(key, value)
        |> update_hash()
    end
  end

  def version(%Source{versions: versions}), do: length(versions)

  def path(%Source{path: path}), do: path

  def path(%Source{path: path, versions: versions}, version) when version <= length(versions) do
    versions
    |> Enum.take(length(versions) - version)
    |> Enum.reduce(path, fn
      {:path, _by, path}, _path -> path
      _version, path -> path
    end)
  end

  def modules(%Source{modules: modules}), do: modules

  def modules(%Source{} = source, version) do
    source |> code(version) |> get_modules()
  end

  def code(%Source{code: code}), do: code

  def code(%Source{code: code, versions: versions}, version) when version <= length(versions) do
    versions
    |> Enum.take(length(versions) - version)
    |> Enum.reduce(code, fn
      {:code, _by, code}, _code -> code
      _version, code -> code
    end)
  end

  defp get_modules(code) do
    code |> Info.from_code() |> Enum.map(fn info -> elem(info.module, 0) end)
  end

  defp update_modules(source, :code, code), do: %{source | modules: get_modules(code)}

  defp update_modules(source, _key, _value), do: source

  defp hash(path, code), do: :crypto.hash(:md5, path <> code)

  defp update_hash(%Source{path: path, code: code} = source) do
    %{source | hash: hash(path, code)}
  end

  defp update_versions(%Source{versions: versions} = source, version) do
    %{source | versions: [version | versions]}
  end

  def abstract_code(%Source{modules: modules, code: code, path: path}, module) do
    case module in modules do
      true -> do_abstract_code(module, code, path)
      false -> {:error, :non_existing_module}
    end
  end

  defp do_abstract_code(module, code, path) do
    # TODO just use the existing BEAM file if we have not a new version
    case BeamFile.exists?(module) do
      true -> BeamFile.abstract_code(module)
      false -> code |> compile_module(path, module) |> BeamFile.abstract_code()
    end
  end

  def abstract_code!(%Source{} = source, module) do
    case abstract_code(source, module) do
      {:ok, abstract_code} ->
        abstract_code

      {:error, reason} ->
        # TODO: Add SourceError
        raise "TODO: Add SourceError, reason: #{inspect(reason)}"
    end
  end

  def debug_info(%Source{modules: modules, code: code, path: path}, module) do
    case module in modules do
      true -> do_debug_info(module, code, path)
      false -> {:error, :non_existing}
    end
  end

  defp do_debug_info(module, code, path) do
    # TODO just use the existing BEAM file if we have not a new version
    case BeamFile.exists?(module) do
      true -> BeamFile.debug_info(module)
      false -> code |> compile_module(path, module) |> BeamFile.debug_info()
    end
  end

  def debug_info!(%Source{} = source, module) do
    case debug_info(source, module) do
      {:ok, debug_info} ->
        debug_info

      {:error, reason} ->
        # TODO: Add SourceError
        raise "TODO: Add SourceError - #{inspect(reason)}"
    end
  end

  defp compile_module(code, path, module) do
    IO.inspect(path, label: :compile_module)
    code |> Code.compile_string(path) |> Keyword.fetch!(module)
  end

  def ast(%Source{code: code}) do
    Sourceror.parse_string(code)
  end

  def ast!(%Source{code: code}) do
    Sourceror.parse_string!(code)
  end

  @deprectead "will be deleted"
  def zipper(%Source{} = source) do
    with {:ok, ast} <- ast(source) do
      {:ok, Zipper.zip(ast)}
    end
  end

  def zipper!(%Source{} = source) do
    source |> ast!() |> Zipper.zip()
  end
end
