import Config

config :nostrum,
  token: System.get_env("EDISON_BOT_TOKEN"),
  num_shards: :auto

config :edison,
  photomarket_role_id: System.get_env("EDISON_PHOTOMARKET_ROLE_ID") |> String.to_integer(),
  photomarket_channel: System.get_env("EDISON_PHOTOMARKET_CHANNEL") |> String.to_integer(),
  photomarket_query: System.get_env("EDISON_PHOTOMARKET_QUERY")
