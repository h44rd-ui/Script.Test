
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local TextChatService = game:GetService("TextChatService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local clock, clear, insert, remove = os.clock, table.clear, table.insert, table.remove
local spawn, defer, wait_ = task.spawn, task.defer, task.wait
local function try(fn, ...) local ok, a, b = pcall(fn, ...) return ok, a, b end
local function clamp(v, lo, hi) if v < lo then return lo end; if v > hi then return hi end; return v end

local IsTouch     = UserInputService.TouchEnabled
local HasKeyboard = UserInputService.KeyboardEnabled
local IsMobile    = IsTouch and not HasKeyboard

local TPS_FOLDER_NAME, TPS_NAME = "WorkspaceLeaderboards", "TPS"
local CATCH_REMOTE_NAME = "CatchBall"
local BALL_NAMES = { TPS = true, PSoccerBall = true }
local TPS_CACHE_TTL, NEAREST_BALL_TTL, EQUIPPED_TOOL_TTL = 1.0, 0.008, 0.05
local GK_TOUCH_COOLDOWN, HITBOX_COOLDOWN, REACH_DEBOUNCE = 0.6, 0.08, 0.1
local REACH_LEAD_S, REACH_LEAD_MAX, HINT_TTL = 0.06, 3.0, 0.20

local State = { Character = nil, Humanoid = nil, HRP = nil, Ready = false }
local function refreshState(char)
    char = char or LocalPlayer.Character
    State.Character = char
    State.Humanoid  = char and char:FindFirstChildOfClass("Humanoid")
    State.HRP       = char and char:FindFirstChild("HumanoidRootPart")
    State.Ready     = State.Humanoid ~= nil and State.HRP ~= nil
end
local onCharacterAdded, onCharacterRemoving = {}, {}
local function fireHandlers(list, char) for i = 1, #list do defer(list[i], char) end end
local _charGen = 0
LocalPlayer.CharacterAdded:Connect(function(c)
    _charGen += 1; local gen = _charGen
    refreshState(c); c:WaitForChild("Humanoid", 15); c:WaitForChild("HumanoidRootPart", 15)
    if gen ~= _charGen then return end
    refreshState(c); fireHandlers(onCharacterAdded, c)
end)
LocalPlayer.CharacterRemoving:Connect(function(c)
    fireHandlers(onCharacterRemoving, c)
    if c == State.Character then
        State.Character, State.Humanoid, State.HRP, State.Ready = nil, nil, nil, false
    end
end)
refreshState()

local BG_ASSET = "rbxassetid://93633918862061"
local ICON_ASSET = "rbxassetid://90533551558606"
local _version = "1.6.66"
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/" .. _version .. "/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "Lua - The Classic", Icon = ICON_ASSET, Author = "Lua",
    Folder = "Luatcs", Size = UDim2.fromOffset(580, 480),
    Transparent = true, Theme = "Dark", Background = BG_ASSET,
})
local ConfigManager = Window.ConfigManager
local uiConfig = ConfigManager:CreateConfig("Luatcs")
local AutoSaveEnabled = false

local KeybindManager = { actions = {}, inputConn = nil }
local UNKNOWN_KEY = "Unknown"
local function resolveKeyCode(v)
    if not v then return nil end
    if type(v) == "string" then return Enum.KeyCode[v] end
    if typeof(v) == "EnumItem" then return v end
    return nil
end
function KeybindManager.register(actionName, defaultKey, callback)
    KeybindManager.actions[actionName] = { key = defaultKey or UNKNOWN_KEY, callback = callback, enabled = true }
end
function KeybindManager.setKey(actionName, newKey)
    local a = KeybindManager.actions[actionName]
    if a then a.key = newKey or UNKNOWN_KEY end
end
KeybindManager.inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    local keyName = input.KeyCode.Name
    for actionName, a in pairs(KeybindManager.actions) do
        if a.key and a.key ~= UNKNOWN_KEY and a.key == keyName and a.callback then
            pcall(a.callback, actionName, keyName)
        end
    end
end)

local _notifyWarned = false
local function Notify(args)
    local ok, err = pcall(function()
        local fn = Window.Notify
        if type(fn) == "function" then fn(Window, args); return end
        if type(Window.notify) == "function" then Window:notify(args) end
    end)
    if not ok and not _notifyWarned then _notifyWarned = true; warn("[Luatcs] Notify failed:", err) end
end
local _configChangeQueued = false
local function onConfigChanged()
    if not AutoSaveEnabled then return end
    if _configChangeQueued then return end
    _configChangeQueued = true
    defer(function() wait_(0.6); _configChangeQueued = false; pcall(function() uiConfig:Save() end) end)
end

local getViewportSize, getSafeTopInset, getButtonSize, reflow
local createMobileButton, destroyMobileButton, applyButtonState
local addBall, removeBall, isTrackedBallPart, getNearestBall, scanBalls
local setTPSCache, resolveTPS, FindTPS
local GetPosition, GetBallPart, ensureOwnership, UpdateESP
local destroyTrajectoryPredict, updateTrajectoryPredict, updatePredictAppearance
local joystickApplyMovement, joystickSetKnob, hideDefaultJoystick, showDefaultJoystick
local CustomJoystick_create, CustomJoystick_destroy
local getNearestAimbotGoal, hasShootTool, resetAimbotState, bindAimbotTouch, detectAimbotShot
local setAimbotGoal, setTelekinesis
local GetShoot, EquipShoot, Shoot, RunShoot, RunAutoGoalGen, setAutoGoal
local applyStretch, refreshStretchState
local getEquippedToolName, ballIsFreeOrMine
local fireTouch, forceLegTouch, forceGKTouch, forceTouchDispatch
local updateOverlapExclude, findTarget
local destroyReachVisualizer, destroyAllReachVisualizers, createStaticReachVisualizer, ReachVisualizer_updateAll
local scheduleReachUpdate, fireCatchBall
local resetPendingDecision, resetDivePrediction, runAutoDiveTick, decideGKAction
local resetPredState, computePredicted, acquireFollowTarget, stopFollow, startFollow, setFollow
local sendGlobalMessage
local bcFindMesh, bcGetOrCreateMesh, bcSetMeshId, bcGetOrCreateTextures, bcSetTextures, bcToAssetId, bcGetBall, bcAutoApply, applyBallCustom

local CustomJoystick = {
    Enabled = false, Gui = nil, Base = nil, Knob = nil, TouchId = nil,
    BaseCenter = nil, CurrentOffset = Vector2.new(0, 0),
    Size = 130, KnobSize = 60, MoveConn = nil, ConnList = {},
}
local MobileButtons = {
    registry = {}, order = {}, baseX = 20, baseY = 200, spacing = 68,
    refSize = Vector2.new(130, 58),
    colors = {
        offBG = Color3.fromRGB(30, 32, 46), onBG = Color3.fromRGB(35, 115, 75),
        offStroke = Color3.fromRGB(100, 100, 130), onStroke = Color3.fromRGB(80, 255, 130),
    },
}

--// MOBILE BUTTON ENGINE
do
    function getViewportSize()
        local cam = Workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1920, 1080)
    end
    function getSafeTopInset() return UserInputService.TouchEnabled and 44 or 0 end
    function getButtonSize()
        local vp = getViewportSize()
        local scale = clamp(math.min(vp.X / 1280, vp.Y / 720), 0.8, 1)
        return Vector2.new(math.floor(MobileButtons.refSize.X * scale), math.floor(MobileButtons.refSize.Y * scale))
    end
    local function computeSlotPosition(idx, _size)
        local vp = getViewportSize()
        local yPx = vp.Y - (MobileButtons.baseY + (idx - 1) * MobileButtons.spacing)
        return UDim2.fromOffset(MobileButtons.baseX, math.max(getSafeTopInset(), yPx))
    end
    function reflow()
        for i, name in ipairs(MobileButtons.order) do
            local data = MobileButtons.registry[name]
            if data and data.btn and data.btn.Parent then
                local sz = data.size or getButtonSize()
                if not data.userMoved then
                    data.btn.Position = computeSlotPosition(i, sz)
                else
                    local vp = getViewportSize()
                    local x, y = data.btn.Position.X.Offset, data.btn.Position.Y.Offset
                    data.btn.Position = UDim2.fromOffset(clamp(x, 0, vp.X - sz.X), clamp(y, getSafeTopInset(), vp.Y - sz.Y))
                end
            end
        end
    end
    local function disconnectAll(conns)
        if not conns then return end
        for i = #conns, 1, -1 do pcall(function() conns[i]:Disconnect() end); conns[i] = nil end
    end
    function applyButtonState(data, on, onText, offText)
        if not data or not data.btn then return end
        data.label.Text = on and onText or offText
        local c = MobileButtons.colors
        local targetTrans = on and 0.55 or 0.1
        TweenService:Create(data.btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on and c.onBG or c.offBG,
            BackgroundTransparency = targetTrans,
        }):Play()
        TweenService:Create(data.stroke, TweenInfo.new(0.15), { Color = on and c.onStroke or c.offStroke }):Play()
    end
    function destroyMobileButton(guiName)
        local data = MobileButtons.registry[guiName]
        if data then
            disconnectAll(data.conns)
            if data.gui then data.gui:Destroy() end
            MobileButtons.registry[guiName] = nil
            local idx = table.find(MobileButtons.order, guiName)
            if idx then remove(MobileButtons.order, idx) end
        else
            local g = PlayerGui:FindFirstChild(guiName); if g then g:Destroy() end
        end
        reflow()
    end
    function createMobileButton(guiName, text, onToggle)
        destroyMobileButton(guiName)
        local btnSize = getButtonSize()
        local sg = Instance.new("ScreenGui")
        sg.Name, sg.ResetOnSpawn, sg.IgnoreGuiInset = guiName, false, true
        sg.DisplayOrder, sg.ZIndexBehavior = 1000, Enum.ZIndexBehavior.Sibling
        sg.Parent = PlayerGui
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(btnSize.X, btnSize.Y)
        btn.BackgroundColor3 = MobileButtons.colors.offBG
        btn.BackgroundTransparency = 0.1
        btn.BorderSizePixel, btn.AutoButtonColor, btn.Text = 0, false, ""
        btn.ClipsDescendants = true
        btn.ZIndex = 0
        btn.Parent = sg
        if BG_ASSET and BG_ASSET ~= "" then
            local bg = Instance.new("ImageLabel")
            bg.Name = "FlowBG"; bg.Size = UDim2.fromScale(1, 1)
            bg.BackgroundTransparency = 1; bg.Image = BG_ASSET
            bg.ImageTransparency = 0.25; bg.ScaleType = Enum.ScaleType.Crop; bg.ZIndex = 1
            bg.Parent = btn
            Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 12)
        end
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
        local grad = Instance.new("UIGradient", btn)
        grad.Name = "FlowGrad"; grad.Rotation = 90
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 65, 90)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 32, 46)),
        })
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.35),
        })
        grad.Parent = btn
        local stroke = Instance.new("UIStroke", btn)
        stroke.Name = "FlowStroke"; stroke.Thickness = 1.5
        stroke.Color = MobileButtons.colors.offStroke; stroke.Transparency = 0.3
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual; stroke.Parent = btn
        local label = Instance.new("TextLabel", btn)
        label.Name = "FlowLabel"
        label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
        label.Text = text; label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize, label.Font, label.TextWrapped = 13, Enum.Font.GothamBold, true
        label.TextStrokeTransparency = 0.5; label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        label.ZIndex = 3; label.Parent = btn
        local conns = {}; local dragging, moved, activeInput, dragStart, startPos = false, false, nil, nil, nil
        local function add(c) conns[#conns + 1] = c end
        add(btn.InputBegan:Connect(function(input)
            local t = input.UserInputType
            if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
                dragging, moved, activeInput = true, false, input
                dragStart = input.Position
                startPos = Vector2.new(btn.Position.X.Offset, btn.Position.Y.Offset)
            end
        end))
        add(UserInputService.InputChanged:Connect(function(input)
            if not dragging or activeInput ~= input then return end
            local delta = input.Position - dragStart
            if not moved then
                if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then moved = true else return end
            end
            local vp = getViewportSize(); local w, h, top = btnSize.X, btnSize.Y, getSafeTopInset()
            btn.Position = UDim2.fromOffset(clamp(startPos.X + delta.X, -w/2, vp.X - w/2), clamp(startPos.Y + delta.Y, top, vp.Y - h/2))
        end))
        add(UserInputService.InputEnded:Connect(function(input)
            if activeInput == input then dragging = false; activeInput = nil end
        end))
        add(btn.Activated:Connect(function()
            if moved then moved = false; return end
            onToggle()
        end))
        local idx = #MobileButtons.order + 1
        MobileButtons.order[idx] = guiName
        btn.Position = computeSlotPosition(idx, btnSize)
        local data = { gui = sg, btn = btn, label = label, stroke = stroke, conns = conns, userMoved = false, size = btnSize }
        MobileButtons.registry[guiName] = data
        return sg, data
    end
end

defer(function()
    for _, t in ipairs({ 0.25, 0.75, 2.0 }) do
        wait_(t)
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, d in ipairs(gui:GetDescendants()) do
                    if d:IsA("ImageLabel") and d.Image == ICON_ASSET then
                        try(function() d.Size = UDim2.fromOffset(32, 32); d.ScaleType = Enum.ScaleType.Fit; d.AnchorPoint = Vector2.new(0, 0.5) end)
                    end
                end
            end
        end
    end
end)

local Tabs = {}
Tabs.Home        = Window:Tab({ Title = "Home", Icon = "home" })
Tabs.Reach       = Window:Tab({ Title = "Reach", Icon = "box" })
Tabs.GK          = Window:Tab({ Title = "GK", Icon = "shield" })
Tabs.Aimbot      = Window:Tab({ Title = "Aimbot", Icon = "target" })
Tabs.BallESP     = Window:Tab({ Title = "Ball ESP", Icon = "eye" })
Tabs.Chars       = Window:Tab({ Title = "Chars", Icon = "user" })
Tabs.Kits        = Window:Tab({ Title = "Kits", Icon = "shirt" })
Tabs.Helper      = Window:Tab({ Title = "Helper", Icon = "wrench" })
Tabs.Misc        = Window:Tab({ Title = "Misc", Icon = "zap" })
Tabs.SkinChanger = Window:Tab({ Title = "Skin Changer", Icon = "palette" })
Tabs.Settings    = Window:Tab({ Title = "Settings", Icon = "settings" })

local ballSet, ballList = {}, {}
function addBall(b) if ballSet[b] then return end; ballSet[b] = true; insert(ballList, b) end
function removeBall(b)
    if not ballSet[b] then return end
    ballSet[b] = nil
    for i = #ballList, 1, -1 do if ballList[i] == b then remove(ballList, i); break end end
end
function isTrackedBallPart(d) return d and d:IsA("BasePart") and BALL_NAMES[d.Name] end
function scanBalls()
    clear(ballSet); clear(ballList)
    for _, d in ipairs(Workspace:GetDescendants()) do if isTrackedBallPart(d) then addBall(d) end end
end
scanBalls()
do
    local cache = { ball = nil, dist = math.huge, stamp = 0 }
    function getNearestBall()
        local now = clock()
        if now - cache.stamp < NEAREST_BALL_TTL then return cache.ball, cache.dist end
        cache.stamp = now
        local hrp = State.HRP
        if not hrp then cache.ball, cache.dist = nil, math.huge; return nil, math.huge end
        local hrpPos = hrp.Position
        local best, bestDistSq = nil, math.huge
        for i = 1, #ballList do
            local ball = ballList[i]
            if ball and ball.Parent then
                local delta = hrpPos - ball.Position
                local d2 = delta:Dot(delta)
                if d2 < bestDistSq then bestDistSq, best = d2, ball end
            end
        end
        cache.ball = best
        cache.dist = best and math.sqrt(bestDistSq) or math.huge
        return best, cache.dist
    end
end

local ESPBall = false
local CurrentTPS = nil
local ESPBallColor = Color3.fromRGB(255, 80, 80)
local ESPHighlight = Instance.new("Highlight")
ESPHighlight.Name = "TPS_ESP"
ESPHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
ESPHighlight.FillColor = ESPBallColor
ESPHighlight.OutlineColor = ESPBallColor
ESPHighlight.FillTransparency = 0.35
ESPHighlight.OutlineTransparency = 0
ESPHighlight.Enabled = false
ESPHighlight.Parent = CoreGui

do
    local _tpsCacheState = { obj = nil, nextSearch = 0 }
    function setTPSCache(tps) _tpsCacheState.obj = tps; _tpsCacheState.nextSearch = clock() + TPS_CACHE_TTL end
    function resolveTPS()
        if _tpsCacheState.obj and _tpsCacheState.obj.Parent then return _tpsCacheState.obj end
        _tpsCacheState.obj = nil
        local now = clock()
        if now < _tpsCacheState.nextSearch then return nil end
        _tpsCacheState.nextSearch = now + TPS_CACHE_TTL
        local folder = Workspace:FindFirstChild(TPS_FOLDER_NAME)
        if folder then
            local tps = folder:FindFirstChild(TPS_NAME)
            if tps then _tpsCacheState.obj = tps; return tps end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name == TPS_NAME then _tpsCacheState.obj = obj; return obj end
        end
        return nil
    end
    FindTPS = resolveTPS
end

function GetPosition(Object)
    if not Object or not Object.Parent then return nil end
    if Object:IsA("BasePart") then return Object.Position end
    if Object:IsA("Model") then return Object:GetPivot().Position end
    return nil
end
function GetBallPart(Object)
    if not Object or not Object.Parent then return nil end
    if Object:IsA("BasePart") then return Object end
    if Object:IsA("Model") then return Object.PrimaryPart or Object:FindFirstChildWhichIsA("BasePart", true) end
    return nil
end
--// BALL FEATURES (replaced with the working implementation)
local SilentAim = false
local PowerShoot = false
local MoreCurve = false
local AimStrength = 0.12
local MaxAngle = 40
local ShootPower = 150
local CurvePower = 35
local FlingBallForce = 300

local function FindFeatureTPS()
    local folder = Workspace:FindFirstChild("WorkspaceLeaderboards")
    if folder then
        local tps = folder:FindFirstChild("TPS")
        if tps then return tps end
    end
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object.Name == "TPS" then
            return object
        end
    end
    return nil
end

local function GetValidBall()
    local object = FindFeatureTPS()
    if not object or not object.Parent then return nil end
    if object:IsA("BasePart") then return object end
    if object:IsA("Model") then
        return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
    end
    return nil
end

local function ApplySilentAim()
    if not SilentAim then return end
    local ball = GetValidBall()
    local rootPart = State.HRP
    if not ball or not rootPart or not rootPart.Parent then return end

    local direction = ball.Position - rootPart.Position
    if direction.Magnitude <= 0 then return end

    local currentLook = rootPart.CFrame.LookVector
    local targetLook = direction.Unit
    local dot = math.clamp(currentLook:Dot(targetLook), -1, 1)
    local angle = math.deg(math.acos(dot))
    if angle > MaxAngle then return end

    local newDirection = currentLook:Lerp(targetLook, AimStrength)
    if newDirection.Magnitude > 0 then
        rootPart.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + newDirection)
    end
