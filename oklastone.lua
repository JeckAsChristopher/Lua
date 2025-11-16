-- POV Lock GUI - Ultimate Edition - PART 1
-- Complete code - Copy all parts and paste together

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Teams = game:GetService("Teams")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Settings
local povActive = false
local lockDistance = 350
local smoothing = 0.35
local lockOn = false
local lockedTarget = nil
local lockedConn = nil
local selectedTeams = {"Guards"}
local isMinimized = false
local crosshairType = "default"
local multiTargetEnabled = false
local multiTargetRadius = 150
local fhftEnabled = false
local lastAttacker = nil

-- Save/Load Settings
local function saveSettings()
    local settings = {
        selectedTeams = selectedTeams,
        crosshairType = crosshairType,
        lockDistance = lockDistance,
        smoothing = smoothing,
        multiTargetEnabled = multiTargetEnabled,
        multiTargetRadius = multiTargetRadius,
        fhftEnabled = fhftEnabled
    }
    local success, err = pcall(function()
        writefile("pov_lock_settings.json", HttpService:JSONEncode(settings))
    end)
    if not success then
        warn("Failed to save settings:", err)
    end
end

local function loadSettings()
    local success, result = pcall(function()
        if isfile("pov_lock_settings.json") then
            return HttpService:JSONDecode(readfile("pov_lock_settings.json"))
        end
    end)
    if success and result then
        selectedTeams = result.selectedTeams or {"Guards"}
        crosshairType = result.crosshairType or "default"
        lockDistance = result.lockDistance or 350
        smoothing = result.smoothing or 0.35
        multiTargetEnabled = result.multiTargetEnabled or false
        multiTargetRadius = result.multiTargetRadius or 150
        fhftEnabled = result.fhftEnabled or false
    end
end

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POV_Lock_GUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Size = UDim2.new(0, 300, 0, 380)
container.Position = UDim2.new(1, -320, 0, 20)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
container.BorderSizePixel = 0
container.ClipsDescendants = true
container.Active = true
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 12)
containerCorner.Parent = container

local rgbBorder = Instance.new("UIStroke")
rgbBorder.Color = Color3.fromRGB(255, 0, 0)
rgbBorder.Thickness = 2
rgbBorder.Transparency = 0.3
rgbBorder.Parent = container

local gradient = Instance.new("Frame")
gradient.Size = UDim2.new(1, 0, 1, 0)
gradient.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
gradient.BackgroundTransparency = 0.95
gradient.BorderSizePixel = 0
gradient.ZIndex = 1
gradient.Parent = container

local gradientCorner = Instance.new("UICorner")
gradientCorner.CornerRadius = UDim.new(0, 12)
gradientCorner.Parent = gradient

local uiGradient = Instance.new("UIGradient")
uiGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255))
})
uiGradient.Rotation = 45
uiGradient.Parent = gradient

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 0, 0, 3)
accentBar.Position = UDim2.new(0, 0, 0, 0)
accentBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 3
accentBar.Parent = container

local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Size = UDim2.new(1, 0, 1, -40)
contentContainer.Position = UDim2.new(0, 0, 0, 40)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.ScrollBarThickness = 4
contentContainer.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
contentContainer.CanvasSize = UDim2.new(0, 0, 0, 440)
contentContainer.ZIndex = 2
contentContainer.Parent = container

local titleContainer = Instance.new("Frame")
titleContainer.Size = UDim2.new(1, -16, 0, 32)
titleContainer.Position = UDim2.new(0, 8, 0, 8)
titleContainer.BackgroundTransparency = 1
titleContainer.ZIndex = 5
titleContainer.Active = true
titleContainer.Parent = container

local titleIcon = Instance.new("Frame")
titleIcon.Size = UDim2.new(0, 20, 0, 20)
titleIcon.Position = UDim2.new(0, 2, 0, 6)
titleIcon.BackgroundTransparency = 1
titleIcon.ZIndex = 5
titleIcon.Parent = titleContainer

local iconOuter = Instance.new("Frame")
iconOuter.Size = UDim2.new(1, 0, 1, 0)
iconOuter.Position = UDim2.new(0.5, 0, 0.5, 0)
iconOuter.AnchorPoint = Vector2.new(0.5, 0.5)
iconOuter.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
iconOuter.BorderSizePixel = 0
iconOuter.ZIndex = 5
iconOuter.Parent = titleIcon

local iconOuterCorner = Instance.new("UICorner")
iconOuterCorner.CornerRadius = UDim.new(1, 0)
iconOuterCorner.Parent = iconOuter

local iconOuterStroke = Instance.new("UIStroke")
iconOuterStroke.Color = Color3.fromRGB(100, 150, 255)
iconOuterStroke.Thickness = 2
iconOuterStroke.Parent = iconOuter

local iconInner = Instance.new("Frame")
iconInner.Size = UDim2.new(0.5, 0, 0.5, 0)
iconInner.Position = UDim2.new(0.5, 0, 0.5, 0)
iconInner.AnchorPoint = Vector2.new(0.5, 0.5)
iconInner.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
iconInner.BorderSizePixel = 0
iconInner.ZIndex = 5
iconInner.Parent = titleIcon

local iconInnerCorner = Instance.new("UICorner")
iconInnerCorner.CornerRadius = UDim.new(1, 0)
iconInnerCorner.Parent = iconInner

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 28, 0, 0)
title.BackgroundTransparency = 1
title.Text = "POV LOCK"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 5
title.Parent = titleContainer

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 6
closeBtn.Parent = titleContainer

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

