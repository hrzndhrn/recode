defmodule Recode.ConfigTest do
  use ExUnit.Case

  doctest Recode.Config

  import GlobEx.Sigils

  alias Recode.Config

  test "version in Config.default() is equal to the version in mix.exs" do
    assert Config.default()[:version] == Mix.Project.config()[:version]
  end

  @exclude_tasks [Recode.Task.Format, Recode.Task.Moduledoc, Recode.Task.Tags]
  test "all tasks in config" do
    tasks =
      Config.default()
      |> Keyword.get(:tasks)
      |> Enum.map(fn {task, _} -> task |> inspect() |> Macro.underscore() end)

    files =
      ~g|lib/recode/task/**/*.ex|
      |> GlobEx.ls()
      |> Enum.map(fn path ->
        ~r/^lib.(.*).ex$/
        |> Regex.run(path)
        |> Enum.at(1)
      end)

    exclude = Enum.map(@exclude_tasks, fn task -> Macro.underscore(task) end)

    missing = files -- tasks
    missing = missing -- exclude
    missing = Enum.map(missing, fn module -> Macro.camelize(module) end)

    assert Enum.empty?(missing), """
    The default config is missing entries for #{inspect(missing)}.

    You can add these to the `@default_config` in `Recode.Config`.
    """
  end

  describe "read/1" do
    test "reads config" do
      assert {:ok, config} = Config.read("test/fixtures/config.exs")
      assert Keyword.keyword?(config)
    end

    test "returns an error tuple for a missing config file" do
      assert Config.read("foo/bar/conf.exs") == {:error, :not_found}
    end
  end

  describe "merge/2" do
    test "merges configs" do
      old = [
        version: "0.0.1",
        verbose: true,
        tasks: [
          {Recode.Task.EnforceLineLength, []},
          {Recode.Task.Specs,
           [
             exclude: ["test/**/*.{ex,exs}", "int_test/**/*.{ex,exs}"],
             config: [only: :visible]
           ]},
          {Recode.Task.PipeFunOne, [active: true]},
          {MyApp.RecodeTask, []}
        ]
      ]

      new = [
        version: "0.0.2",
        verbose: false,
        autocorrect: true,
        tasks: [
          {Recode.Task.EnforceLineLength, [active: false]},
          {Recode.Task.PipeFunOne, [active: false]},
          {Recode.Task.Specs, [exclude: "test/**/*.{ex,exs}", config: [only: :visible]]},
          {Recode.Task.FilterCount, []},
          {Recode.Task.SinglePipe, []}
        ]
      ]

      assert new |> Config.merge(old) |> Enum.sort() == [
               autocorrect: true,
               tasks: [
                 {MyApp.RecodeTask, []},
                 {Recode.Task.EnforceLineLength, [{:active, false}]},
                 {Recode.Task.FilterCount, []},
                 {Recode.Task.PipeFunOne, [active: true]},
                 {Recode.Task.SinglePipe, []},
                 {Recode.Task.Specs,
                  [
                    exclude: ["test/**/*.{ex,exs}", "int_test/**/*.{ex,exs}"],
                    config: [only: :visible]
                  ]}
               ],
               verbose: true,
               version: "0.0.2"
             ]
    end

    test "merges task config" do
      old = [
        tasks: [
          {Test, config: [a: 1, b: 2, c: 3]}
        ]
      ]

      new = [
        tasks: [
          {Test, config: [b: 2, c: 9, d: 4]}
        ]
      ]

      assert Config.merge(new, old) == [
               tasks: [
                 {Test, [config: [a: 1, b: 2, c: 3, d: 4]]}
               ]
             ]
    end
  end
end
