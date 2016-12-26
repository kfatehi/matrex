defmodule Matrex.Controllers.Client.R0.CreateRoom do

  use Matrex.Web, :controller

  import Matrex.Validation

  alias Matrex.Utils
  alias Matrex.DB
  alias Matrex.Events.Room, as: RoomEvent
  alias Matrex.Events.Room.{
    HistoryVisibility,
    JoinRules,
    Create,
    Name,
    Topic,
  }


  def post(conn, _params) do
    access_token = conn.assigns[:access_token]
    with {:ok, args} <- parse_args(conn.body_params),
         {:ok, room_id} <- DB.create_room(args.contents, access_token)
    do
      json(conn, %{room_id: room_id})
    else
      {:error, error} ->
        json_error(conn, error)
    end

  end


  defp parse_args(body) do
    acc = %{}
    with {:ok, acc} <- optional(:creation_content, body, acc, type: :map),
         {:ok, acc} <- optional(:name, body, acc, type: :string),
         {:ok, acc} <- optional(:topic, body, acc, type: :string),
         {:ok, acc} <- optional(:initial_state, body, acc, type: :list, post: &parse_initial_state/1),
         {:ok, acc} <- optional(:preset, body, acc, type: :string, allowed: ["private_chat", "public_chat", "trusted_private_chat"])
         #{:ok, acc} <- optional(:invite, body, acc, type: :list, post: &parse_invite/1),
         #{:ok, acc} <- optional(:visibility, body, acc, type: :string, allowed: ["private", "public"], default: "private"),
         #{:ok, acc} <- optional(:room_alias_name, body, acc, type: :string),
    do
      acc = normalize(acc)
      {:ok, acc}
    end
  end


  defp parse_initial_state(initial_state) do
    Enum.reduce_while(initial_state, {:ok, []}, fn (state, {_,acc}) ->
      event = %{}
      with {:ok, event} <- required(:type, state, event, type: :string),
           {:ok, event} <- required(:content, state, event, type: :map),
           {:ok, event} <- required(:state_key, state, event, type: :string)
      do
        {:cont, {:ok, [event|acc]}}
      else
        {:error, error} ->
          {:halt, {:error, error}}
      end
    end)
  end


  def normalize(args) do
    # Order is important here as later settings overwrite earlier
    contents = %{}
      |> gen_preset_content(args)
      |> gen_initial_state_content(args)
      |> gen_name_content(args)
      |> gen_topic_content(args)
      |> gen_create_content(args)

    # TODO handle invites, visibility, alias
    %{contents: contents}
  end


  defp gen_create_content(acc, %{creation_content:  create_content}) do
    case StateContent.new("m.room.create", create_content) do
      {:ok, content} ->
        Map.put(acc, StateContent.key(content), content)
      _ ->
        gen_create_content(acc, %{})
    end
  end

  defp gen_create_content(acc, _) do
    {:ok, content} = StateContent.new("m.room.create", %{})
    Map.put(acc, StateContent.key(content), content)
  end


  defp gen_name_content(acc, %{name: name}) do
    {:ok, content} = StateContent.new("m.room.name", %{"name" => name})
    Map.put(acc, StateContent.key(content), content)
  end

  defp gen_name_content(acc, _), do: acc


  defp gen_topic_content(acc, %{topic: topic}) do
    {:ok, content} = StateContent.new("m.room.topic", %{"topic" => topic})
    Map.put(acc, StateContent.key(content), content)
  end

  defp gen_topic_content(acc, _), do: acc


  defp gen_initial_state_content(acc, %{initial_state: initial_state}) do
    Enum.reduce(initial_state, acc, fn (state, acc) ->
      case StateContent.new(state.type, state.content, state.state_key) do
        {:ok, content} ->
          Map.put(acc, StateContent.key(content), content)
        _ -> acc
      end
    end)
  end

  defp gen_initial_state_content(acc, _), do: acc


  defp gen_preset_content(acc, %{preset: preset}) do
    {join_rule, visibility} = case preset do
      "private_chat" -> {"invite", "shared"}
      "trusted_private_chat" -> {"invite", "shared"}
      "public_chat" -> {"public", "shared"}
    end

    args = %{"join_rule" => join_rule}
    {:ok, content} = StateContent.new("m.room.join_rules", args)
    acc = Map.put(acc, StateContent.key(content), content)

    args = %{"history_visibility" => visibility}
    {:ok, content} = StateContent.new("m.room.history_visibility", args)
    Map.put(acc, StateContent.key(content), content)
  end

  defp gen_preset_content(acc, _), do: acc


end
