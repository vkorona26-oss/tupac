--[[
    OJB HUB  |  v1.0.0
    Single-file Roblox script hub. No external UI library, no dependencies.
    Entry point: loadstring(game:HttpGet("<your-host>/Exec"))()
    Unload: getgenv().OJBHub.Unload()
]]

local VERSION = "1.0.0"

if getgenv().OJBHub and getgenv().OJBHub.Unload then
    pcall(getgenv().OJBHub.Unload)
end

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local Lighting         = game:GetService("Lighting")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")
local CAM = workspace.CurrentCamera

-- ============================================================
-- THEME
-- ============================================================
local THEME = {
    Accent = Color3.fromRGB(122, 92, 255),
    Bg     = Color3.fromRGB(16, 16, 20),
    Panel  = Color3.fromRGB(23, 23, 28),
    Row    = Color3.fromRGB(30, 30, 37),
    Text   = Color3.fromRGB(234, 234, 242),
    Sub    = Color3.fromRGB(142, 142, 156),
    Stroke = Color3.fromRGB(50, 50, 62),
    Red    = Color3.fromRGB(255, 92, 92),
    Green  = Color3.fromRGB(86, 226, 140),
}

local WIN_W, WIN_H = 560, 436
local TOP_H, RAIL_W, PAD = 38, 140, 14
local ROW_W = WIN_W - RAIL_W - PAD * 2

-- ============================================================
-- STATE
-- ============================================================
local Flags   = {}
local Setters = {}
local Conns   = {}
local Stops   = {}
local menuKey = Enum.KeyCode.RightShift

local function track(c)
    table.insert(Conns, c)
    return c
end

local function bind(flag, fn)
    Setters[flag] = fn
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function round(v, step)
    return math.floor(v / step + 0.5) * step
end

local function new(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    if parent then inst.Parent = parent end
    return inst
end

local function char()
    local c = LP.Character
    if not c then return nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end
    return c, hum
end

local function root()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function copy(text)
    if setclipboard then
        pcall(setclipboard, text)
        return true
    elseif toclipboard then
        pcall(toclipboard, text)
        return true
    end
    return false
end

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
local notifyOn = true
local notifHolder
local notifCards = {}

local function reflowNotifs()
    for i, card in ipairs(notifCards) do
        if card.Parent then
            TweenService:Create(card, TweenInfo.new(0.15), {
                Position = UDim2.new(1, -272, 0, (i - 1) * 46),
            }):Play()
        end
    end
end

local function dropNotif(card)
    for i, c in ipairs(notifCards) do
        if c == card then
            table.remove(notifCards, i)
            break
        end
    end
    if card.Parent then card:Destroy() end
    reflowNotifs()
end

local function notify(text, kind)
    if not notifyOn then return end
    if not notifHolder or not notifHolder.Parent then
        notifHolder = new("ScreenGui", {
            Name = "OJBHubNotify",
            ResetOnSpawn = false,
            IgnoreGuiInset = true,
            DisplayOrder = 999,
        }, PG)
        notifCards = {}
    end

    local color = THEME.Accent
    if kind == "success" then color = THEME.Green
    elseif kind == "error" then color = THEME.Red end

    if #notifCards >= 5 then
        dropNotif(notifCards[1])
    end

    local slot = #notifCards
    local card = new("Frame", {
        Size = UDim2.fromOffset(258, 40),
        Position = UDim2.new(1, 20, 0, slot * 46),
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, notifHolder)
    table.insert(notifCards, card)
    new("UICorner", { CornerRadius = UDim.new(0, 7) }, card)
    new("UIStroke", { Color = color, Thickness = 1, Transparency = 0.45 }, card)
    new("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    }, card)
    new("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.fromOffset(12, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = THEME.Text,
    }, card)

    TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quint), {
        Position = UDim2.new(1, -272, 0, slot * 46),
    }):Play()

    task.delay(3, function()
        if not card.Parent then return end
        TweenService:Create(card, TweenInfo.new(0.18), {
            Position = UDim2.new(1, 20, 0, 0),
        }):Play()
        task.wait(0.2)
        dropNotif(card)
    end)
end

-- ============================================================
-- GUI ROOT
-- ============================================================
local gui = new("ScreenGui", {
    Name = "OJBHub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 500,
}, PG)

local window = new("Frame", {
    Name = "Window",
    Size = UDim2.fromOffset(WIN_W, WIN_H),
    Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
    BackgroundColor3 = THEME.Bg,
    BorderSizePixel = 0,
    ClipsDescendants = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, window)
local winStroke = new("UIStroke", { Color = THEME.Stroke, Thickness = 1 }, window)
new("Frame", {
    Size = UDim2.new(1, 0, 0, 1),
    Position = UDim2.fromOffset(0, TOP_H),
    BackgroundColor3 = THEME.Stroke,
    BorderSizePixel = 0,
}, window)

-- topbar
local topbar = new("Frame", {
    Name = "Topbar",
    Size = UDim2.new(1, 0, 0, TOP_H),
    BackgroundTransparency = 1,
}, window)

local logo = new("Frame", {
    Size = UDim2.fromOffset(20, 20),
    Position = UDim2.fromOffset(14, 9),
    BackgroundColor3 = THEME.Accent,
    BorderSizePixel = 0,
}, topbar)
new("UICorner", { CornerRadius = UDim.new(0, 5) }, logo)
new("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "O",
    Font = Enum.Font.GothamBlack,
    TextSize = 13,
    TextColor3 = Color3.new(1, 1, 1),
}, logo)

