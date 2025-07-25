defmodule Recode.Task.DirectiveOrderTest do
  use RecodeCase

  alias Recode.Task.DirectiveOrder

  test "sorts Use/Import/Alias/Require" do
    code = """
    defmodule MyModule do

      require Alpha
      alias Delta
      alias Alpha.{Bravo, Charlie}
      use Epsilon
      alias Alpha
      use Alpha


      import Bravo


      defp test(), do: 1
    end
    """

    expected = """
    defmodule MyModule do
      use Epsilon

      use Alpha

      import Bravo

      alias Delta
      alias Alpha.{Bravo, Charlie}

      alias Alpha

      require Alpha

      defp test(), do: 1
    end
    """

    code
    |> run_task(DirectiveOrder, autocorrect: true)
    |> assert_code(expected)
  end
end
