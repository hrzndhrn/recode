defmodule Recode.Source do
  @moduledoc """
  A representation of some source in a project.

  The `%Source{}` conatins the `code` of the file given by `path`. The moudle
  contains `Source.update/3` to update the `path` and/or the `code`. he changes
  are recorded in the `versions` list.

  The struct also holds `issues` for the source.
  """

  alias Recode.Context
  alias Recode.Source
  alias Recode.SourceError
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

  @type kind :: :code | :path

  @type by :: module()

  @type t :: %Source{
          id: String.t(),
          path: Path.t(),
          code: String.t(),
          hash: String.t(),
          modules: [module()],
          versions: [{kind(), by(), String.t()}],
          issues: term()
        }

  @doc ~S'''
  Creates a new `%Source{}` from the given `path`.

  ## Examples

      iex> source = Source.new!("test/fixtures/source/simple.ex")
      iex> source.modules
      [MyApp.Simple]
      iex> source.code
      """
      defmodule MyApp.Simple do
        def foo(x) do
          x * 2
        end
      end
      """
  '''
  @spec new!(Path.t()) :: t()
  def new!(path) do
    path |> File.read!() |> from_string(path)
  end

  @doc """
  Creates a new `%Source{}` from the given `string`.

  ## Examples

      iex> source = Source.from_string("a + b")
      iex> source.modules
      []
      iex> source.code
      "a + b"
  """
  @spec from_string(String.t(), Path.t() | nil) :: t()
  def from_string(string, path \\ nil) do
    struct!(
      Source,
      id: make_ref(),
      path: path,
      code: string,
      hash: hash(path, string),
      modules: get_modules(string)
    )
  end

  @doc ~S"""
  Updates the `code` or the `path` of a `source`.

  ## Examples

      iex> source =
      ...>   "a + b"
      ...>   |> Source.from_string()
      ...>   |> Source.update(:example, path: "test/fixtures/new.exs")
      ...>   |> Source.update(:example, code: "a - b")
      iex> source.versions
      [{:code, :example, "a + b"}, {:path, :example, nil}]
      iex> source.code
      "a - b\n"

  If the new value equal to the current value, no versions will be added.

      iex> source =
      ...>   "a + b"
      ...>   |> Source.from_string()
      ...>   |> Source.update(:example, code: "a - b")
      ...>   |> Source.update(:example, code: "a - b")
      ...>   |> Source.update(:example, code: "a - b")
      iex> source.versions
      [{:code, :example, "a + b"}]
  """
  @spec update(t(), by(), [code: String.t() | Zipper.zipper()] | [path: Path.t()]) :: t()
  def update(%Source{} = source, by, [{:code, {ast, _meta}}]) do
    code = ast |> Sourceror.to_string() |> newline()
    update(source, by, code: code)
  end

  def update(%Source{} = source, by, [{key, value}])
      when is_atom(by) and key in [:code, :path] and is_binary(value) do
    legacy = Map.fetch!(source, key)

    value = if key == :code, do: newline(value), else: value

    case legacy == value do
      true ->
        source

      false ->
        version = {key, by, legacy}

        source
        |> put(key, value)
        |> update_versions(version)
        |> update_modules(key, value)
        |> update_hash()
    end
  end

  @doc """
  Returns `true` if the source was updated.

  The optional argument `kind` specifies whether only `:code` changes or `:path`
  changes are considered. Defaults to `:any`.

  ## Examples

      iex> source = Source.from_string("a + b")
      iex> Source.updated?(source)
      false
      iex> source = Source.update(source, :example, code: "a - b")
      iex> Source.updated?(source)
      true
      iex> Source.updated?(source, :path)
      false
      iex> Source.updated?(source, :code)
      true
  """
  @spec updated?(t(), kind :: :code | :path | :any) :: boolean()
  def updated?(source, kind \\ :any)

  def updated?(%Source{versions: []}, _kind), do: false

  def updated?(%Source{versions: _versions}, :any), do: true

  def updated?(%Source{versions: versions}, kind) when kind in [:code, :path] do
    Enum.any?(versions, fn
      {^kind, _by, _value} -> true
      _version -> false
    end)
  end

  @doc """
  Returns the count of updates.

  ## Examples

      iex> source =
      ...>   "a + b"
      ...>   |> Source.from_string()
      ...>   |> Source.update(:example, path: "test/fixtures/new.exs")
      ...>   |> Source.update(:example, code: "a - b")
      iex> Source.updates(source)
      2
  """
  @spec updates(t()) :: non_neg_integer()
  def updates(%Source{versions: versions}), do: length(versions)

  @doc """
  Returns the current path for the given `source`.
  """
  @spec path(t()) :: Path.t()
  def path(%Source{path: path}), do: path

  @doc """
  Returns the path of a `source` for the given `version`.

  ## Examples

      iex> source =
      ...>   "a + b"
      ...>   |> Source.from_string("some/where/plus.exs")
      ...>   |> Source.update(:example, path: "some/where/else/plus.exs")
      ...> Source.path(source, 0)
      "some/where/plus.exs"
      iex> Source.path(source, 1)
      "some/where/else/plus.exs"
  """
  @spec path(t(), non_neg_integer) :: Path.t()
  def path(%Source{path: path, versions: versions}, version) when version <= length(versions) do
    versions
    |> Enum.take(length(versions) - version)
    |> Enum.reduce(path, fn
      {:path, _by, path}, _path -> path
      _version, path -> path
    end)
  end

  @doc """
  Returns the current modules for the given `source`.
  """
  @spec modules(t()) :: [module()]
  def modules(%Source{modules: modules}), do: modules

  @doc ~S'''
  Returns the modules of a `source` for the given `version`.

  ## Examples

      iex> bar =
      ...>   """
      ...>   defmodule Bar do
      ...>      def bar, do: :bar
      ...>   end
      ...>   """
      iex> foo =
      ...>   """
      ...>   defmodule Foo do
      ...>      def foo, do: :foo
      ...>   end
      ...>   """
      iex> source = Source.from_string(bar)
      iex> source = Source.update(source, :example, code: bar <> foo)
      iex> Source.modules(source)
      [Bar, Foo]
      iex> Source.modules(source, 1)
      [Bar, Foo]
      iex> Source.modules(source, 0)
      [Bar]
  '''
  @spec modules(t(), non_neg_integer) :: [module()]
  def modules(%Source{} = source, version) do
    source |> code(version) |> get_modules()
  end

  @doc """
  Returns the current code for the given `source`.
  """
  @spec code(t()) :: String.t()
  def code(%Source{code: code}), do: code

  @doc ~S'''
  Returns the code of a `source` for the given `version`.

  ## Examples

      iex> bar =
      ...>   """
      ...>   defmodule Bar do
      ...>      def bar, do: :bar
      ...>   end
      ...>   """
      iex> foo =
      ...>   """
      ...>   defmodule Foo do
      ...>      def foo, do: :foo
      ...>   end
      ...>   """
      iex> source = Source.from_string(bar)
      iex> source = Source.update(source, :example, code: foo)
      iex> Source.code(source) == foo
      true
      iex> Source.code(source, 1) == foo
      true
      iex> Source.code(source, 0) == bar
      true
  '''
  @spec code(t(), non_neg_integer) :: String.t()
  def code(%Source{code: code, versions: versions}, version) when version <= length(versions) do
    versions
    |> Enum.take(length(versions) - version)
    |> Enum.reduce(code, fn
      {:code, _by, code}, _code -> code
      _version, code -> code
    end)
  end

  @doc """
  Returns the AST for the given `%Source`.

  The returned extended AST is generated with `Sourceror.parse_string/1`.

  Uses the current `code` of the `source`.

  ## Examples

      iex> "def foo, do: :foo" |> Source.from_string() |> Source.ast()
      {:ok,
       {:def, [trailing_comments: [], leading_comments: [], line: 1, column: 1],
        [
          {:foo, [trailing_comments: [], leading_comments: [], line: 1, column: 5], nil},
          [
            {{:__block__,
              [trailing_comments: [], leading_comments: [], format: :keyword, line: 1, column: 10],
              [:do]},
             {:__block__, [trailing_comments: [], leading_comments: [], line: 1, column: 14], [:foo]}}
          ]
        ]}}
  """
  @spec ast(t()) :: {:ok, Macro.t()} | {:error, term()}
  def ast(%Source{code: code}) do
    Sourceror.parse_string(code)
  end

  @doc """
  Same as `ast/1` but raises on error.
  """
  @spec ast!(t()) :: Macro.t()
  def ast!(%Source{code: code}) do
    Sourceror.parse_string!(code)
  end

  @doc """
  Returns a `Sourceror.Zipper` with the AST for the given `%Source`.
  """
  @spec zipper(t()) :: {:ok, Zipper.zipper()} | {:error, term()}
  def zipper(%Source{} = source) do
    with {:ok, ast} <- ast(source) do
      {:ok, Zipper.zip(ast)}
    end
  end

  @doc """
  Same as `zipper/1` but raises on error.
  """
  @spec zipper!(t()) :: Zipper.zipper()
  def zipper!(%Source{} = source) do
    source |> ast!() |> Zipper.zip()
  end

  @doc ~S'''
  Returns the debug info for the give `source` and `module`.

  Uses the current `code` of the `source`.

  ## Examples

      iex> bar =
      ...>   """
      ...>   defmodule Bar do
      ...>      def bar, do: :bar
      ...>   end
      ...>   """
      iex> bar |> Source.from_string() |> Source.debug_info(Bar)
      {:ok,
       %{
         attributes: [],
         compile_opts: [],
         definitions: [{{:bar, 0}, :def, [line: 2], [{[line: 2], [], [], :bar}]}],
         deprecated: [],
         file: "nofile",
         is_behaviour: false,
         line: 1,
         module: Bar,
         relative_file: "nofile",
         struct: nil,
         unreachable: []
       }}
  '''
  @spec debug_info(t(), module()) :: {:ok, term()} | {:error, term()}
  def debug_info(%Source{modules: modules, code: code, path: path} = source, module) do
    case module in modules do
      true -> do_debug_info(module, code, path, updated?(source))
      false -> {:error, :non_existing}
    end
  end

  @doc """
  Same as `debug_info/1` but raises on error.
  """
  @spec debug_info!(t(), module()) :: term()
  def debug_info!(%Source{} = source, module) do
    case debug_info(source, module) do
      {:ok, debug_info} ->
        debug_info

      {:error, reason} ->
        raise SourceError, "Can not find debug info, reason: #{inspect(reason)}"
    end
  end

  defp do_debug_info(module, code, path, updated?) do
    case not updated? and BeamFile.exists?(module) do
      true -> BeamFile.debug_info(module)
      false -> code |> compile_module(path, module) |> BeamFile.debug_info()
    end
  end

  defp get_modules(code) do
    code
    |> Sourceror.parse_string!()
    |> Zipper.zip()
    |> Context.traverse(MapSet.new(), fn zipper, context, acc ->
      acc =
        case Context.module(context) do
          nil -> acc
          module -> MapSet.put(acc, module)
        end

      {zipper, context, acc}
    end)
    |> elem(1)
    |> MapSet.to_list()
  end

  defp update_modules(source, :code, code), do: %{source | modules: get_modules(code)}

  defp update_modules(source, _key, _value), do: source

  defp hash(nil, code), do: :crypto.hash(:md5, code)

  defp hash(path, code), do: :crypto.hash(:md5, path <> code)

  defp update_hash(%Source{path: path, code: code} = source) do
    %{source | hash: hash(path, code)}
  end

  defp put(source, :code, value) do
    code = newline(value)
    Map.put(source, :code, code)
  end

  defp put(source, key, value), do: Map.put(source, key, value)

  defp update_versions(%Source{versions: versions} = source, version) do
    %{source | versions: [version | versions]}
  end

  defp compile_module(code, path, module) do
    code |> Code.compile_string(path || "nofile") |> Keyword.fetch!(module)
  end

  defp newline(string), do: String.trim_trailing(string) <> "\n"
end
