defmodule Recode.Task.Moduledoc do
  @shortdoc "There should be a @moduledoc in any module."

  @moduledoc """
  Any module should contain a `@moduledoc` attribute.

  For a public module, comprehensive documentation should be available. The
  module documentation helps the user of your package, contributors, and your
  future self understand what the module is for.

  For private modules, it is also okay to set `@moduled false`. Modules marked
  in this way are not displayed in the documentation.

  ## Options

    * `ignore_names` - accepts a regex or a list of regexes to recognize modules
      that this task ignores.
  """

  use Recode.Task, corrector: false, category: :readability

  alias Recode.AST
  alias Rewrite.Source

  @default_config [ignore_names: []]
  @error_message """
  The config for the Recode.Task.Moduledoc is wrong. The task excepts the option \
  :ignore_names with a regexp or a list of regexps.
  """

  @impl Recode.Task
  def run(source, config) do
    ignore_names = Keyword.fetch!(config, :ignore_names)

    source
    |> Source.get(:quoted)
    |> check()
    |> update(source, ignore_names)
  end

  @impl Recode.Task
  def init([]), do: {:ok, @default_config}

  def init(config) do
    with {:ok, config} <- validate_keys(config) do
      config =
        Keyword.update!(config, :ignore_names, fn ignore_names -> List.wrap(ignore_names) end)

      if validate_config(config) do
        {:ok, config}
      else
        {:error, @error_message}
      end
    end
  end

  defp check(ast) do
    AST.reduce_while(ast, [], fn
      {:defmodule, meta, [aliases, args]}, acc ->
        module = {AST.module(aliases), meta}
        block = AST.block(args)
        acc = [check_module([module], block) | acc]
        {:skip, acc}

      _ast, acc ->
        {:cont, acc}
    end)
  end

  defp check_module(modules, ast) do
    AST.reduce_while(ast, modules, fn
      {:@, _, [{:moduledoc, _, args} | _]}, [module | modules] when not is_nil(module) ->
        {:cont, [check_moduledoc(args, module) | modules]}

      {:defmodule, meta, [aliases, args]}, acc ->
        module = {AST.module(aliases), meta}
        block = AST.block(args)
        acc = [acc | check_module([module], block)]
        {:skip, acc}

      _ast, acc ->
        {:skip, acc}
    end)
  end

  defp check_moduledoc([{:__block__, _meta, [text]}], {module, meta}) when is_binary(text) do
    {module, Keyword.merge(meta, exist: true, empty: String.trim(text) == "")}
  end

  defp check_moduledoc(_args, {module, meta}) do
    {module, Keyword.merge(meta, exist: true, empty: false)}
  end

  defp update([], source, _ignore_names), do: source

  defp update(result, source, ignore_names) do
    result
    |> List.flatten()
    |> Enum.reduce(source, fn module, source -> issue(module, source, ignore_names) end)
  end

  defp issue({module, meta}, source, ignore_names) do
    cond do
      ignore?(AST.name(module), ignore_names) ->
        source

      Keyword.get(meta, :empty, false) ->
        add_issue(source, meta, """
        The @moduledoc attribute for module #{module} has no content.\
        """)

      Keyword.get(meta, :exist, false) ->
        source

      true ->
        add_issue(source, meta, """
        The module #{module} is missing @moduledoc.\
        """)
    end
  end

  defp add_issue(source, meta, message) do
    Source.add_issue(source, new_issue(message, meta))
  end

  defp ignore?(_name, []), do: false

  defp ignore?(name, [ignore_name | ignore_names]) do
    with false <- Regex.match?(ignore_name, name) do
      ignore?(name, ignore_names)
    end
  end

  defp validate_keys(config) do
    with {:error, unknown} <- Keyword.validate(config, @default_config) do
      {:error, "#{@error_message}. Unknown keys: #{inspect(unknown)}"}
    end
  end

  defp validate_config(config) do
    case Keyword.fetch!(config, :ignore_names) do
      [_ | _] = list -> Enum.all?(list, fn regex -> is_struct(regex, Regex) end)
      %Regex{} -> true
      _invalid -> false
    end
  end
end
