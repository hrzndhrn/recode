# A little demo for a task to add `use ...` to an existing module.
# Run with: mix run scripts/add_use.exs
alias Recode.AST
alias Recode.Formatter
alias Recode.Project
alias Recode.Source
alias Recode.Traverse
alias Sourceror.Zipper

defmodule AddUse do
  @moduledoc false

  use Recode.Task

  @impl Recode.Task
  def run(source, opts) do
    use = opts |> Keyword.get(:use) |> gen_use()

    ast =
      source
      # get a zipper from the source
      |> Source.zipper()
      # move to the right moudle (the source could contain multiple modules)
      |> Traverse.to_defmodule!(opts[:module])
      # insert the new code after current position or after @moduledoc
      |> insert(use)
      # return the root AST
      |> Zipper.root()

    Source.update(source, AdUse, ast: ast)
  end

  defp insert(zipper, ast) do
    zipper =
      case Traverse.to(zipper, {:@, :moduledoc}) do
        {:ok, zipper} -> zipper
        :error -> zipper
      end

    Zipper.insert_right(zipper, ast)
  end

  defp gen_use(module) when is_atom(module), do: gen_use({module, []})

  defp gen_use({module, opts}) do
    AST.gen(:use, module, opts)
  end
end

project = "{config,lib,test}/**/*.{ex,exs}" |> Path.wildcard() |> Project.new()

module = MyCode.Happy
use = {Foo.Bar, baz: 2}

source =
  project
  |> Project.module!(module)
  |> AddUse.run(module: module, use: use)

project = Project.update(project, source)

Formatter.format_code_update(source)
IO.puts("\n" <> Source.code(source))

# If we want to write the changes to disk
# Project.save(project)
