local run = game:GetService('RunService')
local uis = game:GetService('UserInputService')
local core = game:GetService('CoreGui')
local cas = game:GetService('ContextActionService')
--
if shared.savedObjects then
    for _, object in ipairs(shared.savedObjects) do
        pcall(function() object:Remove() end)
        pcall(function() object:Destroy() end)
        pcall(function() object:Disconnect() end)
    end
end
shared.savedObjects = {}

local function cache(object)
    table.insert(shared.savedObjects, object)
    return object
end

local Haze = {}
Haze.__index = Haze

local allDrawings = {}
local clickListeners = {}
local cursorPos = Vector2.new(500, 400)

local function trackDrawing(obj)
    table.insert(allDrawings, obj)
    return obj
end

local function fireFakeClick(pos)
    local hit = false
    for _, listener in ipairs(clickListeners) do
        if listener(pos) then hit = true end
    end
    return hit
end

local function makeClickable(obj, onClick)
    table.insert(clickListeners, function(pos)
        if not obj.Visible then return false end
        local p = obj.Position
        local s = obj.Size
        if pos.X >= p.X and pos.X <= p.X + s.X and
           pos.Y >= p.Y and pos.Y <= p.Y + s.Y then
            onClick()
            return true
        end
        return false
    end)
end

local function isHovering(obj)
    if not obj.Visible then return false end
    local p = obj.Position
    local s = obj.Size
    return cursorPos.X >= p.X and cursorPos.X <= p.X + s.X and
           cursorPos.Y >= p.Y and cursorPos.Y <= p.Y + s.Y
end

local function easeOutQuart(t)
    return 1 - (1 - t) ^ 4
end

local function lerp(a, b, t)
    if typeof(a) == 'Vector2' then
        return Vector2.new(a.X + (b.X - a.X) * t, a.Y + (b.Y - a.Y) * t)
    end
    return a + (b - a) * t
end

local function tweenObj(obj, props, duration)
    duration = duration or 0.5
    local startValues = {}
    for prop, _ in pairs(props) do
        startValues[prop] = obj[prop]
    end
    local i = 0
    local connection
    connection = cache(run.Heartbeat:Connect(function(dt)
        i = i + dt
        local t = easeOutQuart(math.clamp(i / duration, 0, 1))
        for prop, target in pairs(props) do
            obj[prop] = lerp(startValues[prop], target, t)
        end
        if i >= duration then connection:Disconnect() end
    end))
end

local notifQueue = {}
local notifActive = false
local notifFrameRef = nil

local function processNotifQueue()
    if notifActive or #notifQueue == 0 or not notifFrameRef then return end
    notifActive = true
    local text = table.remove(notifQueue, 1)
    local frame = notifFrameRef

    local bg = cache(trackDrawing(Drawing.new('Square')))
    bg.Size = Vector2.new(0, 30)
    bg.Filled = true
    bg.Color = Color3.fromRGB(36, 36, 36)
    bg.Transparency = 0
    bg.Visible = true

    local stroke = cache(trackDrawing(Drawing.new('Square')))
    stroke.Size = Vector2.new(0, 30)
    stroke.Filled = false
    stroke.Thickness = 1.5
    stroke.Transparency = 0
    stroke.Visible = true

    local label = cache(trackDrawing(Drawing.new('Text')))
    label.Text = text
    label.Size = 14
    label.Font = Drawing.Fonts.System
    label.Color = Color3.fromRGB(255, 255, 255)
    label.Transparency = 0
    label.Visible = true

    local targetW = label.TextBounds.X + 20
    local conn
    conn = cache(run.RenderStepped:Connect(function()
        local base = frame.Position + Vector2.new(0, 305)
        bg.Position = base
        stroke.Position = base
        label.Position = base + Vector2.new(
            (bg.Size.X - label.TextBounds.X) / 2,
            (bg.Size.Y - label.TextBounds.Y) / 2
        )
    end))

    tweenObj(bg, {Size = Vector2.new(targetW, 30)}, 0.3)
    tweenObj(stroke, {Size = Vector2.new(targetW, 30)}, 0.3)

    task.delay(2, function()
        tweenObj(bg, {Transparency = 1}, 0.3)
        tweenObj(stroke, {Transparency = 1}, 0.3)
        tweenObj(label, {Transparency = 0}, 0.3)
        task.delay(0.3, function()
            conn:Disconnect()
            bg:Remove()
            stroke:Remove()
            label:Remove()
            notifActive = false
            processNotifQueue()
        end)
    end)
end