new("TextLabel", {
    Size = UDim2.fromOffset(180, 20),
    Position = UDim2.fromOffset(42, 9),
    BackgroundTransparency = 1,
    Text = "OJB HUB",
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
    TextSize = 13,
    TextColor3 = THEME.Text,
}, topbar)

new("TextLabel", {
    Size = UDim2.fromOffset(80, 20),
    Position = UDim2.fromOffset(112, 10),
    BackgroundTransparency = 1,
    Text = "v" .. VERSION,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = THEME.Sub,
}, topbar)

local function topButton(text, x, color, cb)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(26, 22),
        Position = UDim2.new(1, x, 0, 8),
        BackgroundColor3 = THEME.Row,
        BorderSizePixel = 0,
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = color,
        AutoButtonColor = false,
    }, topbar)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Stroke }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Row }):Play()
    end)
    b.MouseButton1Click:Connect(cb)
    return b
end

-- rail
local rail = new("Frame", {
    Name = "Rail",
    Size = UDim2.new(0, RAIL_W, 1, -TOP_H),
    Position = UDim2.fromOffset(0, TOP_H),
    BackgroundColor3 = THEME.Panel,
    BorderSizePixel = 0,
}, window)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, rail)
new("Frame", {
    Size = UDim2.new(1, 0, 1, -20),
    Position = UDim2.fromOffset(0, 10),
    BackgroundTransparency = 1,
}, rail)

local pageHolder = new("Frame", {
    Name = "Pages",
    Size = UDim2.new(1, -RAIL_W, 1, -TOP_H),
    Position = UDim2.fromOffset(RAIL_W, TOP_H),
    BackgroundTransparency = 1,
}, window)

-- ============================================================
-- WIDGETS
-- ============================================================
local function makePage()
    local f = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = THEME.Stroke,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false,
    }, pageHolder)
    return { frame = f, x = PAD, y = 12, w = ROW_W }
end

local function flush(page)
    page.frame.CanvasSize = UDim2.fromOffset(0, page.y + 16)
end

local function addSection(page, label)
    local holder = new("Frame", {
        Size = UDim2.new(0, page.w, 0, 26),
        Position = UDim2.fromOffset(page.x, page.y + 4),
        BackgroundTransparency = 1,
    }, page.frame)
    new("Frame", {
        Size = UDim2.fromOffset(3, 12),
        Position = UDim2.fromOffset(0, 7),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
    }, holder)
    new("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = string.upper(label),
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = THEME.Sub,
    }, holder)
    page.y = page.y + 30
end

local function rowBase(page, h)
    local row = new("Frame", {
        Size = UDim2.new(0, page.w, 0, h),
        Position = UDim2.fromOffset(page.x, page.y),
        BackgroundColor3 = THEME.Row,
        BorderSizePixel = 0,
    }, page.frame)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    page.y = page.y + h + 6
    return row
end

local function addToggle(page, label, default, flag, cb)
    local row = rowBase(page, 32)
    new("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = THEME.Text,
    }, row)

    local sw = new("Frame", {
        Size = UDim2.fromOffset(34, 18),
        Position = UDim2.new(1, -46, 0.5, -9),
        BackgroundColor3 = THEME.Stroke,
        BorderSizePixel = 0,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(0, 9) }, sw)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = THEME.Sub,
        BorderSizePixel = 0,
    }, sw)
    new("UICorner", { CornerRadius = UDim.new(0, 7) }, knob)

    local state = false

    local function render(v)
        TweenService:Create(knob, TweenInfo.new(0.14), {
            Position = UDim2.fromOffset(v and 18 or 2, 2),
            BackgroundColor3 = v and Color3.new(1, 1, 1) or THEME.Sub,
        }):Play()
        TweenService:Create(sw, TweenInfo.new(0.14), {
            BackgroundColor3 = v and THEME.Accent or THEME.Stroke,
        }):Play()
    end

    local function set(v, silent)
        state = v and true or false
        Flags[flag] = state
        render(state)
        if not silent and cb then task.spawn(cb, state) end
    end

    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
    }, row)
    hit.MouseButton1Click:Connect(function()
        set(not state, false)
    end)

    bind(flag, set)
    set(default, true)
    return set
end

