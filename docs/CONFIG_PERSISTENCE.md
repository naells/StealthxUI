# StealthxUI Config Persistence

StealthxUI provides per-window JSON config persistence for flagged elements. The implementation is designed to work with lazy tabs: values for elements that have not been built yet are kept as pending data and applied when the element is created.

## Basic usage

```lua
local Window = StealthxUI:CreateWindow({
    Title = "StealthxUI",
    Folder = "MyScript",
})

Window:Tab({ Title = "Settings" }):Toggle({
    Flag = "AutoFarm",
    Title = "Auto Farm",
    Value = false,
})

local Config = Window:Config({
    Name = "default",
    AutoLoad = true,
})

-- Save manually when desired.
Config:Save()

-- Load manually when desired.
Config:Load()

-- User data can be stored alongside element values.
Config:Set("profile", "default")
local profile = Config:Get("profile")
```

## Supported element types

`Toggle`, `Slider`, `Dropdown`, `Input`, `Keybind`, and `Colorpicker` are persisted by default. Additional parsers can be added with `Window.ConfigManager:RegisterParser(...)`.

## Lazy tabs

When `Config:Load()` runs before a lazy tab is built, the serialized values stay in that config's pending-data table. When the tab is opened and its flagged elements are created, the values are applied once.

## File location

The default path is:

```text
StealthxUI/<Window.Folder>/config/<name>.json
```

Config names are sanitized before they are used as filenames. Writes use a temporary file when the executor exposes `renamefile`, reducing the chance of leaving a half-written JSON file.

## Lifecycle

Each window owns its own ConfigManager instance. Destroying the window releases the manager and its live element references, while JSON files remain on disk.
