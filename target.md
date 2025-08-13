## Tufan Target Bridge — Exports (compact examples)

### AddTargetEntity
```lua
local veh = GetVehiclePedIsIn(PlayerPedId(), false)
exports['Tufan']:AddTargetEntity(veh, {
  distance = 2.5,
  options = {{
    name='inspect',
    label='Inspect',
    icon='fas fa-wrench',
    onSelect=function(ctx) print('inspect', ctx and ctx.entity) end
  },{
    name='wash',
    label='Wash',
    icon='fas fa-soap',
    onSelect=function() print('wash') end
  }}
})
```

### RemoveTargetEntity
```lua
exports['Tufan']:RemoveTargetEntity(veh)
```

### AddBoxZone
```lua
exports['Tufan']:AddBoxZone('repair_zone', vector3(-211.55, -1324.55, 30.89), vector3(3.0, 3.0, 3.0), {
  distance = 2.5,
  rotation = 0.0,
  options = {{
    name='open',
    label='Open Menu',
    icon='fas fa-tools',
    onSelect=function() print('open') end
  }}
})
```

### RemoveZone
```lua
exports['Tufan']:RemoveZone('repair_zone')
```

### AddGlobalPed
```lua
exports['Tufan']:AddGlobalPed('ped_actions', {{
  name='talk',
  label='Talk',
  icon='fas fa-comment',
  onSelect=function() print('hello') end
}})
```

### RemoveGlobalPed
```lua
exports['Tufan']:RemoveGlobalPed('ped_actions')
```

### State
```lua
local backend = exports['Tufan']:State()
print('backend:', backend) -- 'ox' | 'qb' | 'interact' | nil
```