Application.ensure_all_started(:bank, :temporary)
Logger.configure(level: :error)

alias Bank.Commands.{DepositMoney, OpenAccount}
alias Bank.BankAccountCommandHandler
alias Ecto.UUID

deposit_money = fn aggregate_id ->
  %DepositMoney{aggregate_id: aggregate_id, amount: 1}
  |> BankAccountCommandHandler.receive()
end

prepare = fn aggregate_id, deposits ->
  %OpenAccount{aggregate_id: aggregate_id}
  |> BankAccountCommandHandler.receive()

  Enum.each(1..deposits, fn _ ->
    deposit_money.(aggregate_id)
  end)
end

[id_1, id_10, id_50, id_100, id_200, id_300, id_1000] = Enum.map(1..7, fn _ -> UUID.generate() end)
prepare.(id_1, 1)
prepare.(id_10, 10)
prepare.(id_50, 50)
prepare.(id_100, 100)
prepare.(id_200, 200)
prepare.(id_300, 300)
prepare.(id_1000, 1000)

inputs = %{
  "Aggregate ID 1 - #{id_1}" => id_1,
  "Aggregate ID 10 - #{id_10}" => id_10,
  "Aggregate ID 50 - #{id_50}" => id_50,
  "Aggregate ID 100 - #{id_100}" => id_100,
  "Aggregate ID 200 - #{id_200}" => id_200,
  "Aggregate ID 300 - #{id_300}" => id_300,
  "Aggregate ID 1000 - #{id_1000}" => id_1000
}

jobs = %{
  "Deposit Money" => fn aggregate_id -> deposit_money.(aggregate_id) end,
}

Benchee.run(
  jobs,
  inputs: inputs,
  time: 5,
  title: "Opening an account and making money deposits"
)

