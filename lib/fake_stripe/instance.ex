defmodule FakeStripe.Instance do
  @moduledoc """
  An isolated FakeStripe instance
  """

  ##
  # Developer Note
  #
  # This module implements a GenServer with a porcelain interface. Each
  # FakeStripe instance is an isolated worker that is designed to be loaded into
  # a supervision tree. The worker starts a TCP listener (via `ranch`) that
  # listens on a random port and then passes inbound calls onto `cowboy` and
  # then `Plug`.
  #
  # One thing to note when looking up documentation is that `:ranch_tcp` is a
  # layer on top of `:gen_tcp` in the Erlang kernel.

  use GenServer

  # This is the IP address FakeStripe listens on defined in `:inet` notation for
  # IPv4 addresses. There is no reason this should be anything except a loopback
  # address.
  @listen_ip {127, 0, 0, 1}

  @typedoc """
  Represents an instance
  """
  @type t :: %__MODULE__{
    port: :inet.port_number,
    pid: pid
  }

  @typep state :: %{
    port: :inet.port_number
  }

  defstruct [:port, :pid]

  @doc """
  
  ## Options
  
  - `port` - The port number to listen on for inbound HTTP requests. If this port is
  already taken it will cause the initialization to fail. It is recommended you do not
  set this and instead allow the library to pick a random, available port for you.
  """
  @spec start(Keyword.t) :: {:ok, t} | {:error, :already_started}
  def start(opts \\ []) do
    case Supervisor.start_child(FakeStripe.Supervisor, [opts]) do
      {:ok, pid} ->
        instance = %__MODULE__{pid: pid}
        port = get_port(instance)
      other ->
        other
    end
  end

  @doc false
  @spec init(Keyword.t) :: {:ok, t}
  def init(opts) do
    # Starting with some stuff directly from the Bypass library
    # though slightly rearranged
    
    # Using `0` as the port number causes the port to be automatically selected
    # by the operating system; see `:gen_tcp.listen/2`
    port = Keyword.get(opts, :port, 0)
    case :ranch_tcp.listen(ip: @listen_ip, port: port) do
      {:ok, socket} ->
        {:ok, port} = :inet.port(socket)
        :erlang.port_close(socket)

        ref = make_ref()
        socket = do_up(port, ref)

        state = %{
          port: port,
          ref: ref,
          socket: socket
        }

        {:ok, state}
      {:error, reason} ->
        {:stop, reason}
    end
  end

  @doc false
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Retrieves the port number for the instance
  """
  @spec get_port(instance) :: {:ok, :inet.port_number} | {:error, :timeout | :no_instance}
  def get_port(instance) do
    GenServer.call(instance.pid, :get_port)
  end
end
