defmodule FakeStripe do
  @moduledoc """

  """

  defdelegate new(), to: FakeStripe.Instance, as: :start
  defdelegate new(opts), to: FakeStripe.Instance, as: :start
end
