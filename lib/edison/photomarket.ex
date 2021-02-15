defmodule Edison.Photomarket do
  use GenServer

  require Logger

  @refresh_interval :timer.seconds(30)
  @photomarket_query Application.fetch_env!(:edison, :photomarket_query)
  @url "https://www.reddit.com/r/photomarket/search.json?q=#{@photomarket_query}&restrict_sr=true&limit=5&sort=new"
  @photomarket_channel Application.fetch_env!(:edison, :photomarket_channel)

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(options) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  @impl true
  def init(:ok) do
    post_data = fetch_posts()
    Logger.debug("Starting photomarket poller..")
    schedule_refresh()
    {:ok, post_data}
  end

  @impl true
  def handle_info(:refresh, %{latest_time: last_time}) do
    post_data = %{url: url, latest_time: time, author: author, selftext: selftext, title: title} = fetch_posts()

    if DateTime.compare(time, last_time) == :gt do
      Logger.debug("New /r/photomarket post found")

      Nostrum.Api.create_message!(
        @photomarket_channel,
	embed: %{
          author: %{name: "u/#{author}", url: "https://www.reddit.com/u/#{author}"},
          title: "#{title}",
          description: "#{selftext}",
          url: "#{url}",
          timestamp: "#{time}"
        }
      )
    end

    schedule_refresh()
    {:noreply, post_data}
  end

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_interval)
  end

  defp fetch_posts() do
    Logger.debug("Fetching latest /r/photomarket posts..")

    try do
      %{"data" => %{"children" => children}} =
        HTTPoison.get!(@url) |> Map.get(:body) |> Poison.decode!()

      %{"data" => %{"created_utc" => created_utc, "url" => url, "author" => author, "title" => title, "selftext" => selftext}} =
        children |> List.first()

      {:ok, latest_time} = created_utc |> trunc() |> DateTime.from_unix()

      %{url: url, latest_time: latest_time, author: author, selftext: selftext, title: title}
    rescue
      e in RuntimeError -> Logger.debug(e)
    end
  end
end
