defmodule Mix.Tasks.Recode.Rename do
  # TODO
  # @moduledoc
  # @shortdoc

  # TODO
  # mix call:
  # mix rc.reanme --fun Rename.Bar.baz --to bar
  # opts:
  # [from: {Rename.Bar, :baz, nil}, to: %{fun: :bar}]

  use Mix.Task

  alias Recode.Project
  alias Recode.Task.Rename
  alias Recode.Runner
  alias Recode.Source

  def run(opts) do
    {task_opts, runner_opts} = opts(opts)
    runner_opts = Keyword.put_new(runner_opts, :inputs, "{lib,test}/**/*.{ex,exs}")
    # runner_opts = Keyword.put_new(runner_opts, :inputs, "lib/mix/task/recode/rename.ex")

    runner_opts |> Keyword.get(:inputs) |> prepare()

    project = Runner.run({Rename, task_opts}, runner_opts)
    s = Project.source!(project, "lib/mix/task/recode/rename.ex")

    project
    |> Project.state()
    |> IO.inspect(limit: :infinity)

    Source.code(s, 1) |> IO.puts()

    # IO.puts(Source.code(s, 0))
    # IO.puts("---")
    # IO.puts(Source.code(s, 1))
    # IO.puts("---")
    String.myers_difference(Source.code(s, 0), Source.code(s, 1))
    |> IO.inspect()

    raise "TODO"
  end

  defp prepare(inputs) do
    ExUnit.start()

    Code.put_compiler_option(:ignore_module_conflict, true)

    config = Mix.Project.config()
    elixirc_paths = Keyword.fetch!(config, :elixirc_paths)
    compile_path = Mix.Project.compile_path()

    inputs
    |> List.wrap()
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.reject(fn input ->
      # TODO to exclude test/fixtures is just needed for the recode project himself
      String.ends_with?(input, ".exs") or
        String.starts_with?(input, "test/fixtures") or
        Enum.any?(elixirc_paths, fn path -> String.starts_with?(input, path) end)
    end)
    |> Kernel.ParallelCompiler.compile_to_path(compile_path)
  end

  defp opts([from, to]) do
    with {:ok, from_mfa} <- to_mfa(from) do
      to = %{fun: String.to_atom(to)}
      {[from: from_mfa, to: to], []}
    else
      :error ->
        Mix.raise("""
        Can not parse from/to arguments.
        """)
    end
  end

  defp opts(_invalid) do
    # TODO: Update error message
    Mix.raise("""
    Expected a from and to mfa, module and/or function.
    Example:
    MyApp.Some.make_it do_it
    """)
  end

  defp to_mfa(string) when is_binary(string) do
    ~r{[.|/]}
    |> Regex.split(string)
    |> Enum.group_by(fn part ->
      cond do
        part =~ ~r/^[A-Z]/ -> :module
        part =~ ~r/^[a-z]/ -> :fun
        part =~ ~r/^[0.9]/ -> :arity
        true -> :error
      end
    end)
    |> to_mfa()
  end

  defp to_mfa(%{error: _error}), do: :error

  defp to_mfa(%{} = parts) do
    with {:ok, fun} <- to_fun(parts),
         {:ok, arity} <- to_arity(parts) do
      module = to_module(parts)
      {:ok, {module, fun, arity}}
    end
  end

  defp to_module(%{module: module}), do: Module.concat(module)

  defp to_module(_parts), do: nil

  defp to_fun(%{fun: [fun]}), do: {:ok, String.to_atom(fun)}

  defp to_fun(%{fun: _fun}), do: :error

  defp to_fun(_parts), do: {:ok, nil}

  defp to_arity(%{arity: [arity]}), do: {:ok, String.to_integer(arity)}

  defp to_arity(%{arity: _arity}), do: :error

  defp to_arity(_parts), do: {:ok, nil}
end