local function addSlider(page, label, lo, hi, default, step, flag, cb)
    local row = rowBase(page, 46)
    local name = new("TextLabel", {
        Size = UDim2.new(1, -70, 0, 16),
        Position = UDim2.fromOffset(10, 7),
        BackgroundTransparency = 1,
        Text = label,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = THEME.Text,
    }, row)
    local valueLbl = new("TextLabel", {
        Size = UDim2.fromOffset(60, 16),
        Position = UDim2.new(1, -70, 0, 7),
        BackgroundTransparency = 1,
        Text = tostring(default),
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = THEME.Accent,
    }, row)

    local bar = new("Frame", {
        Size = UDim2.new(1, -20, 0, 5),
        Position = UDim2.fromOffset(10, 30),
        BackgroundColor3 = THEME.Stroke,
        BorderSizePixel = 0,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
    local fill = new("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
    }, bar)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(12, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, bar)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local value = default
    local dragging = false

    local function apply(v, silent)
        value = clamp(round(v, step), lo, hi)
        local alpha = (value - lo) / (hi - lo)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLbl.Text = tostring(value)
        Flags[flag] = value
        if not silent and cb then task.spawn(cb, value) end
    end

    local function fromX(x)
        local alpha = (x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1)
        apply(lo + (hi - lo) * clamp(alpha, 0, 1), false)
    end

    track(bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            fromX(input.Position.X)
        end
    end))
    track(bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))
    track(UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            fromX(input.Position.X)
        end
    end))
    track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end))

    bind(flag, function(v) apply(v, true) end)
    apply(default, true)
    return apply
end

local function addButton(page, label, color, cb)
    local b = new("TextButton", {
        Size = UDim2.new(0, page.w, 0, 32),
        Position = UDim2.fromOffset(page.x, page.y),
        BackgroundColor3 = THEME.Row,
        BorderSizePixel = 0,
        Text = label,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = color or THEME.Text,
        AutoButtonColor = false,
    }, page.frame)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Stroke }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = THEME.Row }):Play()
    end)
    b.MouseButton1Click:Connect(cb)
    page.y = page.y + 38
    return b
end

local function addTextbox(page, label, placeholder, flag, cb)
    local row = rowBase(page, 34)
    new("TextLabel", {
        Size = UDim2.new(1, -180, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = THEME.Text,
    }, row)
    local box = new("TextBox", {
        Size = UDim2.fromOffset(158, 24),
        Position = UDim2.new(1, -168, 0.5, -12),
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = THEME.Sub,
        ClearTextOnFocus = false,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = THEME.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, box)
    new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, box)
    box.FocusLost:Connect(function()
        Flags[flag] = box.Text
        if cb then task.spawn(cb, box.Text) end
    end)
    return box
end

local function addKeybind(page, label, default, flag, cb)
    local row = rowBase(page, 32)
    new("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = THEME.Text,
    }, row)
    local btn = new("TextButton", {
        Size = UDim2.fromOffset(96, 22),
        Position = UDim2.new(1, -106, 0.5, -11),
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0,
        Text = default.Name,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = THEME.Accent,
        AutoButtonColor = false,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)

    local capturing = false
    btn.MouseButton1Click:Connect(function()
        capturing = true
        btn.Text = "press a key"
    end)
    track(UIS.InputBegan:Connect(function(input)
        if not capturing then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            capturing = false
            btn.Text = input.KeyCode.Name
            Flags[flag] = input.KeyCode.Name
            if cb then task.spawn(cb, input.KeyCode) end
        end
    end))

    bind(flag, function(v)
        btn.Text = tostring(v)
        local key = Enum.KeyCode[v]
        if key and cb then task.spawn(cb, key) end
    end)

    return btn
end

local function addDropdown(page, label, optionsFn, default, flag, cb)
    local row = rowBase(page, 32)
    new("TextLabel", {
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = THEME.Text,
    }, row)
    local value = default
    local valueLbl = new("TextLabel", {
        Size = UDim2.fromOffset(120, 20),
        Position = UDim2.new(1, -132, 0.5, -10),
        BackgroundTransparency = 1,
        Text = tostring(value) .. "  v",
        TextXAlignment = Enum.TextXAlignment.Right,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = THEME.Accent,
    }, row)

    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
    }, row)

    hit.MouseButton1Click:Connect(function()
        local opts = optionsFn and optionsFn() or {}
        if #opts == 0 then
            notify("No options available", "error")
            return
        end

        local blocker = new("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 40,
        }, window)

        local visible = math.min(#opts, 6)
        local pop = new("Frame", {
            Size = UDim2.fromOffset(180, visible * 26 + 8),
            Position = UDim2.fromOffset(
                row.AbsolutePosition.X - window.AbsolutePosition.X + row.AbsoluteSize.X - 180,
                row.AbsolutePosition.Y - window.AbsolutePosition.Y + row.AbsoluteSize.Y + 4
            ),
            BackgroundColor3 = THEME.Panel,
            BorderSizePixel = 0,
            ZIndex = 41,
            ClipsDescendants = true,
        }, window)
        new("UICorner", { CornerRadius = UDim.new(0, 7) }, pop)
        new("UIStroke", { Color = THEME.Stroke, Thickness = 1 }, pop)

        local list = new("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.fromOffset(0, #opts * 26),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = THEME.Stroke,
            ZIndex = 41,
        }, pop)

        local function close()
            blocker:Destroy()
            pop:Destroy()
        end
        blocker.MouseButton1Click:Connect(close)

        for i, opt in ipairs(opts) do
            local o = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 26),
                Position = UDim2.fromOffset(0, (i - 1) * 26),
                BackgroundTransparency = 1,
                Text = "  " .. tostring(opt),
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamMedium,
                TextSize = 12,
                TextColor3 = THEME.Text,
                ZIndex = 42,
                AutoButtonColor = false,
            }, list)
            o.MouseEnter:Connect(function()
                o.BackgroundTransparency = 0.85
                o.BackgroundColor3 = THEME.Accent
            end)
            o.MouseLeave:Connect(function()
                o.BackgroundTransparency = 1
            end)
            o.MouseButton1Click:Connect(function()
                value = opt
                valueLbl.Text = tostring(opt) .. "  v"
                Flags[flag] = opt
                close()
                if cb then task.spawn(cb, opt) end
            end)
        end
    end)

    bind(flag, function(v)
        value = v
        valueLbl.Text = tostring(v) .. "  v"
    end)
    Flags[flag] = value
    return valueLbl
