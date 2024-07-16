defmodule Recode.Task.ModuledocTest do
  use RecodeCase

  alias Recode.Task.Moduledoc

  describe "run/1 not raises an issue" do
    test "when no defmodule is availabel" do
      """
      def foo(x) do
        {:ok, x}
      end
      """
      |> run_task(Moduledoc)
      |> refute_issues()
    end

    test "when @moduldoc is false" do
      """
      defmodule Bar.Foo do
        @moduledoc false

        def baz(x) do
          {:ok, x}
        end
      end
      """
      |> run_task(Moduledoc)
      |> refute_issues()
    end

    test "when @moduldoc has a string" do
      """
      defmodule Bar.Foo do
        @moduledoc "docdoc"

        def baz(x) do
          {:ok, x}
        end
      end
      """
      |> run_task(Moduledoc)
      |> refute_issues()
    end

    test "when the module is ignored" do
      """
      defmodule Bar.Foo do
        def baz(x) do
          {:ok, x}
        end
      end
      """
      |> run_task(Moduledoc, ignore_names: ~r/.*Foo/)
      |> refute_issues()
    end

    test "when the modules are ignored" do
      """
      defmodule Bar.Foo do
        def baz(x) do
          {:ok, x}
        end
      end

      defmodule Bar.Baz do
        def baz(x) do
          {:ok, x}
        end
      end
      """
      |> run_task(Moduledoc, ignore_names: [~r/.*Foo/, ~r/.*Baz/])
      |> refute_issues()
    end

    test "when @moduldoc has a here doc" do
      ~s'''
      defmodule Bar.Foo do
        @moduledoc """
        docdoc
        """

        def baz(x) do
          {:ok, x}
        end
      end
      '''
      |> run_task(Moduledoc)
      |> refute_issues()
    end

    test "when @moduldoc is always set" do
      ~s'''
      defmodule Bar.Foo do
        @moduledoc "Foo"

        defmodule Baz do
          @moduledoc false

          def baz(x), do: {:baz, x}

          defmodule Bang do
            @moduledoc """
            Bang bang ...
            """
            def bang(x), do: {:bang, x}
          end
        end

        def foo(x), do: {:foo, x}
      end
      '''
      |> run_task(Moduledoc)
      |> refute_issues()
    end

    test "when @moduldoc is set in all modules" do
      ~s'''
      defmodule Bar.Foo do
        @moduledoc "BarFoo ..."

        def baz(x), do: {:baz, x}
      end

      defmodule Baz do
        @moduledoc false

        def foo(x), do: {:foo, x}
      end
      '''
      |> run_task(Moduledoc)
      |> refute_issues()
    end

    test "no matter where moduledoc is written" do
      ~s'''
      defmodule Bar.Foo do
        def baz(x), do: {:baz, x}

        @moduledoc "BarFoo ..."
      end

      defmodule Baz do
        def foo(x), do: {foo_foo(), x}

        @moduledoc false

        defp foo_foo, do: :foo
      end
      '''
      |> run_task(Moduledoc)
      |> refute_issues()
    end
  end

  describe "run/1 raises issue(s)" do
    test "when @moduldoc is missing" do
      """
      defmodule Bar.Foo do
        def baz(x) do
          {:ok, x}
        end
      end
      """
      |> run_task(Moduledoc)
      |> assert_issue_with(message: "The moudle Elixir.Bar.Foo is missing @moduledoc.")
    end

    test "when @moduldoc is empty" do
      ~S'''
      defmodule Bar.Foo do
        @moduledoc """

        """
        def baz(x) do
          {:ok, x}
        end
      end
      '''
      |> run_task(Moduledoc)
      |> assert_issue_with(
        message: "The @moudledoc attribute for moudle Elixir.Bar.Foo has no content."
      )
    end

    test "when @moduldoc is missing in a module and inner modules" do
      """
      defmodule Bar.Foo do

        defmodule Baz do
          def baz(x), do: {:baz, x}

          defmodule Bang do
            def bang(x), do: {:bang, x}
          end
        end

        def foo(x), do: {:foo, x}
      end
      """
      |> run_task(Moduledoc)
      |> assert_issues_with([[line: 6], [line: 3], [line: 1]])
    end

    test "when @moduldoc is missing in inner modules" do
      """
      defmodule Bar.Foo do
        @moduledoc "Foo"

        defmodule Baz do
          def baz(x), do: {:baz, x}

          defmodule Bang do
            def bang(x), do: {:bang, x}
          end
        end

        def foo(x), do: {:foo, x}
      end
      """
      |> run_task(Moduledoc)
      |> assert_issues_with([[line: 7], [line: 4]])
    end

    test "when @moduldoc is missing in module and innerst module" do
      """
      defmodule Bar.Foo do
        defmodule Baz do
          @moduledoc false

          def baz(x), do: {:baz, x}

          defmodule Bang do
            def bang(x), do: {:bang, x}
          end
        end

        def foo(x), do: {:foo, x}
      end
      """
      |> run_task(Moduledoc)
      |> assert_issues_with([[line: 7], [line: 1]])
    end

    test "when @moduldoc is missing in inner module" do
      """
      defmodule Bar.Foo do
        @moduledoc "Foo"

        defmodule Baz do
          def baz(x), do: {:baz, x}

          defmodule Bang do
            @moduledoc false

            def bang(x), do: {:bang, x}
          end
        end

        def foo(x), do: {:foo, x}
      end
      """
      |> run_task(Moduledoc)
      |> assert_issues_with([[line: 4]])
    end

    test "when @moduldoc is missing in innerst module" do
      """
      defmodule Bar.Foo do
        @moduledoc "Foo"

        defmodule Baz do
          @moduledoc false

          def baz(x), do: {:baz, x}

          defmodule Bang do
            def bang(x), do: {:bang, x}
          end
        end

        def foo(x), do: {:foo, x}
      end
      """
      |> run_task(Moduledoc)
      |> assert_issues_with([[line: 9]])
    end

    test "when inner module not ignored" do
      """
      defmodule Bar.Foo do
        defmodule Baz do
          def baz(x), do: {:baz, x}
        end

        def foo(x), do: {:foo, x}
      end
      """
      |> run_task(Moduledoc, ignore_names: ~r/.*Foo/)
      |> assert_issues_with([[line: 2]])
    end

    test "when @moduldoc is missing in first module" do
      ~s'''
      defmodule Bar.Foo do
        def baz(x), do: {:baz, x}
      end

      defmodule Baz do
        @moduledoc false

        def foo(x), do: {:foo, x}
      end
      '''
      |> run_task(Moduledoc)
      |> assert_issues_with([[line: 1]])
    end

    test "when @moduldoc is missing in second module" do
      ~s'''
      defmodule Bar.Foo do
        @moduledoc false

        def baz(x), do: {:baz, x}
      end

      defmodule Baz do
        def foo(x), do: {:foo, x}
      end
      '''
      |> run_task(Moduledoc)
      |> assert_issues_with([[line: 7]])
    end

    test "when modules are optional" do
      ~s'''
      if foo do
        defmodule Bar.Foo do
          @moduledoc false

          def baz(x), do: {:baz, x}
        end

        defmodule Baz do
          def foo(x), do: {:foo, x}
        end
      end
      '''
      |> run_task(Moduledoc)
      |> assert_issues_with([[line: 8]])
    end
  end

  describe "init/1" do
    test "returns an error for unknown options" do
      """
      def foo(x), do: x
      """
      |> run_task(Moduledoc, foobar: nil)
      |> assert_config_error()
    end

    test "returns an error for wrong ignore_names option" do
      """
      def foo(x), do: x
      """
      |> run_task(Moduledoc, ignore_names: nil)
      |> assert_config_error()
    end

    test "returns an error for an invalid value in ignore_names list" do
      """
      def foo(x), do: x
      """
      |> run_task(Moduledoc, ignore_names: [nil])
      |> assert_config_error()
    end
  end
end
