defmodule Mix.Tasks.Recode do
  @moduledoc """
  TODO: add moduledoc
  """

  @shortdoc "TODO: add shortdoc"

  use Mix.Task

  alias Recode.Task.AliasExpansion
  alias Recode.Task.PipeFunOne
  alias Recode.Task.SinglePipe

  @inputs "{lib,test}/**/*.{ex,exs}"
  @tasks [alias_expansion: AliasExpansion, pipe_fun_one: PipeFunOne, single_pipe: SinglePipe]

  @opts strict: [pipe_fun_one: :boolean, alias_expansion: :boolean, single_pipe: :boolean]

  @impl Mix.Task
  def run(opts) do
    tasks =
      opts
      |> OptionParser.parse!(@opts)
      |> elem(0)
      |> tasks(@tasks)

    locals_without_parens = Keyword.get(formatter_opts(), :locals_without_parens, [])

    @inputs
    |> Path.wildcard()
    |> read!()
    |> recode(tasks, locals_without_parens: locals_without_parens)
    |> write!()
  end

  defp write!(outputs) when is_list(outputs) do
    Enum.map(outputs, &write!/1)
  end

  defp write!({path, old, new}) do
    unless old == new do
      File.write!(path, new)
      Mix.Shell.IO.info([IO.ANSI.green(), "* update: ", IO.ANSI.reset(), path])
    end
  end

  defp read!(paths) do
    Enum.map(paths, fn path -> {path, File.read!(path)} end)
  end

  defp recode(inputs, tasks, opts) when is_list(inputs) do
    Enum.map(inputs, fn input -> recode(input, tasks, opts) end)
  end

  defp recode({path, code}, tasks, opts) do
    {path, code, recode(code, tasks, opts)}
  end

  defp recode(code, tasks, opts) do
    Enum.reduce(tasks, code, fn task, code ->
      code
      |> Sourceror.parse_string!()
      |> task.run()
      |> Sourceror.to_string(opts)
      |> newline()
    end)
  end

  defp tasks([], tasks), do: Keyword.values(tasks)

  defp tasks(opts, tasks) do
    opts
    |> Keyword.values()
    |> Enum.any?()
    |> case do
      true -> tasks(opts, tasks, :include)
      false -> tasks(opts, tasks, :exclude)
    end
  end

  defp tasks(opts, tasks, :include) do
    opts
    |> Enum.reduce([], fn {key, true}, acc ->
      [Keyword.get(tasks, key) | acc]
    end)
    |> Enum.reverse()
  end

  defp tasks(opts, tasks, :exclude) do
    tasks
    |> Enum.reduce([], fn {key, task}, acc ->
      case Keyword.get(opts, key, true) do
        false -> acc
        true -> [task | acc]
      end
    end)
    |> Enum.reverse()
  end

  defp newline(string), do: string <> "\n"

  defp formatter_opts do
    ".formatter.exs"
    |> eval_file_with_keyword_list()
    |> eval_deps_opts()
  end

  defp eval_deps_opts(formatter_opts) do
    eval_deps_opts(formatter_opts, formatter_opts[:import_deps])
  end

  defp eval_deps_opts(formatter_opts, []) do
    formatter_opts
  end

  defp eval_deps_opts(formatter_opts, deps) do
    deps_paths = Mix.Project.deps_paths()

    locals_without_parens =
      for dep <- deps,
          dep_path = assert_valid_dep_and_fetch_path(dep, deps_paths),
          dep_dot_formatter = Path.join(dep_path, ".formatter.exs"),
          File.regular?(dep_dot_formatter),
          dep_opts = eval_file_with_keyword_list(dep_dot_formatter),
          parenless <- dep_opts[:export][:locals_without_parens] || [],
          uniq: true,
          do: parenless

    Keyword.update(
      formatter_opts,
      :locals_without_parens,
      locals_without_parens,
      fn list -> list ++ locals_without_parens end
    )
  end

  defp assert_valid_dep_and_fetch_path(dep, deps_paths) when is_atom(dep) do
    case Map.fetch(deps_paths, dep) do
      {:ok, path} ->
        if File.dir?(path) do
          path
        else
          Mix.raise("""
          Unavailable dependency #{inspect(dep)} given to :import_deps in the formatter \
          configuration. The dependency cannot be found in the file system, please run \
          "mix deps.get" and try again\
          """)
        end

      :error ->
        Mix.raise("""
        Unknown dependency #{inspect(dep)} given to :import_deps in the formatter \
        configuration. The dependency is not listed in your mix.exs for environment \
        #{inspect(Mix.env())}\
        """)
    end
  end

  defp assert_valid_dep_and_fetch_path(dep, _deps_paths) do
    Mix.raise("Dependencies in :import_deps should be atoms, got: #{inspect(dep)}")
  end

  defp eval_file_with_keyword_list(path) do
    {opts, _} = Code.eval_file(path)

    unless Keyword.keyword?(opts) do
      Mix.raise("Expected #{inspect(path)} to return a keyword list, got: #{inspect(opts)}")
    end

    opts
  end
end
