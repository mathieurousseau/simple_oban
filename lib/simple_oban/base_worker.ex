defmodule SimpleOban.BaseWorker do
  alias Oban.Pro.Plugins.DynamicCron

  defmacro __using__(opts) do
    quote do
      alias Optimus.Oban.Helpers.Workflows

      @max_attempts 1
      @queue unquote(opts[:queue]) || raise("No queue provided for #{__MODULE__}")
      @timeout unquote(opts[:timeout]) || 5

      use Oban.Pro.Worker,
          unquote(
            [
              queue: opts[:queue],
              priority: opts[:priority] || 2
            ] ++
              [
                # hooks: [SimpleOban.Hooks.ResponseArchiver],
                max_attempts: 3,
                unique: [
                  fields: [:worker, :args],
                  keys: [
                    # all allowed arg keys from ArgsSchema, plus
                    # sub_minute_cron_offset for sub-minute scheduling, plus
                    # params for workflows that still use params. uuid should
                    # not be included in this list because it's always unique
                    :event_id,
                    :json_blob,
                    :league,
                    :match_id,
                    :params,
                    :play_by_play_id,
                    :player_id,
                    :season_id,
                    :season_type,
                    :sub_minute_cron_offset,
                    :team_id
                  ],
                  # setting the period to :infinity is more efficient.
                  # view https://hexdocs.pm/oban/scaling.html#uniqueness for more details.
                  period: :infinity,
                  states: [:available, :retryable, :scheduled]
                ]
              ]
          )

      @spec new(args :: Oban.Job.args(), opts :: [Oban.Job.option()]) :: Oban.Job.changeset()
      def new(args, opts) when is_map(args) and is_list(opts) do
        Map.put_new_lazy(args, :uuid, &Ecto.UUID.generate/0)
        |> super(opts)
      end

      @impl Oban.Pro.Worker
      def process(_) do
        :ok
      end
    end
  end

  # Create Cron jobs
  # We have 1800 Crons jobs currently across 20+ queues. This will simulate our most
  # loaded queue
  def insert_cron_jobs do
    delete_all_crons()

    available_leagues = 4

    1..260
    |> Enum.map(fn idx ->
      scheduler_id = :rand.uniform(30)
      league = "league_#{:rand.uniform(available_leagues)}"
      args = if idx > 200, do: %{league: league}, else: %{league: league, times_per_minute: 6}

      {
        "* * * * *",
        [SimpleOban, Scheduler, "Number#{scheduler_id}"] |> Module.concat(),
        name: "simple_scheduler_#{idx}", args: args, paused: false
      }
    end)
    |> DynamicCron.insert()
  end

  defp delete_all_crons do
    # this is extremely ineffecient and will be removed when we stop syncing
    # crons with the MySQL feed_ingestion_settings table
    DynamicCron.all()
    |> Enum.map(fn %{name: name} ->
      DynamicCron.delete(name)
    end)
  end
end