local closeX1 = Instance.new("Frame")
closeX1.Size = UDim2.new(0, 12, 0, 2)
closeX1.Position = UDim2.new(0.5, 0, 0.5, 0)
closeX1.AnchorPoint = Vector2.new(0.5, 0.5)
closeX1.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeX1.BorderSizePixel = 0
closeX1.Rotation = 45
closeX1.ZIndex = 7
closeX1.Parent = closeBtn

local closeX1Corner = Instance.new("UICorner")
closeX1Corner.CornerRadius = UDim.new(0, 1)
closeX1Corner.Parent = closeX1

local closeX2 = Instance.new("Frame")
closeX2.Size = UDim2.new(0, 12, 0, 2)
closeX2.Position = UDim2.new(0.5, 0, 0.5, 0)
closeX2.AnchorPoint = Vector2.new(0.5, 0.5)
closeX2.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeX2.BorderSizePixel = 0
closeX2.Rotation = -45
closeX2.ZIndex = 7
closeX2.Parent = closeBtn

local closeX2Corner = Instance.new("UICorner")
closeX2Corner.CornerRadius = UDim.new(0, 1)
closeX2Corner.Parent = closeX2

local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Position = UDim2.new(1, -56, 0, 4)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
minimizeBtn.Text = ""
minimizeBtn.AutoButtonColor = false
minimizeBtn.ZIndex = 6
minimizeBtn.Parent = titleContainer

local minimizeBtnCorner = Instance.new("UICorner")
minimizeBtnCorner.CornerRadius = UDim.new(0, 6)
minimizeBtnCorner.Parent = minimizeBtn

local minimizeIcon = Instance.new("Frame")
minimizeIcon.Size = UDim2.new(0, 10, 0, 2)
minimizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
minimizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
minimizeIcon.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
minimizeIcon.BorderSizePixel = 0
minimizeIcon.ZIndex = 7
minimizeIcon.Parent = minimizeBtn

local minimizeIconCorner = Instance.new("UICorner")
minimizeIconCorner.CornerRadius = UDim.new(0, 1)
minimizeIconCorner.Parent = minimizeIcon

local minimizeIconV = Instance.new("Frame")
minimizeIconV.Size = UDim2.new(0, 2, 0, 10)
minimizeIconV.Position = UDim2.new(0.5, 0, 0.5, 0)
minimizeIconV.AnchorPoint = Vector2.new(0.5, 0.5)
minimizeIconV.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
minimizeIconV.BorderSizePixel = 0
minimizeIconV.Visible = false
minimizeIconV.ZIndex = 7
minimizeIconV.Parent = minimizeBtn

local minimizeIconVCorner = Instance.new("UICorner")
minimizeIconVCorner.CornerRadius = UDim.new(0, 1)
minimizeIconVCorner.Parent = minimizeIconV

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(1, -16, 0, 16)
statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 6
statusDot.Parent = container

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(1, 0)
statusCorner.Parent = statusDot

