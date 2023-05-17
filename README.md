# *WORK IN PROGRESS - NOT TESTED YET*.
This project is in progress. It is just created and it needs a lot of polishing probably. Feel free to provide any kind of feedback in issues.

# NavEx
This is the navigation history package for Elixir/Phoenix framework. It uses [Plug](https://github.com/elixir-plug/plug) and [ETS](https://www.erlang.org/doc/man/ets.html) underneath.

## General concept
This is a simple plug saving user's navigation history. It creates an identity for user in cookies and uses it to save his history in ETS.

## Installation

For now the package can be installed by adding `nav_ex` to your list of dependencies in `mix.exs`, it is not available as HexDependency:

```elixir
def deps do
  [
    {:gettext, git: "https://github.com/Kaquadu/nav_ex.git", tag: "0.0.0"}
  ]
end
```

## Usage
Configuration:
```
  config :nav_ex,
    cookies_key: "nav_ex_identity",
    tracked_methods: ["GET"],
    table_name: :navigation_history,
    history_length: 10
```

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

*NavEx.last_path/1*
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

*NavEx.path_at/2*
It returns Nth path counted from 0.
```
# for existing user
iex(1)> NavEx.path_at(conn, 5)
{:ok, "/sample/path"}

# for existing user but exceeding hist paths
iex(2)> NavEx.path_at(conn, 5)
{:ok, nil}

# for not existing user
iex(3)> NavEx.path_at(conn, 5)
{:error, :not_found}

iex(4)> NavEx.path_at(conn, 999)
** (ArgumentError) Max history depth is 10 counted from 0 to 9. You asked for record number 999.
```

*NavEx.list/1*
Lists user's paths. Older paths have higher indexes.
```
# for existing user
iex(1)> NavEx.list(conn)
{:ok, ["/sample/path/2", "sample/path/1]}

# for not existing user
iex(2)> NavEx.list(conn)
{:error, :not_found}
```