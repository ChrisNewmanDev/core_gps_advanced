# Core GPS Advanced - Multi-Framework Installation Guide

This GPS script now supports **QBCore**, **ESX/ESX Extended**, and **Qbox** frameworks!

## Framework Configuration

1. Open `config.lua`
2. Set your framework:
   ```lua
   Config.Framework = 'qbcore'  -- Options: 'qbcore', 'esx', 'qbox'
   ```

## Database Installation

### All Frameworks (QBCore, ESX, Qbox)
All frameworks use the same database tables. Import the SQL file:
- Run `install/core_gps_advanced.sql` in your database

**Note:** All frameworks now use `oxmysql` resource. Make sure you have it installed and started in your server.cfg:
```lua
ensure oxmysql
```

## Item Installation

### QBCore
Add to `qb-core/shared/items.lua`:
```lua
['core_gps_a'] = {
    ['name'] = 'core_gps_a',
    ['label'] = 'GPS Device',
    ['weight'] = 500,
    ['type'] = 'item',
    ['image'] = 'core_gps_a.png',
    ['unique'] = true,
    ['useable'] = true,
    ['shouldClose'] = true,
    ['combinable'] = nil,
    ['description'] = 'Advanced GPS tracking device with location markers'
},
```

### ESX
Add to `ox_inventory/data/items.lua`:
```lua
['core_gps_a'] = {
    label = 'GPS Device',
    weight = 500,
    stack = false,
    close = true,
    description = 'Advanced GPS tracking device with location markers. Save and share your favorite locations!',
    client = {
        image = 'core_gps_a.png',
    }
},
```

### Qbox
Add to `qbx-core/shared/items.lua`:
```lua
['core_gps_a'] = {
    name = 'core_gps_a',
    label = 'GPS Device',
    weight = 500,
    type = 'item',
    image = 'core_gps_a.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'Advanced GPS tracking device with location markers'
},
```

**Important for ESX & Qbox:** This script assumes you're using `ox_inventory`. Make sure it's installed and configured properly.

## Image Installation

Add a GPS image file named `core_gps_a.png` to your inventory images folder:

- **QBCore:** `qb-inventory/html/images/core_gps_a.png`
- **ESX:** `ox_inventory`: `ox_inventory/web/images/core_gps_a.png`
- **Qbox:** `ox_inventory/web/images/core_gps_a.png`

## Server.cfg

Add to your server.cfg:
```lua
ensure oxmysql
ensure core_gps_advanced
```