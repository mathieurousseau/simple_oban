defmodule SimpleOban.SchedulerGenerator do
  def generate do
    quote do
      use Oban.Worker, queue: :scheduler, max_attempts: 1

      @impl true
      def perform(%Oban.Job{
            args: args
          }) do
        times_per_minute = Map.get(args, "times_per_minute")
        multiple = Map.get(args, "multiple", false)
        league = Map.get(args, "league")

        worker_count = 69
        event_count = 50

        number = 10

        jobs =
          1..number
          |> Enum.flat_map(fn _ ->
            event_id = :rand.uniform(event_count)
            worker_id = :rand.uniform(worker_count)

            module = [SimpleOban, SportProvider, "Worker#{worker_id}"] |> Module.concat()

            args = %{
              event_id: event_id,
              league: league
            }

            opts = [priority: :rand.uniform(3)]

            if times_per_minute do
              SimpleOban.SchedulerGenerator.high_frequency_job_split(
                module,
                times_per_minute,
                args,
                opts
              )
            else
              [module.new(args, opts)]
            end
          end)
          |> Oban.insert_all()

        :ok
      end
    end
  end

  def high_frequency_job_split(module, times_per_minute, args, opts) do
    # special handling for sub-1-minute-jobs, schedule several jobs over next
    # minute with delays
    0..59//div(60, times_per_minute)
    |> Enum.map(fn schedule_in ->
      opts =
        Keyword.merge(opts,
          schedule_in: schedule_in,
          replace: [scheduled: [:scheduled_at], available: [:scheduled_at]]
        )

      args = Map.put(args, :sub_minute_cron_offset, schedule_in)

      module.new(args, opts)
    end)
  end
end

# Create scheduler modules dynamically
1..30
|> Enum.each(fn idx ->
  [SimpleOban, Scheduler, "Number#{idx}"]
  |> Module.concat()
  |> Module.create(
    SimpleOban.SchedulerGenerator.generate(),
    Macro.Env.location(__ENV__)
  )
end)
