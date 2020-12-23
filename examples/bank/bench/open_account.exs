Application.ensure_all_started(:bank, :temporary)
Logger.configure(level: :error)

alias Bank.Commands.{OpenAccount}
alias Bank.BankAccountCommandHandler

open_account = fn ->
  %OpenAccount{aggregate_id: Ecto.UUID.generate()}
  |> BankAccountCommandHandler.receive()
end

jobs = %{
  "Open Account" => fn -> open_account.() end
}

Benchee.run(
  jobs,
  time: 5,
  parallel: 2,
  title: "Opening an Account"
)

