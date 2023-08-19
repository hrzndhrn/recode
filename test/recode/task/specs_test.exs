defmodule Recode.Task.SpecsTest do
  use RecodeCase

  alias Recode.Task.Specs

  test "reports missing specs" do
    code = """
    defmodule Bar do
      def bar(x) do
        {:bar, x}
      end

      def foo(y) do
        bar(y)
      end
    end
    """

    code
    |> run_task(Specs)
    |> assert_issues(2)

    code
    |> run_task(Specs, only: :public)
    |> assert_issues(2)

    code
    |> run_task(Specs, only: :visible)
    |> assert_issues(2)
  end

  test "reports missing specs - with private function" do
    code = """
    defmodule Bar do
      defp bar(x) do
        {:bar, x}
      end

      def foo(y) do
        bar(y)
      end
    end
    """

    code
    |> run_task(Specs)
    |> assert_issues(2)

    code
    |> run_task(Specs, only: :public)
    |> assert_issues(1)

    code
    |> run_task(Specs, only: :visible)
    |> assert_issues(1)
  end

  test "reports missing specs - with private and invisible function" do
    code = """
    defmodule Bar do
      defp bar(x) do
        {:bar, x, baz()}
      end

      @doc false
      def baz, do: :baz

      def foo(y) do
        bar(y)
      end
    end
    """

    code
    |> run_task(Specs)
    |> assert_issues(3)

    code
    |> run_task(Specs, only: :public)
    |> assert_issues(2)

    code
    |> run_task(Specs, only: :visible)
    |> assert_issues(1)
  end

  test "reports missing specs - with private function and invisible module" do
    code = """
    defmodule Bar do
      @moduledoc false

      defp bar(x) do
        {:bar, x, baz()}
      end

      def foo(y) do
        bar(y)
      end
    end
    """

    code
    |> run_task(Specs)
    |> assert_issues(2)

    code
    |> run_task(Specs, only: :public)
    |> assert_issues(1)

    code
    |> run_task(Specs, only: :visible)
    |> refute_issues()
  end

  test "reports nothing when specs are available" do
    code = """
    defmodule Bar do
      @spec bar(term()) :: integer()
      defp bar(x) do
        {:bar, x, baz()}
      end

      @spec foo(integer()) :: boolean()
      def foo(nil), do: nil

      def foo(y) do
        bar(y)
      end
    end
    """

    code
    |> run_task(Specs)
    |> refute_issues()

    code
    |> run_task(Specs, only: :public)
    |> refute_issues()

    code
    |> run_task(Specs, only: :visible)
    |> refute_issues()
  end

  test "reports nothing for macros when macros: false is set" do
    code = """
    defmodule Bar do
      defmacro bar(x) do
        quote do
          unquote(x)
        end
      end
    end
    """

    code
    |> run_task(Specs)
    |> refute_issues()
  end

  test "reports issues for macros when macros: true is set" do
    code = """
    defmodule Bar do
      defmacro bar(x) do
        quote do
          unquote(x)
        end
      end
    end
    """

    code
    |> run_task(Specs, macros: true)
    |> assert_issue_with(reporter: Specs)
  end

  test "reports issues for definitions inside quotes" do
    code = """
    defmodule Bar do
      @spec bar(atom()) :: Macro.t()
      defmacro bar(x) do
        quote do
          def unquote(x) do
            unquote(x)
          end
        end
      end
    end
    """

    code
    |> run_task(Specs, macros: true)
    |> assert_issue_with(reporter: Specs)
  end

  test "reports no issues for macro __using__" do
    code = """
    defmodule MyModule do
      defmacro __using__(_opts) do
        quote do
          import MyModule.Foo
        end
      end
    end
    """

    code
    |> run_task(Specs, macros: true)
    |> refute_issues()
  end
end