end

local function ApplyPower()
    if not PowerShoot then return end
    local ball = GetValidBall()
    local rootPart = State.HRP
    if not ball or not rootPart or not rootPart.Parent then return end

    local distance = (ball.Position - rootPart.Position).Magnitude
    if distance > 10 then return end

    local camera = Workspace.CurrentCamera
    if not camera then return end
    ball.AssemblyLinearVelocity = camera.CFrame.LookVector * ShootPower
end

local function ApplyCurve()
    if not MoreCurve then return end
    local ball = GetValidBall()
    if not ball then return end

    local velocity = ball.AssemblyLinearVelocity
    if velocity.Magnitude < 1 then return end

    local camera = Workspace.CurrentCamera
    if not camera then return end

    local side = camera.CFrame.RightVector
    local curve = Vector3.new(side.X, 0, side.Z)
    if curve.Magnitude > 0 then
        ball.AssemblyLinearVelocity = velocity + curve.Unit * CurvePower
    end
end

local function FlingBall()
    local ball = GetValidBall()
    local rootPart = State.HRP
    if not ball or not rootPart or not rootPart.Parent then return end

    local direction = ball.Position - rootPart.Position
    if direction.Magnitude <= 0 then return end
    ball.AssemblyLinearVelocity = direction.Unit * FlingBallForce
end

function ensureOwnership(part)
    if not part or not part.Parent then return false end
    if part.Anchored then pcall(function() part.Anchored = false end) end
    local ok = pcall(function() part:SetNetworkOwner(LocalPlayer) end)
    if not ok then pcall(function() part:SetNetworkOwnershipAuto() end) end
    return true
end
function UpdateESP()
    if not CurrentTPS or not CurrentTPS.Parent then
        ESPHighlight.Adornee = nil; ESPHighlight.Enabled = false; return
    end
    if ESPBall then ESPHighlight.Adornee = CurrentTPS; ESPHighlight.Enabled = true
    else ESPHighlight.Adornee = nil; ESPHighlight.Enabled = false end
end

--// PREDICT (mesmo do anterior)
local PredictEnabled = false
local PredictColor = Color3.fromRGB(255, 255, 255)
local PredictParts, PredictLandingParts, PredictFolder = {}, {}, nil
do
    local PredictCount, PredictSpacing, PredictArrowGap = 28, 0.075, 1.05
    local PredictTransparency, PredictStopSpeed = 0.05, 2.25
    local PredictArrowLength, PredictArrowWidth, PredictArrowSpread = 0.96, 0.17, 0.34
    local LandingMarkerHalfSize, LandingMarkerCornerSize = 1.02, 0.48
    local LandingMarkerWidth, LandingMarkerLift = 0.115, 0.085
    local PredictLastBall, PredictLastVel, PredictLastAccel, PredictLastTime = nil, nil, Vector3.zero, 0
    local PredictPoints = {}
    local PredictRayParams = RaycastParams.new(); local PredictRayFilter = {}
    PredictRayParams.FilterType = Enum.RaycastFilterType.Exclude
    PredictRayParams.IgnoreWater = true
    function destroyTrajectoryPredict()
        if PredictFolder then pcall(function() PredictFolder:Destroy() end); PredictFolder = nil end
        clear(PredictParts); clear(PredictLandingParts)
        PredictLastBall, PredictLastVel = nil, nil
        PredictLastAccel, PredictLastTime = Vector3.zero, 0
    end
    local function ensureTrajectoryFolder()
        if PredictFolder and PredictFolder.Parent then return PredictFolder end
        local folder = Instance.new("Folder"); folder.Name = "Lua_TrajectoryPredict"; folder.Parent = Workspace
        PredictFolder = folder; return folder
    end
    local function hidePredictParts(fromIndex)
        fromIndex = math.max(1, tonumber(fromIndex) or 1)
        for i = fromIndex, #PredictParts do local p = PredictParts[i]; if p and p.Parent then p.Transparency = 1 end end
        for i = 1, #PredictLandingParts do local p = PredictLandingParts[i]; if p and p.Parent then p.Transparency = 1 end end
    end
    local function makePredictPart(index)
        local p = PredictParts[index]; if p and p.Parent then return p end
        p = Instance.new("Part")
        p.Name = "PredictArrowPart_" .. tostring(index)
        p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
        p.CastShadow = false; p.Material = Enum.Material.Neon
        p.Color = PredictColor; p.Transparency = PredictTransparency
        p.Size = Vector3.new(PredictArrowLength, PredictArrowWidth, PredictArrowWidth)
        p.Parent = ensureTrajectoryFolder(); PredictParts[index] = p; return p
    end
    local function makeLandingPart(index)
        local p = PredictLandingParts[index]; if p and p.Parent then return p end
        p = Instance.new("Part")
        p.Name = "PredictLandingPart_" .. tostring(index)
        p.Anchored = true; p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
        p.CastShadow = false; p.Material = Enum.Material.Neon
        p.Color = PredictColor; p.Transparency = 1
        p.Size = Vector3.new(LandingMarkerWidth, LandingMarkerWidth, LandingMarkerWidth)
        p.Parent = ensureTrajectoryFolder(); PredictLandingParts[index] = p; return p
    end
    local function setBeamBetween(part, a, b, width, depth)
        local delta = b - a; local length = delta.Magnitude
        if length < 0.001 then part.Transparency = 1; return end
        local direction = delta / length
        local referenceUp = Vector3.new(0, 1, 0)
        if math.abs(direction:Dot(referenceUp)) > 0.985 then referenceUp = Vector3.new(0, 0, 1) end
        local side = direction:Cross(referenceUp)
        if side.Magnitude < 0.001 then side = Vector3.new(1, 0, 0) else side = side.Unit end
        local up = side:Cross(direction)
        if up.Magnitude < 0.001 then up = Vector3.new(0, 1, 0) else up = up.Unit end
        part.Size = Vector3.new(length, width, depth)
        part.CFrame = CFrame.fromMatrix((a + b) * 0.5, direction, up, side)
    end
    local function setChevron(index, position, direction, fade)
        if direction.Magnitude < 0.001 then return end
        direction = direction.Unit
        local referenceUp = Vector3.new(0, 1, 0)
        if math.abs(direction:Dot(referenceUp)) > 0.985 then referenceUp = Vector3.new(0, 0, 1) end
        local right = direction:Cross(referenceUp)
        if right.Magnitude < 0.001 then right = Vector3.new(1, 0, 0) else right = right.Unit end
        local center = position + direction * 0.035
        local tip = center + direction * (PredictArrowLength * 0.52)
        local backCenter = center - direction * (PredictArrowLength * 0.34)
        local spread = PredictArrowSpread
        local p1 = makePredictPart(index * 2 - 1); local p2 = makePredictPart(index * 2)
        setBeamBetween(p1, backCenter - right * spread, tip, PredictArrowWidth, PredictArrowWidth)
        setBeamBetween(p2, backCenter + right * spread, tip, PredictArrowWidth, PredictArrowWidth)
        p1.Color, p2.Color = PredictColor, PredictColor
        p1.Transparency, p2.Transparency = fade, fade
    end
    local function setLandingCorner(index, cornerCenter, axisX, axisZ, signX, signZ, fade)
        local half = LandingMarkerHalfSize
        local corner = math.min(LandingMarkerCornerSize, half * 0.82)
        local p1 = makeLandingPart(index * 2 - 1); local p2 = makeLandingPart(index * 2)
        local cornerPoint = cornerCenter + axisX * (signX * half) + axisZ * (signZ * half)
        local innerX = cornerPoint - axisX * (signX * corner)
        local innerZ = cornerPoint - axisZ * (signZ * corner)
        setBeamBetween(p1, cornerPoint, innerX, LandingMarkerWidth, LandingMarkerWidth)
        setBeamBetween(p2, cornerPoint, innerZ, LandingMarkerWidth, LandingMarkerWidth)
        p1.Color, p2.Color = PredictColor, PredictColor
        p1.Transparency, p2.Transparency = fade, fade
    end
    local function hidePredictLandingFrom(fromIndex)
        fromIndex = math.max(1, tonumber(fromIndex) or 1)
        for i = fromIndex, #PredictLandingParts do local p = PredictLandingParts[i]; if p and p.Parent then p.Transparency = 1 end end
    end
    local function setLandingMarker(position, normal)
        if not position then
            for i = 1, #PredictLandingParts do local p = PredictLandingParts[i]; if p and p.Parent then p.Transparency = 1 end end
            return
        end
        normal = (normal and normal.Magnitude > 0.001) and normal.Unit or Vector3.new(0, 1, 0)
        local axisX = Vector3.new(1, 0, 0)
        if math.abs(axisX:Dot(normal)) > 0.92 then axisX = Vector3.new(0, 0, 1) end
        axisX = (axisX - normal * axisX:Dot(normal))
        if axisX.Magnitude < 0.001 then axisX = Vector3.new(1, 0, 0) end
        axisX = axisX.Unit
        local axisZ = normal:Cross(axisX)
        if axisZ.Magnitude < 0.001 then axisZ = Vector3.new(0, 0, 1) else axisZ = axisZ.Unit end
        local center = position + normal * LandingMarkerLift
        local fade = clamp(PredictTransparency + 0.015, 0, 0.90)
        setLandingCorner(1, center, axisX, axisZ,  1,  1, fade)
        setLandingCorner(2, center, axisX, axisZ, -1,  1, fade)
        setLandingCorner(3, center, axisX, axisZ, -1, -1, fade)
        setLandingCorner(4, center, axisX, axisZ,  1, -1, fade)
        hidePredictLandingFrom(9)
    end
    function updatePredictAppearance()
        for _, p in ipairs(PredictParts) do if p and p.Parent then p.Color = PredictColor end end
        for _, p in ipairs(PredictLandingParts) do if p and p.Parent then p.Color = PredictColor end end
    end
    local function simulateTrajectory(ball)
        clear(PredictPoints)
        if not ball or not ball.Parent then return PredictPoints, nil, nil, nil end
        local now = clock()
        local pos, vel = ball.Position, ball.AssemblyLinearVelocity
        local gravity = Workspace.Gravity or 196.2
        if vel.Magnitude < PredictStopSpeed then
            PredictLastBall, PredictLastVel = ball, vel
            PredictLastAccel, PredictLastTime = Vector3.zero, now
            return PredictPoints, nil, nil, nil
        end
        local measuredAccel = Vector3.zero
        if PredictLastBall == ball and PredictLastVel and now > PredictLastTime then
            local sampleDt = clamp(now - PredictLastTime, 1/240, 0.08)
            measuredAccel = (vel - PredictLastVel) / sampleDt
            measuredAccel -= Vector3.new(0, -gravity, 0)
            local horizontalAccel = Vector3.new(measuredAccel.X, 0, measuredAccel.Z)
            if horizontalAccel.Magnitude > 300 then horizontalAccel = horizontalAccel.Unit * 300 end
            local verticalAccel = clamp(measuredAccel.Y, -180, 180)
            measuredAccel = Vector3.new(horizontalAccel.X, verticalAccel, horizontalAccel.Z)
            PredictLastAccel = PredictLastAccel:Lerp(measuredAccel, 0.22)
        else PredictLastAccel = Vector3.zero end
        PredictLastBall, PredictLastVel, PredictLastTime = ball, vel, now
        PredictPoints[1] = pos
        local firstImpactPosition, firstImpactNormal, firstImpactIndex = nil, nil, nil
        local step = clamp(PredictSpacing, 0.04, 0.16)
        local currentPos, currentVel = pos, vel
        local ignoreCharacter = LocalPlayer.Character
        local trajectoryFolder = ensureTrajectoryFolder()
        clear(PredictRayFilter); PredictRayFilter[1] = ball
        local filterCount = 1
        if ignoreCharacter then filterCount += 1; PredictRayFilter[filterCount] = ignoreCharacter end
        filterCount += 1; PredictRayFilter[filterCount] = trajectoryFolder
        PredictRayParams.FilterDescendantsInstances = PredictRayFilter
        for _ = 1, PredictCount do
            local previousPos = currentPos; local dt = step
            local extraAccel = PredictLastAccel + Vector3.new(0, -gravity, 0)
            local nextVel = currentVel + extraAccel * dt
            if nextVel.Magnitude > 420 then nextVel = nextVel.Unit * 420 end
            local nextPos = currentPos + currentVel * dt + 0.5 * extraAccel * dt * dt
            local hit = Workspace:Raycast(previousPos, nextPos - previousPos, PredictRayParams)
            if hit then
                local hitPos = hit.Position + hit.Normal * 0.055
                if not firstImpactPosition then
                    firstImpactPosition, firstImpactNormal = hitPos, hit.Normal
                    firstImpactIndex = #PredictPoints + 1
                end
                PredictPoints[#PredictPoints + 1] = hitPos; break
            else PredictPoints[#PredictPoints + 1] = nextPos end
            currentPos = nextPos
            currentVel = nextVel * 0.992
            if currentVel.Magnitude < PredictStopSpeed then break end
        end
        return PredictPoints, firstImpactPosition, firstImpactNormal, firstImpactIndex
    end
    function updateTrajectoryPredict()
        if not PredictEnabled then hidePredictParts(1); return end
        CurrentTPS = FindTPS()
        local ball = GetBallPart(CurrentTPS)
        if not ball or not ball.Parent then hidePredictParts(1); return end
        local points, landingPosition, landingNormal, impactIndex = simulateTrajectory(ball)
        if #points < 2 then hidePredictParts(1); return end
        local maxSegments = #points - 1
        if impactIndex then maxSegments = math.min(maxSegments, impactIndex - 1) end
        local lastArrowPosition, arrowIndex = nil, 0
        for i = 1, maxSegments do
            local a, b = points[i], points[i + 1]
            local delta = b - a; local segmentLength = delta.Magnitude
            if segmentLength >= 0.03 then
                local direction = delta.Unit
                if not lastArrowPosition or (a - lastArrowPosition).Magnitude >= PredictArrowGap then
                    arrowIndex += 1
                    local fade = clamp(PredictTransparency + math.max(0, arrowIndex - 1) * 0.010, 0, 0.88)
                    setChevron(arrowIndex, a, direction, fade)
                    lastArrowPosition = a
                end
            end
        end
        hidePredictParts(arrowIndex * 2 + 1)
        setLandingMarker(landingPosition, landingNormal)
    end
end

--// CUSTOM JOYSTICK
function joystickApplyMovement()
    if not CustomJoystick.Enabled then return end
    local hum = State.Humanoid
    if not hum or hum.Health <= 0 then return end
    local maxR = CustomJoystick.Size / 2 - CustomJoystick.KnobSize / 2
    if maxR <= 0 then return end
    local mag = CustomJoystick.CurrentOffset.Magnitude / maxR
    if CustomJoystick.TouchId == nil and mag < 0.12 then return end
    local dx = CustomJoystick.CurrentOffset.X / maxR
    local dy = CustomJoystick.CurrentOffset.Y / maxR
    if mag > 1 then dx, dy = dx / mag, dy / mag end
    hum:Move(Vector3.new(dx, 0, dy), true)
end
function joystickSetKnob(offset)
    if not CustomJoystick.Knob or not CustomJoystick.Knob.Parent then return end
    CustomJoystick.CurrentOffset = offset
    CustomJoystick.Knob.Position = UDim2.new(0.5, offset.X, 0.5, offset.Y)
end
function hideDefaultJoystick()
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui"); if not pg then return end
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, obj in ipairs(gui:GetDescendants()) do
                    if obj:IsA("Frame") and (obj.Name == "ControlFrame" or obj.Name == "TouchControlFrame" or obj.Name == "DynamicThumbstickFrame" or obj.Name == "ThumbstickFrame") then obj.Visible = false end
                end
            end
        end
    end)
end
function showDefaultJoystick()
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui"); if not pg then return end
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") then
                for _, obj in ipairs(gui:GetDescendants()) do
                    if obj:IsA("Frame") and (obj.Name == "ControlFrame" or obj.Name == "TouchControlFrame" or obj.Name == "DynamicThumbstickFrame" or obj.Name == "ThumbstickFrame") then obj.Visible = true end
                end
            end
        end
    end)
