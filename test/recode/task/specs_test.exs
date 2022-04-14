defmodule Recode.Task.SpecsTest do
  use RecodeCase

  alias Recode.Task.Specs

  def run_specs(code, opts \\ []) do
    code |> source() |> run_task({Specs, opts})
  end

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

    all = run_specs(code)

    assert_issues(all, Specs, 2)

    public = run_specs(code, only: :public)

    assert_issues(public, Specs, 2)

    visible = run_specs(code, only: :visible)

    assert_issues(visible, Specs, 2)
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

    all = run_specs(code)

    assert_issues(all, Specs, 2)

    public = run_specs(code, only: :public)

    assert_issues(public, Specs, 1)

    visible = run_specs(code, only: :visible)

    assert_issues(visible, Specs, 1)
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

    all = run_specs(code)

    assert_issues(all, Specs, 3)

    public = run_specs(code, only: :public)

    assert_issues(public, Specs, 2)

    visible = run_specs(code, only: :visible)

    assert_issues(visible, Specs, 1)
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

    all = run_specs(code)

    assert_issues(all, Specs, 2)

    public = run_specs(code, only: :public)

    assert_issues(public, Specs, 1)

    visible = run_specs(code, only: :visible)

    assert_no_issues(visible)
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

    all = run_specs(code)

    assert_no_issues(all)

    public = run_specs(code, only: :public)

    assert_no_issues(public)

    visible = run_specs(code, only: :visible)

    assert_no_issues(visible)
  end
end
