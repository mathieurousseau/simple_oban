defmodule SimpleOban.SportProvider.Worker do
  def generate do
    quote do
      use SimpleOban.BaseWorker, queue: "sport_provider"
    end
  end
end

# Create Worker Modules Dynamically
# This will simulate the number of workers we have on our main queue
1..69
|> Enum.each(fn idx ->
  [SimpleOban, SportProvider, "Worker#{idx}"]
  |> Module.concat()
  |> Module.create(
    SimpleOban.SportProvider.Worker.generate(),
    Macro.Env.location(__ENV__)
  )
end)
