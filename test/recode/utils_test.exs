defmodule Recode.UtilsTest do
  use ExUnit.Case

  import Recode.Utils

  describe "end_with?/2" do
    test "returns true if alias ends with suffix" do
      assert ends_with?(Foo.Bar, Bar) == true
    end

    test "returns false if alias ends not with suffix" do
      assert ends_with?(Foo.Bar, Zoo) == false
    end

    test "returns false if alias is shorter as suffix" do
      assert ends_with?(Bar, Foo.Bar) == false
    end
  end
end