local toggleRow = Instance.new("Frame")
toggleRow.Size = UDim2.new(1, -16, 0, 36)
toggleRow.Position = UDim2.new(0, 8, 0, 8)
toggleRow.BackgroundTransparency = 1
toggleRow.ZIndex = 3
toggleRow.Parent = contentContainer

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.48, 0, 1, 0)
toggleBtn.Position = UDim2.new(0, 0, 0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 3
toggleBtn.Parent = toggleRow

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(60, 60, 70)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggleBtn

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(1, 0, 1, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "OFF"
toggleLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
toggleLabel.Font = Enum.Font.GothamBold
toggleLabel.TextSize = 13
toggleLabel.ZIndex = 4
toggleLabel.Parent = toggleBtn

local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(0.48, 0, 1, 0)
lockBtn.Position = UDim2.new(0.52, 0, 0, 0)
lockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
lockBtn.Text = ""
lockBtn.AutoButtonColor = false
lockBtn.ZIndex = 3
lockBtn.Parent = toggleRow

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 8)
lockCorner.Parent = lockBtn

local lockStroke = Instance.new("UIStroke")
lockStroke.Color = Color3.fromRGB(60, 60, 70)
lockStroke.Thickness = 1.5
lockStroke.Parent = lockBtn

local lockIcon = Instance.new("Frame")
lockIcon.Size = UDim2.new(0, 12, 0, 14)
lockIcon.Position = UDim2.new(0, 8, 0.5, -7)
lockIcon.BackgroundTransparency = 1
lockIcon.ZIndex = 4
lockIcon.Parent = lockBtn

local lockBody = Instance.new("Frame")
lockBody.Size = UDim2.new(0, 12, 0, 9)
lockBody.Position = UDim2.new(0, 0, 1, -9)
lockBody.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
lockBody.BorderSizePixel = 0
lockBody.ZIndex = 4
lockBody.Parent = lockIcon

local lockBodyCorner = Instance.new("UICorner")
lockBodyCorner.CornerRadius = UDim.new(0, 2)
lockBodyCorner.Parent = lockBody

local lockKeyhole = Instance.new("Frame")
lockKeyhole.Size = UDim2.new(0, 2, 0, 3)
lockKeyhole.Position = UDim2.new(0.5, 0, 0.3, 0)
lockKeyhole.AnchorPoint = Vector2.new(0.5, 0)
lockKeyhole.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
lockKeyhole.BorderSizePixel = 0
lockKeyhole.ZIndex = 5
lockKeyhole.Parent = lockBody

local lockKeyholeCorner = Instance.new("UICorner")
lockKeyholeCorner.CornerRadius = UDim.new(1, 0)
lockKeyholeCorner.Parent = lockKeyhole

local lockShackle = Instance.new("Frame")
lockShackle.Size = UDim2.new(0, 8, 0, 6)
lockShackle.Position = UDim2.new(0.5, 0, 0, 0)
lockShackle.AnchorPoint = Vector2.new(0.5, 0)
lockShackle.BackgroundTransparency = 1
lockShackle.BorderSizePixel = 0
lockShackle.ZIndex = 4
lockShackle.Name = "LockShackle"
lockShackle.Parent = lockIcon

local lockShackleStroke = Instance.new("UIStroke")
lockShackleStroke.Color = Color3.fromRGB(200, 200, 210)
lockShackleStroke.Thickness = 2
lockShackleStroke.Parent = lockShackle

local lockShackleCorner = Instance.new("UICorner")
lockShackleCorner.CornerRadius = UDim.new(1, 0)
lockShackleCorner.Parent = lockShackle

local lockLabel = Instance.new("TextLabel")
lockLabel.Size = UDim2.new(1, -28, 1, 0)
lockLabel.Position = UDim2.new(0, 24, 0, 0)
lockLabel.BackgroundTransparency = 1
lockLabel.Text = "LOCK"
lockLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
lockLabel.Font = Enum.Font.GothamBold
lockLabel.TextSize = 12
lockLabel.TextXAlignment = Enum.TextXAlignment.Left
lockLabel.ZIndex = 4
lockLabel.Parent = lockBtn

local fhftRow = Instance.new("Frame")
fhftRow.Size = UDim2.new(1, -16, 0, 32)
fhftRow.Position = UDim2.new(0, 8, 0, 52)
fhftRow.BackgroundTransparency = 1
fhftRow.ZIndex = 3
fhftRow.Parent = contentContainer

local fhftBtn = Instance.new("TextButton")
fhftBtn.Size = UDim2.new(1, 0, 1, 0)
fhftBtn.Position = UDim2.new(0, 0, 0, 0)
fhftBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
fhftBtn.Text = ""
fhftBtn.AutoButtonColor = false
fhftBtn.ZIndex = 3
fhftBtn.Parent = fhftRow

local fhftCorner = Instance.new("UICorner")
fhftCorner.CornerRadius = UDim.new(0, 8)
fhftCorner.Parent = fhftBtn

local fhftStroke = Instance.new("UIStroke")
fhftStroke.Color = Color3.fromRGB(60, 60, 70)
fhftStroke.Thickness = 1.5
fhftStroke.Parent = fhftBtn

local fhftLabel = Instance.new("TextLabel")
fhftLabel.Size = UDim2.new(1, -40, 1, 0)
fhftLabel.Position = UDim2.new(0, 12, 0, 0)
fhftLabel.BackgroundTransparency = 1
fhftLabel.Text = "FHFT (First Hurt First Target)"
fhftLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
fhftLabel.Font = Enum.Font.GothamMedium
fhftLabel.TextSize = 11
fhftLabel.TextXAlignment = Enum.TextXAlignment.Left
fhftLabel.ZIndex = 4
fhftLabel.Parent = fhftBtn

local fhftStatus = Instance.new("TextLabel")
fhftStatus.Size = UDim2.new(0, 30, 1, 0)
fhftStatus.Position = UDim2.new(1, -36, 0, 0)
fhftStatus.BackgroundTransparency = 1
fhftStatus.Text = "OFF"
fhftStatus.TextColor3 = Color3.fromRGB(150, 150, 160)
fhftStatus.Font = Enum.Font.GothamBold
fhftStatus.TextSize = 10
fhftStatus.ZIndex = 4
fhftStatus.Parent = fhftBtn

local multiRow = Instance.new("Frame")
multiRow.Size = UDim2.new(1, -16, 0, 32)
multiRow.Position = UDim2.new(0, 8, 0, 92)
multiRow.BackgroundTransparency = 1
multiRow.ZIndex = 3
multiRow.Parent = contentContainer

local multiBtn = Instance.new("TextButton")
multiBtn.Size = UDim2.new(1, 0, 1, 0)
multiBtn.Position = UDim2.new(0, 0, 0, 0)
multiBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
multiBtn.Text = ""
multiBtn.AutoButtonColor = false
multiBtn.ZIndex = 3
multiBtn.Parent = multiRow

local multiCorner = Instance.new("UICorner")
multiCorner.CornerRadius = UDim.new(0, 8)
multiCorner.Parent = multiBtn

local multiStroke = Instance.new("UIStroke")
multiStroke.Color = Color3.fromRGB(60, 60, 70)
multiStroke.Thickness = 1.5
multiStroke.Parent = multiBtn

local multiLabel = Instance.new("TextLabel")
multiLabel.Size = UDim2.new(1, -40, 1, 0)
multiLabel.Position = UDim2.new(0, 12, 0, 0)
multiLabel.BackgroundTransparency = 1
multiLabel.Text = "Multi-Target Mode"
multiLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
multiLabel.Font = Enum.Font.GothamMedium
multiLabel.TextSize = 11
multiLabel.TextXAlignment = Enum.TextXAlignment.Left
multiLabel.ZIndex = 4
multiLabel.Parent = multiBtn

local multiStatus = Instance.new("TextLabel")
multiStatus.Size = UDim2.new(0, 30, 1, 0)
multiStatus.Position = UDim2.new(1, -36, 0, 0)
multiStatus.BackgroundTransparency = 1
multiStatus.Text = "OFF"
multiStatus.TextColor3 = Color3.fromRGB(150, 150, 160)
multiStatus.Font = Enum.Font.GothamBold
multiStatus.TextSize = 10
multiStatus.ZIndex = 4
multiStatus.Parent = multiBtn

local teamSectionLabel = Instance.new("TextLabel")
teamSectionLabel.Size = UDim2.new(1, -16, 0, 20)
teamSectionLabel.Position = UDim2.new(0, 8, 0, 132)
teamSectionLabel.BackgroundTransparency = 1
teamSectionLabel.Text = "TARGET TEAMS (Click to select multiple)"
teamSectionLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
teamSectionLabel.Font = Enum.Font.GothamBold
teamSectionLabel.TextSize = 10
teamSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
teamSectionLabel.ZIndex = 3
teamSectionLabel.Parent = contentContainer

local teamListContainer = Instance.new("Frame")
teamListContainer.Size = UDim2.new(1, -16, 0, 100)
teamListContainer.Position = UDim2.new(0, 8, 0, 154)
teamListContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
teamListContainer.BorderSizePixel = 0
teamListContainer.ZIndex = 3
teamListContainer.Parent = contentContainer

local teamListCorner = Instance.new("UICorner")
teamListCorner.CornerRadius = UDim.new(0, 8)
teamListCorner.Parent = teamListContainer

local teamListStroke = Instance.new("UIStroke")
teamListStroke.Color = Color3.fromRGB(50, 50, 60)
teamListStroke.Thickness = 1
teamListStroke.Parent = teamListContainer

local teamScrolling = Instance.new("ScrollingFrame")
teamScrolling.Size = UDim2.new(1, 0, 1, 0)
teamScrolling.BackgroundTransparency = 1
teamScrolling.BorderSizePixel = 0
teamScrolling.ScrollBarThickness = 3
teamScrolling.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
teamScrolling.CanvasSize = UDim2.new(0, 0, 0, 0)
teamScrolling.ZIndex = 4
teamScrolling.Parent = teamListContainer

local teamListLayout = Instance.new("UIListLayout")
teamListLayout.Padding = UDim.new(0, 2)
teamListLayout.SortOrder = Enum.SortOrder.LayoutOrder
teamListLayout.Parent = teamScrolling

teamListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    teamScrolling.CanvasSize = UDim2.new(0, 0, 0, teamListLayout.AbsoluteContentSize.Y + 4)
end)

