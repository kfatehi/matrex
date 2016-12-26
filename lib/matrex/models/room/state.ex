defmodule Matrex.Models.Room.State do

  alias __MODULE__, as: This
  alias Matrex.Models.Room.Members


  def new do
    %{}
  end


  #def update_state(this, content) do
  #  case Content.state_key(



  def is_current_member?(this, user) do
    Members.is_current_member(this.members, user)
  end


end

