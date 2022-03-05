Code.require_file("test/support/recode_case.ex")

Code.put_compiler_option(:ignore_module_conflict, true)

Mox.defmock(Recode.RunnerMock, for: Recode.Runner) # <- Add this
Application.put_env(:recode, :runner, Recode.RunnerMock)

ExUnit.start()
