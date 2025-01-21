defmodule Recode.Task.PipeChainStartTest do
  use RecodeCase

  alias Recode.Task.PipeChainStart

  describe "corrects" do
    test "pipes with vars" do
      code = """
      foo(x) |> bar()
      foo(x, y) |> bar()
      foo(x) |> bar() |> baz()
      foo(x.y) |> bar()
      foo(x.y, z) |> bar()
      foo(u.v.w.x, y.z) |> bar()
      foo(x[:y]) |> bar()
      foo(x[:x][:y], z) |> bar()
      foo(x["y"]) |> bar()
      """

      expected = """
      x |> foo() |> bar()
      x |> foo(y) |> bar()
      x |> foo() |> bar() |> baz()
      x.y |> foo() |> bar()
      x.y |> foo(z) |> bar()
      u.v.w.x |> foo(y.z) |> bar()
      x[:y] |> foo() |> bar()
      x[:x][:y] |> foo(z) |> bar()
      x["y"] |> foo() |> bar()
      """

      code
      |> run_task(PipeChainStart, autocorrect: true)
      |> assert_code(expected)
    end

    test "pipes with vars in dot calls" do
      code = """
      Enum.reverse(x) |> bar()
      Foo.foo(x, y) |> bar()
      Foo.foo(x) |> bar() |> baz()
      Foo.foo(x.y) |> bar()
      Foo.foo(x.y, z) |> bar()
      Foo.foo(u.v.w.x, y.z) |> bar()
      Foo.foo(x[:y]) |> bar()
      Foo.foo(x[:x][:y], z) |> bar()
      Foo.foo(x["y"]) |> bar()
      """

      expected = """
      x |> Enum.reverse() |> bar()
      x |> Foo.foo(y) |> bar()
      x |> Foo.foo() |> bar() |> baz()
      x.y |> Foo.foo() |> bar()
      x.y |> Foo.foo(z) |> bar()
      u.v.w.x |> Foo.foo(y.z) |> bar()
      x[:y] |> Foo.foo() |> bar()
      x[:x][:y] |> Foo.foo(z) |> bar()
      x["y"] |> Foo.foo() |> bar()
      """

      code
      |> run_task(PipeChainStart, autocorrect: true)
      |> assert_code(expected)
    end

    test "pipes with vars in var function calls" do
      code = """
      foo.(x) |> bar()
      foo.bar.(x) |> bar()
      foo.(x, y) |> bar()
      foo.(x) |> bar() |> baz()
      foo.(x) |> bar.() |> baz()
      foo.(x.y) |> bar()
      foo.(x.y, z) |> bar()
      foo.(u.v.w.x, y.z) |> bar()
      foo.(x[:y]) |> bar()
      foo.(x[:x][:y], z) |> bar()
      foo.(x["y"]) |> bar()
      """

      expected = """
      x |> foo.() |> bar()
      x |> foo.bar.() |> bar()
      x |> foo.(y) |> bar()
      x |> foo.() |> bar() |> baz()
      x |> foo.() |> bar.() |> baz()
      x.y |> foo.() |> bar()
      x.y |> foo.(z) |> bar()
      u.v.w.x |> foo.(y.z) |> bar()
      x[:y] |> foo.() |> bar()
      x[:x][:y] |> foo.(z) |> bar()
      x["y"] |> foo.() |> bar()
      """

      code
      |> run_task(PipeChainStart, autocorrect: true)
      |> assert_code(expected)
    end

    test "pipes with literals" do
      code = """
      foo("x") |> bar()
      foo("x", y) |> bar()
      foo("x") |> bar() |> baz()
      foo(:x) |> bar()
      foo(42) |> bar()
      foo(4.2) |> bar()
      foo([2]) |> bar()
      """

      expected = """
      "x" |> foo() |> bar()
      "x" |> foo(y) |> bar()
      "x" |> foo() |> bar() |> baz()
      :x |> foo() |> bar()
      42 |> foo() |> bar()
      4.2 |> foo() |> bar()
      [2] |> foo() |> bar()
      """

      code
      |> run_task(PipeChainStart, autocorrect: true)
      |> assert_code(expected)
    end

    test "pipes with ranges" do
      code = """
      foo(1..11) |> bar()
      foo(1..11//3) |> bar()
      """

      expected = """
      1..11 |> foo() |> bar()
      1..11//3 |> foo() |> bar()
      """

      code
      |> run_task(PipeChainStart, autocorrect: true)
      |> assert_code(expected)
    end

    test "pipes with functions and refs" do
      code = """
      foo(fn x -> x * 2 end) |> bar()
      foo(fn x -> x * 2 end, y, z) |> bar()
      foo(&baz/5) |> bar()
      foo(&baz/5,y ,z) |> bar()
      """

      expected = """
      fn x -> x * 2 end |> foo() |> bar()
      fn x -> x * 2 end |> foo(y, z) |> bar()
      (&baz/5) |> foo() |> bar()
      (&baz/5) |> foo(y, z) |> bar()
      """

      code
      |> run_task(PipeChainStart, autocorrect: true)
      |> assert_code(expected)
    end

    test "in depth" do
      code = """
      bar(foo(x)) |> baz()
      bar(foo(a,b),c) |> baz(d)
      foo(Enum.reverse(bar(x))) |> baz()
      """

      expected = """
      x |> foo() |> bar() |> baz()
      a |> foo(b) |> bar(c) |> baz(d)
      x |> bar() |> Enum.reverse() |> foo() |> baz()
      """

      code
      |> run_task(PipeChainStart, autocorrect: true)
      |> assert_code(expected)
    end

    test "crazy constructs" do
      code = """
      bar(case x do
        :u -> :x
        :x -> :u
      end) |> baz()
      """

      expected = """
      case x do
        :u -> :x
        :x -> :u
      end
      |> bar()
      |> baz()
      """

      code
      |> run_task(PipeChainStart, autocorrect: true)
      |> assert_code(expected)
    end
  end

  describe "does not correct" do
    test "pipes starting with a var" do
      """
      def test(x) do
        foo = x |> bar()
        x |> baz(foo) |> bang()
      end
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with accessing a var" do
      """
      x.y |> foo()
      x[:y] |> foo()
      x["y"] |> foo()
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with a literal" do
      ~s'''
      :foo |> foo()
      1 |> add(1)
      1 |> add(1) |> add(2)
      "1" |> foo(1)
      """
      foo
      """
      |> foo()
      '''
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with a sigil" do
      """
      ~s'''
      foo
      ''' |> foo()
      ~r/.*/ |> foo()
      ~q"asdf" |> foo()
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with an unary op" do
      """
      +1 |> add(1)
      -1 |> add(1) |> add(2)
      not x |> foo()
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with an binary op" do
      """
      (1 + 1) |> foo(x)
      x or y |> foo()
      (x or y) |> foo()
      x ~> foo() |> bar()
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with a range" do
      """
      1..10 |> foo()
      1..10//2 |> foo()
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with module attribute" do
      """
      @foo |> bar()
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with special forms" do
      """
      quote do
        unquote(x) |> foo()
      end

      if x do
        y
      end
      |> foo()

      case x do
        :a -> "a"
        _ -> "b"
      end
      |> foo()

      <<x::utf8>> |> foo()

      cond do
        x -> y
      end
      |> foo()

      with x <- y do
        foo(x)
      end |> bar()
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with functions and refs" do
      """
      fn x -> x + 1 end |> foo()
      (&Enum.reverse/1) |> foo()
      foo() |> bar()
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes starting with expected code" do
      """
      defmodule RecodeTest do
        defmacro a ~> b do
          quote do
            unquote(a) |> unquote(b)
          end
        end

        def test do
          1
          |> Kernel.*(2)
          ~> Kernel.*(2)
          |> Kernel.*(2)
        end
      end
      """
      |> run_task(PipeChainStart, autocorrect: true)
      |> refute_update()
    end

    test "pipes with functions and refs if excluded" do
      """
      foo(fn x -> x * 2 end) |> bar()
      foo(&baz/5) |> bar()
      """
      |> run_task(PipeChainStart, autocorrect: true, exclude_arguments: [:fn, :&])
      |> refute_update()
    end

    test "crazy constructs if excluded" do
      """
      bar(case x do
        :u -> :x
        :x -> :u
      end) |> baz()
      """
      |> run_task(PipeChainStart, autocorrect: true, exclude_arguments: [:case])
      |> refute_update()
    end

    test "pipes if start function is excluded" do
      """
      foo(x) |> bar()
      Foo.foo(x) |> bar()
      Bar.foo(x) |> foo()
      Bar.bar(x) |> foo()
      """
      |> run_task(PipeChainStart,
        autocorrect: true,
        exclude_functions: [:foo, {Foo, :foo}, {Bar, :*}]
      )
      |> refute_update()
    end
  end

  describe "reports an issue for" do
    test "a single pipe" do
      """
      def test(x) do
        foo(x) |> bar()
      end
      """
      |> run_task(PipeChainStart, autocorrect: false)
      |> assert_issue_with(
        message: "Pipe chain should start with a raw value.",
        reporter: Recode.Task.PipeChainStart,
        line: 2,
        column: 10,
        meta: nil
      )
    end
  end
end
