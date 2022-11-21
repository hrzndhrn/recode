# A little demo for a task to add `use ...` to an existing module.
# Run with: mix run scripts/add_use.exs
alias Recode.AST
alias Recode.Formatter
alias Rewrite.Project
alias Rewrite.Source
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
      |> Source.ast()
      # get a zipper from the source
      |> Zipper.zip()
      # move to the right moudle (the source could contain multiple modules)
      |> Traverse.to_defmodule!(opts[:module])
      # insert the new code after current position or after @moduledoc
      |> insert(use)
      # return the root AST
      |> Zipper.root()

    Source.update(source, __MODULE__, ast: ast)
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

project = "{config,lib,test}/**/*.{ex,exs}" |> Path.wildcard() |> Project.read!()

module = MyCode.Happy
use = {Foo.Bar, baz: 2}

source =
  project
  |> Project.source_by_module!(module)
  |> AddUse.run(module: module, use: use)

project = Project.update(project, source)

config = [verbose: true]
Formatter.format(:project, {project, config}, [])
Formatter.format(:results, {project, config}, [])
IO.puts("The new code:" <> Source.code(source))

# If we want to write the changes to disk
# Project.save(project)
