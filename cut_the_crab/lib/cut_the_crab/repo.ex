defmodule CutTheCrab.Repo do
  use Ecto.Repo,
    otp_app: :cut_the_crab,
    adapter: Ecto.Adapters.Postgres
end
