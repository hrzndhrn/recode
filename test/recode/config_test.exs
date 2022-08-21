defmodule Recode.ConfigTest do
  use ExUnit.Case

  alias Mix.Project
  alias Recode.Config
  alias Recode.Task.Format

  describe "read/1" do
    test "reads config" do
      config =
        "priv/config.exs"
        |> File.read!()
        |> Code.eval_string()
        |> elem(0)
        |> Keyword.update!(:tasks, fn tasks -> [{Format, []} | tasks] end)

      assert Config.read("priv/config.exs") == {:ok, config}
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
