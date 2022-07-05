defmodule Mix.Tasks.Recode.Gen.ConfigTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  alias Mix.Tasks.Recode.Gen.Config

  @config ".recode.exs"

  test "mix recode.gen.config" do
    unless File.exists?(@config) do
      capture_io(fn -> Config.run([]) end)
      assert File.read!(@config) == File.read!("priv/config.exs")
      File.rm!(@config)
    end
  end
end