local crosshairSectionLabel = Instance.new("TextLabel")
crosshairSectionLabel.Size = UDim2.new(1, -16, 0, 18)
crosshairSectionLabel.Position = UDim2.new(0, 8, 0, 262)
crosshairSectionLabel.BackgroundTransparency = 1
crosshairSectionLabel.Text = "CROSSHAIR TYPE"
crosshairSectionLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
crosshairSectionLabel.Font = Enum.Font.GothamBold
crosshairSectionLabel.TextSize = 10
crosshairSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
crosshairSectionLabel.ZIndex = 3
crosshairSectionLabel.Parent = contentContainer

local crosshairContainer = Instance.new("Frame")
crosshairContainer.Size = UDim2.new(1, -16, 0, 80)
crosshairContainer.Position = UDim2.new(0, 8, 0, 282)
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.ZIndex = 3
crosshairContainer.Parent = contentContainer

local crosshairGrid = Instance.new("UIGridLayout")
crosshairGrid.CellSize = UDim2.new(0, 88, 0, 38)
crosshairGrid.CellPadding = UDim2.new(0, 4, 0, 4)
crosshairGrid.SortOrder = Enum.SortOrder.LayoutOrder
crosshairGrid.Parent = crosshairContainer

local infoPanel = Instance.new("Frame")
infoPanel.Size = UDim2.new(1, -16, 0, 60)
infoPanel.Position = UDim2.new(0, 8, 0, 370)
infoPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
infoPanel.BorderSizePixel = 0
infoPanel.ZIndex = 3
infoPanel.Parent = contentContainer

local infoPanelCorner = Instance.new("UICorner")
infoPanelCorner.CornerRadius = UDim.new(0, 8)
infoPanelCorner.Parent = infoPanel

local infoPanelStroke = Instance.new("UIStroke")
infoPanelStroke.Color = Color3.fromRGB(50, 50, 60)
infoPanelStroke.Thickness = 1
infoPanelStroke.Parent = infoPanel

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -16, 0, 24)
nameLabel.Position = UDim2.new(0, 8, 0, 8)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "● No Target"
nameLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
nameLabel.Font = Enum.Font.GothamMedium
nameLabel.TextSize = 12
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.ZIndex = 4
nameLabel.Parent = infoPanel

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(1, -16, 0, 20)
distLabel.Position = UDim2.new(0, 8, 0, 32)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Range: -- studs"
distLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
distLabel.Font = Enum.Font.Gotham
distLabel.TextSize = 10
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.ZIndex = 4
distLabel.Parent = infoPanel

local crosshairDisplay = Instance.new("Frame")
crosshairDisplay.Size = UDim2.new(0, 60, 0, 60)
crosshairDisplay.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairDisplay.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairDisplay.BackgroundTransparency = 1
crosshairDisplay.Visible = false
crosshairDisplay.ZIndex = 10
crosshairDisplay.Parent = screenGui

local crosshairDefault = Instance.new("Frame")
crosshairDefault.Size = UDim2.new(1, 0, 1, 0)
crosshairDefault.BackgroundTransparency = 1
crosshairDefault.Name = "Default"
crosshairDefault.Parent = crosshairDisplay

local defaultTop = Instance.new("Frame")
defaultTop.Size = UDim2.new(0, 2, 0, 8)
defaultTop.Position = UDim2.new(0.5, 0, 0.5, -16)
defaultTop.AnchorPoint = Vector2.new(0.5, 1)
defaultTop.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
defaultTop.BorderSizePixel = 0
defaultTop.ZIndex = 11
defaultTop.Parent = crosshairDefault

local defaultTopStroke = Instance.new("UIStroke")
defaultTopStroke.Color = Color3.fromRGB(0, 0, 0)
defaultTopStroke.Thickness = 1
defaultTopStroke.Parent = defaultTop

