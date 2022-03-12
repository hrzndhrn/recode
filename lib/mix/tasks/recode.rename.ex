defmodule Mix.Tasks.Recode.Rename do
  @shortdoc "TODO: @shortdoc"

  @moduledoc """
  TODO: @moduledoc
  """

  # TODO
  # mix call:
  # mix rc.reanme Rename.Bar.baz bar
  # opts:
  # [from: {Rename.Bar, :baz, nil}, to: %{fun: :bar}]

  use Mix.Task

  alias Recode.Config
  alias Recode.Runner
  alias Recode.Task.Rename

  @opts strict: [config: :string]

  @impl Mix.Task
  def run(opts) do
    {opts, args} = OptionParser.parse!(opts, @opts)
    args = args!(args)

    config = config!(opts)

    prepare(config)

    Runner.run({Rename, args}, config)
  end

  defp config!(opts) do
    case Config.read(opts) do
      {:ok, config} -> config
      {:error, :not_found} -> Mix.raise("Config file not found")
    end
  end

  defp prepare(opts) do
    inputs = opts[:inputs]

    exclude_compilation =
      case Keyword.fetch(opts, :exclude_compilation) do
        {:ok, wildcard} ->
          wildcard
          |> List.wrap()
          |> Enum.flat_map(fn wildcard -> Path.wildcard(wildcard) end)

        :error ->
          []
      end

    ExUnit.start()

    Code.put_compiler_option(:ignore_module_conflict, true)

    config = Mix.Project.config()
    elixirc_paths = Keyword.fetch!(config, :elixirc_paths)
    compile_path = Mix.Project.compile_path()

    inputs
    |> List.wrap()
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.reject(fn input ->
      String.ends_with?(input, ".exs") or
        Enum.any?(elixirc_paths, fn path -> String.starts_with?(input, path) end) or
        input in exclude_compilation
    end)
    |> Kernel.ParallelCompiler.compile_to_path(compile_path)
  end

  defp args!([from, to]) do
    case to_mfa(from) do
      {:ok, from_mfa} ->
        to = %{fun: String.to_atom(to)}
        [from: from_mfa, to: to]

      :error ->
        Mix.raise("Can not parse arguments")
    end
  end

  defp args!(_invalid) do
    Mix.raise("""
    Expected module.fun and the new function name.
    Examples:
    mix recode.rename MyApp.Some.make_it do_it\
    """)
  end

  defp to_mfa(string) when is_binary(string) do
    ~r{[.|/]}
    |> Regex.split(string)
    |> Enum.group_by(fn part ->
      cond do
        part =~ ~r/^[A-Z]/ -> :module
        part =~ ~r/^[a-z]/ -> :fun
        part =~ ~r/^[0-9]/ -> :arity
        true -> :error
      end
    end)
    |> to_mfa()
  end

  defp to_mfa(%{error: _error}), do: :error

  defp to_mfa(%{} = parts) do
    with {:ok, fun} <- to_fun(parts),
         {:ok, arity} <- to_arity(parts),
         {:ok, module} <- to_module(parts) do
      {:ok, {module, fun, arity}}
    end
  end

  defp to_module(%{module: module}), do: {:ok, Module.concat(module)}

  defp to_module(_parts), do: :error

  defp to_fun(%{fun: [fun]}), do: {:ok, String.to_atom(fun)}

  defp to_fun(_parts), do: :error

  defp to_arity(%{arity: [arity]}), do: {:ok, String.to_integer(arity)}

  defp to_arity(_parts), do: {:ok, nil}
end
