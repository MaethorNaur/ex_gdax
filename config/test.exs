use Mix.Config

config :ex_gdax,
  api_key: {:system, "GDAX_TEST_API_KEY"},
  # Base.encode64("GDAX_TEST_API_SECRET")
  api_secret: {:system, "R0RBWF9URVNUX0FQSV9TRUNSRVQ="},
  api_passphrase: {:system, "GDAX_TEST_API_PASSPHRASE"},
  api_url: {:system, "https://api-public.sandbox.gdax.com"}