local defaultBottom = Instance.new("Frame")
defaultBottom.Size = UDim2.new(0, 2, 0, 8)
defaultBottom.Position = UDim2.new(0.5, 0, 0.5, 16)
defaultBottom.AnchorPoint = Vector2.new(0.5, 0)
defaultBottom.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
defaultBottom.BorderSizePixel = 0
defaultBottom.ZIndex = 11
defaultBottom.Parent = crosshairDefault

local defaultBottomStroke = Instance.new("UIStroke")
defaultBottomStroke.Color = Color3.fromRGB(0, 0, 0)
defaultBottomStroke.Thickness = 1
defaultBottomStroke.Parent = defaultBottom

local defaultLeft = Instance.new("Frame")
defaultLeft.Size = UDim2.new(0, 8, 0, 2)
defaultLeft.Position = UDim2.new(0.5, -16, 0.5, 0)
defaultLeft.AnchorPoint = Vector2.new(1, 0.5)
defaultLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
defaultLeft.BorderSizePixel = 0
defaultLeft.ZIndex = 11
defaultLeft.Parent = crosshairDefault

local defaultLeftStroke = Instance.new("UIStroke")
defaultLeftStroke.Color = Color3.fromRGB(0, 0, 0)
defaultLeftStroke.Thickness = 1
defaultLeftStroke.Parent = defaultLeft

local defaultRight = Instance.new("Frame")
defaultRight.Size = UDim2.new(0, 8, 0, 2)
defaultRight.Position = UDim2.new(0.5, 16, 0.5, 0)
defaultRight.AnchorPoint = Vector2.new(0, 0.5)
defaultRight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
defaultRight.BorderSizePixel = 0
defaultRight.ZIndex = 11
defaultRight.Parent = crosshairDefault

local defaultRightStroke = Instance.new("UIStroke")
defaultRightStroke.Color = Color3.fromRGB(0, 0, 0)
defaultRightStroke.Thickness = 1
defaultRightStroke.Parent = defaultRight

local defaultCenter = Instance.new("Frame")
defaultCenter.Size = UDim2.new(0, 3, 0, 3)
defaultCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
defaultCenter.AnchorPoint = Vector2.new(0.5, 0.5)
defaultCenter.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
defaultCenter.BorderSizePixel = 0
defaultCenter.ZIndex = 11
defaultCenter.Parent = crosshairDefault

local defaultCenterCorner = Instance.new("UICorner")
defaultCenterCorner.CornerRadius = UDim.new(1, 0)
defaultCenterCorner.Parent = defaultCenter

local crosshairCircle = Instance.new("Frame")
crosshairCircle.Size = UDim2.new(1, 0, 1, 0)
crosshairCircle.BackgroundTransparency = 1
crosshairCircle.Name = "Circle"
crosshairCircle.Visible = false
crosshairCircle.Parent = crosshairDisplay

local circleOuter = Instance.new("Frame")
circleOuter.Size = UDim2.new(0, 30, 0, 30)
circleOuter.AnchorPoint = Vector2.new(0.5, 0.5)
circleOuter.Position = UDim2.new(0.5, 0, 0.5, 0)
circleOuter.BackgroundTransparency = 1
circleOuter.BorderSizePixel = 0
circleOuter.ZIndex = 11
circleOuter.Parent = crosshairCircle

local circleStroke = Instance.new("UIStroke")
circleStroke.Color = Color3.fromRGB(255, 255, 255)
circleStroke.Thickness = 2
circleStroke.Parent = circleOuter

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circleOuter

local circleDot = Instance.new("Frame")
circleDot.Size = UDim2.new(0, 4, 0, 4)
circleDot.AnchorPoint = Vector2.new(0.5, 0.5)
circleDot.Position = UDim2.new(0.5, 0, 0.5, 0)
circleDot.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
circleDot.BorderSizePixel = 0
circleDot.ZIndex = 11
circleDot.Parent = crosshairCircle

local circleDotCorner = Instance.new("UICorner")
circleDotCorner.CornerRadius = UDim.new(1, 0)
circleDotCorner.Parent = circleDot

local crosshairBox = Instance.new("Frame")
crosshairBox.Size = UDim2.new(1, 0, 1, 0)
crosshairBox.BackgroundTransparency = 1
crosshairBox.Name = "Box"
crosshairBox.Visible = false
crosshairBox.Parent = crosshairDisplay

local boxOuter = Instance.new("Frame")
boxOuter.Size = UDim2.new(0, 26, 0, 26)
boxOuter.AnchorPoint = Vector2.new(0.5, 0.5)
boxOuter.Position = UDim2.new(0.5, 0, 0.5, 0)
boxOuter.BackgroundTransparency = 1
boxOuter.BorderSizePixel = 0
boxOuter.ZIndex = 11
boxOuter.Parent = crosshairBox

local boxStroke = Instance.new("UIStroke")
boxStroke.Color = Color3.fromRGB(255, 255, 255)
boxStroke.Thickness = 2
boxStroke.Parent = boxOuter

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 3)
boxCorner.Parent = boxOuter

local boxDot = Instance.new("Frame")
boxDot.Size = UDim2.new(0, 3, 0, 3)
boxDot.AnchorPoint = Vector2.new(0.5, 0.5)
boxDot.Position = UDim2.new(0.5, 0, 0.5, 0)
boxDot.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
boxDot.BorderSizePixel = 0
boxDot.ZIndex = 11
boxDot.Parent = crosshairBox

local boxDotCorner = Instance.new("UICorner")
boxDotCorner.CornerRadius = UDim.new(1, 0)
boxDotCorner.Parent = boxDot

local multiTargetCircle = Instance.new("Frame")
multiTargetCircle.Size = UDim2.new(0, multiTargetRadius * 2, 0, multiTargetRadius * 2)
multiTargetCircle.AnchorPoint = Vector2.new(0.5, 0.5)
multiTargetCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
multiTargetCircle.BackgroundTransparency = 1
multiTargetCircle.Visible = false
multiTargetCircle.ZIndex = 9
multiTargetCircle.Parent = screenGui

