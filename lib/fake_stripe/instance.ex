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

  # This is the number of Cowboy "acceptors" to run for every instance;
  # acceptors are what actually handle the inbound request. Since the number of
  # inbound requests should be rather low per instance, we keep this at 1
  @cowboy_acceptors 1

  @typedoc """
  Represents an instance
  """
  @type t :: %__MODULE__{
    port: :inet.port_number,
    pid: pid
  }

  # state
  #
  # Fields:
  #
  #   - `:cowboy_ref` - An opaque, unique reference used to stop Cowboy
  #   - `:port` - The port number which the instance is listening on
  @typep state :: %{
    cowboy_ref: reference,
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

        instance = %__MODULE__{ instance | port: port }

        {:ok, instance}
      other ->
        other
    end
  end

  @doc false
  @spec init(Keyword.t) :: {:ok, state}
  def init(opts) do
    # Starting with some stuff directly from the Bypass library
    # though slightly rearranged
    
    # Using `0` as the port number causes the port to be automatically selected
    # by the operating system; see `:gen_tcp.listen/2`
    port = Keyword.get(opts, :port, 0)

    # Establishes a socket connection to the specified port (or if 0, to a
    # random, available port chosen by the OS)
    case :ranch_tcp.listen(ip: @listen_ip, port: port) do
      {:ok, socket} ->
        # Gets the actual port for the socket by requesting it from the
        # `:inet` application
        {:ok, port} = :inet.port(socket)

        # this reference value can be used to stop Cowboy later on using
        # `Plug.Adapters.Cowboy.shutdown/1`
        cowboy_ref = make_ref()

        # These options establish how Cowboy will run; notably it needs the
        # reference which we created above which helps keep track of what to
        # shutdown later. It also needs to know how many acceptors (which accept
        # inbound requests) to start, the port number to use, and the socket it
        # can use.
        #
        # We won't pass these options to Cowboy directly, though, instead we'll
        # let Plug do that on our behalf.
        cowboy_opts = [
          ref: cowboy_ref,
          acceptors: @cowboy_acceptors,
          port: port,
          socket: socket
        ]

        plug_opts = [self()]

        # The following function starts the Cowboy listener supervision pool for this instance
        # and returns the pool's PID. The pool itself is added to the
        # `:ranch_sup` supervision pool as well.
        #
        # But we don't need the PID so we throw it away…
        {:ok, _pid} = Plug.Adapters.Cowboy.http(FakeStripe.Router, plug_opts, cowboy_opts)

        # Cowboy turns over ownership of the socket to the listener pool, so we
        # may not actually be needed later
        state = %{
          port: port,
          cowboy_ref: cowboy_ref,
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
  @spec get_port(t) :: {:ok, :inet.port_number} | {:error, :timeout | :no_instance}
  def get_port(instance) do
    GenServer.call(instance.pid, :get_port)
  end
end
