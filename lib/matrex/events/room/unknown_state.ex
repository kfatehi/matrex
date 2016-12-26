alias Matrex.Events.Room.StateContent, as: This
defmodule This do

  @type t :: %This{
    content: map,
    state_key: String.t,
    type: String.t,
  }

  defstruct [
    :content,
    :state_key,
    :type
  ]

  def new(type, content, state_key \\ "")

  def new(type, content, state_key) do
    with {:ok, parsed} <- parse_content(type, content),
         content =  Map.merge(content, parsed),
    do: {:ok, %This{type: type, content: content, state_key: state_key}}
  end


  def key(this), do: {this.type, this.state_key}


  def set_content(this, key, value) do
    content = Map.put(this.content, key, value)
    %This{this | content: content}
  end


  @allowed_history_visibility [
    "invited",
    "joined",
    "shared",
    "world_readable",
  ]

  @allowed_join_rules [
    "public",
    "invite"
  ]

  @allowed_membership [
    "invite",
    "join",
    "leave",
    "ban",
  ]

  defp parse_content("m.room.create", content) do
    options = [type: :boolean, default: true]
    optional("m.federate", content, %{}, options)
  end

  defp parse_content("m.room.history_visibility", content) do
    options = [type: :string, allowed: @allowed_history_visibility],
    required("history_visibility", content, %{}, options),
  end

  defp parse_content("m.room.join_rules", content) do
    options = [type: :string, allowed: @allowed_join_rules]
    required("join_rule", content, %{}, options)
  end

  defp parse_content("m.room.member", content) do
    options = [type: :string, allowed: @allowed_membership]
    required("membership", content, %{}, options)
  end

  defp parse_content("m.room.name", content) do
    options = [type: :string]
    required("name", content, %{}, options)
  end

  defp parse_content("m.room.topic", content) do
    options = [type: :string]
    required("topic", content, %{}, options)
  end

  defp parse_content(_, content), do: {:ok, content}


 def factory(type) do
   fn (content, state_key) ->
     {:ok, %This{type: type, content: content, state_key: state_key}}
   end
 end


end

defimpl Matrex.Events.Room.Content, for: This do

  def type(%This{type: type}), do: type

  def is_state?(_), do: true

  def state_key(%This{state_key: state_key}), do: state_key

  def output(this), do: this.content

end