end

local function addPanel(page, height)
    local p = new("ScrollingFrame", {
        Size = UDim2.new(0, page.w, 0, height),
        Position = UDim2.fromOffset(page.x, page.y),
        BackgroundColor3 = THEME.Panel,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = THEME.Stroke,
    }, page.frame)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, p)
    page.y = page.y + height + 8
    return p
end

-- ============================================================
-- FEATURES
-- ============================================================
local Features = {}

-- walk speed / jump power
local baseWalk, baseJump = 16, 50
local baseFov = CAM and CAM.FieldOfView or 70
do
    local c, hum = char()
    if hum then
        baseWalk = hum.WalkSpeed
        baseJump = hum.JumpPower
    end
end

Features.setWalk = function(v)
    local _, hum = char()
    if hum then hum.WalkSpeed = v end
end

Features.setJump = function(v)
    local _, hum = char()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = v
    end
end

Features.reset = function()
    local _, hum = char()
    if hum then hum.Health = 0 end
end

-- infinite jump
local infJumpOn = false
track(UIS.JumpRequest:Connect(function()
    if not infJumpOn then return end
    local _, hum = char()
    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

Features.infJump = function(on)
    infJumpOn = on
end

-- noclip
local noclipOn = false
local noclipConn
Stops.Noclip = function()
    noclipOn = false
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
end
Features.noclip = function(on)
    noclipOn = on
    if on and not noclipConn then
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipOn then return end
            local c = LP.Character
            if not c then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    elseif not on then
        Stops.Noclip()
    end
end

-- anti-afk
local antiAfkConn
Features.antiAfk = function(on)
    if antiAfkConn then antiAfkConn:Disconnect() antiAfkConn = nil end
    if not on then return end
    antiAfkConn = LP.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
    notify("Anti-AFK armed", "success")
end

-- fly
local fly = { active = false, bv = nil, bg = nil, conn = nil, speed = 50 }

local function flyStop()
    fly.active = false
    if fly.conn then fly.conn:Disconnect() fly.conn = nil end
    if fly.bv then fly.bv:Destroy() fly.bv = nil end
    if fly.bg then fly.bg:Destroy() fly.bg = nil end
    local _, hum = char()
    if hum then hum.PlatformStand = false end
end
Stops.Fly = flyStop

local function flyStart()
    local c, hum = char()
    local hrp = c and c:FindFirstChild("HumanoidRootPart")
    if not (hrp and hum) then
        notify("No character to fly", "error")
        return
    end
    flyStop()
    fly.active = true
    hum.PlatformStand = true

    local bv = new("BodyVelocity", { MaxForce = Vector3.new(1e5, 1e5, 1e5), Velocity = Vector3.zero }, hrp)
    local bg = new("BodyGyro", { MaxTorque = Vector3.new(1e5, 1e5, 1e5), P = 2500, D = 120, CFrame = hrp.CFrame }, hrp)
    fly.bv, fly.bg = bv, bg

    fly.conn = RunService.RenderStepped:Connect(function()
        if not hrp.Parent or not hum.Parent then
            flyStop()
            return
        end
        local cam = workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

        if dir.Magnitude > 0 then
            bv.Velocity = dir.Unit * fly.speed
        else
            bv.Velocity = Vector3.zero
        end
        bg.CFrame = CFrame.new(hrp.Position) * (cam.CFrame - cam.CFrame.Position)
    end)
end

Features.fly = function(on)
    if on then flyStart() else flyStop() end
end
Features.flySpeed = function(v)
    fly.speed = v
end

-- anti void
local voidOn = false
local voidConn
local safePos = nil
Features.antiVoid = function(on)
    voidOn = on
    if voidConn then voidConn:Disconnect() voidConn = nil end
    if not on then return end
    voidConn = RunService.Heartbeat:Connect(function()
        if not voidOn then return end
        local c, hum = char()
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            safePos = hrp.Position
        end
        if hrp.Position.Y < -60 and safePos then
            hrp.CFrame = CFrame.new(safePos + Vector3.new(0, 6, 0))
        end
    end)
end

-- esp
local esp = { on = false, names = false, hi = {}, bb = {}, conn = nil }

local function espClear()
    for plr, inst in pairs(esp.hi) do
        if inst then inst:Destroy() end
        esp.hi[plr] = nil
    end
    for plr, inst in pairs(esp.bb) do
        if inst then inst:Destroy() end
        esp.bb[plr] = nil
    end
end

local function espTick()
    if not esp.on then
        if next(esp.hi) or next(esp.bb) then espClear() end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local c = plr.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local head = c and c:FindFirstChild("Head")
            local hum = c and c:FindFirstChildOfClass("Humanoid")

            if hrp and not esp.hi[plr] then
                esp.hi[plr] = new("Highlight", {
                    FillColor = THEME.Accent,
                    FillTransparency = 0.78,
                    OutlineColor = THEME.Accent,
                    OutlineTransparency = 0.25,
                    DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                    Adornee = c,
                }, c)
            elseif not hrp and esp.hi[plr] then
                esp.hi[plr]:Destroy()
                esp.hi[plr] = nil
            end

            if esp.names and head and not esp.bb[plr] then
                local bb = new("BillboardGui", {
                    Size = UDim2.fromOffset(130, 40),
                    StudsOffset = Vector3.new(0, 2.4, 0),
                    AlwaysOnTop = true,
                    Adornee = head,
                }, head)
                new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 16),
                    BackgroundTransparency = 1,
                    Text = plr.Name,
                    Font = Enum.Font.GothamBold,
                    TextSize = 12,
                    TextColor3 = THEME.Text,
                    TextStrokeTransparency = 0.4,
                }, bb)
                local barBg = new("Frame", {
                    Size = UDim2.new(1, -20, 0, 5),
                    Position = UDim2.fromOffset(10, 18),
                    BackgroundColor3 = THEME.Bg,
                    BorderSizePixel = 0,
                }, bb)
                new("UICorner", { CornerRadius = UDim.new(1, 0) }, barBg)
                local bar = new("Frame", {
                    Size = UDim2.fromScale(1, 1),
                    BackgroundColor3 = THEME.Green,
                    BorderSizePixel = 0,
                }, barBg)
                new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
                bb:SetAttribute("Bar", true)
                esp.bb[plr] = bb
            elseif (not esp.names) and esp.bb[plr] then
                esp.bb[plr]:Destroy()
                esp.bb[plr] = nil
            end

            if esp.bb[plr] and hum then
                local barBg = nil
                for _, child in ipairs(esp.bb[plr]:GetChildren()) do
                    if child:IsA("Frame") then barBg = child break end
                end
                if barBg then
                    local fill = barBg:FindFirstChildOfClass("Frame")
                    if fill then
                        local ratio = clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        fill.Size = UDim2.fromScale(ratio, 1)
                        fill.BackgroundColor3 = THEME.Green:Lerp(THEME.Red, 1 - ratio)
                    end
                end
            end
        end
    end
    for plr, inst in pairs(esp.hi) do
        if not plr.Parent or not plr.Character then
            inst:Destroy()
            esp.hi[plr] = nil
        end
    end
    for plr, inst in pairs(esp.bb) do
        if not plr.Parent or not plr.Character then
            inst:Destroy()
            esp.bb[plr] = nil
        end
    end
