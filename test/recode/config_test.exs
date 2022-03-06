defmodule Recode.ConfigTest do
  use ExUnit.Case

  alias Recode.Config

  describe "read/1" do
    test "reads config" do
      assert Config.read("priv/config.exs") ==
               {:ok,
                [
                  autocorrect: true,
                  dry: false,
                  verbose: false,
                  inputs: ["{config,lib,test}/**/*.{ex,exs}"],
                  tasks: [
                    {Recode.Task.SinglePipe, []},
                    {Recode.Task.PipeFunOne, []},
                    {Recode.Task.AliasExpansion, []}
                  ]
                ]}
    end

    test "returns an error tuple for a missing config file" do
      assert Config.read("foo/bar/conf.exs") == {:error, :not_found}
    end
  end
end
