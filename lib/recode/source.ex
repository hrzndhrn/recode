defmodule Recode.Source do
  @moduledoc """
  A representation of some source in a project.

  The `%Source{}` contains the `code` of the file given by `path`. The module
  contains `Source.update/3` to update the `path` and/or the `code`. The changes
  are recorded in the `updates` list.

  The struct also holds `issues` for the source.
  """

  alias Recode.Context
  alias Recode.DotFormatter
  alias Recode.Issue
  alias Recode.Source
  alias Recode.SourceError
  alias Sourceror.Zipper

  defstruct [
    :id,
    :path,
    :code,
    :ast,
    :hash,
    :modules,
    updates: [],
    issues: []
  ]

  @typedoc """
  The `version` of a `%Source{}`. The version `1` indicates that the source has
  no changes.
  """
  @type version :: pos_integer()

  @type kind :: :code | :path

  @type by :: module()

  @type id :: String.t()

  @type t :: %Source{
          id: id(),
          path: Path.t() | nil,
          code: String.t(),
          ast: Macro.t(),
          hash: String.t(),
          modules: [module()],
          updates: [{kind(), by(), String.t()}],
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
    ast = Sourceror.parse_string!(string)

    struct!(
      Source,
      id: make_ref(),
      path: path,
      code: string,
      ast: ast,
      hash: hash(path, string),
      modules: get_modules(ast)
    )
  end

  @doc """
  Marks the given `source` as deleted.

  This function set the `path` of the `given` source to `nil`.
  """
  @spec del(t(), nil | module()) :: t()
  def del(source, by \\ nil)

  def del(%Source{path: nil} = source, _by), do: source

  def del(%Source{path: legacy} = source, by) do
    source
    |> put(:path, nil)
    |> update_updates({:path, by, legacy})
    |> update_hash()
  end

  @doc ~S"""
  Saves the source to disk.

  If the source `:path` was updated then the old file will be deleted. The
  original file will also deleted when the `source` was marked as deleted with
  `del/1`.

  Missing directories are created.

  ## Examples

      iex> ":test" |> Source.from_string() |> Source.save()
      {:error, :nofile}

      iex> path = "tmp/foo.ex"
      iex> File.write(path, ":foo")
      iex> source = path |> Source.new!() |> Source.update(:test, code: ":bar")
      iex> Source.save(source)
      :ok
      iex> File.read(path)
      {:ok, ":bar\n"}
      iex> source |> Source.del() |> Source.save()
      iex> File.exists?(path)
      false

      iex> source = Source.from_string(":bar")
      iex> Source.save(source)
      {:error, :nofile}
      iex> source |> Source.update(:test, path: "tmp/bar.ex") |> Source.save()
      :ok

      iex> path = "tmp/ping.ex"
      iex> File.write(path, ":ping")
      iex> source = path |> Source.new!()
      iex> new_path = "tmp/pong.ex"
      iex> source |> Source.update(:test, path: new_path) |> Source.save()
      :ok
      iex> File.exists?(path)
      false
      iex> File.read(new_path)
      {:ok, ":ping"}
  """
  @spec save(t()) :: :ok | {:error, :nofile | File.posix()}
  def save(%Source{path: nil, updates: []}), do: {:error, :nofile}

  def save(%Source{updates: []}), do: :ok

  def save(%Source{path: nil} = source), do: rm(source)

  def save(%Source{path: path, code: code} = source) do
    with :ok <- mkdir_p(path),
         :ok <- File.write(path, code) do
      rm(source)
    end
  end

  defp mkdir_p(path) do
    path |> Path.dirname() |> File.mkdir_p()
  end

  defp rm(source) do
    case {Source.updated?(source, :path), Source.path(source, 1)} do
      {false, _path} -> :ok
      {true, nil} -> :ok
      {true, path} -> File.rm(path)
    end
  end

  @doc """
  Returns the `version` of the given `source`. The value `1` indicates that the
  source has no changes.
  """
  @spec version(t()) :: version()
  def version(%Source{updates: updates}), do: length(updates) + 1

  @doc """
  Adds the given `issues` to the `source`.
  """
  @spec add_issues(t(), [Issue.t()]) :: t()
  def add_issues(%Source{issues: list} = source, issues) do
    version = version(source)
    issues = issues |> Enum.map(fn issue -> {version, issue} end) |> Enum.concat(list)

    %Source{source | issues: issues}
  end

  @doc """
  Adds the given `issue` to the `source`.
  """
  @spec add_issue(t(), Issue.t()) :: t()
  def add_issue(%Source{} = source, %Issue{} = issue), do: add_issues(source, [issue])

  @doc ~S"""
  Updates the `code` or the `path` of a `source`.

  ## Examples

      iex> source =
      ...>   "a + b"
      ...>   |> Source.from_string()
      ...>   |> Source.update(:example, path: "test/fixtures/new.exs")
      ...>   |> Source.update(:example, code: "a - b")
      iex> source.updates
      [{:code, :example, "a + b"}, {:path, :example, nil}]
      iex> source.code
      "a - b\n"

  If the new value equal to the current value, no updates will be added.

      iex> source =
      ...>   "a = 42"
      ...>   |> Source.from_string()
      ...>   |> Source.update(:example, code: "b = 21")
      ...>   |> Source.update(:example, code: "b = 21")
      ...>   |> Source.update(:example, code: "b = 21")
      iex> source.updates
      [{:code, :example, "a = 42"}]
  """
  @spec update(t(), by(), [code: String.t() | Zipper.zipper()] | [path: Path.t()]) :: t()
  def update(%Source{ast: ast} = source, _by, [{:code, {ast, _meta}}]), do: source

  def update(%Source{} = source, by, [{:code, {ast, _meta}}]) do
    code = ast |> Sourceror.to_string(DotFormatter.opts()) |> newline()
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
        update = {key, by, legacy}

        source
        |> put(key, value)
        |> update_updates(update)
        |> update_modules(key, value)
        |> update_hash()
    end
  end

  @doc """
  Returns `true` if the source was updated.

  The optional argument `kind` specifies whether only `:code` changes or `:path`
  changes are considered. Defaults to `:any`.

  ## Examples

      iex> source = Source.from_string("a = 42")
      iex> Source.updated?(source)
      false
      iex> source = Source.update(source, :example, code: "b = 21")
      iex> Source.updated?(source)
      true
      iex> Source.updated?(source, :path)
      false
      iex> Source.updated?(source, :code)
      true
  """
  @spec updated?(t(), kind :: :code | :path | :any) :: boolean()
  def updated?(source, kind \\ :any)

  def updated?(%Source{updates: []}, _kind), do: false

  def updated?(%Source{updates: _updates}, :any), do: true

  def updated?(%Source{updates: updates}, kind) when kind in [:code, :path] do
    Enum.any?(updates, fn
      {^kind, _by, _value} -> true
      _update -> false
    end)
  end

  @doc """
  Returns `true` if the `source` has issues for the given `version`.

  The `version` argument also accepts `:actual` and `:all` to check whether the
  `source` has problems for the actual version or if there are problems at all.

  ## Examples

      iex> alias Recode.Issue
      iex> source =
      ...>   "a + b"
      ...>   |> Source.from_string("some/where/plus.exs")
      ...>   |> Source.add_issue(Issue.new(:test, "no comment", line: 1))
      ...>   |> Source.update(:example, path: "some/where/else/plus.exs")
      ...>   |> Source.add_issue(Issue.new(:test, "no comment", line: 1))
      iex> Source.has_issues?(source)
      true
      iex> Source.has_issues?(source, 1)
      true
      iex> Source.has_issues?(source, :all)
      true
      iex> source = Source.update(source, :example, code: "a - b")
      iex> Source.has_issues?(source)
      false
      iex> Source.has_issues?(source, 2)
      true
      iex> Source.has_issues?(source, :all)
      true
  """
  @spec has_issues?(t(), version() | :actual | :all) :: boolean
  def has_issues?(source, version \\ :actual)

  def has_issues?(%Source{issues: issues}, :all), do: not_empty?(issues)

  def has_issues?(%Source{} = source, :actual) do
    has_issues?(source, version(source))
  end

  def has_issues?(%Source{issues: issues, updates: updates}, version)
      when version >= 1 and version <= length(updates) + 1 do
    issues
    |> Enum.filter(fn {for_version, _issue} -> for_version == version end)
    |> not_empty?()
  end

  @doc """
  Returns the current path for the given `source`.
  """
  @spec path(t()) :: Path.t() | nil
  def path(%Source{path: path}), do: path

  @doc """
  Returns the path of a `source` for the given `version`.

  ## Examples

      iex> source =
      ...>   "a + b"
      ...>   |> Source.from_string("some/where/plus.exs")
      ...>   |> Source.update(:example, path: "some/where/else/plus.exs")
      ...> Source.path(source, 1)
      "some/where/plus.exs"
      iex> Source.path(source, 2)
      "some/where/else/plus.exs"
  """
  @spec path(t(), version()) :: Path.t() | nil
  def path(%Source{path: path, updates: updates}, version)
      when version >= 1 and version <= length(updates) + 1 do
    updates
    |> Enum.take(length(updates) - version + 1)
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
      iex> Source.modules(source, 2)
      [Bar, Foo]
      iex> Source.modules(source, 1)
      [Bar]
  '''
  @spec modules(t(), version()) :: [module()]
  def modules(%Source{updates: updates} = source, version)
      when version >= 1 and version <= length(updates) + 1 do
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
      iex> Source.code(source, 2) == foo
      true
      iex> Source.code(source, 1) == bar
      true
  '''
  @spec code(t(), version()) :: String.t()
  def code(%Source{code: code, updates: updates}, version)
      when version >= 1 and version <= length(updates) + 1 do
    updates
    |> Enum.take(length(updates) - version + 1)
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
      {:def, [trailing_comments: [], leading_comments: [], line: 1, column: 1],
        [
          {:foo, [trailing_comments: [], leading_comments: [], line: 1, column: 5], nil},
          [
            {{:__block__,
              [trailing_comments: [], leading_comments: [], format: :keyword, line: 1, column: 10],
              [:do]},
             {:__block__, [trailing_comments: [], leading_comments: [], line: 1, column: 14], [:foo]}}
          ]
        ]
      }
  """
  @spec ast(t()) :: {:ok, Macro.t()} | {:error, term()}
  def ast(%Source{ast: ast}), do: ast

  @doc """
  Returns a `Sourceror.Zipper` with the AST for the given `%Source`.
  """
  @spec zipper(t()) :: {:ok, Zipper.zipper()} | {:error, term()}
  def zipper(%Source{ast: ast}), do: Zipper.zip(ast)

  @doc """
  Compares the `path` values of the given sources.

  ## Examples

      iex> a = Source.from_string(":foo", "a.exs")
      iex> Source.compare(a, a)
      :eq
      iex> b = Source.from_string(":foo", "b.exs")
      iex> Source.compare(a, b)
      :lt
      iex> Source.compare(b, a)
      :gt
  """
  @spec compare(t(), t()) :: :lt | :eq | :gt
  def compare(%Source{path: path1}, %Source{path: path2}) do
    cond do
      path1 < path2 -> :lt
      path1 > path2 -> :gt
      true -> :eq
    end
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

  defp get_modules(code) when is_binary(code) do
    code
    |> Sourceror.parse_string!()
    |> get_modules()
  end

  defp get_modules(code) do
    # `get_modules/1` does not use `Code.compile_*/2` so that code fragments and
    # non-compilable code can also be examined.
    code
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

    source
    |> Map.put(:code, code)
    |> Map.put(:ast, Sourceror.parse_string!(code))
  end

  defp put(source, key, value), do: Map.put(source, key, value)

  defp update_updates(%Source{updates: updates} = source, update) do
    %{source | updates: [update | updates]}
  end

  defp compile_module(code, path, module) do
    code |> Code.compile_string(path || "nofile") |> Keyword.fetch!(module)
  end

  defp not_empty?(enum), do: not Enum.empty?(enum)

  defp newline(string), do: String.trim_trailing(string) <> "\n"
end
