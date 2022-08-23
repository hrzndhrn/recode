# A little demo for a task to add `use ...` to an existing module.
# Run with: mix run scripts/add_use.exs
alias Recode.AST
alias Recode.Formatter
alias Recode.Project
alias Recode.Source
alias Recode.Traverse
alias Sourceror.Zipper

defmodule ModulePerFile do
  @moduledoc false

  use Recode.Task

  @impl Recode.Task
  def run(source, _opts) do
    zippers =
      source
      |> Source.zipper()
      |> Traverse.collect(:defmodule)

    case zippers do
      [] ->
        source

      zippers ->
        sources =
          Enum.map(zippers, fn zipper ->
            ast = Zipper.node(zipper)
            name = ast |> AST.module_name() |> Macro.underscore()
            path = Path.join("lib", name <> ".ex")

            ast
            |> Source.from_ast()
            |> Source.update(__MODULE__, path: path)
          end)

        [Source.del(source, __MODULE__) | sources]
    end

    # Source.update(source, __MODULE__, ast: ast)
  end
end

project = "{config,lib,test}/**/*.{ex,exs}" |> Path.wildcard() |> Project.new()

path = "lib/my_code/two_modules.ex"

sources =
  project
  |> Project.source!(path)
  |> ModulePerFile.run([])

project =
  Enum.reduce(sources, project, fn source, project ->
    Project.update(project, source)
  end)

config = [verbose: true]
Formatter.format(:project, {project, config}, [])
Formatter.format(:results, {project, config}, [])
# IO.puts("The new code:" <> Source.code(source))

# If we want to write the changes to disk
# Project.save(project)
