# StealthxUI Tab Lazy Loading

StealthxUI supports optional lazy tab construction through `Lazy = true` plus a `Build` callback.

```lua
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "house",
    Lazy = true,
    Build = function(Tab)
        Tab:Paragraph({
            Title = "Loaded on first open",
            Content = "This tab is not populated during window creation.",
        })
    end,
})
```

## Lifecycle

- The tab navigation UI and content container are created immediately.
- The `Build` callback runs once when the tab is first selected.
- Lazy build is synchronous on the first open. A very large `Build` callback can still cause a first-open hitch, so keep expensive work outside the callback or split it into smaller deferred tasks.
- A failed build is recorded and is not automatically retried on every click. Any tab-owned resources and partially created elements are released immediately to avoid duplicate state and signal accumulation.
- `Tab:Build()` explicitly builds a lazy tab before selection when needed.
- `Tab:Track(resource[, cleanup])` registers a resource for automatic cleanup.
- `Tab:TrackSignal(signal, callback)` creates a tab-owned connection that is disconnected by `Tab:Destroy()`.
- `Tab:OnCleanup(callback)` registers a cleanup callback for external resources.
- `Tab:Destroy()` disconnects tab-owned signals, destroys its elements, and releases its containers.
- `Window:Destroy()` destroys all tabs before tearing down the window GUI.

## Compatibility

`Lazy = true` only takes effect when `Build` is a function. Existing eager tabs keep their previous behavior, so scripts that create elements directly after `Window:Tab()` do not need to change.

## Recommended pattern

For long-lived connections created inside a lazy tab, register them with the tab instead of leaving them in a global collection:

```lua
Build = function(Tab)
    local Connection = SomeSignal:Connect(function()
        -- ...
    end)

    Tab:Track(Connection)

    Tab:OnCleanup(function()
        -- Optional external cleanup.
    end)
end
```
