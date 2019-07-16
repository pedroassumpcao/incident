defmodule Incident.Aggregate do
  @moduledoc """
  An aggregate is the unit of business logic in the domain. The business logic is used to handle commands and also to apply events to change the aggregate state.

  This behaviour defines the callbacks for command execution and event application.
  """

  @doc """
  Receives and executes the command, performing a specific business logic for it, usually considering the aggregate state as part of the logic.

  In case of a successful command and logic, a new event is composed and returned along with the aggregate state.

  In case of an unsuccessful command and logic, an error is returned containing a business logic reason.

  """
  @callback execute(struct) :: {:ok, struct, map} | {:error, atom}

  @doc """
  Receives a persisted event and the aggregate state, performing an aggregate state update.
  """
  @callback apply(struct, map) :: map
end
