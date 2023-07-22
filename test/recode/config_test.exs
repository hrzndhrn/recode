defmodule Recode.ConfigTest do
  use ExUnit.Case

  alias Recode.Config

  describe "read/1" do
    test "reads config" do
      assert {:ok, config} = Config.read("priv/config.exs")
      assert Keyword.keyword?(config)
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

    assert config[:version] == Mix.Project.config()[:version]
  end
end
