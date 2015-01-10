PlugRailsCookieSessionStore
===========================

Rails compatible Plug session store.

This allows you to share session information between Rails and a Plug-based framework like Phoenix.

> Note: The information stored in the session cookie is serialized by Rails. Prior to version 4.1, this information was serialized using Ruby's Marshal format. Since Elixir can't (yet!) read Marshal format we have to configure Rails to serialize its cookie information with its Json Serializer.

## How to use with Phoenix
#### Set Rails serialization format to JSON

In an initialer of your Rails project make sure you set the serializer to JSON:

```ruby
Rails.application.config.action_dispatch.cookies_serializer = :json
```

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
  serializer: Poison
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
