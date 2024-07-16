defmodule Recode.Task.TagsTest do
  use RecodeCase

  alias Recode.Task.Tags

  describe "run/1" do
    #
    # cases NOT raising issues
    #

    test "does not trigger" do
      ~s'''
      defmodule TODO do
        @moduledoc """
        The TODO module
        """

        # Returns TODO atom
        def todo(x), do: :TODO
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> refute_issues()
    end

    test "does not triggers tags in doc when deactivated" do
      ~s'''
      defmodule TODO do
        @moduledoc """
        The TODO module
        TODO add examples
        """

        def todo(x), do: :TODO
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags, include_docs: false)
      |> refute_issues()
    end

    test "triggers no issue when @doc is false" do
      ~s'''
      defmodule Foo do
        @moduledoc false

        @doc false
        def foo(x), do: x
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> refute_issues()
    end

    test "triggers no issue for a comment in a keyword list" do
      ~s'''
      defmodule Foo do
        def foo do
          [
            a: 5,
            # a comment
            b: 1
          ]
        end
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> refute_issues()
    end

    test "triggers no issue for @doc nil" do
      ~s'''
      defmodule Foo do
        @doc nil
        def foo do
          :foo
        end
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> refute_issues()
    end

    test "triggers no issue for doc function" do
      ~s'''
      defmodule Foo do
        def doc(:x), do: :x
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> refute_issues()
    end

    #
    # cases raising issues
    #

    test "triggers an issue for a tag in comment" do
      ~s'''
      defmodule TODO do
        @moduledoc """
        The TODO module
        """

        # TODO: add spec
        def todo(x), do: :TODO
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> assert_issue_with(
        reporter: Tags,
        line: 6,
        message: "Found a tag: TODO: add spec"
      )
    end

    test "triggers multiple issues for tags in one comment" do
      ~s'''
      defmodule TODO do
        @moduledoc """
        The TODO module
        """

        # TODO: add spec
        # TODO: add spec
        def todo(x), do: :TODO
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> assert_issues(2)
    end

    test "triggers an issue for a tag in moduledoc" do
      ~s'''
      defmodule TODO do
        @moduledoc """
        The TODO module
        TODO add examples
        """

        def todo(x), do: :TODO
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> assert_issue_with(
        reporter: Tags,
        line: 4,
        message: "Found a tag: TODO add examples"
      )
    end

    test "triggers an issue for a tag in oneline moduledoc" do
      ~s'''
      defmodule TODO do
        @moduledoc "TODO add impl"
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> assert_issue_with(
        reporter: Tags,
        line: 2,
        message: "Found a tag: TODO add impl"
      )
    end

    test "triggers an issue for a tag in oneline doc" do
      ~s'''
      defmodule TODO do
        @doc "TODO add impl"
        def todo, do: :todo
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> assert_issue_with(
        reporter: Tags,
        line: 2,
        message: "Found a tag: TODO add impl"
      )
    end

    test "triggers an issue for a tag in doc" do
      ~s'''
      defmodule TODO do
        @doc """
        TODO add impl
        """
        def todo, do: :todo
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> assert_issue_with(
        reporter: Tags,
        line: 3,
        message: "Found a tag: TODO add impl"
      )
    end

    test "triggers an issue for a tag in doc with trailing and penidng text" do
      ~s'''
      defmodule TODO do
        @doc """
        Lorem ispum ...

        TODO do it

        Lorem ispum ...
        """
        def todo, do: :todo
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> assert_issue_with(
        reporter: Tags,
        line: 5,
        message: "Found a tag: TODO do it"
      )
    end

    test "triggers an issue for a tag in a keyword list" do
      ~s'''
      defmodule Foo do
        def foo do
          [
            a: 5,
            # TODO: add b
            c: 1
          ]
        end
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> assert_issue_with(
        reporter: Tags,
        line: 5,
        message: "Found a tag: TODO: add b"
      )
    end

    test "ignores doc function" do
      ~s'''
      defmodule Foo do
        def doc([{:__block__, meta, [text]}]) do
          text
        end
      end
      '''
      |> run_task(Tags, tag: "TODO", reporter: Tags)
      |> refute_issues()
    end
  end

  describe "init/1" do
    test "returns an error tuple for missing :tag" do
      message = ~s|Recode.Task.Tags needs a configuration entry for :tag (e.g. tag: "TODO")|
      assert Tags.init([]) == {:error, message}
    end

    test "returns an error tuple for missing :reporter" do
      message = """
      Recode.Task.Tags needs a configuration entry for :reporter \
      (e.g. reporter: "Recode.Task.TagTODO")\
      """

      assert Tags.init(tag: "TODO") == {:error, message}
    end

    test "returns an ok tuple with added defaults" do
      assert Tags.init(tag: "TODO", reporter: Tags) ==
               {:ok, include_docs: true, tag: "TODO", reporter: Tags}
    end

    test "returns an ok tuple" do
      assert Tags.init(tag: "TODO", reporter: Tags, include_docs: false) ==
               {:ok, tag: "TODO", reporter: Tags, include_docs: false}
    end
  end
end
