defmodule Matrex.Models.Room do

  alias __MODULE__, as: This
  alias Matrex.Identifier
  alias Matrex.Events.Event
  alias Matrex.Events.Room, as: RoomEvent
  alias Matrex.Events.Room.{
    Create,
    JoinRules,
    Member,
  }


  @type t :: %This{
    id: Identifier.t,
    state: map,
    events: [Event.t],
  }

  @enforce_keys [:id]

  defstruct [
    :id,
    :state,
    events: [],
  ]


  @spec new(Identifier.room, map, Identifier.user)
    :: This.t
  def new(id, contents, actor) do
    {create_content,rest} = Map.pop(contents, {"m.room.create", ""})

    content = StateContent.new("m.room.member", %{"membership" => "join"}, actor)

    contents = contents
      # TODO is this correct behavior?
      |> Map.put(contents, StateContent.key(content), content)
      |> Map.update!(contents, {"m.room.create", ""}, fn content ->
        StateContent.set_content(content, "creator", actor)
      end)

    update_state(%This{id: id, events: events, state: %State{}}, events)
  end


  @spec join(This.t, Identifier.user) :: {:ok, This.t} | {:error, atom}
  def join(this, user) do
    case this.state.join_rule do
      :invite -> {:error, :forbidden}
      :public ->
        content = Member.new(user, :join)
        event = RoomEvent.create(this.id, user, content)
        this = %This{this | events: [event|this.events]}
        {:ok, update_state(this, [event])}
    end
  end


  @spec send_event(This.t, Identifier.user, RoomEvent.Content.t)
    :: {:ok, Identifier.event, This.t} | {:error, atom}
  def send_event(this, user, content) do
    case State.is_current_member?(this.state, user) do
      false -> {:error, :forbidden}
      true ->
        event = RoomEvent.create(this.id, user, content)
        this = %This{this | events: [event|this.events]}
        {:ok, event.event_id, update_state(this, [event])}
    end
  end


  #@spec fetch_state_content(This.t, String.t, String.t, Identifier.user)
  #  :: {:ok, RoomEvent.Content.t, This.t} | {:error, atom}
  #def fetch_state_content(this, event_type, state_key, user) do
  #  case State.is_current_member?(this.state, user) do
  #    false -> {:error, :forbidden}
  #    true ->
  #      


  # Internal Funcs

  @spec update_state(This.t, [RoomEvent.t]) :: This.t
  defp update_state(this, []), do: this
  defp update_state(this, [%RoomEvent{content: %JoinRules{join_rule: rule}}|rest]) do
    this = %This{this | state: State.set_join_rule(this.state, rule)}
    update_state(this, rest)
  end
  defp update_state(this, [%RoomEvent{content: %Member{}} = event|rest]) do
    user = event.content.state_key
    membership = event.content.membership
    event_id = event.event_id
    state = State.update_members(this.state, user, event_id, membership)
    this = %This{this | state: state}
    update_state(this, rest)
  end
  defp update_state(this, [_|rest]) do
    update_state(this, rest)
  end


end
