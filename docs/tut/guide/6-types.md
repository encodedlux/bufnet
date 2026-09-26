# Types

This page contains an explanation of all DataTypes supported by BufNet.

---

# Primitives

BufNet provides a collection of primitive types that serve as the foundation for creating more complex data types tailored to your game.

## General types

- `string`: String
- `boolean`: Boolean
- `buffer`: Buffer
- `unknown`: Any
- `nothing`: Nil

## Number types

- `u8`: Unsigned 8-bit integer
- `u16`: Unsigned 16-bit integer
- `u32`: Unsigned 32-bit integer
- `i8`: Signed 8-bit integer
- `i16`: Signed 16-bit integer
- `i32`: Signed 32-bit integer
- `f16`: 16-bit float
- `f32`: 32-bit float
- `f64`: 64-bit float

## Roblox types

- `vec2`: Vector2
- `vec3`: Vector3
- `cframe`: CFrame
- `instance`: Instance
- `color3`: Color3
- `player`: Player

---

# Special

Special types are used to build more complex structures. They can contain nearly any type, including other special types, and are designed to be dynamic.

## Optionals

BufNet uses 1 byte of overhead for each optional value.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.optional(t.string)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all("hello")
net_server.my_event.fire_all(nil)
```

## Arrays

Arrays are straightforward: they represent ordinary ordered arrays. One thing to keep in mind is that passing mixed tables as arrays has **undefined** behavior. As a result, some values may not be preserved when the data is received.

BufNet uses 2 bytes of overhead for each array. These bytes store the array length as an unsigned 16-bit integer. Because of this, arrays in BufNet can contain up to **65,536** entries.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.array(t.string)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({ "foo", "bar" })
```

## Structs

Structs are used to group multiple named values into a single structured type. Each field can have its own datatype, allowing you to define the exact shape of the data being sent.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.struct({
            foo = t.string,
            bar = t.u8
        })
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({
    foo = "foo",
    bar = 2,
})
```

## Maps

Maps are used to store values using keys. Both the key and value can have their own datatype, allowing you to define maps with different key and value types.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.map(t.string, t.boolean)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({
    ["foo"] = true,
    ["bar"] = false,
})
```

## Sets

Sets represent a collection of unique values, where each value acts as a member of the set. Unlike an array, a set does not care about element order or numeric indices.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.set(t.string)
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({
    ["foo"] = true,
    ["bar"] = true,
})
```

## Literals

Literals define a value that can only be one of a predefined set of literal options (such as strings, numbers, booleans, or any other literal values). This is useful for restricting a value to a fixed list of valid options while taking only **1 byte** over the wire.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.literals("foo" :: "foo", "bar" :: "bar")
    })
})
```

In this example, the value can only be `"foo"` or `"bar"`:
```luau
-- server.luau
net_server.my_event.fire_all("foo")
net_server.my_event.fire_all("bar")
```

::: tip
`t.literals` supports strings, numbers, and booleans as varargs. Type casts (e.g. `"foo" :: "foo"` or `true :: true`) ensure Luau narrows the arguments to exact singleton literal types instead of widening them to general types like `string` or `boolean`.
:::

## Tagged

Tagged defines a value that can have different data structures depending on a specified tag. Each tag represents a variant with its own schema, allowing different fields and data types for each variant.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.tagged({
            foo = {
                name = t.string,
                amount = t.u16,
            },
            bar = {
                position = t.vec3,
                active = t.boolean,
            }
        })
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all({
    type = "foo",
    name = "Sword",
    amount = 10,
})

net_server.my_event.fire_all({
    type = "bar",
    position = Vector3.zero,
    active = true,
})
```

## Tuples

Tuples let a single event or funct carry more than one value without wrapping them in a struct. Each type passed to `t.tuple(...)` becomes a separate value on the wire, so `t.tuple` itself adds no extra byte overhead of its own.

```luau
-- net.luau
return define("example", {
    my_event = event({
        value = t.tuple(t.string, t.u8, t.optional(t.vec2))
    })
})
```
```luau
-- server.luau
net_server.my_event.fire_all("hello world", 2, Vector2.new(1, 1))
net_server.my_event.fire_all("hello world", 2)
```

## Custom

`t.create<<T>>(write_fn, read_fn, size)`

Custom types let you create a datatype with a custom wire representation when the built-in datatypes cannot express the desired encoding efficiently.

```luau
type WeaponData = {
    level: number,
    model: Model
}

