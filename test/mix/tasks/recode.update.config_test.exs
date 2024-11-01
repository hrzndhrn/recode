defmodule Mix.Tasks.Recode.Gen.UpdateTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.Recode.Update.Config

  @config ".recode.exs"

  @tag :tmp_dir
  test "mix recode.update.config --force", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      File.write!(@config, "[verbose: true, tasks: []]")

      capture_io(fn -> Config.run(["--force"]) end)

      config = File.read!(@config)

      assert config ==
               Recode.Config.default()
               |> Keyword.put(:verbose, true)
               |> Recode.Config.to_string()
    end)
  end

  @tag :tmp_dir
  test "mix recode.update.config - input: Y", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      File.write!(@config, "[verbose: true, tasks: []]")

      capture_io([input: "Y"], fn -> Config.run([]) end)

      config = File.read!(@config)

      assert config ==
               Recode.Config.default()
               |> Keyword.put(:verbose, true)
               |> Recode.Config.to_string()
    end)
  end

  @tag :tmp_dir
  test "mix recode.update.config - input: n", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      config = "[verbose: true, tasks: []]"
      File.write!(@config, config)

      capture_io([input: "n"], fn -> Config.run([]) end)

      assert File.read!(@config) == config
    end)
  end

  @tag :tmp_dir
  test "mix recode.update.config cleans up removed tasks", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      File.write!(@config, "[verbose: true, tasks: [{Recode.Task.TestFileExt, []}]]")

      capture_io(fn -> Config.run(["--force"]) end)

      config = File.read!(@config)

      assert config ==
               Recode.Config.default()
               |> Keyword.put(:verbose, true)
               |> Recode.Config.to_string()
    end)
  end

  test "mix recode.update.config # with missing .recode.exs" do
    message = ~s|config file .recode.exs not found, run "mix recode.gen.config"|

    assert_raise Mix.Error, message, fn ->
      Config.run([])
    end
  end

  test "mix recode.update.config foo" do
    message = ~s|get unknown options: ["--foo"]|

    assert_raise Mix.Error, message, fn ->
      Config.run(["--foo"])
    end
  end
end
