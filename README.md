# FakeStripe

This library is designed as a test helper for other libraries that utilize the
Stripe API. This library mocks the Stripe API, providing isolated instances that
can be tested against in order to allow tests to be run in parallel. It also
provides a stateful backing via the Elixir Registry module; this allows tests to
structure the expected state of the system. For example:

```elixir
test "retrieves customer by ID" do
  customer_id = "1234"
  customer_email = "

  stripe_api = FakeStripe.new()
  setup_conf(stripe_api)
  FakeStripe.Customer.create(stripe_api, %{id: customer_id, email: customer_email})

  returned_customer = StripityStripe.Customer.retrieve(customer_id)

  assert returned_customer.id == customer_id
end
```

This work was primarily based on the
[Bypass](https://github.com/PSPDFKit-labs/bypass) library from PSPDFKit Labs,
which is fantastic for general HTTP mocking. We needed something much more
specific for testing the
[StripityStripe](https://github.com/codecorps/stripity_stripe) library, though.

## Installation


```elixir
def deps do
  [{:fake_stripe, "~> 0.1.0"}]
end
```