end

Features.esp = function(on)
    esp.on = on
    if not on then espClear() end
end
Features.espNames = function(on)
    esp.names = on
    if not on then
        for plr, inst in pairs(esp.bb) do
            inst:Destroy()
            esp.bb[plr] = nil
        end
    end
end
Stops.Esp = function() esp.on = false espClear() end

local espAccum = 0
track(RunService.Heartbeat:Connect(function(dt)
    espAccum = espAccum + (dt or 0)
    if espAccum < 0.4 then return end
    espAccum = 0
    if esp.on then pcall(espTick) end
end))

-- lighting
local lightingBackup = nil
Features.fullbright = function(on)
    if on then
        if not lightingBackup then
            lightingBackup = {
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                Brightness = Lighting.Brightness,
                ClockTime = Lighting.ClockTime,
                FogEnd = Lighting.FogEnd,
            }
        end
        Lighting.Ambient = Color3.fromRGB(190, 190, 190)
        Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e5
    elseif lightingBackup then
        Lighting.Ambient = lightingBackup.Ambient
        Lighting.OutdoorAmbient = lightingBackup.OutdoorAmbient
        Lighting.Brightness = lightingBackup.Brightness
        Lighting.ClockTime = lightingBackup.ClockTime
        Lighting.FogEnd = lightingBackup.FogEnd
        lightingBackup = nil
    end