const weapon = t.create<<WeaponData>>(function(buff, offset, value, refs)
    buffer.writeu16(buff, offset, value.level)
    table.insert(refs, value.model or t.null_ref)

    return 2
end, function(buff, offset, refs)
    const level = buffer.readu16(buff, offset)

    refs.cursor += 1
    const model: Model = refs[refs.cursor]
    assert(model:IsA("Model"), "Expected a Model, got " .. model.ClassName)

    return 2, {
        level = level,
        model = model,
    }
end, 2)
```

- `T` is the type of the value that will be serialized.
- `write_fn` is a function that takes `(buffer, offset, value, refs)`, writes the value to the buffer, and returns the number of bytes written. `refs` is the reference table associated with the current serialization. It allows values that cannot or should not be serialized into the buffer to be stored as references instead.
- `read_fn` is a function that takes `(buffer, offset, refs)` and returns the number of bytes read and the deserialized value.
- `size` defines the exact number of bytes required by the datatype. It can be either a fixed number or a function that calculates the size from the value.

For variable-sized datatypes, `size` can be a function:

```luau
type WeaponData = {
    level: number,
    name: string,
    model: Model
}

const weapon = t.create<<WeaponData>>(function(buff, offset, value, refs)
    buffer.writeu16(buff, offset, value.level)

    const len = string.len(value.name)
	buffer.writeu16(buff, offset + 2, len)
	buffer.writestring(buff, offset + 4, value.name)

    table.insert(refs, value.model or t.null_ref)

    return 4 + len
end, function(buff, offset, refs)
    const level = buffer.readu16(buff, offset)
    const len = buffer.readu16(buff, offset + 2)
    const name = buffer.readstring(buff, offset + 4, len)

    refs.cursor += 1
    const model: Model = refs[refs.cursor]
    assert(model:IsA("Model"), "Expected a Model, got " .. model.ClassName)

    return 4 + len, {
        level = level,
        name = name,
        model = model,
    }
end, function(value)
    return 4 + string.len(value.name)
end)
```

The `size` function is used to determine how much space the value requires before serialization, so it must always return the exact number of bytes that `write_fn` will produce.

### References

`refs` is a side-channel reference table used to pass values that are not serialized into the buffer. References are stored separately from the binary data, so they do not contribute to the datatype's byte size.

In `write_fn`, values are added to `refs` in the order they should be consumed by `read_fn`:

```luau
table.insert(refs, value.model or t.null_ref)
```

Using `t.null_ref` as a fallback is recommended even when the value is expected to always exist. It guarantees that a reference slot is inserted into the table even when the value is `nil`, keeping the reference order consistent between serialization and deserialization.

`t.null_ref` represents an empty reference slot. It is not serialized into the buffer and does not consume any bytes.

In `read_fn`, `refs.cursor` tracks the current position in the reference table. Increment it before consuming a reference:

```luau
refs.cursor += 1

const model = refs[refs.cursor]
```

The writer and reader must consume references in exactly the same order. If `write_fn` inserts three references, `read_fn` must advance `refs.cursor` three times in the corresponding order.

```luau
function(buff, offset, value, refs)
	table.insert(refs, value.model or t.null_ref)
	table.insert(refs, value.owner or t.null_ref)
	table.insert(refs, value.target or t.null_ref)

	return 0
end

function(buff, offset, refs)
	refs.cursor += 1
	const model = refs[refs.cursor]

	refs.cursor += 1
	const owner = refs[refs.cursor]

	refs.cursor += 1
	const target = refs[refs.cursor]

	return 0, {
		model = model,
		owner = owner,
		target = target,
	}
end
```

`refs` is independent from the buffer offset. `offset` tracks binary data inside the buffer, while `refs.cursor` tracks external references.