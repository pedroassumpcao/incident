defmodule Incident.Aggregate do
  @moduledoc """
  An aggregate is the unit of business logic in the domain. The business logic is used to handle commands and also to apply events to change the aggregate state.

  This behaviour defines the callbacks for command execution and event application.
  """

  @doc """
  Receives and executes the command, performing a specific business logic for it, usually considering the aggregate state as part of the logic.

  In case of an unsuccessful command and logic:
  - an error is returned containing a business logic reason;

  In case of a successful command and logic:
  - an event data structure is composed;
  - the event is persisted in the Event Store;
  - the persisted event is broadcasted to the Event Handler;

  Returns an error if:
  - event can't be persisted in the Event Store;
  - event can't be broadcasted to the Event Handler;
  """
  @callback execute(struct) :: :ok | {:error, atom}

  @doc """
  Receives a persisted event and the aggregate state, performing an aggregate state update.
  """
  @callback apply(struct, map) :: map
end