end
Stops.Lighting = function() Features.fullbright(false) end

Features.fov = function(v)
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = v end
end

-- waypoints
local CFG_DIR = "OJBHub"
local WP_FILE = CFG_DIR .. "/waypoints.json"
local waypoints = {}
local waypointPanel
local renderWaypoints

local function ensureDir()
    if isfolder and makefolder then
        if not isfolder(CFG_DIR) then
            pcall(makefolder, CFG_DIR)
        end
    end
end

local function saveWaypoints()
    ensureDir()
    if not writefile then return end
    pcall(writefile, WP_FILE, HttpService:JSONEncode(waypoints))
end

local function loadWaypoints()
    if not (readfile and isfile) then return end
    if not isfile(WP_FILE) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(WP_FILE))
    end)
    if ok and type(data) == "table" then
        waypoints = data
    end
end

renderWaypoints = function()
    if not waypointPanel then return end
    for _, child in ipairs(waypointPanel:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    if #waypoints == 0 then
        waypointPanel.CanvasSize = UDim2.fromOffset(0, 26)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Text = "   no waypoints saved",
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = THEME.Sub,
        }, waypointPanel)
        return
    end
    for i, wp in ipairs(waypoints) do
        local b = new("TextButton", {
            Size = UDim2.new(1, -8, 0, 26),
            Position = UDim2.fromOffset(4, (i - 1) * 27),
            BackgroundTransparency = 1,
            Text = "  " .. tostring(wp.name),
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = THEME.Text,
            AutoButtonColor = false,
        }, waypointPanel)
        b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.9 b.BackgroundColor3 = THEME.Accent end)
        b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
        b.MouseButton1Click:Connect(function()
            local hrp = root()
            if hrp then
                hrp.CFrame = CFrame.new(Vector3.new(wp.x, wp.y, wp.z) + Vector3.new(0, 3, 0))
                notify("Teleported: " .. tostring(wp.name), "success")
            end
        end)
        local del = new("TextButton", {
            Size = UDim2.fromOffset(22, 22),
            Position = UDim2.new(1, -26, 0.5, -11),
            BackgroundTransparency = 1,
            Text = "x",
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = THEME.Red,
            AutoButtonColor = false,
        }, b)
        del.MouseButton1Click:Connect(function()
            table.remove(waypoints, i)
            saveWaypoints()
            renderWaypoints()
        end)
    end
    waypointPanel.CanvasSize = UDim2.fromOffset(0, #waypoints * 27 + 6)
end

local function addWaypoint(name)
    local hrp = root()
    if not hrp then
        notify("No character", "error")
        return
    end
    if name == "" then
        notify("Give the waypoint a name", "error")
        return
    end
    table.insert(waypoints, { name = name, x = hrp.Position.X, y = hrp.Position.Y, z = hrp.Position.Z })
    saveWaypoints()
    renderWaypoints()
    notify("Saved: " .. name, "success")
end

-- teleport
Features.tpMouse = function()
    local hrp = root()
    local mouse = LP:GetMouse()
    if hrp and mouse.Hit then
        hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        notify("Teleported to cursor", "success")
    end
end

Features.tpPlayer = function(name)
    local target = Players:FindFirstChild(name)
    if not target then
        notify("Player not found", "error")
        return
    end
    local theirHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = root()
    if theirHrp and myHrp then
        myHrp.CFrame = theirHrp.CFrame + Vector3.new(0, 0, 3)
        notify("Teleported to " .. name, "success")
    else
        notify("Target has no character", "error")
    end
end

local function playerNames()
    local out = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then table.insert(out, plr.Name) end
    end
    return out
end

-- server
Features.rejoin = function()
    notify("Rejoining...", "info")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
end

Features.hop = function()
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100",
        game.PlaceId
    )
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)
    if not ok or type(decoded) ~= "table" or not decoded.data then
        notify("Server list failed", "error")
        return
    end
    local pick = nil
    for _, srv in ipairs(decoded.data) do
        if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
            pick = srv
            break
        end
    end
    if not pick then
        notify("No open server found", "error")
        return
    end
    notify("Hopping to " .. tostring(pick.playing) .. "/" .. tostring(pick.maxPlayers), "info")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, pick.id, LP)
end

Features.joinJob = function(jobId)
    if not jobId or jobId == "" then
        notify("Paste a JobId first", "error")
        return
    end
    notify("Joining instance...", "info")
    TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LP)
end

Features.copyJob = function()
    if copy(game.JobId) then
        notify("JobId copied", "success")
    else
        notify("Clipboard unavailable", "error")
    end
end

Features.copyPlace = function()
    if copy(tostring(game.PlaceId)) then
        notify("PlaceId copied", "success")
    else
        notify("Clipboard unavailable", "error")
    end
end

-- ============================================================
-- PAGES
-- ============================================================
local pages = {}
local tabButtons = {}
local selectedTab