local multiCircleStroke = Instance.new("UIStroke")
multiCircleStroke.Color = Color3.fromRGB(100, 200, 255)
multiCircleStroke.Thickness = 2
multiCircleStroke.Transparency = 0.5
multiCircleStroke.Parent = multiTargetCircle

local multiCircleCorner = Instance.new("UICorner")
multiCircleCorner.CornerRadius = UDim.new(1, 0)
multiCircleCorner.Parent = multiTargetCircle

local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 60) % 360
    rgbBorder.Color = Color3.fromHSV(hue / 360, 1, 1)
end)

local function tweenButton(button, active)
    local color = active and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(40, 40, 50)
    local strokeColor = active and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70)
    TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = color}):Play()
    local stroke = button:FindFirstChildOfClass("UIStroke")
    if stroke then
        TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Color = strokeColor, Thickness = active and 2 or 1.5}):Play()
    end
end

local function animateAccentBar(active)
    local targetSize = active and UDim2.new(1, 0, 0, 3) or UDim2.new(0, 0, 0, 3)
    TweenService:Create(accentBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
end

local function animateStatusDot(active)
    local color = active and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(100, 100, 110)
    TweenService:Create(statusDot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = color}):Play()
    if active then
        spawn(function()
            while povActive do
                TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.5}):Play()
                wait(0.8)
                if povActive then
                    TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0}):Play()
                    wait(0.8)
                end
            end
        end)
    else
        statusDot.BackgroundTransparency = 0
    end
end

local function updateCrosshair(type)
    crosshairDefault.Visible = (type == "default")
    crosshairCircle.Visible = (type == "circle")
    crosshairBox.Visible = (type == "box")
end

local function toggleMinimize()
    isMinimized = not isMinimized
    if isMinimized then
        contentContainer.Visible = false
        minimizeIconV.Visible = true
        container.Size = UDim2.new(0, 300, 0, 40)
    else
        contentContainer.Visible = true
        minimizeIconV.Visible = false
        container.Size = UDim2.new(0, 300, 0, 380)
    end
end

local dragging = false
local dragStart
local startPos
local dragInput

titleContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = container.Position
        dragInput = input
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

titleContainer.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        if dragInput == input or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
end)

local function isTeamSelected(teamName)
    for _, selectedTeam in ipairs(selectedTeams) do
        if selectedTeam == teamName then
            return true
        end
    end
    return false
end

local function toggleTeamSelection(teamName)
    local maxTeams = #Teams:GetTeams()
    if isTeamSelected(teamName) then
        for i, selectedTeam in ipairs(selectedTeams) do
            if selectedTeam == teamName then
                table.remove(selectedTeams, i)
                break
            end
        end
    else
        if #selectedTeams < maxTeams then
            table.insert(selectedTeams, teamName)
        end
    end
    saveSettings()
    populateTeamList()
end

function populateTeamList()
    for _, child in pairs(teamScrolling:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    local teams = {}
    for _, team in pairs(Teams:GetTeams()) do
        table.insert(teams, team.Name)
    end
    for i, teamName in ipairs(teams) do
        local isSelected = isTeamSelected(teamName)
        local teamBtn = Instance.new("TextButton")
        teamBtn.Size = UDim2.new(1, -6, 0, 26)
        teamBtn.BackgroundColor3 = isSelected and Color3.fromRGB(60, 100, 180) or Color3.fromRGB(40, 40, 48)
        teamBtn.BorderSizePixel = 0
        teamBtn.Text = ""
        teamBtn.AutoButtonColor = false
        teamBtn.ZIndex = 5
        teamBtn.LayoutOrder = i
        teamBtn.Parent = teamScrolling
        local teamBtnCorner = Instance.new("UICorner")
        teamBtnCorner.CornerRadius = UDim.new(0, 6)
        teamBtnCorner.Parent = teamBtn
        local teamBtnStroke = Instance.new("UIStroke")
        teamBtnStroke.Color = isSelected and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70)
        teamBtnStroke.Thickness = isSelected and 2 or 1
        teamBtnStroke.Parent = teamBtn
        local checkbox = Instance.new("Frame")
        checkbox.Size = UDim2.new(0, 16, 0, 16)
        checkbox.Position = UDim2.new(0, 8, 0.5, -8)
        checkbox.BackgroundColor3 = isSelected and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(30, 30, 35)
        checkbox.BorderSizePixel = 0
        checkbox.ZIndex = 6
        checkbox.Parent = teamBtn
        local checkboxCorner = Instance.new("UICorner")
        checkboxCorner.CornerRadius = UDim.new(0, 3)
        checkboxCorner.Parent = checkbox
        local checkboxStroke = Instance.new("UIStroke")
        checkboxStroke.Color = Color3.fromRGB(80, 80, 90)
        checkboxStroke.Thickness = 1
        checkboxStroke.Parent = checkbox
        if isSelected then
            local checkmark = Instance.new("TextLabel")
            checkmark.Size = UDim2.new(1, 0, 1, 0)
            checkmark.BackgroundTransparency = 1
            checkmark.Text = "✓"
            checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
            checkmark.Font = Enum.Font.GothamBold
            checkmark.TextSize = 14
            checkmark.ZIndex = 7
            checkmark.Parent = checkbox
        end
        local teamNameLabel = Instance.new("TextLabel")
        teamNameLabel.Size = UDim2.new(1, -32, 1, 0)
        teamNameLabel.Position = UDim2.new(0, 28, 0, 0)
        teamNameLabel.BackgroundTransparency = 1
        teamNameLabel.Text = teamName
        teamNameLabel.TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 190)
        teamNameLabel.Font = Enum.Font.GothamMedium
        teamNameLabel.TextSize = 11
        teamNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        teamNameLabel.ZIndex = 6
        teamNameLabel.Parent = teamBtn
        teamBtn.MouseEnter:Connect(function()
            if not isSelected then
                TweenService:Create(teamBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 58)}):Play()
            end
        end)
        teamBtn.MouseLeave:Connect(function()
            if not isSelected then
                TweenService:Create(teamBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 48)}):Play()
            end
        end)
        teamBtn.MouseButton1Click:Connect(function()
            toggleTeamSelection(teamName)
        end)
    end
