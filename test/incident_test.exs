defmodule IncidentTest do
  use ExUnit.Case
  doctest Incident

  test "greets the world" do
    assert Incident.hello() == :world
  end
end