end
function CustomJoystick_create()
    if CustomJoystick.Enabled then return end
    CustomJoystick.Enabled = true
    hideDefaultJoystick()
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.IgnoreGuiInset = "LuaCustomJoystick", false, true
    gui.ZIndexBehavior, gui.DisplayOrder, gui.Parent = Enum.ZIndexBehavior.Sibling, 999, PlayerGui
    local size, knobSize = CustomJoystick.Size, CustomJoystick.KnobSize
    local maxR = size / 2 - knobSize / 2
    local base = Instance.new("Frame")
    base.Name = "Base"; base.Size = UDim2.fromOffset(size, size); base.AnchorPoint = Vector2.new(0, 1)
    base.Position = UDim2.new(0, 30, 1, -30); base.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    base.BackgroundTransparency = 0.55; base.BorderSizePixel = 0; base.Active = true; base.Parent = gui
    Instance.new("UICorner", base).CornerRadius = UDim.new(1, 0)
    local bs = Instance.new("UIStroke", base)
    bs.Thickness, bs.Color, bs.Transparency = 2, Color3.fromRGB(90, 90, 130), 0.35
    local knob = Instance.new("Frame")
    knob.Name = "Knob"; knob.Size = UDim2.fromOffset(knobSize, knobSize)
    knob.AnchorPoint = Vector2.new(0.5, 0.5); knob.Position = UDim2.new(0.5, 0, 0.5, 0)
    knob.BackgroundColor3 = Color3.fromRGB(80, 100, 160); knob.BackgroundTransparency = 0.15
    knob.BorderSizePixel = 0; knob.Parent = base
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    local ks = Instance.new("UIStroke", knob)
    ks.Thickness, ks.Color, ks.Transparency = 2, Color3.fromRGB(150, 180, 255), 0.15
    CustomJoystick.Gui, CustomJoystick.Base, CustomJoystick.Knob = gui, base, knob
    CustomJoystick.CurrentOffset, CustomJoystick.TouchId, CustomJoystick.BaseCenter = Vector2.new(0, 0), nil, nil
    local c1 = base.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        if CustomJoystick.TouchId ~= nil then return end
        CustomJoystick.TouchId = input
        local absPos = base.AbsolutePosition + base.AbsoluteSize / 2
        CustomJoystick.BaseCenter = Vector2.new(absPos.X, absPos.Y)
        joystickSetKnob(Vector2.new(0, 0))
    end)
    local c2 = UserInputService.InputChanged:Connect(function(input)
        if CustomJoystick.TouchId == nil or input ~= CustomJoystick.TouchId then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        local center = CustomJoystick.BaseCenter; if not center then return end
        local pos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = pos - center
        if delta.Magnitude > maxR then delta = delta.Unit * maxR end
        joystickSetKnob(delta)
    end)
    local c3 = UserInputService.InputEnded:Connect(function(input)
        if CustomJoystick.TouchId == nil or input ~= CustomJoystick.TouchId then return end
        CustomJoystick.TouchId = nil
        joystickSetKnob(Vector2.new(0, 0))
        if State.Humanoid then pcall(function() State.Humanoid:Move(Vector3.zero, true) end) end
    end)
    CustomJoystick.ConnList = { c1, c2, c3 }
    if CustomJoystick.MoveConn then CustomJoystick.MoveConn:Disconnect() end
    CustomJoystick.MoveConn = RunService.RenderStepped:Connect(joystickApplyMovement)
end
function CustomJoystick_destroy()
    CustomJoystick.Enabled = false
    if CustomJoystick.MoveConn then CustomJoystick.MoveConn:Disconnect(); CustomJoystick.MoveConn = nil end
    for i = 1, #CustomJoystick.ConnList do pcall(function() CustomJoystick.ConnList[i]:Disconnect() end) end
    CustomJoystick.ConnList = {}
    if CustomJoystick.Gui then CustomJoystick.Gui:Destroy(); CustomJoystick.Gui = nil end
    CustomJoystick.Base, CustomJoystick.Knob = nil, nil
    CustomJoystick.TouchId, CustomJoystick.BaseCenter = nil, nil
    showDefaultJoystick()
    if State.Humanoid then pcall(function() State.Humanoid:Move(Vector3.zero, true) end) end
end
CustomJoystick.create, CustomJoystick.destroy = CustomJoystick_create, CustomJoystick_destroy

--// GOAL / AIMBOT
local AutoGoal = false
local SelectedGoal = "Goal 1"
local ShootCooldown = 0.15
local Goal1, Goal2 = Vector3.new(-17, -29, 379), Vector3.new(-19, -29, -197)
local _goalState = { gen = 0, shootGen = 0 }
local AimbotGoal = {
    Enabled = false, Speed = 180, Smoothness = 0.25,
    BallControl = false, ShotDetected = false,
    LastBallVelocity = Vector3.zero, LastTouchTime = 0,
    TouchConn = nil, MobileRefs = nil,
    DistanceToGoal = 3, DistanceToBall = 8, VelHistory = {}, HistLen = 6,
}
local Telekinesis = { Enabled = false, Speed = 180, Smoothness = 0.25, OldCameraSubject = nil }
local Modifier = { StretchToggleOn = false, StretchEnabled = false, StretchScale = 100, StretchBound = false }

function getNearestAimbotGoal(position)
    local Goal, Distance = nil, math.huge
    for _, PositionGoal in ipairs({ Goal1, Goal2 }) do
        local D = (PositionGoal - position).Magnitude
        if D < Distance then Distance, Goal = D, PositionGoal end
    end
    return Goal
end
function hasShootTool()
    local Character = LocalPlayer.Character; if not Character then return false end
    local Shoot = Character:FindFirstChild("Shoot")
    return Shoot and Shoot:IsA("Tool") or false
end
function resetAimbotState()
    AimbotGoal.BallControl, AimbotGoal.ShotDetected = false, false
    AimbotGoal.LastTouchTime, AimbotGoal.LastBallVelocity = 0, Vector3.zero
    clear(AimbotGoal.VelHistory)
end
function bindAimbotTouch()
    if AimbotGoal.TouchConn then AimbotGoal.TouchConn:Disconnect(); AimbotGoal.TouchConn = nil end
    resetAimbotState(); CurrentTPS = FindTPS()
    local Ball = GetBallPart(CurrentTPS); if not Ball then return end
    local boundBall = Ball
    AimbotGoal.TouchConn = Ball.Touched:Connect(function()
        if not AimbotGoal.Enabled or not hasShootTool() then return end
        if not boundBall.Parent then task.defer(bindAimbotTouch); return end
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Root then return end
        if (boundBall.Position - Root.Position).Magnitude > AimbotGoal.DistanceToBall then return end
        AimbotGoal.LastTouchTime, AimbotGoal.ShotDetected, AimbotGoal.BallControl = os.clock(), false, false
        AimbotGoal.LastBallVelocity = boundBall.AssemblyLinearVelocity
    end)
end
function detectAimbotShot(Ball)
    if not Ball then return false end
    if AimbotGoal.LastTouchTime <= 0 or os.clock() - AimbotGoal.LastTouchTime > 1 then return false end
    local CurrentVelocity = Ball.AssemblyLinearVelocity
    local CurrentSpeed, OldSpeed = CurrentVelocity.Magnitude, AimbotGoal.LastBallVelocity.Magnitude
    if CurrentSpeed > 8 and CurrentSpeed > OldSpeed + 4 then return true end
    AimbotGoal.LastBallVelocity = CurrentVelocity
    return false
