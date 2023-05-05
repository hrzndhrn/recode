defmodule Recode.ConfigTest do
  use ExUnit.Case

  import GlobEx.Sigils

  alias Mix.Project
  alias Recode.Config
  alias Recode.Formatter
  alias Recode.Task

  describe "read/1" do
    test "reads config" do
      assert Config.read("priv/config.exs") ==
               {:ok,
                [
                  version: "0.5.0",
                  autocorrect: true,
                  dry: false,
                  verbose: false,
                  inputs: [~g|{apps,config,lib,test}/**/*.{ex,exs}|],
                  formatter: {Formatter, []},
                  tasks: [
                    {Task.Format, []},
                    {Task.AliasExpansion, []},
                    {Task.AliasOrder, []},
                    {Task.EnforceLineLength, [active: false]},
                    {Task.PipeFunOne, []},
                    {Task.SinglePipe, []},
                    {Task.Specs, [exclude: "test/**/*.{ex,exs}", config: [only: :visible]]},
                    {Task.TestFileExt, []},
                    {Task.UnusedVariable, [active: false]}
                  ]
                ]}
    end

    test "returns an error tuple for a missing config file" do
      assert Config.read("foo/bar/conf.exs") == {:error, :not_found}
    end
  end

  test "version in priv/config is equal to the version in mix.exs" do
    config =
      "priv/config.exs"
      |> File.read!()
      |> Code.eval_string()
      |> elem(0)

    assert config[:version] == Project.config()[:version]
  end
end
