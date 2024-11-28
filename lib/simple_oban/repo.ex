defmodule SimpleOban.Repo do
  use Ecto.Repo,
    otp_app: :simple_oban,
    adapter: Ecto.Adapters.Postgres
end
