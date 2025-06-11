# NavEx
**Information: NavEx is currently being tested. Please notify about any bugs that might be there in Issues. Contributions welcome.**
NavEx is the navigation history package for Elixir/Phoenix Framework. It uses adapter pattern and lets you choose between a few adapters to keep your users navigation history.

## Adapters

### NavEx.Adapters.ETS
Keeps user's navigation history in the ETS. It saves user's identity in his cookies.

### NavEx.Adapters.Session
Keeps user's navigation history in session. Might lead to cookies overflow error when navigation history config or links are too long.

## Installation
NavEx can be installed by adding `nav_ex` as a dependency in `mix.exs`:

```elixir
def deps do
  [
    {:nav_ex, "~> 0.1.0"}
  ]
end
```

It might be added to HexDependencies once I feel that it is ready enough for it :D

## Configuration:
### NavEx
```
  config :nav_ex,
    tracked_methods: ["GET"], # what methods to track
    history_length: 10, # what is the history list length per user
    adapter: NavEx.Adapters.ETS # adapter used by NavEx to save data
```
### Adapters
```
  config NavEx.Adapters.ETS,
    identity_key: "nav_ex_identity", # name of the key in cookies where the user's identity is saved
    table_name: :navigation_history # name of the ETS table
```

```
  config NavEx.Adapters.Session,
    history_key: "nav_ex_history" # name of the key in session where navigation history is saved
```

## Usage

```
defmodule MyApp.Router do
  ...
  pipeline :browser do
    ...
    NavEx.Plug
  end
  ...
end
```

**NavEx.last_path/1**\
It returns 2nd last path.
```
# for existing user
iex(1)> NavEx.last_path(conn)
{:ok, "/sample/path"}

# for existing user, but without 2 paths
iex(2)> NavEx.last_path(conn)
{:ok, nil}

# for not existing user
iex(3)> NavEx.last_path(conn)
{:error, :not_found}
```

**NavEx.path_at/2**\
It returns Nth path counted from 0.
```
# for existing user
iex(1)> NavEx.path_at(conn, 5)
{:ok, "/sample/path"}

# for existing user but exceeding paths number
iex(2)> NavEx.path_at(conn, 5)
{:ok, nil}

# for not existing user
iex(3)> NavEx.path_at(conn, 5)
{:error, :not_found}

iex(4)> NavEx.path_at(conn, 999)
** (ArgumentError) Max history depth is 10 counted from 0 to 9. You asked for record number 999.
```

**NavEx.list/1**\
Lists user's paths. Older paths have higher indexes.
```
# for existing user
iex(1)> NavEx.list(conn)
{:ok, ["/sample/path/2", "sample/path/1]}

# for not existing user
iex(2)> NavEx.list(conn)
{:error, :not_found}
```