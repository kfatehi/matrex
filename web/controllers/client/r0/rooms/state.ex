defmodule Matrex.Controllers.Client.R0.Rooms.State do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Identifier
  alias Matrex.DB

  def get(conn, params) do
    access_token = conn.assigns[:access_token]
    with {:ok, args} <- parse_args(params),
         {:ok, events} <- fetch_state(args, access_token)
    do
      json(conn, events)
    else
      {:error, error} ->
        json_error(conn, error)
    end
  end


  defp parse_args(params) do
    acc = %{}
    with {:ok, acc} <- required(:room_id, params, acc, type: :string, post: &parse_room_id/1),
    do: {:ok, acc}
  end


  defp parse_room_id(room_id) do
    case Identifier.parse(room_id, :room) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end


  defp fetch_state(args, access_token) do
    DB.fetch_state(args.room_id, access_token)
  end


end

