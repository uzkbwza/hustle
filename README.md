![cover](./screenshot/cover.png)

# Godot Export Categories

A very hacky way to separate script variables in categories.

This is not optimized at all, it's just something I put together to help me
separate my `Script Variables` into "sections".

If it helps you too, awseom! :grin:

Feel free to edit, contribute, share, do whatever you want with this.

It's for everyone and it is free!

## Instalation

Just copy the `export_categories` folder into your project's `addons` folder.

Or copy the whole `addons` folder and paste it into your project's root folder.

Then just enable it on
`Project > Project Settings > Plugins > ExportCategories`.

## Usage

Export a var (of any type, if you want) with the `_c_` prefix. That's it.

Examples:

```javascript
export var _c_Movement
export var move_speed = 10
// or
export var _c_Mouse_Sensitivity: string
export var mouse_sensitivity_x: float = 0.03
export var mouse_sensitivity_y: float = 0.03
```

![screenshot](./screenshot/screenshot.png)

All variables prefixed with `_c_` will be turned into a red label.

Enjoy

## Changelog
### 1.1
- Cleaner category name
- Updated images

### 1.0
- Basic addon
