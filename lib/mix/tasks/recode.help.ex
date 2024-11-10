defmodule Mix.Tasks.Recode.Help do
  @shortdoc "Lists recode tasks"

  @moduledoc """
  Lists all availbale recode tasks with a short description or prints the
  documentation for a given recode task.

  To print the documentation of a task run `mix recode.help {task-name}`. As a
  task name the module name (e.g. `Nesting`) or the full module name (e.g.
  `Recode.Task.Nesting`) is accepted.
  """

  use Mix.Task

  @task_namespace "Recode.Task."

  @impl Mix.Task
  def run([]) do
    :recode
    |> Application.spec(:modules)
    |> Enum.filter(&task?/1)
    |> Enum.group_by(&category/1, &info/1)
    |> print()
  end

  def run([task]) do
    module =
      :recode |> Application.spec(:modules) |> Enum.find(fn module -> task?(module, task) end)

    if module do
      IEx.Introspection.h(module)
      :ok
    else
      Mix.raise("""
      The recode task #{task} could not be found. \
      Run "mix recode.help" for a list of recode tasks.\
      """)
    end
  end

  def run(_opts) do
    Mix.raise("""
    recode.help does not support this command. For more information run "mix help recode.help"\
    """)
  end

  defp category(module), do: Recode.Task.category(module)

  defp task?(module) do
    task? = module |> inspect() |> String.starts_with?(@task_namespace)

    task? and not is_nil(Recode.Task.shortdoc(module))
  end

  defp task?(module, name) do
    with true <- task?(module) do
      inspect(module) == name or
        module |> inspect() |> String.trim_leading(@task_namespace) == name
    end
  end

  defp info(module) do
    name = module |> inspect() |> String.trim_leading(@task_namespace)
    {name, Recode.Task.shortdoc(module), Recode.Task.corrector?(module)}
  end

  defp print(info) do
    max = max_name_length(info)
    print("Design tasks:", info.design, max)
    print("Readability tasks:", info.readability, max)
    print("Refactor tasks:", info.refactor, max)
    print("Warning tasks:", info.warning, max)

    Escape.puts([
      "\n",
      "To get help for a specific task run ",
      [:cyan, "mix recode.help [task-name]."]
    ])
  end

  defp print(section, tasks, max) do
    Escape.puts([:yellow, :reverse, " #{section} "])

    Enum.each(tasks, fn {task, doc, corrector?} ->
      type = if corrector?, do: "Corrector -", else: "Checker   -"
      IO.puts(String.pad_trailing(task, max) <> " # #{type} #{doc}")
    end)
  end

  defp max_name_length(info) when is_map(info) do
    info
    |> Map.values()
    |> List.flatten()
    |> Enum.reduce(0, fn {name, _shortdoc, _corrector?}, max ->
      max(byte_size(name), max)
    end)
  end
end
