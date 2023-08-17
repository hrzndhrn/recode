defmodule Recode.Task.NestingTest do
  use RecodeCase

  alias Recode.Task.Nesting

  describe "run/1" do
    #
    # cases NOT raising issues
    #

    test "does not trigger" do
      """
      defmodule Sample do
        def fun(x) do
          if x do
            :ok
          else
            :error
          end
        end
      end
      """
      |> run_task(Nesting)
      |> refute_issues()
    end

    test "does not trigger for multiple nested expressions" do
      """
      defmodule Sample do
        def fun(x, y, z) do
          a = if x do
            case y do
              true -> Bar.bar(y)
              false -> Bar.bar(x)
            end
          else
            :y
          end

          b = if x do
            if y == 42 do
              Bar.bar(y)
            else
              Bar.bar(x)
            end
          else
            :y
          end

          {a, b}
        end
      end
      """
      |> run_task(Nesting)
      |> refute_issues()
    end

    test "trigers not when max_depth is great enough" do
      """
      defmodule Sample do
        def function(x, y) do
          if x do
            if y do
              case x do
                0 -> nil
                1 -> foo(x)
              end
            end
          end
        end
      end
      """
      |> run_task(Nesting, max_depth: 3)
      |> refute_issues()
    end

    #
    # cases raising issues
    #

    test "trigers when max depth is exceeded" do
      """
      defmodule Sample do
        def something(x, y) do
          if x do
            if y do
              case x do
                0 -> nil
                1 -> foo(x)
              end
            end
          end
        end
      end
      """
      |> run_task(Nesting)
      |> assert_issue_with(reporter: Nesting, line: 5)
    end

    test "trigers once when max depth is exceeded by more then one step" do
      """
      defmodule Sample do
        def something(x, y) do
          if x do
            if y do
              case x do
                0 ->
                  cond do
                    y == 5 -> boo(y)
                    y > 5 -> foo(y)
                  end
                1 ->
                  foo(x)
              end
            end
          end
        end
      end
      """
      |> run_task(Nesting)
      |> assert_issue_with(reporter: Nesting, line: 5)
    end

    test "trigers with a greate max_depth" do
      """
      defmodule Sample do
        def something(x, y) do
          if x do
            if y do
              case x do
                0 ->
                  cond do
                    y == 5 -> boo(y)
                    y > 5 -> foo(y)
                  end
                1 ->
                  foo(x)
              end
            end
          end
        end
      end
      """
      |> run_task(Nesting, max_depth: 3)
      |> assert_issue_with(reporter: Nesting, line: 7)
    end

    test "trigers twice when max depth is exceeded twice" do
      """
      defmodule Sample do
        def something(x, y) do
          if x do
            if y do
              case x do
                0 -> nil
                1 -> foo(x)
              end
            end
          end

          if x do
            if y do
              case x do
                0 -> nil
                1 -> foo(x)
              end
            end
          end
        end
      end
      """
      |> run_task(Nesting)
      |> assert_issues(2)
    end

    test "trigers in an anonymous function" do
      """
      defmodule Sample do
        def something(x) do
          Enum.each(x, fn y ->
            Enum.each(x, fn z ->
              Enum.each(z, fn i -> foo(i) end)
            end)
          end)
        end
      end
      """
      |> run_task(Nesting)
      |> assert_issue_with(reporter: Nesting, line: 5)
    end
  end

  describe "init/1" do
    test "sets default max_depth" do
      assert Nesting.init([]) == {:ok, max_depth: 2}
    end
  end
end