local function addTab(name, glyph)
    local page = makePage()
    pages[name] = page

    local idx = #tabButtons + 1
    local btn = new("TextButton", {
        Size = UDim2.new(1, -16, 0, 32),
        Position = UDim2.fromOffset(8, 8 + (idx - 1) * 36),
        BackgroundColor3 = THEME.Row,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, rail)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)

    local marker = new("Frame", {
        Size = UDim2.fromOffset(3, 16),
        Position = UDim2.fromOffset(0, 8),
        BackgroundColor3 = THEME.Accent,
        BorderSizePixel = 0,
        Visible = false,
    }, btn)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, marker)

    local label = new("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.fromOffset(16, 0),
        BackgroundTransparency = 1,
        Text = glyph .. "   " .. name,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = THEME.Sub,
    }, btn)

    btn.MouseEnter:Connect(function()
        if selectedTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.9, BackgroundColor3 = THEME.Accent }):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if selectedTab ~= name then
            TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play()
        end
    end)

    btn.MouseButton1Click:Connect(function()
        for tabName, p in pairs(pages) do
            p.frame.Visible = (tabName == name)
        end
        for tabName, b in pairs(tabButtons) do
            local isSel = (tabName == name)
            b.btn.BackgroundTransparency = isSel and 0.82 or 1
            b.btn.BackgroundColor3 = THEME.Accent
            b.label.TextColor3 = isSel and THEME.Text or THEME.Sub
            b.marker.Visible = isSel
        end
        selectedTab = name
    end)

    tabButtons[name] = {
        btn = btn,
        marker = marker,
        label = label,
    }

    if not selectedTab then
        selectedTab = name
        page.frame.Visible = true
        btn.BackgroundTransparency = 0.82
        btn.BackgroundColor3 = THEME.Accent
        marker.Visible = true
        label.TextColor3 = THEME.Text
    end

    return page
end

-- ---------- MAIN ----------
local main = addTab("Main", "◈")
addSection(main, "Character")
addSlider(main, "Walk Speed", 16, 200, 16, 1, "walkSpeed", function(v) Features.setWalk(v) end)
addSlider(main, "Jump Power", 50, 300, 50, 1, "jumpPower", function(v) Features.setJump(v) end)
addToggle(main, "Infinite Jump", false, "infJump", function(v) Features.infJump(v) end)
addToggle(main, "Noclip", false, "noclip", function(v) Features.noclip(v) end)
addToggle(main, "Anti-AFK", false, "antiAfk", function(v) Features.antiAfk(v) end)
addToggle(main, "Anti-Void", false, "antiVoid", function(v) Features.antiVoid(v) end)
addButton(main, "Reset Character", THEME.Red, function() Features.reset() end)

addSection(main, "Flight")
addToggle(main, "Fly", false, "fly", function(v) Features.fly(v) end)
addSlider(main, "Fly Speed", 10, 300, 50, 1, "flySpeed", function(v) Features.flySpeed(v) end)

-- ---------- VISUALS ----------
local vis = addTab("Visuals", "◉")
addSection(vis, "Players")
addToggle(vis, "Player ESP", false, "esp", function(v) Features.esp(v) end)
addToggle(vis, "ESP Names + Health", false, "espNames", function(v) Features.espNames(v) end)
addSection(vis, "Environment")
addToggle(vis, "Fullbright", false, "fullbright", function(v) Features.fullbright(v) end)
addSlider(vis, "Camera FOV", 70, 120, 70, 1, "fov", function(v) Features.fov(v) end)

-- ---------- TELEPORT ----------
local tp = addTab("Teleport", "◎")
addSection(tp, "Waypoints")
local wpName = addTextbox(tp, "Name", "spawn", "wpName")
addButton(tp, "Save Current Position", THEME.Text, function()
    addWaypoint(wpName.Text)
end)
waypointPanel = addPanel(tp, 150)
addSection(tp, "Targets")
addDropdown(tp, "Player", playerNames, "-", "tpTarget", function(v) Features.tpPlayer(v) end)
addButton(tp, "Teleport To Player", THEME.Text, function()
    if Flags.tpTarget and Flags.tpTarget ~= "-" then
        Features.tpPlayer(Flags.tpTarget)
    else
        notify("Pick a player first", "error")
    end
end)
addButton(tp, "Teleport To Cursor", THEME.Text, function() Features.tpMouse() end)

-- ---------- MISC ----------
local misc = addTab("Misc", "◍")
addSection(misc, "Server")
addButton(misc, "Rejoin", THEME.Text, function() Features.rejoin() end)
addButton(misc, "Server Hop", THEME.Text, function() Features.hop() end)
local jobBox = addTextbox(misc, "JobId", "paste job id", "jobId")
addButton(misc, "Join Instance", THEME.Text, function() Features.joinJob(jobBox.Text) end)
addButton(misc, "Copy JobId", THEME.Text, function() Features.copyJob() end)
addButton(misc, "Copy PlaceId", THEME.Text, function() Features.copyPlace() end)

