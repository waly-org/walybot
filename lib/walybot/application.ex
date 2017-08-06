defmodule Walybot.Application do
  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    children = [
      supervisor(Walybot.Ecto.Repo, []),
      Plug.Adapters.Cowboy.child_spec(:http, Walybot.Plug, [], [port: 4000]),
      supervisor(Walybot.ConversationSupervisor, [:ok], shutdown: 10_000),
    ]
    children = add_poller(children, Mix.env)

    # setup the table of expected translations
    Walybot.ExpectedTranslations.init()

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Walybot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp add_poller(children, :dev), do: children ++ [worker(Walybot.PollTelegram, [])]
  defp add_poller(children, _), do: children
end
