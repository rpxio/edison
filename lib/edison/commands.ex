defmodule Edison.Commands do
  alias Nostrum.Api

  @prefix "!edison"

  @spec handle_command(Nostrum.Struct.Message.t()) :: any()
  def handle_command(msg) do
    cond do
      String.starts_with?(msg.content, @prefix) ->
        command = String.replace_leading(msg.content, "#{@prefix} ", "")

        case command do
          "ping" ->
            Api.create_message(msg.channel_id, "pong")

          "give_role photomarket" ->
            photomarket_role_id = Application.fetch_env!(:edison, :photomarket_role_id)

            photomarket_role_name =
              Api.get_guild_roles!(msg.guild_id)
              |> Enum.find(fn role -> role.id == photomarket_role_id end)
              |> Map.get(:name)

            Api.add_guild_member_role(msg.guild_id, msg.author.id, photomarket_role_id)

            Api.create_message(
              msg.channel_id,
              "Added role @#{photomarket_role_name} to <@#{msg.author.id}>"
            )

          _ ->
            :ignore
        end

      true ->
        :ignore
    end
  end
end
