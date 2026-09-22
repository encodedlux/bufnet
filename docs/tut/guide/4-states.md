# States

States represent persistent values that can be read, updated, and observed by both the server and client.

## Defining a State

A state is created by calling `state`:
```luau
return define("game", {
    score = state({
        value = t.u32,
        initial = 0,
    }),
})
```

A state can also contain structured data. For example, a map can store data for each player:

```luau
return define("game", {
    accounts = state({
        value = t.map(
            t.player,
            t.struct({
                level = t.u16,
                coins = t.u32,
                pets = t.array(t.string),
            }),
        ),
        initial = {},
    }),
})
```

### `value`

Defines the type of data stored by the state.

```luau
value = t.u32
```

### `initial`

Defines the initial value of the state.

```luau
initial = 0
```

The initial value must match the type defined by `value`.

## Usage

### Updating

The server updates a state with `set()`:

```luau
net_server.score.set(100)
```

`set()` also accepts a callback that receives the current value and returns the new one:

```luau
net_server.accounts.set(function(state)
    const new_state = table.clone(state)
    new_state[player] = {
        level = 1,
        coins = 0,
    }
    return new_state
end)
```

This is useful when the next value depends on the current state:

```luau
const function add_coins(player: Player, amount: number)
    net_server.accounts.set(function(state)
        if state[player] == nil then
            return false
        end
        const new_state = table.clone(state)
        const new_account = table.clone(new_state[player])
        new_account.coins += amount
        new_state[player] = new_account
        return new_state
    end)
end
```

Returning `false` from the callback cancels the update.

### Filtering

Use `filter()` to control which value each client receives from the server.

The callback receives the complete state value and the client receiving it. The returned value must match the type defined by `value`.

For example, to only send each player their own account:

```luau
net_server.accounts.filter(function(accounts, player)
    return {
        [player] = accounts[player],
    } -- Exclude all other players' account
end)
```

Here, `accounts` is the complete state cache. The returned table is the filtered value sent to that specific player.

### Subscribing to State

Use `subscribe()` to run a callback when the state changes:

```luau
net_server.accounts.subscribe(function(state, prev_state)
    for player in state do
        if prev_state[player] == nil then
            -- Account was added
        end
    end
end)
```

You can also subscribe to a value getter:

```luau
const function get_player_coins(player: Player)
    return function(state)
        return state[player].coins
    end
end

const get_coins = get_player_coins(player)

net_server.accounts.subscribe(get_coins, function(coins, prev_coins)
    if prev_coins and coins > prev_coins then
        print(`{player.Name} gained {coins - prev_coins} coins!`)
    end
end)
```

The callback only runs when the returned value changes.

### Listening to State

`listen()` works like `subscribe()`, but the callback also runs immediately with the current value:

```luau
net_server.accounts.listen(function(state, prev_state)
    -- Runs immediately, then whenever state changes
end)
```

### Getting a Value

Use `get()` to read the current state value:

```luau
const value = net_server.score.get()

print(value)
```

You can also pass a value getter:

```luau
const function get_player_coins(player: Player)
    return function(state)
        return state[player].coins
    end
end

const get_coins = get_player_coins(player)
const coins = net_server.accounts.get(get_coins)
print(coins)
```

The state passes its current value to the value getter.

### Using Derive

Use `derive()` to create a cached value getter for expensive or frequently reused transformations.

Consider calculating a leaderboard directly:

```luau
const function get_top_coins(state)
    -- This creates a new table every time the function is called
    const sorted = {}

    for player, data in state do
        table.insert(sorted, {
            player = player,
            coins = data.coins,
        })
    end

    table.sort(sorted, function(a, b)
        return a.coins > b.coins
    end)

    return sorted
end

const function display_top_coins()
    for rank, data in net_server.accounts.get(get_top_coins) do
        print(`Rank: {rank}, Player: {data.player.Name}, Coins: {data.coins}`)
    end
end

display_top_coins() -- creates a new table and sorts it
display_top_coins() -- creates a new table and sorts it - 2x
```

Every call to `get_top_coins()` creates a new table and sorts it again, even when `accounts` has not changed.

With `derive()`, the result is cached:

```luau
const get_top_coins = net_server.accounts.derive(function(state)
    const sorted = {}

    for player, data in state do
        table.insert(sorted, {
            player = player,
            coins = data.coins,
        })
    end

    table.sort(sorted, function(a, b)
        return a.coins > b.coins
    end)

    return sorted
end)

const function display_top_coins()
    for rank, data in net_server.accounts.get(get_top_coins) do
        print(`Rank: {rank}, Player: {data.player.Name}, Coins: {data.coins}`)
    end
end

display_top_coins() -- Computes the leaderboard
display_top_coins() -- Reuses the cached result
```

The derived value is recomputed when the state changes, or when the value getter passed as the first argument changes.

```luau
const function get_player_coins(player: Player)
    return function(state)
        return state[player].coins
    end
end

const get_coins = get_player_coins(player)

const get_double_coins = net_server.accounts.derive(get_coins, function(coins)
    return coins * 2
end)
```