end

-- END OF PART 1 - Type "Continue" for Part 2

-- PART 2 STARTS HERE

local function createCrosshairButton(type, displayName, order)
    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = (crosshairType == type) and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(40, 40, 50)
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ZIndex = 4
    btn.LayoutOrder = order
    btn.Parent = crosshairContainer
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = (crosshairType == type) and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70)
    btnStroke.Thickness = (crosshairType == type) and 2 or 1
    btnStroke.Parent = btn
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = displayName
    label.TextColor3 = (crosshairType == type) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.ZIndex = 5
    label.Parent = btn
    btn.MouseEnter:Connect(function()
        if crosshairType ~= type then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        if crosshairType ~= type then
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
        end
    end)
    btn.MouseButton1Click:Connect(function()
        crosshairType = type
        updateCrosshair(type)
        saveSettings()
        for _, child in pairs(crosshairContainer:GetChildren()) do
            if child:IsA("TextButton") then
                local isActive = (child == btn)
                TweenService:Create(child, TweenInfo.new(0.3), {BackgroundColor3 = isActive and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(40, 40, 50)}):Play()
                local stroke = child:FindFirstChildOfClass("UIStroke")
                if stroke then
                    TweenService:Create(stroke, TweenInfo.new(0.3), {Color = isActive and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70), Thickness = isActive and 2 or 1}):Play()
                end
                local lbl = child:FindFirstChildOfClass("TextLabel")
                if lbl then
                    TweenService:Create(lbl, TweenInfo.new(0.3), {TextColor3 = isActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)}):Play()
                end
            end
        end
    end)
end

createCrosshairButton("default", "Default", 1)
createCrosshairButton("circle", "Circle", 2)
createCrosshairButton("box", "Box", 3)

local function clearLocked()
    if lockedConn then
        lockedConn:Disconnect()
        lockedConn = nil
    end
    lockedTarget = nil
    lockOn = false
    lockLabel.Text = "LOCK"
    local shackle = lockIcon:FindFirstChild("LockShackle")
    if shackle then
        TweenService:Create(shackle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, -3)}):Play()
    end
    tweenButton(lockBtn, false)
end

local function canSee(part)
    if not part or not part.Parent then return false end
    local origin = Camera.CFrame.Position
    local dirVec = part.Position - origin
    if dirVec.Magnitude <= 0 then return false end
    local direction = dirVec.Unit * math.min(dirVec.Magnitude + 1, 1000)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction, params)
    if result and result.Instance then
        return result.Instance:IsDescendantOf(part.Parent)
    end
    return false
end

local function getClosestVisiblePlayer()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHrp then return nil end
    if fhftEnabled and lastAttacker and lastAttacker.Parent then
        local attackerHrp = lastAttacker.Parent:FindFirstChild("HumanoidRootPart")
        local attackerHumanoid = lastAttacker.Parent:FindFirstChildWhichIsA("Humanoid")
        if attackerHrp and attackerHumanoid and attackerHumanoid.Health > 0 then
            local dist = (myHrp.Position - attackerHrp.Position).Magnitude
            if dist <= lockDistance and canSee(attackerHrp) then
                return attackerHrp
            end
        end
    end
    local closest = nil
    local shortest = lockDistance
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Team and isTeamSelected(player.Team.Name) then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and myHrp then
                    local dist = (myHrp.Position - hrp.Position).Magnitude
                    if dist < shortest then
                        if canSee(hrp) then
                            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                if multiTargetEnabled then
                                    if dist <= multiTargetRadius then
                                        closest = hrp
                                        shortest = dist
                                    end
                                else
                                    closest = hrp
                                    shortest = dist
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function setLockedTarget(hrp)
    clearLocked()
    if not hrp or not hrp.Parent then return end
    local humanoid = hrp.Parent:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then return end
    if humanoid.Health <= 0 then return end
    lockedTarget = hrp
    lockOn = true
    lockLabel.Text = "LOCKED"
    local shackle = lockIcon:FindFirstChild("LockShackle")
    if shackle then
        TweenService:Create(shackle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 0)}):Play()
    end
    tweenButton(lockBtn, true)
    lockedConn = humanoid.Died:Connect(function()
        clearLocked()
    end)
end

local function setupFHFT()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid.HealthChanged:Connect(function(health)
                if health < humanoid.MaxHealth then
                    local creator = humanoid:FindFirstChild("creator")
                    if creator and creator.Value then
                        lastAttacker = creator.Value
                    end
                end
            end)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(setupFHFT)
if LocalPlayer.Character then
    setupFHFT()
end

