defmodule FakeStripe.Application do
  @moduledoc false

  ##
  # Developer Notes
  #
  # This module defines the start-up behavior of the Erlang application that
  # will be produced. Here, we are creating a supervision tree that uses the
  # `:simple_one_for_one` supervision methodology. Unlike other supervision
  # methodologies, `:simple_one_for_one` doesn't start any children when the
  # supervisor starts. Instead, the child specification it is given is used when
  # `Supervisor.start_child/2` is called. This allows us to dynamically add and
  # remove child instances.
  #
  # The child instance in this case is an instance of the `FakeStripe.Instance`
  # GenServer. It is set to use `restart: :transient`, so each child instance
  # will only be restarted if it terminates abnormally (for example, if it
  # crashes due to a bad argument error).

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(FakeStripe.Instance, [], restart: :transient),
    ]

    opts = [strategy: :simple_one_for_one, name: FakeStripe.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
