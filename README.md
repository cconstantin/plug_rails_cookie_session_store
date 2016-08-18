PlugRailsCookieSessionStore
===========================

Rails compatible Plug session store.

This allows you to share session information between Rails and a Plug-based framework like Phoenix.

## How to use with Phoenix

#### Copy/share the encryption information from Rails to Phoenix.

There are 4 things to copy:
* secret_key_base
* signing_salt
* encryption_salt
* session_key
 
The `secret_key_base` can be found usually in the Rails' `secrets.yml` file and should be copied to Phoenix's `config.exs` file. There should already be a key named like that and you should override it.

The other three values can be found somewhere in the initializers directory of your Rails project. Some people don't set the `signing_salt` and `encryption_salt`. If you don't find them, set them like so:

```ruby
Rails.application.config.session_store :cookie_store, key: '_SOMETHING_HERE_session'
Rails.application.config.action_dispatch.encrypted_cookie_salt =  'encryption salt'
Rails.application.config.action_dispatch.encrypted_signed_cookie_salt = 'signing salt'
```

#### Configure the Cookie Store in Phoenix. 

Edit the `endpoint.ex` file and add the following:

```elixir
# ...
plug Plug.Session,
  store: PlugRailsCookieSessionStore,
  key: "_SOMETHING_HERE_session",
  domain: '.myapp.com',
  secure: true,
  signing_salt: "signing salt",
  encrypt: true,
  encryption_salt: "encryption salt",
  key_iterations: 1000,
  key_length: 64,
  key_digest: :sha,
  serializer: Poison # see serializer details below
end
```

#### Set up a serializer

Plug & Rails must use the same strategy for serializing cookie data.

- __JSON__: Since 4.1, Rails defaults to serializing cookie data with JSON. Support this strategy by getting a JSON serializer and passing it to `Plug.Session`. For example, add `Poison` to your dependencies, then:

  ```elixir
  plug Plug.Session,
    store: PlugRailsCookieSessionStore,
    # ... see encryption config above
    serializer: Poison
  end
  ```  

  You can confirm that your app uses JSON by searching for

  ```ruby
  Rails.application.config.action_dispatch.cookies_serializer = :json
  ```

  in an initializer.

- __Marshal__: Previous to 4.1, Rails defaulted to Ruby's [`Marshal` library](http://ruby-doc.org/core-2.3.0/Marshal.html) for serializing cookie data. You can deserialize this by adding [`ExMarshal`](https://hex.pm/packages/ex_marshal) to your project and defining a serializer module:

  ```elixir
  defmodule RailsMarshalSessionSerializer do
    @moduledoc """
    Share a session with a Rails app using Ruby's Marshal format.
    """
    def encode(value) do
      {:ok, ExMarshal.encode(value)}
    end

    def decode(value) do
      {:ok, ExMarshal.decode(value)}
    end
  end
  ```

  Then, pass that module as a serializer to `Plug.Session`:

  ```elixir
  plug Plug.Session,
    store: PlugRailsCookieSessionStore,
    # ... see encryption config above
    serializer: RailsMarshalSessionSerializer
  end
  ```

#### That's it!

To test it, set a session value in your Rails application:

```elixir
session[:foo] = 'bar'
```
    
And print it on Phoenix in whatever Controller you want:

```elixir
Logger.debug get_session(conn, "foo")
```