function Haze:CreateWindow(config)
    local name = config.Name or 'Haze'
    local color = config.Color or {200, 150, 255}
    local pos = config.Position or {500, 250}
    local guiOpen = true

    local gui = cache(Instance.new('ScreenGui'))
    gui.Parent = core

    local hitbox = Instance.new('Frame')
    hitbox.Parent = gui
    hitbox.AnchorPoint = Vector2.new(0, 0.19)
    hitbox.BackgroundTransparency = 1
    hitbox.Size = UDim2.new(0, 500, 0, 300)
    hitbox.Position = UDim2.new(0, pos[1], 0, pos[2])

    local frame = cache(trackDrawing(Drawing.new('Square')))
    frame.Size = Vector2.new(500, 300)
    frame.Position = Vector2.new(unpack(pos))
    frame.Color = Color3.fromRGB(36, 36, 36)
    frame.Thickness = 0
    frame.Visible = true
    frame.Filled = true

    local frameStroke = cache(trackDrawing(Drawing.new('Square')))
    frameStroke.Size = Vector2.new(500, 300)
    frameStroke.Position = Vector2.new(unpack(pos))
    frameStroke.Color = Color3.fromRGB(unpack(color))
    frameStroke.Thickness = 6
    frameStroke.Visible = true

    local grads = {}
    for i = 1, 295 do
        local grad = cache(trackDrawing(Drawing.new('Square')))
        grad.Size = Vector2.new(500, 300 - i)
        grad.Position = Vector2.new(unpack(pos))
        grad.Color = Color3.fromRGB(
            math.floor((color[1] * 0.2) + (24 - (color[1] * 0.15)) * (i / 300)),
            math.floor((color[2] * 0.2) + (24 - (color[2] * 0.15)) * (i / 300)),
            math.floor((color[3] * 0.2) + (24 - (color[3] * 0.15)) * (i / 300))
        )
        grad.Thickness = 2
        grad.Visible = true
        grads[i] = grad
    end

    local title = cache(trackDrawing(Drawing.new('Text')))
    title.Text = name
    title.Size = 19
    title.Font = Drawing.Fonts.System
    title.Position = Vector2.new(pos[1] + 9, pos[2] + 2)
    title.Color = Color3.fromRGB(255, 255, 255)
    title.Visible = true
    title.Transparency = 0
    tweenObj(title, {Transparency = 1, Position = Vector2.new(pos[1] + 4, pos[2] + 2)}, 1)

    local dragging = false
    local dragStart = nil
    local offsets = {}
    local allObjs = {frame, frameStroke, title, table.unpack(grads)}

    local function tryStartDrag()
        if isHovering(frame) then
            dragging = true
            dragStart = cursorPos - frame.Position
            offsets = {}
            for _, obj in ipairs(allObjs) do
                offsets[obj] = obj.Position - frame.Position
            end
        end
    end

    local function tryEndDrag()
        dragging = false
    end

    cache(run.Heartbeat:Connect(function()
        if not dragging then return end
        local target = cursorPos - dragStart
        frame.Position = target
        hitbox.Position = UDim2.new(0, target.X, 0, target.Y)
        for _, obj in ipairs(allObjs) do
            if obj ~= frame then
                obj.Position = target + offsets[obj]
            end
        end
    end))

    local tabsPanel = cache(trackDrawing(Drawing.new('Square')))
    tabsPanel.Size = Vector2.new(0, 0)
    tabsPanel.Visible = true
    tabsPanel.Transparency = 0
    tabsPanel.Thickness = 1.3
    tabsPanel.Color = Color3.fromRGB(unpack(color))
    cache(run.RenderStepped:Connect(function()
        tabsPanel.Position = frame.Position + Vector2.new(5, 21)
    end))

    local tabContainer = cache(trackDrawing(Drawing.new('Square')))
    tabContainer.Size = Vector2.new(0, 0)
    tabContainer.Visible = true
    tabContainer.Transparency = 0
    tabContainer.Thickness = 1.3
    tabContainer.Color = Color3.fromRGB(unpack(color))
    cache(run.RenderStepped:Connect(function()
        tabContainer.Position = frame.Position + Vector2.new(115, 21)
    end))

    task.delay(0.8, function()
        tweenObj(tabContainer, {Transparency = 0.4, Size = Vector2.new(375, 273)}, 0.7)
    end)
    task.delay(0.5, function()
        tweenObj(tabsPanel, {Transparency = 0.4, Size = Vector2.new(100, 273)}, 0.7)
    end)

    local cursor = cache(trackDrawing(Drawing.new('Triangle')))
    cursor.Visible = true
    cursor.Filled = true
    cursor.Color = Color3.fromRGB(255, 255, 255)
    cursor.Transparency = 1
    cursor.Thickness = 1

    local cursorOutline = cache(trackDrawing(Drawing.new('Triangle')))
    cursorOutline.Visible = true
    cursorOutline.Filled = false
    cursorOutline.Color = Color3.fromRGB(0, 0, 0)
    cursorOutline.Transparency = 0.6
    cursorOutline.Thickness = 1

    local cursorSpeed = 300
    local keys = {up = false, down = false, left = false, right = false}

    local function bindWASD()
        cas:BindAction('fcUp', function(_, state) keys.up = state == Enum.UserInputState.Begin end, false, Enum.KeyCode.W)
        cas:BindAction('fcDown', function(_, state) keys.down = state == Enum.UserInputState.Begin end, false, Enum.KeyCode.S)
        cas:BindAction('fcLeft', function(_, state) keys.left = state == Enum.UserInputState.Begin end, false, Enum.KeyCode.A)
        cas:BindAction('fcRight', function(_, state) keys.right = state == Enum.UserInputState.Begin end, false, Enum.KeyCode.D)
    end

    local function unbindWASD()
        cas:UnbindAction('fcUp')
        cas:UnbindAction('fcDown')
        cas:UnbindAction('fcLeft')
        cas:UnbindAction('fcRight')
        keys = {up = false, down = false, left = false, right = false}
    end

    bindWASD()

    cache(uis.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.R then
            guiOpen = not guiOpen
            for _, obj in ipairs(allDrawings) do
                pcall(function() obj.Visible = guiOpen end)
            end
            hitbox.Visible = guiOpen
            cursor.Visible = guiOpen
            cursorOutline.Visible = guiOpen
            if guiOpen then
                bindWASD()
            else
                unbindWASD()
                dragging = false
            end
            return
        end
        if input.KeyCode == Enum.KeyCode.V then
            if not guiOpen then return end
            if dragging then
                tryEndDrag()
            else
                local clickFired = fireFakeClick(cursorPos)
                if not clickFired then
                    tryStartDrag()
                end
            end
        end
    end))

    cache(uis.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.V then
            if dragging then
                tryEndDrag()
            end
        end
    end))

    cache(run.RenderStepped:Connect(function(dt)
        if not guiOpen then return end
        if keys.up then cursorPos = cursorPos + Vector2.new(0, -cursorSpeed * dt) end
        if keys.down then cursorPos = cursorPos + Vector2.new(0, cursorSpeed * dt) end
        if keys.left then cursorPos = cursorPos + Vector2.new(-cursorSpeed * dt, 0) end
        if keys.right then cursorPos = cursorPos + Vector2.new(cursorSpeed * dt, 0) end
        local vp = workspace.CurrentCamera.ViewportSize
        cursorPos = Vector2.new(math.clamp(cursorPos.X, 0, vp.X), math.clamp(cursorPos.Y, 0, vp.Y))
        cursor.PointA = cursorPos
        cursor.PointB = cursorPos + Vector2.new(0, 16)
        cursor.PointC = cursorPos + Vector2.new(11, 11)
        cursorOutline.PointA = cursorPos
        cursorOutline.PointB = cursorPos + Vector2.new(0, 16)
        cursorOutline.PointC = cursorPos + Vector2.new(11, 11)
    end))

    notifFrameRef = frame

    local tabCount = 0
    local onTab = '???'

    local Window = {}
    Window.__index = Window

    function Window:Notify(text)
        table.insert(notifQueue, text)
        processNotifQueue()
    end

    function Window:CreateTab(tabConfig)
        local tabName = tabConfig.Name or 'Tab'
        tabCount += 1
        local myIndex = tabCount

        local bg = cache(trackDrawing(Drawing.new('Square')))
        bg.Visible = true
        bg.Size = Vector2.new(93, 25)
        bg.Filled = true
        bg.Color = Color3.fromRGB(unpack(color))
        bg.Transparency = 0

        local tit = cache(trackDrawing(Drawing.new('Text')))
        tit.Visible = true
        tit.Color = Color3.fromRGB(255, 255, 255)
        tit.Text = tabName
        tit.Size = 15
        tit.Transparency = 0

        task.delay(1, function()
            tweenObj(bg, {Transparency = 0.1}, 1)
            tweenObj(tit, {Transparency = 0.6}, 2)
            makeClickable(bg, function()
                onTab = tabName
            end)
            local lastTab = nil
            cache(run.RenderStepped:Connect(function()
                local bgPos = frame.Position + Vector2.new(3, 2.7 + (myIndex - 1) * 28) + Vector2.new(6, 22)
                bg.Position = bgPos
                tit.Position = bgPos + Vector2.new(
                    (bg.Size.X - tit.TextBounds.X) / 2,
                    (bg.Size.Y - tit.TextBounds.Y) / 2
                )
                if onTab ~= lastTab then
                    lastTab = onTab
                    if onTab == tabName then
                        tweenObj(bg, {Transparency = 0.3}, 0.3)
                        tweenObj(tit, {Transparency = 1, Size = 15}, 0.3)
                    else
                        tweenObj(tit, {Transparency = 0.6, Size = 15}, 0.3)
                        tweenObj(bg, {Transparency = 0.1}, 0.3)
                    end
                end
            end))
        end)

        local Tab = {}
        Tab.__index = Tab

        function Tab:IsActive()
            return onTab == tabName
        end

        return Tab
    end

    return Window
end

return Haze
