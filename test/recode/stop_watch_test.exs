defmodule Recode.StopWatchTest do
  use ExUnit.Case

  alias Recode.StopWatch

  doctest Recode.StopWatch

  setup do
    [name: String.to_atom("sw-#{System.unique_integer()}")]
  end

  describe "init/1" do
    test "raises an ArgumentError when already initalized", %{name: name} do
      message = "StopWatch already exisits."

      assert_raise(ArgumentError, message, fn ->
        StopWatch.init(name: name)
        StopWatch.init(name: name)
      end)
    end
  end

  describe "start/2" do
    test "raises an ArgumentError when already started", %{name: name} do
      message = "StopWatch has already received the :start operation for :foo."

      assert_raise(ArgumentError, message, fn ->
        StopWatch.init(name: name)
        StopWatch.start(name, :foo)
        StopWatch.start(name, :foo)
      end)
    end
  end

  describe "stop/2" do
    test "raises an ArgumentError when already stoped", %{name: name} do
      message = "StopWatch has already received the :stop operation for :foo."

      assert_raise(ArgumentError, message, fn ->
        StopWatch.init(name: name)
        StopWatch.start(name, :foo)
        StopWatch.stop(name, :foo)
        StopWatch.stop(name, :foo)
      end)
    end
  end

  describe "time/2" do
    test "returns time for a running stop watch", %{name: name} do
      StopWatch.init(name: name)
      StopWatch.start(name, :foo)
      time_1 = StopWatch.time(name, :foo)
      time_2 = StopWatch.time(name, :foo)

      assert time_1 < time_2
    end

    test "returns time for a stoped stop watch", %{name: name} do
      StopWatch.init(name: name)
      StopWatch.start(name, "foo")
      StopWatch.stop(name, "foo")
      time_1 = StopWatch.time(name, "foo")
      time_2 = StopWatch.time(name, "foo")

      assert time_1 == time_2
    end
  end
end
