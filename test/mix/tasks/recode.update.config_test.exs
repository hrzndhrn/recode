defmodule Mix.Tasks.Recode.Gen.UpdateTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.Recode.Update.Config

  @config ".recode.exs"

  test "mix recode.update.config" do
    unless File.exists?(@config) do
      File.write!(@config, "[verbose: true, tasks: []]")

      capture_io(fn -> Config.run(["--force"]) end)

      config = File.read!(@config)
      File.rm!(@config)

      assert config ==
               Recode.Config.default() |> Keyword.put(:verbose, true) |> Recode.Config.to_string()
    end
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
