defmodule Incident.Command do
  @moduledoc """
  Defines the API for a Command.
  """

  @doc """
  Returns if a command is valid or not.
  """
  @callback valid?(struct) :: boolean
end