end
local function recordBallVel(ball)
    local h = AimbotGoal.VelHistory
    h[#h + 1] = { v = ball.AssemblyLinearVelocity, t = clock() }
    while #h > AimbotGoal.HistLen do remove(h, 1) end
end
local function aimbotDecelPerSec()
    local h = AimbotGoal.VelHistory
    if #h < 3 then return 0 end
    local a, b = h[1], h[#h]; local dt = b.t - a.t
    if dt <= 0 then return 0 end
    return (b.v.Magnitude - a.v.Magnitude) / dt
end
function setAimbotGoal(v)
    AimbotGoal.Enabled = v
    if AimbotGoal.MobileRefs then applyButtonState(AimbotGoal.MobileRefs, v, "AIMBOT\nON", "AIMBOT\nOFF") end
    if not v then
        resetAimbotState()
        if AimbotGoal.TouchConn then AimbotGoal.TouchConn:Disconnect(); AimbotGoal.TouchConn = nil end
        return
    end
    CurrentTPS = FindTPS(); bindAimbotTouch()
end
function setTelekinesis(v)
    local Camera = Workspace.CurrentCamera; if not Camera then Telekinesis.Enabled = false; return end
    if not v then
        Telekinesis.Enabled = false
        local Ball = GetBallPart(CurrentTPS)
        if Ball then pcall(function() Ball.AssemblyLinearVelocity = Vector3.zero end) end
        if Telekinesis.OldCameraSubject and Telekinesis.OldCameraSubject.Parent then
            Camera.CameraSubject = Telekinesis.OldCameraSubject
        else
            local Character = LocalPlayer.Character
            local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
            if Humanoid then Camera.CameraSubject = Humanoid end
        end
        Telekinesis.OldCameraSubject = nil; return
    end
    CurrentTPS = FindTPS()
    local Ball = GetBallPart(CurrentTPS); if not Ball then Telekinesis.Enabled = false; return end
    ensureOwnership(Ball)
    Telekinesis.OldCameraSubject = Camera.CameraSubject
    Telekinesis.Enabled = true
    Camera.CameraSubject = Ball
end
function GetShoot()
    local Character = LocalPlayer.Character
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    local Shoot = Character and Character:FindFirstChild("Shoot")
    if Shoot then return Shoot end
    if Backpack then return Backpack:FindFirstChild("Shoot") end
    return nil
end
function EquipShoot()
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid then return nil end
    local Shoot = GetShoot(); if not Shoot then return nil end
    if Shoot.Parent == LocalPlayer.Backpack then Humanoid:EquipTool(Shoot); task.wait(0.02) end
    return Shoot
end
function Shoot()
    local Tool = EquipShoot()
    if Tool and Tool.Parent == LocalPlayer.Character then Tool:Activate() end
end
function RunShoot(gen) while AutoGoal and _goalState.shootGen == gen do Shoot(); task.wait(ShootCooldown) end end
function RunAutoGoalGen(gen)
    while AutoGoal and _goalState.gen == gen do
        local Character = LocalPlayer.Character
        local Root = Character and Character:FindFirstChild("HumanoidRootPart")
        if not Root then task.wait(0.01); continue end
        CurrentTPS = FindTPS()
        local BallPosition = GetPosition(CurrentTPS)
        if not BallPosition then task.wait(0.005); continue end
        local GoalPosition = (SelectedGoal == "Goal 1") and Goal1 or Goal2
        local DistanceVector = GoalPosition - BallPosition
        local Distance = DistanceVector.Magnitude
        if Distance <= 4 then task.wait(0.02); continue end
        local Direction = DistanceVector.Unit
        Root.CFrame = CFrame.lookAt(BallPosition - Direction * 0.8 + Vector3.new(0, 0.3, 0), BallPosition)
        task.wait(0.015)
        CurrentTPS = FindTPS(); BallPosition = GetPosition(CurrentTPS)
        if not BallPosition then continue end
        DistanceVector = GoalPosition - BallPosition; Distance = DistanceVector.Magnitude
        if Distance <= 4 then continue end
        Direction = DistanceVector.Unit
        Root.CFrame = CFrame.lookAt(BallPosition + Direction * math.min(2.5, Distance) + Vector3.new(0, 0.3, 0), GoalPosition)
        Shoot(); task.wait(ShootCooldown)
    end
end
function setAutoGoal(v)
    AutoGoal = v; _goalState.gen += 1; _goalState.shootGen += 1
    if not v then return end
    local gen, sgen = _goalState.gen, _goalState.shootGen
    task.spawn(function() RunShoot(sgen) end)
    task.spawn(function() RunAutoGoalGen(gen) end)
end
function applyStretch()
    if not Modifier.StretchEnabled then return end
    local camera = Workspace.CurrentCamera; if not camera then return end
    local scale = math.clamp(Modifier.StretchScale / 100, 0.4, 1)
    if scale >= 0.999 then return end
    local cf = camera.CFrame
    camera.CFrame = CFrame.fromMatrix(cf.Position, cf.RightVector, cf.UpVector * scale, -cf.LookVector)
end
function refreshStretchState()
    local scale = math.clamp(Modifier.StretchScale / 100, 0.4, 1)
    local shouldApply = Modifier.StretchToggleOn and scale < 0.999
    if shouldApply then
        Modifier.StretchEnabled = true
        if not Modifier.StretchBound then
            Modifier.StretchBound = true
            pcall(function() RunService:BindToRenderStep("LuatcsStretch", Enum.RenderPriority.Camera.Value + 100, applyStretch) end)
        end
    else
        Modifier.StretchEnabled = false
        if Modifier.StretchBound then
            pcall(function() RunService:UnbindFromRenderStep("LuatcsStretch") end); Modifier.StretchBound = false
        end
    end
end
do
    local cache, stamp = nil, 0
    function getEquippedToolName()
        local now = clock()
        if now - stamp < EQUIPPED_TOOL_TTL then return cache end
        stamp = now
        local char = LocalPlayer.Character
        if not char then cache = "NONE"; return cache end
        local tool = char:FindFirstChildOfClass("Tool")
        cache = tool and tool.Name or "NONE"
        return cache
    end
end
function ballIsFreeOrMine(ball)
    local owner = ball:FindFirstChild("Owner")
    if not owner or not owner:IsA("ObjectValue") then return true end
    local v = owner.Value
    return v == nil or v == LocalPlayer
end

--// HITBOX / TOUCH DISPATCH
do
    local fireTouchFn = firetouchtransmitter or firetouchinterest
    function fireTouch(part, ball)
        if not part or not ball or not part.Parent or not ball.Parent or not fireTouchFn then return end
        pcall(fireTouchFn, part, ball, 0); pcall(fireTouchFn, part, ball, 1)
    end
end
function forceLegTouch(leg, ball)
    if not leg or not ball then return end
    if not ballIsFreeOrMine(ball) then return end
    fireTouch(leg, ball)
end
do
    local gkLastTrigger = 0
    function forceGKTouch(ball)
        if not ball or not ball.Parent then return end
        if not ballIsFreeOrMine(ball) then return end
        local now = clock()
        if now - gkLastTrigger < GK_TOUCH_COOLDOWN then return end
        gkLastTrigger = now
        local char = LocalPlayer.Character; if not char then return end
        local la, ra = char:FindFirstChild("Left Arm"), char:FindFirstChild("Right Arm")
        if la then fireTouch(la, ball) end
        if ra then fireTouch(ra, ball) end
    end
end
local _frameTouchGuard, _frameStamp = {}, 0
local function beginTouchFrame()
    local now = clock()
    if now - _frameStamp > 0.016 then _frameStamp = now; clear(_frameTouchGuard) end
end
function forceTouchDispatch(limbPart, ball, isGKGroup)
    if not ball or not ball.Parent then return end
    local key = ball:GetFullName()
    if _frameTouchGuard[key] then return end
    _frameTouchGuard[key] = true
    if isGKGroup then forceGKTouch(ball)
    else
        local tool = getEquippedToolName()
        if tool == "GK" then forceGKTouch(ball) else forceLegTouch(limbPart, ball) end
    end
end
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
local EXCLUDE = {}
overlapParams.FilterDescendantsInstances = EXCLUDE
function updateOverlapExclude(char) clear(EXCLUDE); if char then EXCLUDE[1] = char end end
updateOverlapExclude(LocalPlayer.Character)
insert(onCharacterAdded, updateOverlapExclude)
insert(onCharacterRemoving, function() updateOverlapExclude(nil) end)
function findTarget(part)
    local c = part
    while c and c ~= Workspace do
        if c:IsA("BasePart") and BALL_NAMES[c.Name] then return c end
        c = c.Parent
    end
    return nil
end

local HitboxGroup = {}
HitboxGroup.__index = HitboxGroup
function HitboxGroup.new(parts, partToGroup)
    local self = setmetatable({}, HitboxGroup)
    self.parts, self.partToGroup = parts, partToGroup
    self.hitboxes, self.baseParts, self.lastTouch = {}, {}, {}
    self._stepNames, self._staleKeys = {}, {}
    self.timer, self.isGKGroup = HITBOX_COOLDOWN, false
    return self
end
function HitboxGroup:_getSettings(_) return nil end
function HitboxGroup:_makeSize(parent, settings) return parent.Size * settings.Size end
function HitboxGroup:getAutomaticTouchDistance(hb)
    if not hb then return 15 end
    local size = hb.Size
    return math.max(5, math.max(size.X, size.Y, size.Z) / 2 + 3)
end
function HitboxGroup:clearPart(partName)
    local hb = self.hitboxes[partName]; if hb then hb:Destroy() end
    self.hitboxes[partName], self.baseParts[partName] = nil, nil
end
function HitboxGroup:updatePart(partName)
    local char = LocalPlayer.Character
    if not char then self:clearPart(partName); return end
    local parent = char:FindFirstChild(partName)
    if not parent then self:clearPart(partName); return end
    local cfg = self:_getSettings(partName)
    if not cfg or not cfg.Enabled then self:clearPart(partName); return end
    local sz = self:_makeSize(parent, cfg)
    if sz.X <= 0 or sz.Y <= 0 or sz.Z <= 0 then self:clearPart(partName); return end
    local hb = self.hitboxes[partName]
    if not hb or not hb.Parent then
        hb = Instance.new("Part")
        hb.Name = partName .. "_Hitbox"
        hb.Anchored, hb.CanCollide, hb.CanTouch, hb.CanQuery = false, false, false, false
        hb.Transparency, hb.Massless = 1, true
        hb.Size, hb.CFrame = sz, parent.CFrame
        hb.Parent = char
        local w = Instance.new("WeldConstraint")
        w.Part0, w.Part1, w.Parent = parent, hb, hb
        self.hitboxes[partName] = hb
    end
    hb.Size = sz
    self.baseParts[partName] = parent
end
function HitboxGroup:updateAll() for i = 1, #self.parts do self:updatePart(self.parts[i]) end end
function HitboxGroup:clearAll()
    for i = 1, #self.parts do self:clearPart(self.parts[i]) end
    clear(self.hitboxes); clear(self.baseParts); clear(self.lastTouch)
end
function HitboxGroup:pruneLastTouch(now)
    local stale = self._staleKeys; clear(stale)
    for k, v in pairs(self.lastTouch) do if now - v > 3 then stale[#stale + 1] = k end end
    for i = 1, #stale do self.lastTouch[stale[i]] = nil end
end
function HitboxGroup:stepLead(now, prefix)
    if next(self.hitboxes) == nil then return end
    local hrp = State.HRP; local hrpPos = hrp and hrp.Position
    local isGK = self.isGKGroup
    local names = self._stepNames; clear(names)
    for name in pairs(self.hitboxes) do names[#names + 1] = name end
    for i = 1, #names do
        local name = names[i]
        local hb = self.hitboxes[name]
        if hb and hb.Parent then
            local bp = self.baseParts[name]
            if bp and bp.Parent then
                local automaticDistance = hrpPos and self:getAutomaticTouchDistance(hb) or math.huge
                local parts = Workspace:GetPartBoundsInBox(hb.CFrame, hb.Size, overlapParams)
                for j = 1, #parts do
                    local t = findTarget(parts[j])
                    if t then
                        local vel = t.AssemblyLinearVelocity
                        local leadVec = vel * REACH_LEAD_S
                        if leadVec.Magnitude > REACH_LEAD_MAX then leadVec = leadVec.Unit * REACH_LEAD_MAX end
                        local predictedPos = t.Position + leadVec
                        if hrpPos then
                            local d = (predictedPos - hrpPos).Magnitude
                            if d > automaticDistance + leadVec.Magnitude then continue end
                        end
                        local key = prefix .. name .. ":" .. t:GetFullName()
                        local last = self.lastTouch[key]
                        if not last or now - last > self.timer then
                            self.lastTouch[key] = now
                            forceTouchDispatch(bp, t, isGK)
                        end
                    end
                end
            end
        end
    end
end

local REACH_PARTS = { "Head", "Torso", "Right Leg", "Left Leg" }
local PART_TO_GROUP = { ["Head"] = "Head", ["Torso"] = "Torso", ["Right Leg"] = "Legs", ["Left Leg"] = "Legs" }
local ReachSettings = {
    Legs  = { Enabled = false, Size = 1, Visualizer = false },
    Torso = { Enabled = false, Size = 1, Visualizer = false },
    Head  = { Enabled = false, Size = 1, Visualizer = false },
}
local ReachVisualizer = { Objects = {}, Character = nil }

function destroyReachVisualizer(name)
    local obj = ReachVisualizer.Objects[name]
    if obj then pcall(function() obj:Destroy() end) end
    ReachVisualizer.Objects[name] = nil
end
function destroyAllReachVisualizers()
    for name in pairs(ReachVisualizer.Objects) do destroyReachVisualizer(name) end
    ReachVisualizer.Character = nil
end
function createStaticReachVisualizer(name, size, worldCFrame, root)
    local obj = ReachVisualizer.Objects[name]
    if not obj or not obj.Parent then
        destroyReachVisualizer(name)
        obj = Instance.new("Part")
        obj.Name = "ReachVisualizer_" .. name
        obj.Shape = Enum.PartType.Ball
        obj.Anchored, obj.CanCollide, obj.CanTouch, obj.CanQuery = false, false, false, false
        obj.CastShadow, obj.Massless = false, true
        obj.Material = Enum.Material.ForceField
        obj.Color, obj.Transparency = Color3.fromRGB(255, 70, 70), 0.72
        obj.Size, obj.CFrame, obj.Parent = size, worldCFrame, Workspace
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1, weld.Parent = root, obj, obj
        ReachVisualizer.Objects[name] = obj
    else obj.Size = size end
    return obj
end
function ReachVisualizer_updateAll()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not root then destroyAllReachVisualizers(); return end
    if ReachVisualizer.Character ~= char then destroyAllReachVisualizers(); ReachVisualizer.Character = char end
    local function part(name) return char:FindFirstChild(name) end
    local legL, legR = part("Left Leg"), part("Right Leg")
    local legCfg = ReachSettings.Legs
    if legCfg.Visualizer and (legL or legR) then
        local sx, sy, sz = 1, 1, 1
        local centers = {}
        for _, leg in ipairs({legL, legR}) do
            if leg then
                local reachSize = leg.Size * legCfg.Size
                sx, sy, sz = math.max(sx, reachSize.X), math.max(sy, reachSize.Y), math.max(sz, reachSize.Z)
                centers[#centers + 1] = root.CFrame:PointToObjectSpace(leg.Position)
            end
        end
        if #centers > 0 then
            local minX, maxX = centers[1].X - sx/2, centers[1].X + sx/2
            local minY, maxY = centers[1].Y - sy/2, centers[1].Y + sy/2
            local minZ, maxZ = centers[1].Z - sz/2, centers[1].Z + sz/2
            for i = 2, #centers do
                local c = centers[i]
                minX, maxX = math.min(minX, c.X - sx/2), math.max(maxX, c.X + sx/2)
                minY, maxY = math.min(minY, c.Y - sy/2), math.max(maxY, c.Y + sy/2)
                minZ, maxZ = math.min(minZ, c.Z - sz/2), math.max(maxZ, c.Z + sz/2)
            end
            local localCenter = Vector3.new((minX+maxX)/2, (minY+maxY)/2, (minZ+maxZ)/2)
            local localSize = Vector3.new(maxX-minX, maxY-minY, maxZ-minZ)
            createStaticReachVisualizer("Legs", localSize, root.CFrame:ToWorldSpace(CFrame.new(localCenter)), root)
        end
    else destroyReachVisualizer("Legs") end
    for groupName, partName in pairs({ Torso = "Torso", Head = "Head" }) do
        local cfg = ReachSettings[groupName]
        local base = part(partName)
        if cfg.Visualizer and base then
            local size = base.Size * cfg.Size
            local obj = ReachVisualizer.Objects[groupName]
            if not obj or not obj.Parent then
                local fixedWorld = root.CFrame:ToWorldSpace(root.CFrame:ToObjectSpace(base.CFrame))
                createStaticReachVisualizer(groupName, size, fixedWorld, root)
            else obj.Size = size end
        else destroyReachVisualizer(groupName) end
    end
end
ReachVisualizer.updateAll = ReachVisualizer_updateAll

local Reach = HitboxGroup.new(REACH_PARTS, PART_TO_GROUP)
function Reach:_getSettings(partName)
    local grp = self.partToGroup[partName]
    return grp and ReachSettings[grp] or nil
end
insert(onCharacterAdded, function()
    destroyAllReachVisualizers(); Reach:clearAll()
    wait_(2); Reach:updateAll(); ReachVisualizer:updateAll()
end)

local ARM_PARTS = { "Left Arm", "Right Arm" }
local GKSettings = { Enabled = false, Size = 1 }
local GKReach = HitboxGroup.new(ARM_PARTS, nil)
GKReach.isGKGroup = true
function GKReach:_getSettings(_) return GKSettings end
insert(onCharacterAdded, function() GKReach:clearAll(); wait_(2); GKReach:updateAll() end)

local BallReachSettings = { Enabled = false, Size = 1, Visualizer = false }
local BallReach = { Visualizer = nil, LastTouch = 0 }
function BallReach:clearVisualizer()
    if self.Visualizer then pcall(function() self.Visualizer:Destroy() end) end
    self.Visualizer = nil
end
function BallReach:updateVisualizer(ball)
    if not BallReachSettings.Visualizer or not ball or not ball.Parent then self:clearVisualizer(); return end
    if not self.Visualizer or not self.Visualizer.Parent then
        self.Visualizer = Instance.new("Part")
        self.Visualizer.Name = "BallReachVisualizer"
        self.Visualizer.Shape = Enum.PartType.Ball
        self.Visualizer.Anchored = true
        self.Visualizer.CanCollide, self.Visualizer.CanTouch, self.Visualizer.CanQuery = false, false, false
        self.Visualizer.CastShadow = false
        self.Visualizer.Material = Enum.Material.ForceField
        self.Visualizer.Color = Color3.fromRGB(80, 200, 255)
        self.Visualizer.Transparency = 0.55
        self.Visualizer.Size = ball.Size * BallReachSettings.Size
        self.Visualizer.CFrame = ball.CFrame
        self.Visualizer.Parent = Workspace
    end
    self.Visualizer.Size = ball.Size * BallReachSettings.Size
    self.Visualizer.CFrame = ball.CFrame
end
function BallReach:step(now)
    if not BallReachSettings.Enabled then self:clearVisualizer(); return end
    local ball = getNearestBall()
    if not ball or not ball.Parent then self:clearVisualizer(); return end
    self:updateVisualizer(ball)
    local hrp = State.HRP; if not hrp then return end
    local radius = math.max(ball.Size.X, ball.Size.Y, ball.Size.Z) * BallReachSettings.Size / 2
    local distance = (hrp.Position - ball.Position).Magnitude
    if distance <= math.max(3, radius + 3) and now - self.LastTouch >= HITBOX_COOLDOWN then
        self.LastTouch = now
        local char = State.Character
        if char then
            local candidates = {
                char:FindFirstChild("Right Leg"), char:FindFirstChild("Left Leg"),
                char:FindFirstChild("RightFoot"), char:FindFirstChild("LeftFoot"),
                char:FindFirstChild("Torso"), char:FindFirstChild("UpperTorso"),
            }
            local sent = false
            for i = 1, #candidates do
                local limb = candidates[i]
                if limb and limb:IsA("BasePart") then fireTouch(limb, ball); sent = true end
            end
            if not sent then fireTouch(hrp, ball) end
        end
    end
end
insert(onCharacterAdded, function() BallReach:clearVisualizer(); BallReach.LastTouch = 0 end)
insert(onCharacterRemoving, function() BallReach:clearVisualizer(); BallReach.LastTouch = 0 end)

do
    local queued = false
    function scheduleReachUpdate()
        if queued then return end
        queued = true
        defer(function()
            wait_(REACH_DEBOUNCE); queued = false
            Reach:updateAll(); GKReach:updateAll(); ReachVisualizer:updateAll()
        end)
    end
end

local AutoCatch = { Enabled = false, Range = 50, Cooldown = 0.25, LastCatch = 0, MobileRefs = nil, _lastPrune = 0 }
function fireCatchBall(ball)
    local remote = ReplicatedStorage:FindFirstChild(CATCH_REMOTE_NAME)
    if remote and remote:IsA("RemoteEvent") then
        AutoCatch.LastCatch = clock(); pcall(function() remote:FireServer(ball) end); return true
    end
    return false
end

local AutoDive = {
    Enabled = false,
    Range = 16,
    Cooldown = 0.35,
    DiveCooldown = 0.35,
    LastAction = 0,
    Prediction = 0.35,
    CenterWidth = 2.5,
    FrontHeight = 1,
    HighHeight = 3.5,
    MinBallSpeed = 4,
    MinApproachDot = 0.15,
    CoverLine = true,
    AutoJump = true,
    AutoEquipGK = true,
}

local DiveButtons = {
    Front = "Front Dive",
    HighLeft = "High Dive Left",
    HighRight = "High Dive Right",
    LowLeft = "Dive Left",
    LowRight = "Dive Right",
    HighCatch = "High Catch",
}

local GKBotoes = {}
local AutoDiveConnection

local function EscanearBotoesGK()
    GKBotoes = {}
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end
    pcall(function()
        for _, object in ipairs(playerGui:GetDescendants()) do
            if object:IsA("TextButton") or object:IsA("ImageButton") then
                local name = object.Name
                local textValue = ""
                pcall(function() textValue = object.Text end)
                if name:find("GK") or name:find("C2") or textValue:find("Dive") or
                    textValue:find("Catch") or textValue:find("High") or textValue:find("Low") or
                    textValue:find("Reflex") or textValue:find("Forward") or textValue:find("Front") or
                    textValue:find("Rush") then
                    table.insert(GKBotoes, { Button = object, Nome = name, Texto = textValue })
                end
            end
        end
    end)
end

local function EncontrarBotaoPorTexto(textoAlvo)
    local alvo = textoAlvo:lower()
    for _, info in ipairs(GKBotoes) do
        if info.Button and info.Button.Parent and info.Texto and info.Texto:lower() == alvo then
            return info.Button
        end
    end
    for _, info in ipairs(GKBotoes) do
        if info.Button and info.Button.Parent and info.Texto and info.Texto:lower():find(alvo, 1, true) then
            return info.Button
        end
    end
    return nil
end

local function ClicarBotao(button)
    if not button or not button.Parent then return false end
    pcall(function() firesignal(button.Activated) end)
    pcall(function() firesignal(button.MouseButton1Click) end)
    pcall(function() firesignal(button.MouseButton1Down) end)
    pcall(function() firesignal(button.MouseButton1Up) end)
    pcall(function() firesignal(button.TouchTap) end)
    return true
end

local function GetDivePrediction(ball)
    local rootPart = State.HRP
    if not ball or not rootPart or not rootPart.Parent then return nil end
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local velocity = ball.AssemblyLinearVelocity
    local distance = (ball.Position - rootPart.Position).Magnitude
    local travelTime = 0
    if velocity.Magnitude > 3 then
        travelTime = math.clamp(distance / velocity.Magnitude, 0, AutoDive.Prediction)
    end

    local predictedPosition = ball.Position + velocity * travelTime
    local cameraRight = camera.CFrame.RightVector
    local rightHorizontal = Vector3.new(cameraRight.X, 0, cameraRight.Z)
    if rightHorizontal.Magnitude < 0.1 then rightHorizontal = Vector3.new(1, 0, 0) end
    rightHorizontal = rightHorizontal.Unit

    local delta = predictedPosition - rootPart.Position
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    local side = horizontal:Dot(rightHorizontal)
    local height = delta.Y

    return {
        Ball = ball,
        Velocity = velocity,
        Distance = distance,
        TravelTime = travelTime,
        Position = predictedPosition,
        Side = side,
        SideAbs = math.abs(side),
        Height = height,
        IsCentral = math.abs(side) < AutoDive.CenterWidth,
        IsHigh = height >= AutoDive.HighHeight,
        IsFront = height < AutoDive.FrontHeight,
    }
end

local function GetDiveAction(info)
    if not info then return nil end
    if info.IsCentral then
        if info.IsHigh then return DiveButtons.HighCatch end
        return DiveButtons.Front
    end
    if info.IsHigh then
        if info.Side > 0 then return DiveButtons.HighRight end
        return DiveButtons.HighLeft
    end
    if info.Side > 0 then return DiveButtons.LowRight end
    return DiveButtons.LowLeft
end

local function ExecuteDiveAction(action)
    if not action then return false end
    local button = EncontrarBotaoPorTexto(action)
    if not button then
        EscanearBotoesGK()
        button = EncontrarBotaoPorTexto(action)
    end
    if not button then return false end

    if action == DiveButtons.HighCatch then
        local humanoid = State.Humanoid
        if humanoid then
            pcall(function() humanoid.Jump = true end)
            pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
        task.wait(0.05)
    end
    return ClicarBotao(button)
end

local function IsBallComingToGoalkeeper(ball)
    local rootPart = State.HRP
    if not ball or not rootPart or not rootPart.Parent then return false end

    local velocity = ball.AssemblyLinearVelocity
    if velocity.Magnitude < AutoDive.MinBallSpeed then return false end

    local toPlayer = rootPart.Position - ball.Position
    local horizontalToPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    if horizontalToPlayer.Magnitude < 0.1 or horizontalVelocity.Magnitude < 0.1 then return false end

    local dot = horizontalVelocity.Unit:Dot(horizontalToPlayer.Unit)
    return dot >= AutoDive.MinApproachDot
end

local function ExecuteAutoDive()
    local ball = GetValidBall()
    if not ball then return end
    local info = GetDivePrediction(ball)
    if not info then return end
    local action = GetDiveAction(info)
    if not action then return end
    if ExecuteDiveAction(action) then
        AutoDive.LastAction = clock()
    end
end

local function StartAutoDive()
    AutoDive.Enabled = true
    if AutoDiveConnection then return end
    EscanearBotoesGK()
    AutoDiveConnection = RunService.Heartbeat:Connect(function()
        if not AutoDive.Enabled then return end
        local rootPart = State.HRP
        if not rootPart or not rootPart.Parent then return end
        local now = clock()
        local cooldown = tonumber(AutoDive.Cooldown or AutoDive.DiveCooldown) or 0.35
        if now - AutoDive.LastAction < cooldown then return end

        local ball = GetValidBall()
        if not ball then return end
        local distance = (ball.Position - rootPart.Position).Magnitude
        if distance > AutoDive.Range then return end
        if not IsBallComingToGoalkeeper(ball) then return end
        ExecuteAutoDive()
    end)
end

local function StopAutoDive()
    AutoDive.Enabled = false
    if AutoDiveConnection then
        AutoDiveConnection:Disconnect()
        AutoDiveConnection = nil
    end
end

-- Compatibility with the original main heartbeat/keybind structure.
resetPendingDecision = function() end
resetDivePrediction = function() end
runAutoDiveTick = function() end
decideGKAction = function() end

--// FLOW
local Follow = { Enabled = false, Distance = 0.5, PredictTime = 0.35, MinSpeed = 2, SmoothRate = 15, Connection = nil, TargetBall = nil, MobileRefs = nil }
local FlowControls = nil
local function getFlowManualMove()
    if not FlowControls then
        pcall(function()
            local ps = LocalPlayer:FindFirstChildOfClass("PlayerScripts")
            local pm = ps and ps:FindFirstChild("PlayerModule")
            if pm then FlowControls = require(pm):GetControls() end
        end)
    end
    if FlowControls then
        local ok, move = pcall(function() return FlowControls:GetMoveVector() end)
        if ok and typeof(move) == "Vector3" then return Vector3.new(move.X, 0, move.Z) end
    end
    return Vector3.zero
end
defer(function()
    local ps = LocalPlayer:WaitForChild("PlayerScripts", 10)
    if ps then
        local pm = ps:WaitForChild("PlayerModule", 10)
        if pm then pcall(function() FlowControls = require(pm):GetControls() end) end
    end
end)
local PredState = { ball = nil, lastVel = nil, lastTime = 0, smoothed = nil }
function resetPredState(ball)
    PredState.ball, PredState.lastVel, PredState.lastTime, PredState.smoothed = ball, nil, clock(), nil
end
function computePredicted(ball, _dt)
    local pos, vel = ball.Position, ball.AssemblyLinearVelocity
    if PredState.ball ~= ball then resetPredState(ball); return pos end
    local now = clock()
    local deltaT = clamp(now - PredState.lastTime, 1/240, 1/15)
    PredState.lastTime = now
    local accel = Vector3.zero
    if PredState.lastVel then
        accel = (vel - PredState.lastVel) / deltaT
        if accel.Magnitude > 500 then accel = accel.Unit * 500 end
    end
    PredState.lastVel = vel
    local t = Follow.PredictTime
    local rawPredicted = pos + vel * t + 0.5 * accel * t * t
    if PredState.smoothed then
        local rate = Follow.SmoothRate
        local k = 1 - math.exp(-rate * deltaT)
        PredState.smoothed = PredState.smoothed:Lerp(rawPredicted, k)
    else PredState.smoothed = rawPredicted end
    return PredState.smoothed
end
function acquireFollowTarget()
    CurrentTPS = FindTPS()
    local ball = GetBallPart(CurrentTPS)
    if not ball or not ball.Parent then return nil end
    if ball.AssemblyLinearVelocity.Magnitude < Follow.MinSpeed then return nil end
    return ball
end
local function isAnyManualMovementActive()
    local keyboardMove = getFlowManualMove()
    if keyboardMove.Magnitude > 0.05 then return true end
    if CustomJoystick.Enabled then
        local offset = CustomJoystick.CurrentOffset
        local maxR = CustomJoystick.Size / 2 - CustomJoystick.KnobSize / 2
        if maxR > 0 and (offset.Magnitude / maxR) > 0.15 then return true end
    end
    return false
end
function stopFollow()
    Follow.Enabled, Follow.TargetBall = false, nil
    if Follow.Connection then Follow.Connection:Disconnect(); Follow.Connection = nil end
    if State.Humanoid then pcall(function() State.Humanoid:Move(Vector3.zero, false) end) end
    resetPredState(nil)
end
function startFollow()
    Follow.Enabled, Follow.TargetBall = true, nil
    if Follow.Connection then Follow.Connection:Disconnect() end
    resetPredState(nil)
    Follow.Connection = RunService.RenderStepped:Connect(function(dt)
        if not Follow.Enabled then return end
        local hum, hrp = State.Humanoid, State.HRP
        if not hum or not hrp or hum.Health <= 0 then return end
        if isAnyManualMovementActive() then
            Follow.TargetBall = nil; resetPredState(nil); return
        end
        if not Follow.TargetBall then
            local ball = acquireFollowTarget(); if not ball then return end
            Follow.TargetBall = ball; resetPredState(ball)
        end
        local ball = Follow.TargetBall
        if not ball or not ball.Parent then Follow.TargetBall = nil; resetPredState(nil); return end
        local predicted = computePredicted(ball, dt); if not predicted then return end
        local target = Vector3.new(predicted.X, hrp.Position.Y, predicted.Z)
        local diff = target - hrp.Position; local distance = diff.Magnitude
        if distance > Follow.Distance then
            hum:Move(diff.Unit, false)
            hrp.CFrame = CFrame.new(hrp.Position, target)
        else hum:Move(Vector3.zero, false) end
    end)
end
function setFollow(v) if v then if not Follow.Enabled then startFollow() end else stopFollow() end end

--// AUTO SWITCH LEG
local AutoSwitchLeg = {
    Enabled = false,
    ToolManagement = nil,
    SideDeadzone = 0.8,
    BallRange = 15,
    Cooldown = 0.15,
    LastSwitch = 0,
    LastLeg = nil,
}
local function getToolManagement()
    if AutoSwitchLeg.ToolManagement then return AutoSwitchLeg.ToolManagement end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return nil end
    local tm = backpack:FindFirstChild("ToolManagement")
    if not tm then return nil end
    local ok, mod = pcall(require, tm)
    if ok and type(mod) == "table" then
        AutoSwitchLeg.ToolManagement = mod
        return mod
    end
    return nil
end
local function notifyLegSwitch(side)
    pcall(function()
        local startGui = LocalPlayer.PlayerGui:FindFirstChild("Start")
        if not startGui then return end
        local notifR = startGui:FindFirstChild("Foot_R_Notif")
        local notifL = startGui:FindFirstChild("Foot_L_Notif")
        local notif = (side == "R") and notifR or notifL
        if not notif then return end
        notif.TextTransparency = 0.5
        notif.Size = UDim2.new(0.073, 0, 0.07, 0)
        notif:TweenSize(UDim2.new(0.073, 0, 0.203, 0), "Out", "Back", 0.2, true)
        local imgLabel = startGui:FindFirstChild("ImageLabel")
        if imgLabel then
            local footLabel = imgLabel:FindFirstChild("Foot")
            if footLabel then footLabel.Text = side end
        end
        local footBtn = startGui:FindFirstChild("Foot")
        if footBtn then footBtn.Text = side end
    end)
end
local function autoSwitchLegTick(now)
    if not AutoSwitchLeg.Enabled then return end
    local tm = getToolManagement()
    if not tm or not tm.check or not tm.Set then return end
    local hrp = State.HRP
    if not hrp then return end
    local ball = getNearestBall()
    if not ball then return end
    local dist = (ball.Position - hrp.Position).Magnitude
    if dist > AutoSwitchLeg.BallRange then return end
    local right = hrp.CFrame.RightVector
    local toBall = ball.Position - hrp.Position
    local sideDot = toBall:Dot(right)
    if math.abs(sideDot) < AutoSwitchLeg.SideDeadzone then return end
    local want = sideDot > 0 and "R" or "L"
    local ok, current = pcall(tm.check)
    if not ok then return end
    if current == want then return end
    if now - AutoSwitchLeg.LastSwitch < AutoSwitchLeg.Cooldown then return end
    pcall(tm.Set, want)
    AutoSwitchLeg.LastSwitch = now
    AutoSwitchLeg.LastLeg = want
    notifyLegSwitch(want)
end

function sendGlobalMessage(msg)
    local CHAT_KEYWORDS = { "global", "chat", "say", "messenger", "main" }
    local list = {}
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local lname = string.lower(v.Name)
            for i = 1, #CHAT_KEYWORDS do
                if string.find(lname, CHAT_KEYWORDS[i], 1, true) then insert(list, v); break end
            end
        end
    end
    if #list > 0 then
        for i = 1, #list do pcall(function() list[i]:FireServer(msg) end) end
        return true
    end
    if TextChatService then
        local sent = false
        pcall(function()
            local channels = TextChatService:FindFirstChild("TextChannels")
            local channel = channels and channels:FindFirstChild("RBXGeneral")
            if channel then channel:SendAsync(msg); sent = true end
        end)
        if sent then return true end
    end
    local chat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chat then
        local sayRequest = chat:FindFirstChild("SayMessageRequest")
        if sayRequest then pcall(function() sayRequest:FireServer(msg, "All") end); return true end
    end
    return false
end

local BallCustom = { cachedBall = nil, BallFolders = { "WorkspaceLeaderboards", "Balls", "BallFolder" }, LastMeshId = nil, LastTexId = nil, _reapplyAt = 0 }
local BallNormalIds = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom }
function bcFindMesh(obj)
    if not obj then return nil end
    for _, v in ipairs(obj:GetDescendants()) do if v:IsA("SpecialMesh") then return v end end
    for _, v in ipairs(obj:GetDescendants()) do if v:IsA("MeshPart") then return v end end
    return nil
end
function bcGetOrCreateMesh(obj)
    if not obj then return nil end
    local m = bcFindMesh(obj); if m then return m end
    local sm = Instance.new("SpecialMesh"); sm.Name, sm.MeshType, sm.Parent = "Lua_BM", Enum.MeshType.FileMesh, obj
    return sm
end
function bcSetMeshId(mesh, id)
    if not mesh then return end
    if mesh:IsA("SpecialMesh") then mesh.MeshType = Enum.MeshType.FileMesh; mesh.MeshId = id
    elseif mesh:IsA("MeshPart") then mesh.MeshId = id end
end
function bcGetOrCreateTextures(obj)
    if not obj then return {} end
    local t = {}
    for _, v in ipairs(obj:GetChildren()) do if v:IsA("Texture") then insert(t, v) end end
    if #t > 0 then return t end
    local t2 = {}
    for _, face in ipairs(BallNormalIds) do
        local tex = Instance.new("Texture"); tex.Face, tex.StudsPerTileU, tex.StudsPerTileV, tex.Parent = face, 10, 10, obj
        insert(t2, tex)
    end
    return t2
end
function bcSetTextures(obj, id)
    if not obj then return 0 end
    local textures = bcGetOrCreateTextures(obj); local n = 0
    for _, tex in ipairs(textures) do tex.Texture = id; n = n + 1 end
    return n
end
function bcToAssetId(s)
    s = tostring(s or ""):gsub("%s+", "")
    if s == "" then return nil end
    if s:match("^rbxassetid://") then return s end
    if s:match("^%d+$") then return "rbxassetid://" .. s end
    return nil
end
function bcGetBall()
    if BallCustom.cachedBall and BallCustom.cachedBall.Parent then return BallCustom.cachedBall end
    BallCustom.cachedBall = nil
    local ball = GetBallPart(CurrentTPS)
    if ball and ball.Parent then BallCustom.cachedBall = ball; return ball end
    local nearest = getNearestBall()
    if nearest and nearest.Parent then BallCustom.cachedBall = nearest; return nearest end
    local found = {}
    local function check(o)
        if o:IsA("BasePart") then
            local n = o.Name:lower()
            if n == "tps" or n == "ball" or n == "bola" or n == "soccerball" or n == "football" or n == "psoccerball" then insert(found, o) end
        end
    end
    for _, v in ipairs(Workspace:GetChildren()) do check(v) end
    for _, folderName in ipairs(BallCustom.BallFolders) do
        local f = Workspace:FindFirstChild(folderName)
        if f then for _, d in ipairs(f:GetDescendants()) do check(d) end end
    end
    if #found == 0 then return nil end
    if #found == 1 then BallCustom.cachedBall = found[1]; return BallCustom.cachedBall end
    local hrp = State.HRP; local origin = hrp and hrp.Position
    if not origin then BallCustom.cachedBall = found[1]; return BallCustom.cachedBall end
    local best, bestDist = nil, math.huge
    for _, b in ipairs(found) do
        local d = (b.Position - origin).Magnitude
        if d < bestDist then bestDist, best = d, b end
    end
    BallCustom.cachedBall = best; return best
end
function bcAutoApply(ball)
    if not ball or not ball.Parent then return end
    if BallCustom.LastMeshId then pcall(bcSetMeshId, bcGetOrCreateMesh(ball), BallCustom.LastMeshId) end
    if BallCustom.LastTexId then pcall(bcSetTextures, ball, BallCustom.LastTexId) end
end
function applyBallCustom(meshId, texId)
    local mesh, tex = bcToAssetId(meshId), bcToAssetId(texId)
    if not mesh and not tex then Notify({ Title = "Ball Custom", Content = "Invalid ID.", Duration = 3 }); return false end
    if mesh then BallCustom.LastMeshId = mesh end
    if tex then BallCustom.LastTexId = tex end
    local ball = bcGetBall()
    if not ball then Notify({ Title = "Ball Custom", Content = "Saved. Will apply when a ball spawns.", Duration = 3 }); return true end
    bcAutoApply(ball); Notify({ Title = "Ball Custom", Content = "Applied!", Duration = 2, Icon = "check" }); return true
end
local BALL_PRESETS = {
    { Name = "Qatar 2022", Mesh = "rbxassetid://9802400541", Tex = "rbxassetid://9802410463" },
    { Name = "Copa 2018", Mesh = "rbxassetid://8717252855", Tex = "rbxassetid://8717257870" },
    { Name = "New Balance", Mesh = "rbxassetid://8719142749", Tex = "rbxassetid://8719146312" },
}
insert(onCharacterAdded, function()
    resetAimbotState()
    defer(function() wait_(1); bindAimbotTouch() end)
end)

--// MAIN HEARTBEAT
RunService.Heartbeat:Connect(function()
    local now = clock()
    Reach:stepLead(now, "")
    GKReach:stepLead(now, "GK:")
    BallReach:step(now)
    autoSwitchLegTick(now)
    if SilentAim then
        pcall(ApplySilentAim)
    end
    if MoreCurve then
        pcall(ApplyCurve)
    end
    if PowerShoot then
        pcall(ApplyPower)
    end
    if now - (AutoCatch._lastPrune or 0) > 5 then
        AutoCatch._lastPrune = now
        Reach:pruneLastTouch(now); GKReach:pruneLastTouch(now)
    end
    if AutoCatch.Enabled then
        local hum, hrp = State.Humanoid, State.HRP
        if hum and hrp and hum.Health > 0 and now - AutoCatch.LastCatch >= AutoCatch.Cooldown then
            local ball, dist = getNearestBall()
            if ball and dist <= AutoCatch.Range then fireCatchBall(ball) end
        end
    end
    if AimbotGoal.Enabled then
        CurrentTPS = FindTPS()
        local Ball = GetBallPart(CurrentTPS)
        if Ball then
            if not AimbotGoal.BallControl and not AimbotGoal.ShotDetected then
                local speed = Ball.AssemblyLinearVelocity.Magnitude
                if speed > 15 then AimbotGoal.ShotDetected, AimbotGoal.BallControl = true, true
                elseif detectAimbotShot(Ball) then AimbotGoal.ShotDetected, AimbotGoal.BallControl = true, true end
            end
            if AimbotGoal.BallControl then
                ensureOwnership(Ball)
                local Goal = getNearestAimbotGoal(Ball.Position)
                if Goal then
                    local dir = Goal - Ball.Position; local dist = dir.Magnitude
                    if dist <= AimbotGoal.DistanceToGoal then
                        pcall(function() Ball.AssemblyLinearVelocity = Vector3.zero end)
                        AimbotGoal.BallControl, AimbotGoal.ShotDetected, AimbotGoal.LastTouchTime = false, false, 0
                    else
                        local decel = aimbotDecelPerSec(); local speed = Ball.AssemblyLinearVelocity.Magnitude
                        local tSol
                        if speed > 0.1 and decel < -0.01 then
                            tSol = (-speed + math.sqrt(speed*speed + 2*(-decel)*dist)) / (-decel)
                        else tSol = dist / math.max(speed, 1) end
                        tSol = clamp(tSol, 0.05, 1.5)
                        local curve = Vector3.new(0, 0.5 * math.sin(tSol * 4), 0)
                        local target = Goal + curve
                        local v = (target - Ball.Position).Unit * AimbotGoal.Speed
                        pcall(function() Ball.AssemblyLinearVelocity = Ball.AssemblyLinearVelocity:Lerp(v, AimbotGoal.Smoothness) end)
                    end
                    recordBallVel(Ball)
                end
            end
        end
    end
    if Telekinesis.Enabled then
        CurrentTPS = FindTPS()
        local Ball = GetBallPart(CurrentTPS); local Camera = Workspace.CurrentCamera
        if Ball and Camera then
            ensureOwnership(Ball)
            local Direction = Camera.CFrame.LookVector
            local TargetVelocity = Direction * Telekinesis.Speed
            pcall(function() Ball.AssemblyLinearVelocity = Ball.AssemblyLinearVelocity:Lerp(TargetVelocity, Telekinesis.Smoothness) end)
            if Camera.CameraSubject ~= Ball then Camera.CameraSubject = Ball end
        end
    end
    if BallCustom.LastMeshId or BallCustom.LastTexId then
        if now - BallCustom._reapplyAt > 1.5 then
            BallCustom._reapplyAt = now
            local ball = BallCustom.cachedBall or bcGetBall()
            if ball and ball.Parent then
                local mesh = bcFindMesh(ball)
                local meshOk = (BallCustom.LastMeshId == nil) or (mesh and ((mesh:IsA("SpecialMesh") and mesh.MeshId == BallCustom.LastMeshId) or (mesh:IsA("MeshPart") and mesh.MeshId == BallCustom.LastMeshId)))
                local texOk = (BallCustom.LastTexId == nil)
                if not texOk then
                    for _, v in ipairs(ball:GetChildren()) do
                        if v:IsA("Texture") and v.Texture == BallCustom.LastTexId then texOk = true; break end
                    end
                end
                if not meshOk or not texOk then bcAutoApply(ball) end
            end
        end
    end
    runAutoDiveTick()
    beginTouchFrame()
end)

RunService.RenderStepped:Connect(function()
    CurrentTPS = resolveTPS(); UpdateESP(); updateTrajectoryPredict()
end)

Workspace.DescendantRemoving:Connect(function(d)
    if ballSet[d] then removeBall(d) end
    if d == CurrentTPS then
        CurrentTPS = nil; ESPHighlight.Adornee = nil; ESPHighlight.Enabled = false; resetAimbotState()
    end
    if d == BallCustom.cachedBall then BallCustom.cachedBall = nil end
end)

Workspace.DescendantAdded:Connect(function(d)
    if isTrackedBallPart(d) then
        addBall(d)
        if BallCustom.LastMeshId or BallCustom.LastTexId then task.defer(function() if d.Parent then bcAutoApply(d) end end) end
    end
    if d.Name == TPS_NAME then
        setTPSCache(d)
        if BallCustom.LastMeshId or BallCustom.LastTexId then
            task.defer(function() local b = GetBallPart(d); if b and b.Parent then bcAutoApply(b) end end)
        end
        task.defer(function()
            CurrentTPS = d
            if AimbotGoal.Enabled then bindAimbotTouch() end
            if Telekinesis.Enabled then
                local Ball = GetBallPart(CurrentTPS); local Camera = Workspace.CurrentCamera
                if Ball and Camera then ensureOwnership(Ball); Camera.CameraSubject = Ball end
            end
        end)
    end
end)

CurrentTPS = FindTPS()

--// UI BUILDER
local function resetKeybindToUnknown(keybindElement)
    if keybindElement then pcall(function() if keybindElement.SetValue then keybindElement:SetValue(UNKNOWN_KEY) end end) end
end
local function sec(tab, title)
    return tab:Section({ Title = title })
end

local function buildUI()
    local setAutoDiveMobileMode
    local setAutoDiveMobileJoystickSize
    local setAutoDiveMobileJumpSize
    local AutoDiveMobileOn = false
    local AutoDiveMobileJoystickOn = true
    local AutoDiveMobileJumpOn = true
    local UIKeybindName = UNKNOWN_KEY
    local _keybindElement = nil
    Window:SetToggleKey(Enum.KeyCode.LeftShift)
    KeybindManager.register("UItoggle", UNKNOWN_KEY, function() Window:Toggle() end)
    KeybindManager.register("FlowBall", UNKNOWN_KEY, function()
        setFollow(not Follow.Enabled)
        if Follow.MobileRefs then applyButtonState(Follow.MobileRefs, Follow.Enabled, "FLOW\nON", "FLOW\nOFF") end
        Notify({ Title = "Flow Ball", Content = Follow.Enabled and "ON" or "OFF", Duration = 1 })
    end)

    --// HOME
    do
        local sys = Tabs.Home
        sys:Button({ Title = "Player: " .. LocalPlayer.Name, Justify = "Left", Callback = function() end })
        local function getExecutor()
            if not identifyexecutor then return "Unknown" end
            local ok, ex = pcall(identifyexecutor)
            return (ok and ex) or "Unknown"
        end
        sys:Button({ Title = "Executor: " .. getExecutor(), Justify = "Left", Callback = function() end })
        sys:Button({ Title = "Platform: " .. (IsMobile and "Mobile/Tablet/iOS" or "PC/Desktop"), Justify = "Left", Callback = function() end })
    end

    --// REACH
    do
        local legs  = sec(Tabs.Reach, "Legs")
        local torso = sec(Tabs.Reach, "Torso")
        local head  = sec(Tabs.Reach, "Head")
        local ball  = sec(Tabs.Reach, "Ball Reach")
        legs:Toggle({ Title = "Enable Leg Reach", Flag = "Reach_Legs_Enabled", Default = false,
            Callback = function(v) ReachSettings.Legs.Enabled = v; scheduleReachUpdate(); onConfigChanged() end })
        legs:Slider({ Title = "Leg Size", Flag = "Reach_Legs_Size", Step = 0.5, Value = { Min = 0.5, Max = 20, Default = 1 },
            Callback = function(v) ReachSettings.Legs.Size = v; scheduleReachUpdate(); onConfigChanged() end })
        legs:Toggle({ Title = "Leg Visualizer", Flag = "Reach_Legs_Visualizer", Default = false,
            Callback = function(v) ReachSettings.Legs.Visualizer = v; ReachVisualizer:updateAll(); onConfigChanged() end })
        torso:Toggle({ Title = "Enable Torso Reach", Flag = "Reach_Torso_Enabled", Default = false,
            Callback = function(v) ReachSettings.Torso.Enabled = v; scheduleReachUpdate(); onConfigChanged() end })
        torso:Slider({ Title = "Torso Size", Flag = "Reach_Torso_Size", Step = 0.5, Value = { Min = 0.5, Max = 20, Default = 1 },
            Callback = function(v) ReachSettings.Torso.Size = v; scheduleReachUpdate(); onConfigChanged() end })
        torso:Toggle({ Title = "Torso Visualizer", Flag = "Reach_Torso_Visualizer", Default = false,
            Callback = function(v) ReachSettings.Torso.Visualizer = v; ReachVisualizer:updateAll(); onConfigChanged() end })
        head:Toggle({ Title = "Enable Head Reach", Flag = "Reach_Head_Enabled", Default = false,
            Callback = function(v) ReachSettings.Head.Enabled = v; scheduleReachUpdate(); onConfigChanged() end })
        head:Slider({ Title = "Head Size", Flag = "Reach_Head_Size", Step = 0.5, Value = { Min = 0.5, Max = 20, Default = 1 },
            Callback = function(v) ReachSettings.Head.Size = v; scheduleReachUpdate(); onConfigChanged() end })
        head:Toggle({ Title = "Head Visualizer", Flag = "Reach_Head_Visualizer", Default = false,
            Callback = function(v) ReachSettings.Head.Visualizer = v; ReachVisualizer:updateAll(); onConfigChanged() end })
        ball:Toggle({ Title = "Enable Reach Ball", Flag = "ReachBall_Enabled", Default = false,
            Callback = function(v) BallReachSettings.Enabled = v; if not v then BallReach:clearVisualizer() end; onConfigChanged() end })
        ball:Slider({ Title = "Reach Ball Size", Flag = "ReachBall_Size", Step = 0.5, Value = { Min = 0.5, Max = 20, Default = 1 },
            Callback = function(v) BallReachSettings.Size = v; onConfigChanged() end })
        ball:Toggle({ Title = "Reach Ball Visualizer", Flag = "ReachBall_Visualizer", Default = false,
            Callback = function(v) BallReachSettings.Visualizer = v; if not v then BallReach:clearVisualizer() end; onConfigChanged() end })
    end

    --// GK
    do
        local gkReach = sec(Tabs.GK, "GK Reach")
        local autoCatch = sec(Tabs.GK, "Auto Catch")
        local autoDive = sec(Tabs.GK, "Auto Dive")
        gkReach:Toggle({ Title = "Enable GK Reach", Flag = "GKReach_Enabled", Default = false,
            Callback = function(v) GKSettings.Enabled = v; scheduleReachUpdate(); onConfigChanged() end })
        gkReach:Slider({ Title = "GK Reach Size", Flag = "GKReach_Size", Step = 0.5, Value = { Min = 0.5, Max = 20, Default = 1 },
            Callback = function(v) GKSettings.Size = v; scheduleReachUpdate(); onConfigChanged() end })
        autoCatch:Toggle({ Title = "Enable Auto Catch", Flag = "AutoCatch_Enabled", Default = false,
            Callback = function(v) AutoCatch.Enabled = v; onConfigChanged() end })
        autoCatch:Slider({ Title = "Catch Distance", Flag = "AutoCatch_Range", Step = 1, Value = { Min = 1, Max = 150, Default = 50 },
            Callback = function(v) AutoCatch.Range = v; onConfigChanged() end })
        autoCatch:Slider({ Title = "Catch Cooldown", Flag = "AutoCatch_Cooldown", Step = 0.05, Value = { Min = 0.05, Max = 2, Default = 0.25 },
            Callback = function(v) AutoCatch.Cooldown = v; onConfigChanged() end })
        local function setAutoDiveState(v)
            if v then
                StartAutoDive()
            else
                StopAutoDive()
            end
            Notify({ Title = "Auto Dive", Content = v and "Enabled!" or "Disabled!", Duration = 2 })
        end
        KeybindManager.register("AutoDive", UNKNOWN_KEY, function() setAutoDiveState(not AutoDive.Enabled) end)
        autoDive:Toggle({ Title = "Enable Auto Dive", Flag = "AutoDive_Enabled", Default = false,
            Callback = function(v) setAutoDiveState(v); onConfigChanged() end })
        autoDive:Slider({ Title = "Dive Cooldown", Flag = "AutoDive_Cooldown", Step = 0.05, Value = { Min = 0.10, Max = 5.00, Default = 0.75 },
            Callback = function(v) AutoDive.DiveCooldown = v; AutoDive.Cooldown = v; onConfigChanged() end })
        autoDive:Toggle({ Title = "Cover Line (Idle)", Flag = "AutoDive_CoverLine", Default = true,
            Callback = function(v) AutoDive.CoverLine = v; onConfigChanged() end })
        autoDive:Toggle({ Title = "Auto Jump", Flag = "AutoDive_AutoJump", Default = true,
            Callback = function(v) AutoDive.AutoJump = v; onConfigChanged() end })
        autoDive:Toggle({ Title = "Auto Equip GK Tool", Flag = "AutoDive_EquipGK", Default = true,
            Callback = function(v) AutoDive.AutoEquipGK = v; onConfigChanged() end })

        local autoDiveMobile = sec(Tabs.GK, "Auto Dive Mobile")
        autoDiveMobile:Toggle({ Title = "Enable Auto Dive Mobile", Flag = "AutoDiveMobile_Enabled", Default = false,
            Callback = function(v)
                AutoDiveMobileOn = v
                if setAutoDiveMobileMode then setAutoDiveMobileMode(v) end
                if v then StartAutoDive() else StopAutoDive() end
                onConfigChanged()
            end })
        autoDiveMobile:Toggle({ Title = "Mobile Joystick", Flag = "AutoDiveMobile_Joystick", Default = true,
            Callback = function(v)
                AutoDiveMobileJoystickOn = v
                if AutoDiveMobileOn and setAutoDiveMobileMode then setAutoDiveMobileMode(true) end
                onConfigChanged()
            end })
        autoDiveMobile:Toggle({ Title = "Mobile Jump Button", Flag = "AutoDiveMobile_Jump", Default = true,
            Callback = function(v)
                AutoDiveMobileJumpOn = v
                if AutoDiveMobileOn and setAutoDiveMobileMode then setAutoDiveMobileMode(true) end
                onConfigChanged()
            end })
        autoDiveMobile:Slider({ Title = "Joystick Size", Flag = "AutoDiveMobile_JoystickSize", Step = 5,
            Value = { Min = 90, Max = 200, Default = 130 },
            Callback = function(v) if setAutoDiveMobileJoystickSize then setAutoDiveMobileJoystickSize(v) end; onConfigChanged() end })
        autoDiveMobile:Slider({ Title = "Jump Button Size", Flag = "AutoDiveMobile_JumpSize", Step = 4,
            Value = { Min = 40, Max = 160, Default = 72 },
            Callback = function(v) if setAutoDiveMobileJumpSize then setAutoDiveMobileJumpSize(v) end; onConfigChanged() end })

    end


    --// BALL ESP
    do
        local esp = sec(Tabs.BallESP, "Ball ESP")
        local predict = sec(Tabs.BallESP, "Predict Trajectory")
        esp:Toggle({ Title = "Enable Ball ESP", Flag = "BallESP_Enabled", Default = false,
            Callback = function(v) ESPBall = v; UpdateESP(); onConfigChanged() end })
        esp:Colorpicker({ Title = "ESP Ball Color", Flag = "BallESP_Color", Default = ESPBallColor, Transparency = 0,
            Callback = function(color) ESPBallColor = color; ESPHighlight.FillColor = color; ESPHighlight.OutlineColor = color; onConfigChanged() end })
        predict:Toggle({ Title = "Enable Predict", Flag = "TrajectoryPredict_Enabled", Default = false,
            Callback = function(v) PredictEnabled = v; if not v then destroyTrajectoryPredict() end; onConfigChanged() end })
        predict:Colorpicker({ Title = "Predict Arrow Color", Flag = "TrajectoryPredict_Color", Default = PredictColor, Transparency = 0,
            Callback = function(color) PredictColor = color; updatePredictAppearance(); onConfigChanged() end })
    end

    --// AIMBOT
    do
        local silentAimSec = sec(Tabs.Aimbot, "Silent Aim")
        silentAimSec:Toggle({ Title = "Silent Aim", Flag = "SilentAim_Enabled", Default = false,
            Callback = function(v) SilentAim = v; onConfigChanged() end })
        silentAimSec:Slider({ Title = "Aim Strength", Flag = "SilentAim_AimStrength", Step = 0.01,
            Value = { Min = 0.01, Max = 1, Default = 0.12 },
            Callback = function(v) AimStrength = v; onConfigChanged() end })
        silentAimSec:Slider({ Title = "Max Angle", Flag = "SilentAim_MaxAngle", Step = 1,
            Value = { Min = 5, Max = 90, Default = 40 },
            Callback = function(v) MaxAngle = v; onConfigChanged() end })

        local autoGoal = sec(Tabs.Aimbot, "Auto Goal")
        local aimbot = sec(Tabs.Aimbot, "Aimbot Goal")
        local tele = sec(Tabs.Aimbot, "Telekinesis")
        autoGoal:Toggle({ Title = "Auto Goal", Flag = "AutoGoal_Enabled", Default = false, Callback = function(v) setAutoGoal(v); onConfigChanged() end })
        autoGoal:Dropdown({ Title = "Select Goal", Flag = "AutoGoal_Target", Values = { "Goal (Green)", "Goal (Blue)" }, Value = "Goal (Green)",
            Callback = function(Value) SelectedGoal = (Value == "Goal (Green)") and "Goal 1" or "Goal 2"; onConfigChanged() end })
        aimbot:Toggle({ Title = "Enable Aimbot Goal", Flag = "Aimbot_Enabled", Default = false, Callback = function(v) setAimbotGoal(v); onConfigChanged() end })
        aimbot:Slider({ Title = "Aimbot Speed", Flag = "Aimbot_Speed", Step = 5, Value = { Min = 20, Max = 500, Default = 180 }, Callback = function(v) AimbotGoal.Speed = v; onConfigChanged() end })
        aimbot:Slider({ Title = "Aimbot Smoothness", Flag = "Aimbot_Smoothness", Step = 0.01, Value = { Min = 0.01, Max = 1, Default = 0.25 }, Callback = function(v) AimbotGoal.Smoothness = v; onConfigChanged() end })
        tele:Toggle({ Title = "Enable Telekinesis", Flag = "Telekinesis_Enabled", Default = false, Callback = function(v) setTelekinesis(v); onConfigChanged() end })
        tele:Slider({ Title = "Telekinesis Speed", Flag = "Telekinesis_Speed", Step = 5, Value = { Min = 20, Max = 500, Default = 180 }, Callback = function(v) Telekinesis.Speed = v; onConfigChanged() end })
        tele:Slider({ Title = "Telekinesis Smoothness", Flag = "Telekinesis_Smoothness", Step = 0.01, Value = { Min = 0.01, Max = 1, Default = 0.25 }, Callback = function(v) Telekinesis.Smoothness = v; onConfigChanged() end })
    end

    --// CHARS
    do
        local listSec = sec(Tabs.Chars, "Char")
        local CHAR_NICKS = {
            "Feliipeef","pret_oncio","jessnaldo","lucasbr8181","PositiveVapor","kvbberdad","kvbber","ongoal",
            "leolity","paulonetos05","candyxzzz0","zvbFaeTVXTq","defantastico","emaofj","5zB4y","ByGui08",
            "levi_furacao","o_lfk","feliou23","3qu","thunder65q","legendinho","talenttt","vnpthu","oxlade",
            "Dismalbeni","megutrap","brvnofalcon","Rhuanbla","SenAstrozx","I_Ruanblox","Rvnezzy","heheboi202000",
            "Nescauzin_skills","heitor756666","nexzaard","mitoashpikachu2","rosa_skillsz","zico_alt123","b_2020f",
            "ry_dinno","cachorrao_fla","barard28","yurinho_0011","deyvztcs","euperdro14","Alex151kk",
            "i3ftt","Messi901yr","NeverNerfDiper","cleemdk","Ywhte","Kako11fa","stivaneIli","vammpetta","FelIipeta","jucobala17",
        }
        local charButtons = {}
        local currentSearch = ""
        local function rebuildCharButtons(filter)
            filter = string.lower(filter or "")
            for i = 1, #charButtons do pcall(function() charButtons[i]:Destroy() end); charButtons[i] = nil end
            for i = 1, #CHAR_NICKS do
                local raw = CHAR_NICKS[i]
                if filter == "" or string.find(string.lower(raw), filter, 1, true) then
                    local cmd = ":char " .. raw
                    local btn = listSec:Button({ Title = ":char " .. raw, Justify = "Left", Icon = "user",
                        Callback = function()
                            local ok = sendGlobalMessage(cmd)
                            if ok then Notify({ Title = "Chars", Content = cmd .. " sent.", Duration = 2, Icon = "check" })
                            else Notify({ Title = "Chars", Content = "Failed to send.", Duration = 3 }) end
                        end })
                    if btn then charButtons[#charButtons + 1] = btn end
                end
            end
        end
        pcall(function()
            listSec:Input({ Title = "Search Nick", Placeholder = "type the nick here...",
                Callback = function(text) currentSearch = text or ""; rebuildCharButtons(currentSearch) end })
        end)
        listSec:Button({ Title = "Clear Char Filter", Justify = "Center", Icon = "x",
            Callback = function() currentSearch = ""; rebuildCharButtons("") end })
        rebuildCharButtons("")
    end

    --// KITS
    do
        local kitHomeSec = sec(Tabs.Kits, "Kit Home")
        local kitAwaySec = sec(Tabs.Kits, "Kit Away")
        local KITS_RAW = {
            { Team = "Corinthians", Type = "home", Command = "homekit", Id1 = "88856850708793", Id2 = "108313157540337" },
            { Team = "Cruzeiro", Type = "home", Command = "homekit", Id1 = "70926814136478", Id2 = "13107199852" },
            { Team = "França", Type = "home", Command = "homekit", Id1 = "102492906401842", Id2 = "119195677474230" },
            { Team = "Galo", Type = "home", Command = "homekit", Id1 = "7028912209", Id2 = "18771310063" },
            { Team = "Santos", Type = "home", Command = "homekit", Id1 = "121132840804685", Id2 = "91763222495878" },
            { Team = "Flamengo", Type = "away", Command = "awaykit", Id1 = "136058723687909", Id2 = "14944077080" },
            { Team = "Palmeiras", Type = "away", Command = "awaykit", Id1 = "139708295438764", Id2 = "78090547249690" },
        }
        local function buildKitCommand(kit) return ":" .. kit.Command .. " " .. kit.Id1 .. " " .. kit.Id2 end
        local function isHomeKit(kit) return kit.Command == "homekit" or kit.Command == "gkhomekit" end
        local function isAwayKit(kit) return kit.Command == "awaykit" or kit.Command == "gkawaykit" end
        local function addKitButton(parent, kit)
            local cmd = buildKitCommand(kit)
            parent:Button({ Title = kit.Team .. " | " .. kit.Type, Justify = "Left", Icon = "shirt",
                Callback = function()
                    local ok = sendGlobalMessage(cmd)
                    if ok then Notify({ Title = "Kits", Content = cmd .. " sent.", Duration = 2, Icon = "check" })
                    else Notify({ Title = "Kits", Content = "Failed to send.", Duration = 3 }) end
                end })
        end
        for i = 1, #KITS_RAW do if isHomeKit(KITS_RAW[i]) then addKitButton(kitHomeSec, KITS_RAW[i]) end end
        for i = 1, #KITS_RAW do if isAwayKit(KITS_RAW[i]) then addKitButton(kitAwaySec, KITS_RAW[i]) end end
    end

    --// HELPER
    local PerfectAngleState = {
        ShootEnabled = false, ToteEnabled = false,
        ToteButtonActive = { [Enum.KeyCode.R] = false, [Enum.KeyCode.T] = false },
        ToteKeyActive    = { [Enum.KeyCode.R] = false, [Enum.KeyCode.T] = false },
    }
    local setPerfectToteActive
    local applyPerfectAngleNow

    do
        local ForceAngle = { Enabled = false, Conn = nil, ValueConn = nil, BoundValue = nil,
            AngleValue = nil, AngleValueNextSearch = 0, AngleBool = nil, AngleBoolNextSearch = 0, CacheTTL = 0.5 }
        local function findAngleBarValue()
            local now = clock()
            if ForceAngle.AngleValue and ForceAngle.AngleValue.Parent then return ForceAngle.AngleValue end
            if now < ForceAngle.AngleValueNextSearch then return nil end
            ForceAngle.AngleValueNextSearch = now + ForceAngle.CacheTTL
            local v = ReplicatedStorage:FindFirstChild("AngleBarValue", true)
            if v and v:IsA("NumberValue") then ForceAngle.AngleValue = v; return v end
            ForceAngle.AngleValue = nil; return nil
        end
        local function unbindAngleValue()
            if ForceAngle.ValueConn then pcall(function() ForceAngle.ValueConn:Disconnect() end); ForceAngle.ValueConn = nil end
            ForceAngle.BoundValue = nil
        end
        local function bindAngleValue(angleVal)
            if ForceAngle.BoundValue == angleVal and ForceAngle.ValueConn then return end
            unbindAngleValue(); if not angleVal then return end
            ForceAngle.BoundValue = angleVal
            ForceAngle.ValueConn = angleVal:GetPropertyChangedSignal("Value"):Connect(function()
                if not ForceAngle.Enabled then return end
                local target
                if PerfectAngleState.ToteEnabled and (PerfectAngleState.ToteButtonActive[Enum.KeyCode.R] or PerfectAngleState.ToteButtonActive[Enum.KeyCode.T] or PerfectAngleState.ToteKeyActive[Enum.KeyCode.R] or PerfectAngleState.ToteKeyActive[Enum.KeyCode.T]) then target = 27
                elseif PerfectAngleState.ShootEnabled then target = 13 end
                if target and angleVal.Parent and angleVal.Value ~= target then pcall(function() angleVal.Value = target end) end
            end)
        end
        local function findAngleBarBool()
            local now = clock()
            if ForceAngle.AngleBool and ForceAngle.AngleBool.Parent then return ForceAngle.AngleBool end
            if now < ForceAngle.AngleBoolNextSearch then return nil end
            ForceAngle.AngleBoolNextSearch = now + ForceAngle.CacheTTL
            local v = ReplicatedStorage:FindFirstChild("AngleBar")
            if v and v:IsA("BoolValue") then ForceAngle.AngleBool = v; return v end
            ForceAngle.AngleBool = nil; return nil
        end
        local function tickForceAngle()
            local target
            if PerfectAngleState.ToteEnabled and (PerfectAngleState.ToteButtonActive[Enum.KeyCode.R] or PerfectAngleState.ToteButtonActive[Enum.KeyCode.T] or PerfectAngleState.ToteKeyActive[Enum.KeyCode.R] or PerfectAngleState.ToteKeyActive[Enum.KeyCode.T]) then target = 27
            elseif PerfectAngleState.ShootEnabled then target = 13 end
            if not target then unbindAngleValue(); return end
            local angleVal = findAngleBarValue()
            if angleVal then
                bindAngleValue(angleVal)
                if angleVal.Value ~= target then pcall(function() angleVal.Value = target end) end
            else unbindAngleValue() end
            local angleBar = findAngleBarBool()
            if angleBar and not angleBar.Value then pcall(function() angleBar.Value = true end) end
        end
        applyPerfectAngleNow = tickForceAngle
        local function ensureForceAngleConnection()
            if not ForceAngle.Conn then ForceAngle.Conn = RunService.Heartbeat:Connect(tickForceAngle) end
        end
        local function stopForceAngleConnectionIfUnused()
            if PerfectAngleState.ShootEnabled or PerfectAngleState.ToteEnabled then return end
            if ForceAngle.Conn then ForceAngle.Conn:Disconnect(); ForceAngle.Conn = nil end
            unbindAngleValue()
        end
        local function setShootEnabled(v)
            PerfectAngleState.ShootEnabled = v
            ForceAngle.Enabled = PerfectAngleState.ShootEnabled or PerfectAngleState.ToteEnabled
            if ForceAngle.Enabled then ensureForceAngleConnection(); tickForceAngle() else stopForceAngleConnectionIfUnused() end
        end
        local function setToteEnabled(v)
            PerfectAngleState.ToteEnabled = v
            ForceAngle.Enabled = PerfectAngleState.ShootEnabled or PerfectAngleState.ToteEnabled
            if ForceAngle.Enabled then ensureForceAngleConnection(); tickForceAngle() else stopForceAngleConnectionIfUnused() end
        end
        setPerfectToteActive = function(keyCode, active)
            if keyCode ~= Enum.KeyCode.R and keyCode ~= Enum.KeyCode.T then return end
            PerfectAngleState.ToteButtonActive[keyCode] = active
            if applyPerfectAngleNow then applyPerfectAngleNow() end
        end
        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.T then
                PerfectAngleState.ToteKeyActive[input.KeyCode] = true
                if applyPerfectAngleNow then applyPerfectAngleNow() end
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.T then
                PerfectAngleState.ToteKeyActive[input.KeyCode] = false
                if applyPerfectAngleNow then applyPerfectAngleNow() end
            end
        end)

        --// MOBILE MODE SYSTEM — Auto Skill vs TOTE
        local MobileControls = {
            Mode = "none", -- "none" | "tote" | "autoskill" | "autodive"
            Gui = nil,
            Conns = {},
            CreatedJoystick = false,
            JumpSize = 72,
            JumpBtn = nil,
        }

        local function destroyMobileGui()
            for i = #MobileControls.Conns, 1, -1 do
                pcall(function() MobileControls.Conns[i]:Disconnect() end)
                MobileControls.Conns[i] = nil
            end
            if MobileControls.Gui then MobileControls.Gui:Destroy(); MobileControls.Gui = nil end
            MobileControls.JumpBtn = nil
        end

        local function ensureJoystick()
            if not CustomJoystick.Enabled then
                CustomJoystick.create()
                MobileControls.CreatedJoystick = true
            else
                MobileControls.CreatedJoystick = false
            end
        end

        local function releaseJoystick()
            if MobileControls.CreatedJoystick and CustomJoystick.Enabled then
                CustomJoystick.destroy()
            end
            MobileControls.CreatedJoystick = false
        end

        local function makeDraggable(btn)
            local dragging, movedThisGesture = false, false
            local activeInput, startPos, startBtnPos = nil, nil, nil
            insert(MobileControls.Conns, btn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging, movedThisGesture = true, false; activeInput = input
                    startPos, startBtnPos = input.Position, btn.Position
                end
            end))
            insert(MobileControls.Conns, UserInputService.InputChanged:Connect(function(input)
                if not dragging or activeInput ~= input then return end
                local delta = input.Position - startPos
                if not movedThisGesture then
                    if math.abs(delta.X) > 10 or math.abs(delta.Y) > 10 then movedThisGesture = true else return end
                end
                btn.Position = UDim2.new(startBtnPos.X.Scale, startBtnPos.X.Offset + delta.X, startBtnPos.Y.Scale, startBtnPos.Y.Offset + delta.Y)
            end))
            insert(MobileControls.Conns, UserInputService.InputEnded:Connect(function(input)
                if activeInput == input then dragging = false; activeInput = nil end
            end))
            return function() local w = movedThisGesture; movedThisGesture = false; return w end
        end

        local function styleFlowLikeButton(btn, labelText)
            local size = UDim2.fromOffset(130, 58)
            btn.Size = size
            btn.BackgroundColor3 = MobileButtons.colors.offBG
            btn.BackgroundTransparency = 0.1
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Text = ""
            btn.ClipsDescendants = true
            if BG_ASSET and BG_ASSET ~= "" then
                local bg = Instance.new("ImageLabel")
                bg.Name = "FlowLikeBackground"
                bg.Size = UDim2.fromScale(1, 1); bg.Position = UDim2.fromScale(0, 0)
                bg.BackgroundTransparency = 1; bg.Image = BG_ASSET
                bg.ImageTransparency = 0.25; bg.ScaleType = Enum.ScaleType.Crop; bg.ZIndex = 0
                bg.Parent = btn
                Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 12)
            end
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
            local grad = Instance.new("UIGradient", btn)
            grad.Name = "FlowLikeGradient"; grad.Rotation = 90
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 65, 90)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 32, 46)),
            })
            grad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.35),
            })
            grad.Parent = btn
            local stroke = Instance.new("UIStroke", btn)
            stroke.Name = "FlowLikeStroke"; stroke.Thickness = 1.5
            stroke.Color = MobileButtons.colors.offStroke; stroke.Transparency = 0.3
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual; stroke.Parent = btn
            local label = Instance.new("TextLabel", btn)
            label.Name = "FlowLikeLabel"
            label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
            label.Text = labelText; label.TextColor3 = Color3.fromRGB(255, 255, 255)
            label.TextSize = 18; label.Font = Enum.Font.GothamBold
            label.TextStrokeTransparency = 0.5; label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            label.ZIndex = 3; label.Parent = btn
            return stroke, label
        end

        local function buildJumpButton(screenGui)
            local jumpBtn = Instance.new("TextButton")
            jumpBtn.Name = "Mobile_Jump"
            local js = MobileControls.JumpSize
            jumpBtn.AnchorPoint = Vector2.new(0.5, 0.5)
            jumpBtn.Size = UDim2.fromOffset(js, js)
            jumpBtn.Position = UDim2.new(1, -150, 1, -105)
            jumpBtn.Parent = screenGui
            local jumpStroke, jumpLabel = styleFlowLikeButton(jumpBtn, "JUMP")
            local getJumpMoved = makeDraggable(jumpBtn)
            jumpLabel.TextSize = math.max(14, math.floor(js * 0.22))
            MobileControls.JumpBtn = jumpBtn
            insert(MobileControls.Conns, jumpBtn.MouseButton1Click:Connect(function()
                if getJumpMoved() then return end
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.Jump = true; pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
                jumpBtn.BackgroundColor3 = MobileButtons.colors.onBG
                task.delay(0.15, function() if jumpBtn.Parent then jumpBtn.BackgroundColor3 = MobileButtons.colors.offBG end end)
            end))
        end

        local function buildTOTEGui()
            destroyMobileGui()
            ensureJoystick()
            pcall(function() require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Disable() end)
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "TOTEGui"; screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true; screenGui.DisplayOrder = 999
            screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            MobileControls.Gui = screenGui
            local RTCfg = {
                { name = "R", key = Enum.KeyCode.R, x = -150, y = -235 },
                { name = "T", key = Enum.KeyCode.T, x = -150, y = -305 },
            }
            for _, item in ipairs(RTCfg) do
                local btn = Instance.new("TextButton")
                btn.Name = "TOTE_" .. item.name
                btn.Position = UDim2.new(1, item.x, 1, item.y)
                btn.Parent = screenGui
                local stroke, label = styleFlowLikeButton(btn, item.name)
                local getMoved = makeDraggable(btn)
                local isPressed = false
                insert(MobileControls.Conns, btn.MouseButton1Click:Connect(function()
                    if getMoved() then return end
                    if isPressed then
                        isPressed = false
                        if setPerfectToteActive then setPerfectToteActive(item.key, false) end
                        label.Text = item.name
                        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = MobileButtons.colors.offBG, BackgroundTransparency = 0.1 }):Play()
                        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = MobileButtons.colors.offStroke }):Play()
                        VirtualInputManager:SendKeyEvent(false, item.key, false, game)
                    else
                        isPressed = true
                        if setPerfectToteActive then setPerfectToteActive(item.key, true) end
                        label.Text = item.name .. "  ON"
                        TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = MobileButtons.colors.onBG, BackgroundTransparency = 0.55 }):Play()
                        TweenService:Create(stroke, TweenInfo.new(0.15), { Color = MobileButtons.colors.onStroke }):Play()
                        VirtualInputManager:SendKeyEvent(true, item.key, false, game)
                    end
                end))
            end
            buildJumpButton(screenGui)
        end

        local function buildAutoSkillGui()
            destroyMobileGui()
            ensureJoystick()
            pcall(function() require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Disable() end)
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "AutoSkillGui"; screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true; screenGui.DisplayOrder = 999
            screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            MobileControls.Gui = screenGui
            buildJumpButton(screenGui)
        end

        local function buildAutoDiveGui()
            destroyMobileGui()
            if AutoDiveMobileJoystickOn then
                ensureJoystick()
                pcall(function() require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Disable() end)
            end
            local screenGui = Instance.new("ScreenGui")
            screenGui.Name = "AutoDiveMobileGui"; screenGui.ResetOnSpawn = false
            screenGui.IgnoreGuiInset = true; screenGui.DisplayOrder = 999
            screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            MobileControls.Gui = screenGui
            if AutoDiveMobileJumpOn then
                buildJumpButton(screenGui)
            end
        end

        setAutoDiveMobileJoystickSize = function(v)
            v = tonumber(v) or 130
            CustomJoystick.Size = v
            CustomJoystick.KnobSize = math.floor(v * 0.46)
            if CustomJoystick.Enabled and AutoDiveMobileOn then
                CustomJoystick.destroy(); CustomJoystick.create()
            end
        end

        setAutoDiveMobileJumpSize = function(v)
            v = tonumber(v) or 72
            MobileControls.JumpSize = v
            local jb = MobileControls.JumpBtn
            if jb and jb.Parent then
                jb.Size = UDim2.fromOffset(v, v)
                local lbl = jb:FindFirstChild("FlowLikeLabel")
                if lbl then lbl.TextSize = math.max(12, math.floor(v * 0.22)) end
            end
        end

        local function setMobileMode(mode)
            if MobileControls.Mode == mode then return end
            MobileControls.Mode = mode
            if mode == "none" then
                destroyMobileGui()
                releaseJoystick()
                pcall(function() require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls():Enable() end)
            elseif mode == "tote" then
                buildTOTEGui()
            elseif mode == "autoskill" then
                buildAutoSkillGui()
            elseif mode == "autodive" then
                buildAutoDiveGui()
            end
        end

        -- Toggle TOTE
        local TOTEOn = false
        local AutoSkillOn = false

        local function refreshMode()
            if TOTEOn then
                setMobileMode("tote")
            elseif AutoSkillOn then
                setMobileMode("autoskill")
            elseif AutoDiveMobileOn then
                setMobileMode("autodive")
            else
                setMobileMode("none")
            end
        end

        setAutoDiveMobileMode = function(enabled)
            AutoDiveMobileOn = enabled == true
            refreshMode()
        end

        local switchLegSec = sec(Tabs.Helper, "Switch")
        switchLegSec:Toggle({ Title = "Enable Auto Switch Leg", Flag = "AutoSwitchLeg_Enabled", Default = false,
            Callback = function(v)
                AutoSwitchLeg.Enabled = v
                if v then
                    local tm = getToolManagement()
                    if not tm then
                        Notify({ Title = "Auto Switch Leg", Content = "ToolManagement não encontrado.", Duration = 3 })
                    else
                        Notify({ Title = "Auto Switch Leg", Content = "Enabled!", Duration = 2, Icon = "check" })
                    end
                else
                    Notify({ Title = "Auto Switch Leg", Content = "Disabled!", Duration = 2 })
                end
                onConfigChanged()
            end })
        switchLegSec:Slider({ Title = "Ball Range (studs)", Flag = "AutoSwitchLeg_BallRange", Step = 1,
            Value = { Min = 5, Max = 40, Default = 15 },
            Callback = function(v) AutoSwitchLeg.BallRange = v; onConfigChanged() end })
        switchLegSec:Slider({ Title = "Side Deadzone (studs)", Flag = "AutoSwitchLeg_Deadzone", Step = 0.1,
            Value = { Min = 0.1, Max = 5, Default = 0.8 },
            Callback = function(v) AutoSwitchLeg.SideDeadzone = v; onConfigChanged() end })
        switchLegSec:Slider({ Title = "Switch Cooldown (s)", Flag = "AutoSwitchLeg_Cooldown", Step = 0.01,
            Value = { Min = 0.05, Max = 2, Default = 0.15 },
            Callback = function(v) AutoSwitchLeg.Cooldown = v; onConfigChanged() end })

        local toteSec      = sec(Tabs.Helper, "TOTE")
        local angBar       = sec(Tabs.Helper, "Perfect AngleBar")
        local flow         = sec(Tabs.Helper, "Flow Ball")
        local autoSkillSec = sec(Tabs.Helper, "Auto Skill")

        toteSec:Toggle({ Title = "Enable TOTE buttons (R / T / Jump)", Flag = "TOTE_Enabled", Default = false,
            Callback = function(v)
                TOTEOn = v
                refreshMode()
                if v then Notify({ Title = "TOTE", Content = "Enabled!", Duration = 2 })
                else Notify({ Title = "TOTE", Content = "Disabled.", Duration = 2 }) end
                onConfigChanged()
            end })
        toteSec:Slider({ Title = "Joystick Size", Flag = "TOTE_JoystickSize", Step = 5,
            Value = { Min = 90, Max = 200, Default = 130 },
            Callback = function(v)
                CustomJoystick.Size = v
                CustomJoystick.KnobSize = math.floor(v * 0.46)
                if CustomJoystick.Enabled then CustomJoystick.destroy(); CustomJoystick.create() end
                onConfigChanged()
            end })
        toteSec:Slider({ Title = "Jump Button Size", Flag = "TOTE_JumpSize", Step = 4,
            Value = { Min = 40, Max = 160, Default = 72 },
            Callback = function(v)
                MobileControls.JumpSize = v
                local jb = MobileControls.JumpBtn
                if jb and jb.Parent then
                    jb.Size = UDim2.fromOffset(v, v)
                    local lbl = jb:FindFirstChild("FlowLikeLabel")
                    if lbl then lbl.TextSize = math.max(12, math.floor(v * 0.22)) end
                end
                onConfigChanged()
            end })

        angBar:Toggle({ Title = "Enable Perfect AngleBar Shoot", Flag = "ForceAngle_Enabled", Default = false,
            Callback = function(v) setShootEnabled(v); onConfigChanged() end })
        angBar:Toggle({ Title = "Enable Perfect AngleBar Tote", Flag = "PerfectAngleTote_Enabled", Default = false,
            Callback = function(v)
                setToteEnabled(v)
                if not v then
                    PerfectAngleState.ToteButtonActive[Enum.KeyCode.R] = false
                    PerfectAngleState.ToteButtonActive[Enum.KeyCode.T] = false
                    PerfectAngleState.ToteKeyActive[Enum.KeyCode.R] = false
                    PerfectAngleState.ToteKeyActive[Enum.KeyCode.T] = false
                    if applyPerfectAngleNow then applyPerfectAngleNow() end
                end
                onConfigChanged()
            end })

        flow:Slider({ Title = "Flow Stop Distance", Flag = "FlowBall_Distance", Step = 0.5, Value = { Min = 0.5, Max = 30, Default = 0.5 },
            Callback = function(v) Follow.Distance = math.max(0.5, tonumber(v) or 0.5); onConfigChanged() end })
        local _flowKeybindEl = flow:Keybind({ Title = "Flow Ball Keybind", Flag = "FlowBall_Keybind", Value = UNKNOWN_KEY,
            Callback = function(v) local kc = resolveKeyCode(v); if kc then KeybindManager.setKey("FlowBall", kc.Name); onConfigChanged() end end })
        flow:Button({ Title = "Reset Flow Ball Keybind", Justify = "Center", Icon = "rotate-ccw",
            Callback = function() KeybindManager.setKey("FlowBall", UNKNOWN_KEY); resetKeybindToUnknown(_flowKeybindEl); onConfigChanged() end })
        flow:Toggle({ Title = "Flow Ball Mobile Button", Default = false,
            Callback = function(v)
                if v then
                    local _, refs = createMobileButton("LuaFlowMobile", "FLOW\nOFF", function()
                        setFollow(not Follow.Enabled)
                        if Follow.MobileRefs then applyButtonState(Follow.MobileRefs, Follow.Enabled, "FLOW\nON", "FLOW\nOFF") end
                    end)
                    Follow.MobileRefs = refs
                    if Follow.Enabled then applyButtonState(refs, true, "FLOW\nON", "FLOW\nOFF") end
                else
                    destroyMobileButton("LuaFlowMobile"); Follow.MobileRefs = nil
                end
            end })

        --// AUTO SKILL
        local AutoSkill = {
            Enabled = false,
            Combos = {
                ["X + T + PASS E + X + T + T"] = {
                    { Key = Enum.KeyCode.X, Tool = "Dribble" },
                    { Key = Enum.KeyCode.T, Tool = "Dribble" },
                    { Key = Enum.KeyCode.E, Tool = "PASS"    },
                    { Key = Enum.KeyCode.X, Tool = "Dribble" },
                    { Key = Enum.KeyCode.T, Tool = "Dribble" },
                    { Key = Enum.KeyCode.T, Tool = "Dribble" },
                },
                ["Pass E + X + Z + N"] = {
                    { Key = Enum.KeyCode.E, Tool = "PASS"    },
                    { Key = Enum.KeyCode.X, Tool = "Dribble" },
                    { Key = Enum.KeyCode.Z, Tool = "Dribble" },
                    { Key = Enum.KeyCode.N, Tool = "Dribble" },
                },
                ["Dribble (Z X N)"] = {
                    { Key = Enum.KeyCode.Z, Tool = "Dribble" },
                    { Key = Enum.KeyCode.X, Tool = "Dribble" },
                    { Key = Enum.KeyCode.N, Tool = "Dribble" },
                },
                ["Combo (M + Pula + T + N)"] = {
                    { Key = Enum.KeyCode.M, Tool = "Dribble" },
                    { Key = "JUMP", Tool = "Dribble" },
                    { Key = Enum.KeyCode.T, Tool = "Dribble" },
                    { Key = Enum.KeyCode.N, Tool = "Dribble" },
                },
                ["C + E + X + R + T + M"] = {
                    { Key = Enum.KeyCode.C, Tool = "Dribble" },
                    { Key = Enum.KeyCode.E, Tool = "Dribble" },
                    { Key = Enum.KeyCode.X, Tool = "Dribble" },
                    { Key = Enum.KeyCode.R, Tool = "Dribble" },
                    { Key = Enum.KeyCode.T, Tool = "Dribble" },
                    { Key = Enum.KeyCode.M, Tool = "Dribble" },
                },
            },
            SelectedCombo = "X + T + PASS E + X + T + T",
            CurrentIndex = 1,
            LastKeyTime = 0,
            Cooldown = 0.25,
            AutoEquip = true,
            BallRange = 6,
        }
        local function findToolByName(name)
            local char = LocalPlayer.Character
            local backpack = LocalPlayer:FindFirstChild("Backpack")
            local lower = string.lower(name)
            local function matches(item)
                if not item or not item:IsA("Tool") then return false end
                local n = string.lower(item.Name)
                return n == lower or string.find(n, lower, 1, true) ~= nil
            end
            if char then for _, item in ipairs(char:GetChildren()) do if matches(item) then return item end end end
            if backpack then for _, item in ipairs(backpack:GetChildren()) do if matches(item) then return item end end end
            return nil
        end
        local function equipToolByName(name)
            if not AutoSkill.AutoEquip then return true end
            local char = LocalPlayer.Character; if not char then return false end
            local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
            local tool = findToolByName(name); if not tool then return false end
            if tool.Parent ~= char then
                pcall(function() hum:EquipTool(tool) end)
                task.wait(0.05)
            end
            return true
        end
        local function sendKey(keyCode)
            if typeof(keyCode) ~= "EnumItem" then return false end
            return pcall(function()
                VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
                task.wait(0.03)
                VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
            end)
        end
        local function executeJump()
            local char = LocalPlayer.Character; if not char then return false end
            local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
            hum.Jump = true
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            return true
        end
        local function isNearBall()
            local hrp = State.HRP
            if not hrp then return false end
            local ball = getNearestBall()
            if not ball then return false end
            return (hrp.Position - ball.Position).Magnitude <= AutoSkill.BallRange
        end
        local function autoSkillLoop()
            while AutoSkill.Enabled do
                if not isNearBall() then
                    if AutoSkill.CurrentIndex ~= 1 then AutoSkill.CurrentIndex = 1 end
                else
                    local now = clock()
                    if now - AutoSkill.LastKeyTime >= AutoSkill.Cooldown then
                        local combo = AutoSkill.Combos[AutoSkill.SelectedCombo]
                        if combo then
                            local entry = combo[AutoSkill.CurrentIndex]
                            if entry then
                                if AutoSkill.AutoEquip and entry.Tool then equipToolByName(entry.Tool) end
                                if entry.Key == "JUMP" then executeJump() else sendKey(entry.Key) end
                                AutoSkill.LastKeyTime = clock()
                                AutoSkill.CurrentIndex = AutoSkill.CurrentIndex + 1
                                if AutoSkill.CurrentIndex > #combo then AutoSkill.CurrentIndex = 1 end
                            end
                        end
                    end
                end
                RunService.Heartbeat:Wait()
            end
        end
        local function setAutoSkillState(v)
            if AutoSkill.Enabled == v then return end
            AutoSkill.Enabled = v
            AutoSkillOn = v
            if v then
                AutoSkill.CurrentIndex = 1
                AutoSkill.LastKeyTime = 0
                refreshMode()
                task.spawn(autoSkillLoop)
                Notify({ Title = "Auto Skill", Content = "Enabled!", Duration = 2, Icon = "check" })
            else
                refreshMode()
                Notify({ Title = "Auto Skill", Content = "Disabled!", Duration = 2 })
            end
        end
        autoSkillSec:Dropdown({
            Title = "Skill Combo",
            Flag = "AutoSkill_Combo",
            Values = {
                "X + T + PASS E + X + T + T",
                "Pass E + X + Z + N",
                "Dribble (Z X N)",
                "Combo (M + Pula + T + N)",
                "C + E + X + R + T + M",
            },
            Value = "X + T + PASS E + X + T + T",
            Callback = function(Value)
                AutoSkill.SelectedCombo = Value
                AutoSkill.CurrentIndex = 1
                Notify({ Title = "Auto Skill", Content = "Combo: " .. Value, Duration = 2 })
                onConfigChanged()
            end
        })
        autoSkillSec:Toggle({ Title = "Enable Auto Skill", Flag = "AutoSkill_Enabled", Default = false,
            Callback = function(v) setAutoSkillState(v); onConfigChanged() end })
        autoSkillSec:Slider({ Title = "Global Cooldown (s)", Flag = "AutoSkill_Cooldown", Step = 0.01,
            Value = { Min = 0.05, Max = 2.00, Default = 0.25 },
            Callback = function(v) AutoSkill.Cooldown = v; onConfigChanged() end })
        autoSkillSec:Slider({ Title = "Ball Range (studs)", Flag = "AutoSkill_BallRange", Step = 0.5,
            Value = { Min = 1, Max = 30, Default = 6 },
            Callback = function(v) AutoSkill.BallRange = v; onConfigChanged() end })
        autoSkillSec:Toggle({ Title = "Auto Equip Tool", Flag = "AutoSkill_AutoEquip", Default = true,
            Callback = function(v) AutoSkill.AutoEquip = v; onConfigChanged() end })
        local _autoSkillKeybindEl = autoSkillSec:Keybind({ Title = "Auto Skill Toggle Key", Flag = "AutoSkill_ToggleKey", Value = UNKNOWN_KEY,
            Callback = function(v) local kc = resolveKeyCode(v); if kc then KeybindManager.setKey("AutoSkill", kc.Name); onConfigChanged() end end })
        autoSkillSec:Button({ Title = "Reset Auto Skill Keybind", Justify = "Center", Icon = "rotate-ccw",
            Callback = function()
                KeybindManager.setKey("AutoSkill", UNKNOWN_KEY)
                resetKeybindToUnknown(_autoSkillKeybindEl)
                onConfigChanged()
            end })
        KeybindManager.register("AutoSkill", UNKNOWN_KEY, function() setAutoSkillState(not AutoSkill.Enabled) end)
    end

    --// MISC
    do
        local powerShootSec = sec(Tabs.Misc, "Power Shoot")
        powerShootSec:Toggle({ Title = "Power Shoot", Flag = "PowerShoot_Enabled", Default = false,
            Callback = function(v) PowerShoot = v; onConfigChanged() end })
        powerShootSec:Slider({ Title = "Power", Flag = "PowerShoot_Power", Step = 1,
            Value = { Min = 50, Max = 500, Default = 150 },
            Callback = function(v) ShootPower = v; onConfigChanged() end })

        local moreCurveSec = Tabs.Misc:Section({
            Title = "More Curve",
            Opened = true,
        })
        moreCurveSec:Toggle({
            Title = "More Curve",
            Flag = "MoreCurve_Enabled",
            Value = false,
            Callback = function(v)
                MoreCurve = v
                onConfigChanged()
            end,
        })
        moreCurveSec:Slider({
            Title = "Curve",
            Desc = "Curve Power",
            Flag = "MoreCurve_Power",
            Step = 1,
            IsTooltip = true,
            IsTextbox = true,
            Width = 220,
            Value = {
                Min = 0,
                Max = 100,
                Default = 35,
            },
            Callback = function(v)
                CurvePower = v
                onConfigChanged()
            end,
        })

        local flingBallSec = sec(Tabs.Misc, "Fling Ball")
        flingBallSec:Button({ Title = "Fling Ball", Justify = "Center", Icon = "zap",
            Callback = function() FlingBall() end })
        flingBallSec:Slider({ Title = "Força do Fling", Flag = "FlingBall_Force", Step = 1,
            Value = { Min = 100, Max = 800, Default = 300 },
            Callback = function(v) FlingBallForce = v; onConfigChanged() end })

        local stretch = sec(Tabs.Misc, "Screen Stretch")
        stretch:Toggle({ Title = "Enable Screen Stretch", Flag = "Modifier_Stretch_Enabled", Default = false,
            Callback = function(v) Modifier.StretchToggleOn = v; refreshStretchState(); onConfigChanged() end })
        stretch:Slider({ Title = "Screen Stretch Scale (%)", Flag = "Modifier_Stretch_Scale", Step = 1,
            Value = { Min = 40, Max = 100, Default = 100 },
            Callback = function(v) Modifier.StretchScale = v; refreshStretchState(); onConfigChanged() end })
    end

    --// SKIN CHANGER
    do
        local ballSkin = sec(Tabs.SkinChanger, "Ball Skins")
        local meshInputRef, texInputRef
        pcall(function() meshInputRef = ballSkin:Input({ Title = "Mesh ID", Placeholder = "rbxassetid://...", Callback = function() end }) end)
        pcall(function() texInputRef  = ballSkin:Input({ Title = "Texture ID", Placeholder = "rbxassetid://...", Callback = function() end }) end)
        local function readInputValue(ref)
            if not ref then return "" end
            local inst = ref
            if type(inst) == "table" then
                for _, key in ipairs({ "Instance", "Object", "UIElement", "UI", "Main", "Frame", "Button", "TextBox", "Root", "Element" }) do
                    local v = inst[key]
                    if typeof(v) == "Instance" then inst = v; break end
                end
            end
            if typeof(inst) == "Instance" then
                local tb = inst:IsA("TextBox") and inst or inst:FindFirstChildWhichIsA("TextBox", true)
                if tb then return tb.Text end
            end
            return ""
        end
        ballSkin:Button({ Title = "Apply Ball Custom", Justify = "Center", Icon = "check",
            Callback = function() applyBallCustom(readInputValue(meshInputRef), readInputValue(texInputRef)) end })
        for _, preset in ipairs(BALL_PRESETS) do
            ballSkin:Button({ Title = preset.Name, Justify = "Left", Icon = "circle",
                Callback = function() applyBallCustom(preset.Mesh, preset.Tex) end })
        end
    end

    --// SETTINGS
    do
        local uiKey = sec(Tabs.Settings, "UI Keybind")
        local cfg = sec(Tabs.Settings, "Save Manager")
        _keybindElement = uiKey:Keybind({ Title = "UI Toggle Keybind", Flag = "UI_Keybind", Value = UNKNOWN_KEY,
            Callback = function(v)
                local key = Enum.KeyCode[v]
                if key then
                    Window:SetToggleKey(key)
                    KeybindManager.setKey("UItoggle", key.Name)
                    onConfigChanged()
                end
            end
        })

        local configName = "Luatcs"
        local configInput = cfg:Input({ Title = "Config Name", Value = configName, Placeholder = "Config name...",
            Callback = function(v) configName = tostring(v or "Luatcs"); if configName == "" then configName = "Luatcs" end end })
        local configDropdown = cfg:Dropdown({ Title = "Saved Configs", Values = ConfigManager:AllConfigs(),
            Value = table.find(ConfigManager:AllConfigs(), configName) and configName or nil, AllowNone = true,
            Callback = function(v) if v and v ~= "" then configName = v; pcall(function() configInput:Set(v) end) end end })
        local function refreshConfigs() pcall(function() configDropdown:Refresh(ConfigManager:AllConfigs()) end) end

        cfg:Button({ Title = "Save Config", Justify = "Center", Icon = "save", Callback = function()
            local name = configName ~= "" and configName or "Luatcs"
            local ok, result = pcall(function() local c = ConfigManager:CreateConfig(name); Window.CurrentConfig = c; return c:Save() end)
            if ok and result then refreshConfigs(); Notify({ Title = "Config Manager", Content = "Saved: " .. name, Duration = 2 })
            else Notify({ Title = "Config Manager", Content = "Failed to save: " .. name, Duration = 3 }) end
        end })
        cfg:Button({ Title = "Load Config", Justify = "Center", Icon = "upload", Callback = function()
            local name = configName ~= "" and configName or "Luatcs"
            local ok, result = pcall(function() local c = ConfigManager:CreateConfig(name); Window.CurrentConfig = c; return c:Load() end)
            if ok and result ~= false then Notify({ Title = "Config Manager", Content = "Loaded: " .. name, Duration = 2 })
            else Notify({ Title = "Config Manager", Content = "Config not found: " .. name, Duration = 3 }) end
        end })
        cfg:Button({ Title = "Delete Config", Justify = "Center", Icon = "trash-2", Callback = function()
            local name = configName ~= "" and configName or "Luatcs"
            local ok, result = pcall(function() return ConfigManager:DeleteConfig(name) end)
            if ok and result then refreshConfigs(); Notify({ Title = "Config Manager", Content = "Deleted: " .. name, Duration = 2 })
            else Notify({ Title = "Config Manager", Content = "Could not delete: " .. name, Duration = 3 }) end
        end })
        cfg:Toggle({ Title = "Auto Save Config", Flag = "Config_AutoSave", Default = false, Callback = function(v)
            AutoSaveEnabled = v; if v then pcall(function() uiConfig:Save() end) end
        end })
        cfg:Toggle({ Title = "Auto Load Selected Config", Flag = "Config_AutoLoad", Default = false, Callback = function(v)
            pcall(function() (Window.CurrentConfig or uiConfig):SetAutoLoad(v) end); onConfigChanged()
        end })
    end
end

buildUI()

script.Destroying:Connect(function()
    if CustomJoystick and CustomJoystick.Enabled then CustomJoystick.destroy() end
    if KeybindManager.inputConn then pcall(function() KeybindManager.inputConn:Disconnect() end) end
    stopFollow()
    Modifier.StretchToggleOn, Modifier.StretchEnabled, Modifier.StretchBound = false, false, false
    pcall(function() RunService:UnbindFromRenderStep("LuatcsStretch") end)
    setAutoGoal(false); setAimbotGoal(false); setTelekinesis(false)
    StopAutoDive()
    AutoSwitchLeg.Enabled = false
    Reach:clearAll(); GKReach:clearAll()
    destroyAllReachVisualizers()
    BallReach:clearVisualizer()
    destroyTrajectoryPredict()
    if ESPHighlight then ESPHighlight:Destroy() end
    for name in pairs(MobileButtons.registry) do destroyMobileButton(name) end
end)

Notify({ Title = "Lua - The Classic", Content = "Loaded v2.2.0 — Auto Skill + Ball features", Duration = 5, Icon = "check" })
