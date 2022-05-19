Code.put_compiler_option(:ignore_module_conflict, true)
Code.compile_file("test/support/recode_case.ex")

Mox.defmock(Recode.RunnerMock, for: Recode.Runner)
Application.put_env(:recode, :runner, Recode.RunnerMock)

ExUnit.start(capture_log: true)
