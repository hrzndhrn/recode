# Run with: mix run scripts/module_per_file.exs

alias Recode.AST
alias Recode.Formatter
alias Rewrite.Project
alias Rewrite.Source
alias Recode.Traverse
alias Sourceror.Zipper

defmodule ModulePerFile do
  @moduledoc false

  use Recode.Task

  @impl Recode.Task
  def run(source, _opts) do
    source
    |> Source.ast()
    |> Zipper.zip()
    |> Traverse.collect(:defmodule)
    |> update(source)
  end

  def update([], source), do: source

  def update(zippers, source) do
    sources =
      Enum.map(zippers, fn zipper ->
        ast = Zipper.node(zipper)
        name = ast |> AST.module_name() |> Macro.underscore()
        path = Path.join("lib", name <> ".ex")

        Source.from_ast(ast, path, __MODULE__)
      end)

    [Source.del(source, __MODULE__) | sources]
  end
end

project = "{config,lib,test}/**/*.{ex,exs}" |> Path.wildcard() |> Project.read!()

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
Formatter.format(:results, {project, config}, [])

# If we want to write the changes to disk
# Project.save(project)
