PlugRailsCookieSessionStore
===========================

Rails compatible Plug session store

```elixir
defmodule Router do
  use Plug.Router

  ...

  plug Plug.Session,
    store: PlugRailsCookieSessionStore,
    key: "_rails_session_key",
    domain: '.myapp.com',
    secure: true,
    signing_salt: "signing salt",
    encrypt: true,
    encryption_salt: "encryption salt",
    key_iterations: 1000,
    key_length: 64,
    key_digest: :sha,
    serializer: Poison

  ...

end
```
