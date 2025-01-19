defmodule Mix.Tasks.Recode.Gen.ConfigTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.Recode.Gen.Config

  @config ".recode.exs"

  test "mix recode.gen.config" do
    if !File.exists?(@config) do
      capture_io(fn -> Config.run([]) end)
      config = File.read!(@config)
      File.rm!(@config)
      assert config == Recode.Config.to_string()
    end
  end
end
