defmodule Recode.ConfigTest do
  use ExUnit.Case

  doctest Recode.Config

  alias Recode.Config

  test "version in Config.default() is equal to the version in mix.exs" do
    assert Config.default()[:version] == Mix.Project.config()[:version]
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

      assert Config.merge(new, old) == [
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
  end
end
