defmodule FakeStipe.Endpoint do
  use Plug.Router

  plug Plug.Parsers, parsers: [:urlencoded],
                     pass: ["application/x-www-urlencoded"]

  get "/v1/customer" do
    send_resp(conn, 200, "")
  end
end
