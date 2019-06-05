defmodule BankAccountTest do
  use ExUnit.Case
  doctest BankAccount

  test "greets the world" do
    assert BankAccount.hello() == :world
  end
end
