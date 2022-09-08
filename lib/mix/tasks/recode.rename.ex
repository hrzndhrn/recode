defmodule Mix.Tasks.Recode.Rename do
  @shortdoc "Renames the given function"

  @moduledoc """
  A mix task to rename functions.

  ```shell
  mix recode.rename Module.name[/arity] new_name
  ```
  This mix task overwrite the definition and all calls of the given function
  with the `new_name`. If the `arity` is given to `Module.name` only functions
  with the corresponding `arity` will be rewritten.

  ## Examples
  ```shell
  mix recode.rename MyApp.hello say_hello
  ```

  ```shell
  mix recode.rename MyApp.SomeMoudle.do_it/2 make
  ```

  ## Switchtes

    * `--config` - specifies an alternative config file.

    * `--dry`, `--no-dry` - Activates/deactivates the dry mode. No file is
      overwritten in dry mode. Overwrites the corresponding value in the
      configuration.

    * `--verbose`, `--no-verbose` - Activate/deactivates the verbose mode.
      Overwrites the corresponding value in the configuration.
  """

  use Mix.Task

  alias Recode.Config
  alias Recode.Runner
  alias Recode.Task.Rename

  @opts strict: [config: :string, dry: :boolean, verbose: :boolean]

  @impl Mix.Task
  def run(opts) do
    {opts, args} = OptionParser.parse!(opts, @opts)
    args = args!(args)

    config =
      opts
      |> config!()
      |> Keyword.merge(opts)
      |> update(:verbose)

    :ok = prepare(config)

    Runner.run({Rename, config: args}, config)
  end

  defp config!(opts) do
    case Config.read(opts) do
      {:ok, config} -> config
      {:error, :not_found} -> Mix.raise("Config file not found")
    end
  end

  defp prepare(opts) do
    Mix.Task.run("compile")

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

    ExUnit.start(autorun: false)

    Code.put_compiler_option(:ignore_module_conflict, true)

    config = Mix.Project.config()
    elixirc_paths = Keyword.fetch!(config, :elixirc_paths)
    compile_path = Mix.Project.compile_path()

    {:ok, _modules, _warnings} =
      inputs
      |> List.wrap()
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.reject(fn input ->
        String.ends_with?(input, ".exs") or
          Enum.any?(elixirc_paths, fn path -> String.starts_with?(input, path) end) or
          input in exclude_compilation
      end)
      |> Kernel.ParallelCompiler.compile_to_path(compile_path)

    :ok
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

  defp update(opts, :verbose) do
    case opts[:dry] do
      true -> Keyword.put(opts, :verbose, true)
      false -> opts
    end
  end
end
