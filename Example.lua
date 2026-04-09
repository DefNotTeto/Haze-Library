-- Controls:
--  R: Toggle Gui
--  WASD: Move Cursor
--  V: Click

local Haze = loadstring(game:HttpGet('https://github.com/DefNotTeto/Haze-Library/raw/refs/heads/main/Library.lua'))()

local Window = Haze:CreateWindow({
    Name = 'teto',
    Color = {200, 100, 120},
    Position = {500, 250}
})

local tab1 = Window:CreateTab({Name = 'Tab 1'})
local tab2 = Window:CreateTab({Name = 'Tab 2'})
