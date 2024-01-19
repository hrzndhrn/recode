defmodule Recode.Task.Moduledoc do
  @shortdoc "There should be a @moduledoc in the module."

  @moduledoc """
  Any module should contain a `@moudledoc` attribute.

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
  alias Recode.Issue
  alias Rewrite.Source
  alias Sourceror.Zipper

  @skip_def_kinds [:def, :defp, :defmacro, :defmacrop]
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
    |> Zipper.zip()
    |> Zipper.traverse_while([], module(ignore_names))
    |> update(source)
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

  defp update({_zipper, []}, source), do: source
  defp update({_zipper, issues}, source), do: Source.add_issues(source, issues)

  defp module(ignore_names) do
    fn
      %Zipper{node: {:defmodule, meta, args}} = zipper, issues ->
        issues = issues ++ check(zipper, name(args), meta, ignore_names)

        {:skip, zipper, issues}

      zipper, issues ->
        {:cont, zipper, issues}
    end
  end

  defp check(zipper, name, meta, ignore_names) do
    acc = if ignore?(name, ignore_names), do: [:ignore], else: []

    {_zipper, issues} =
      zipper
      |> do_block()
      |> Zipper.traverse_while(acc, moduledoc(ignore_names))

    issues(issues, name, meta)
  end

  defp moduledoc(ignore_names) do
    fn
      %Zipper{node: {def_kind, _, _}} = zipper, issues when def_kind in @skip_def_kinds ->
        {:skip, zipper, issues}

      %Zipper{node: {:defmodule, meta, args}} = zipper, issues ->
        issues = issues ++ check(zipper, name(args), meta, ignore_names)

        {:skip, zipper, issues}

      zipper, [:ignore | _issues] = issues ->
        {:cont, zipper, issues}

      %Zipper{node: {:@, _, [{:moduledoc, _, _} | _]}} = zipper, issues ->
        {:cont, zipper, [:exist | issues]}

      zipper, issues ->
        {:cont, zipper, issues}
    end
  end

  defp issues([issue | issues], _name, _meta) when issue in [:exist, :ignore], do: issues

  defp issues(issues, name, meta) do
    [issue(name, meta) | issues]
  end

  defp issue(name, meta) do
    message = "The moudle #{name} is missing @moduledoc."
    Issue.new(Moduledoc, message, meta)
  end

  defp do_block(zipper) do
    Zipper.traverse_while(zipper, fn
      %Zipper{node: {{:__block__, _, [:do]}, block}} ->
        {:halt, Zipper.zip(block)}

      zipper ->
        {:cont, zipper}
    end)
  end

  defp ignore?(_name, []), do: false

  defp ignore?(name, [ignore_name | ignore_names]) do
    with false <- Regex.match?(ignore_name, name) do
      ignore?(name, ignore_names)
    end
  end

  defp name([arg | _args]), do: name(arg)
  defp name(arg), do: arg |> AST.aliases_concat() |> inspect()
end
