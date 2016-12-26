defmodule Matrex.Models.Rooms do

  require Logger

  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Models.Room
  alias Matrex.Events.Room, as: RoomEvent

  @type t :: %{}

  def new, do: %{}


  @spec create(This.t, map, Identifier.user)
    :: {Identifier.room, This.t}
  def create(this, contents, actor) do
    id = generate_room_id(this)
    room = Room.new(id, contents, actor)
    {room.id, Map.put(this, id, room)}
  end


  @spec join_room(This.t, Identifier.room, Identifier.user)
    :: {:ok, This.t} | {:error, atom}
  def join_room(this, room_id, user) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, room} <- Room.join(room, user)
    do
      {:ok, Map.put(this, room_id, room)}
    end
  end


  @spec send_event(This.t, Identifier.room, Identifier.user, RoomEvent.Content.t)
    :: {:ok, Identifier.event, This.t} | {:error, atom}
  def send_event(this, room_id, user, content) do
    with {:ok, room} <- fetch_room(this, room_id),
         {:ok, event_id, room} <- Room.send_event(room, user, content)
    do
      {:ok, event_id, Map.put(this, room_id, room)}
    end
  end


  # Internal Funcs

  @spec fetch_room(This.t, Identifier.room)
    :: {:ok, Room.t} | {:error, :forbidden}
  def fetch_room(this, room_id) do
    case Map.fetch(this, room_id) do
      :error -> {:error, :forbidden}
      res -> res
    end
  end


  @spec generate_room_id(This.t) :: Identifier.room
  defp generate_room_id(this) do
    id = Identifier.generate(:room)
    if Map.has_key?(this, id) do
      generate_room_id(this)
    else
      id
    end
  end


end
