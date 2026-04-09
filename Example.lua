-------------------------------------------- // MAIN EXAMPLE // ---------------------------------------------------------

-- Controls:
--  R: Toggle Gui
--  WASD: Move Cursor
--  V: Click

-- // Services
local cloneref = (cloneref or clonereference) or function(obj)
    return obj
end
local starterGui = game:GetService('StarterGui')

-- // Main Library
local Haze = loadstring(game:HttpGet('https://github.com/DefNotTeto/Haze-Library/raw/refs/heads/main/Library.lua'))()

-- // Window
local Window = Haze:CreateWindow({
    Name = 'teto',
    Color = {200, 100, 120},
    Position = {500, 250}
})

-- // Tabs
local tab1 = Window:CreateTab({
    Name = 'Teto 1'
})
local tab2 = Window:CreateTab({
    Name = 'Teto 2'
})

----------------------------------------------------------------------------------------------------------------------