-- ---------- SETTINGS ----------
local set = addTab("Settings", "⚙")
addSection(set, "Interface")
addSlider(set, "UI Transparency", 0, 60, 0, 5, "uiAlpha", function(v)
    gui.Enabled = true
    for _, inst in ipairs(window:GetDescendants()) do
        if inst:IsA("Frame") or inst:IsA("TextButton") or inst:IsA("ScrollingFrame") then
            if inst.BackgroundTransparency < 0.99 and inst.Name ~= "Knob" then
                inst:SetAttribute("BaseTransparency", inst:GetAttribute("BaseTransparency") or inst.BackgroundTransparency)
                inst.BackgroundTransparency = clamp(inst:GetAttribute("BaseTransparency") + v / 100, 0, 0.95)
            end
        end
    end
end)
addToggle(set, "Notifications", true, "notifications", function(v) notifyOn = v end)
addKeybind(set, "Menu Key", Enum.KeyCode.RightShift, "menuKey", function(key) menuKey = key end)

addSection(set, "Config")
local cfgName = addTextbox(set, "Config Name", "default", "configName")
addButton(set, "Save Config", THEME.Text, function() Features.saveConfig(cfgName.Text) end)
addButton(set, "Load Config", THEME.Text, function() Features.loadConfig(cfgName.Text) end)
addButton(set, "Delete Config", THEME.Red, function() Features.deleteConfig(cfgName.Text) end)
addButton(set, "Unload Hub", THEME.Red, function() Features.unload() end)

for _, page in pairs(pages) do
    flush(page)
end

-- ============================================================
-- CONFIG IO
-- ============================================================
local function cfgPath(name)
    name = (name and name ~= "") and name or "default"
    name = name:gsub("[^%w_%-]", "")
    if name == "" then name = "default" end
    return CFG_DIR .. "/" .. name .. ".json"
end

Features.saveConfig = function(name)
    if not writefile then
        notify("Executor has no writefile", "error")
        return
    end
    ensureDir()
    local ok = pcall(writefile, cfgPath(name), HttpService:JSONEncode(Flags))
    notify(ok and ("Saved " .. cfgPath(name)) or "Save failed", ok and "success" or "error")
end

Features.loadConfig = function(name)
    if not (readfile and isfile) then
        notify("Executor has no readfile", "error")
        return
    end
    local path = cfgPath(name)
    if not isfile(path) then
        notify("No config: " .. path, "error")
        return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    if not ok or type(data) ~= "table" then
        notify("Config is corrupt", "error")
        return
    end
    for key, value in pairs(data) do
        if Setters[key] then
            pcall(Setters[key], value)
        end
    end
    notify("Loaded " .. path, "success")
end

Features.deleteConfig = function(name)
    if not delfile then
        notify("Executor has no delfile", "error")
        return
    end
    local path = cfgPath(name)
    local ok = pcall(delfile, path)
    notify(ok and ("Deleted " .. path) or "Delete failed", ok and "success" or "error")
end

-- ============================================================
-- UNLOAD
-- ============================================================
Features.unload = function()
    notifyOn = false
    for _, stop in pairs(Stops) do
        pcall(stop)
    end
    for _, c in ipairs(Conns) do
        pcall(function() c:Disconnect() end)
    end
    Conns = {}

    local _, hum = char()
    if hum then
        hum.WalkSpeed = baseWalk
        hum.JumpPower = baseJump
        hum.UseJumpPower = true
    end
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = baseFov end

    if notifHolder then notifHolder:Destroy() end
    if gui then gui:Destroy() end
    getgenv().OJBHub = nil
end

-- ============================================================
-- DRAG + MENU KEY
-- ============================================================
do
    local dragging = false
    local dragStart, startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    track(UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
end

local minimized = false
local minBtn, closeBtn

minBtn = topButton("–", -66, THEME.Sub, function()
    minimized = not minimized
    if minimized then
        rail.Visible = false
        pageHolder.Visible = false
        TweenService:Create(window, TweenInfo.new(0.18), { Size = UDim2.fromOffset(WIN_W, TOP_H) }):Play()
        minBtn.Text = "+"
    else
        rail.Visible = true
        pageHolder.Visible = true
        TweenService:Create(window, TweenInfo.new(0.18), { Size = UDim2.fromOffset(WIN_W, WIN_H) }):Play()
        minBtn.Text = "–"
    end
end)

closeBtn = topButton("×", -32, THEME.Red, function()
    Features.unload()
end)

track(UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == menuKey then
        window.Visible = not window.Visible
    end
end))

-- ============================================================
-- BOOT
-- ============================================================
loadWaypoints()
renderWaypoints()

getgenv().OJBHub = {
    Version = VERSION,
    Unload = Features.unload,
    Flags = Flags,
    Features = Features,
}

notify("OJB HUB v" .. VERSION .. " loaded", "success")
notify("RightShift toggles the menu", "info")

print("[OJB HUB] v" .. VERSION .. " ready | " .. tostring(game.PlaceId))
