defmodule Recode.DotFormatter do
  @moduledoc """
  This module provides the information from `.formatter.exs`.
  """

  @doc """
  Returns the options from the `.formatter.exs`.
  """
  @spec opts :: keyword()
  def opts do
    ".formatter.exs"
    |> eval_file_with_keyword_list()
    |> eval_deps_opts()
  end

  @doc """
  Returns the option `inputs` from the `.formatter.exs`.
  """
  @spec inputs :: list()
  def inputs, do: Keyword.get(opts(), :inputs, [])

  @doc """
  Returns the option `locals_without_parens` from the `.formatter.exs`.
  """
  @spec locals_without_parens :: keyword()
  def locals_without_parens, do: Keyword.get(opts(), :locals_without_parens, [])

  defp eval_deps_opts(formatter_opts) do
    eval_deps_opts(formatter_opts, Keyword.get(formatter_opts, :import_deps, []))
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