RunService.RenderStepped:Connect(function()
    if povActive then
        local target = nil
        if lockOn and lockedTarget and lockedTarget.Parent and lockedTarget.Parent:FindFirstChildWhichIsA("Humanoid") then
            local humanoid = lockedTarget.Parent:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local myChar = LocalPlayer.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHrp and (myHrp.Position - lockedTarget.Position).Magnitude <= lockDistance and canSee(lockedTarget) then
                    target = lockedTarget
                else
                    clearLocked()
                end
            else
                clearLocked()
            end
        end
        if not target then
            target = getClosestVisiblePlayer()
        end
        if target then
            local humanoid = target.Parent and target.Parent:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local goalCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
                if smoothing and smoothing > 0 then
                    Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, math.clamp(smoothing, 0, 1))
                else
                    Camera.CFrame = goalCFrame
                end
                local myChar = LocalPlayer.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local dist = (myHrp.Position - target.Position).Magnitude
                    nameLabel.Text = "● " .. (target.Parent.Name or "Unknown")
                    distLabel.Text = string.format("Range: %.1f studs", dist)
                    local distColor
                    if dist < 100 then
                        distColor = Color3.fromRGB(100, 255, 150)
                    elseif dist < 200 then
                        distColor = Color3.fromRGB(255, 220, 100)
                    else
                        distColor = Color3.fromRGB(255, 150, 100)
                    end
                    distLabel.TextColor3 = distColor
                end
            else
                if lockOn then clearLocked() end
            end
        else
            nameLabel.Text = "● No Target"
            distLabel.Text = "Range: -- studs"
            distLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
        end
    end
    multiTargetCircle.Visible = (povActive and multiTargetEnabled)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(180, 50, 50)}):Play()
end)

closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
end)

minimizeBtn.MouseButton1Click:Connect(function()
    toggleMinimize()
end)

minimizeBtn.MouseEnter:Connect(function()
    TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(70, 70, 80)}):Play()
end)

minimizeBtn.MouseLeave:Connect(function()
    TweenService:Create(minimizeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
end)

toggleBtn.MouseButton1Click:Connect(function()
    povActive = not povActive
    toggleLabel.Text = povActive and "ON" or "OFF"
    toggleLabel.TextColor3 = povActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
    crosshairDisplay.Visible = povActive
    tweenButton(toggleBtn, povActive)
    animateAccentBar(povActive)
    animateStatusDot(povActive)
    if not povActive then clearLocked() end
end)

lockBtn.MouseButton1Click:Connect(function()
    if not povActive then return end
    if lockOn then
        clearLocked()
    else
        local candidate = getClosestVisiblePlayer()
        if candidate then setLockedTarget(candidate) end
    end
end)

fhftBtn.MouseButton1Click:Connect(function()
    fhftEnabled = not fhftEnabled
    fhftStatus.Text = fhftEnabled and "ON" or "OFF"
    fhftStatus.TextColor3 = fhftEnabled and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(150, 150, 160)
    tweenButton(fhftBtn, fhftEnabled)
    saveSettings()
end)

multiBtn.MouseButton1Click:Connect(function()
    multiTargetEnabled = not multiTargetEnabled
    multiStatus.Text = multiTargetEnabled and "ON" or "OFF"
    multiStatus.TextColor3 = multiTargetEnabled and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(150, 150, 160)
    tweenButton(multiBtn, multiTargetEnabled)
    saveSettings()
end)

Mouse.Button2Down:Connect(function()
    if not povActive then return end
    local target = getClosestVisiblePlayer()
    if target then setLockedTarget(target) end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P then
        povActive = not povActive
        toggleLabel.Text = povActive and "ON" or "OFF"
        toggleLabel.TextColor3 = povActive and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 160)
        crosshairDisplay.Visible = povActive
        tweenButton(toggleBtn, povActive)
        animateAccentBar(povActive)
        animateStatusDot(povActive)
        if not povActive then clearLocked() end
    end
end)

local function onLocalHumanoidAdded(humanoid)
    if humanoid then
        humanoid.Died:Connect(function()
            povActive = false
            toggleLabel.Text = "OFF"
            toggleLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
            crosshairDisplay.Visible = false
            tweenButton(toggleBtn, false)
            animateAccentBar(false)
            animateStatusDot(false)
            clearLocked()
        end)
    end
end

if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
    onLocalHumanoidAdded(hum)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    onLocalHumanoidAdded(hum)
end)

toggleBtn.MouseEnter:Connect(function()
    if not povActive then
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

toggleBtn.MouseLeave:Connect(function()
    if not povActive then
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end
end)

lockBtn.MouseEnter:Connect(function()
    if not lockOn then
        TweenService:Create(lockBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

lockBtn.MouseLeave:Connect(function()
    if not lockOn then
        TweenService:Create(lockBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end
end)

fhftBtn.MouseEnter:Connect(function()
    if not fhftEnabled then
        TweenService:Create(fhftBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

fhftBtn.MouseLeave:Connect(function()
    if not fhftEnabled then
        TweenService:Create(fhftBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end
end)

multiBtn.MouseEnter:Connect(function()
    if not multiTargetEnabled then
        TweenService:Create(multiBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
    end
end)

multiBtn.MouseLeave:Connect(function()
    if not multiTargetEnabled then
        TweenService:Create(multiBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
    end
end)

loadSettings()
populateTeamList()
updateCrosshair(crosshairType)

if fhftEnabled then
    fhftStatus.Text = "ON"
    fhftStatus.TextColor3 = Color3.fromRGB(100, 255, 150)
    tweenButton(fhftBtn, true)
end

if multiTargetEnabled then
    multiStatus.Text = "ON"
    multiStatus.TextColor3 = Color3.fromRGB(100, 255, 150)
    tweenButton(multiBtn, true)
end

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🎯 POV LOCK GUI - Ultimate Edition")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✓ Multi-Team Selection")
print("✓ FHFT (First Hurt First Target)")
print("✓ Multi-Target Mode with Volume")
print("✓ 3 Clean Crosshair Styles")
print("✓ Draggable & Minimizable")
print("✓ Settings Auto-Save to JSON")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("Press 'P' to toggle POV Lock")
print("Right-click to quick lock target")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- END OF COMPLETE CODE