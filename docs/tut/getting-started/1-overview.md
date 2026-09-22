# Overview

BufNet is a typed and lightweight networking library for Roblox, built to make networking efficient, structured, and enjoyable to work with.

It gives you a single foundation for events, functions, and synchronized state, while letting you describe the data your game uses with reusable, composable data types.

## What makes BufNet different?

BufNet is designed to keep networking lightweight without making the API harder to use.

### Structured Data

Instead of treating network data as arbitrary values, BufNet lets you define its shape using composable data types. This makes complex payloads easier to represent while keeping their structure explicit.

### Lightweight Communication

Events and functions are designed around focused communication patterns, avoiding unnecessary abstractions between your game logic and the networking layer.

### Built Around Buffers

BufNet uses Roblox buffers as a foundation for efficient data handling, making structured binary data a first-class part of the networking model.

## Developer Experience

Networking should be easy to define, easy to understand, and easy to change.

### Luau First

Everything is defined directly in Luau, so your networking definitions live alongside your game code. No separate language or generation step is required.

### Fully Typed

BufNet's API and data types are designed to work naturally with Luau's type system, giving you type checking and autocomplete throughout your networking code.

### Composable Data Types

Build larger structures from smaller types and reuse them wherever they are needed. From simple values to nested structures, arrays, maps, tuples, and variants, your data can be described precisely.

## One Networking Layer

BufNet brings different communication patterns together without making them feel like separate systems.

### Events

Send data when an action happens. Reliable and unreliable communication can be used where each makes the most sense.

### Functions

Perform an operation when you need an answer back, with typed arguments and return values.

### State

Keep important values synchronized and react to changes as they happen, without manually rebuilding the same synchronization logic throughout your game.

## Designed to Scale

Networking definitions can grow alongside the rest of your project without becoming a collection of disconnected remotes and ad-hoc data structures.

### Organized Definitions

Group related networking definitions into clear namespaces and paths, keeping large projects easier to navigate.

### Reusable Schemas

Define a data type once and use it across events, functions, and state. Changes to the shape of your data remain centralized instead of being duplicated throughout your code.

### Consistent API

Events, functions, state, and data types share the same design philosophy, giving BufNet a predictable API from simple interactions to larger networking systems.