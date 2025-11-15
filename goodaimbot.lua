-- POV Lock with Beautiful Animated GUI - Complete Edition
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
local selectedTeam = "Guards"
local isMinimized = false
local crosshairType = "default" -- default, circle, box

-- Save/Load Settings
local function saveSettings()
    local settings = {
        selectedTeam = selectedTeam,
        crosshairType = crosshairType,
        lockDistance = lockDistance,
        smoothing = smoothing
    }
    writefile("pov_lock_settings.json", HttpService:JSONEncode(settings))
end

local function loadSettings()
    if isfile("pov_lock_settings.json") then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile("pov_lock_settings.json"))
        end)
        if success and result then
            selectedTeam = result.selectedTeam or "Guards"
            crosshairType = result.crosshairType or "default"
            lockDistance = result.lockDistance or 350
            smoothing = result.smoothing or 0.35
        end
    end
end

-- UI Creation
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "POV_Lock_GUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Container
local container = Instance.new("Frame")
container.Size = UDim2.new(0, 280, 0, 280)
container.Position = UDim2.new(1, -300, 0, 20)
container.AnchorPoint = Vector2.new(0, 0)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
container.BorderSizePixel = 0
container.ClipsDescendants = false
container.Active = true
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 12)
containerCorner.Parent = container

-- RGB Border Effect
local rgbBorder = Instance.new("UIStroke")
rgbBorder.Color = Color3.fromRGB(255, 0, 0)
rgbBorder.Thickness = 2
rgbBorder.Transparency = 0.3
rgbBorder.Parent = container

-- Gradient overlay
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

-- Animated accent bar
local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 0, 0, 3)
accentBar.Position = UDim2.new(0, 0, 0, 0)
accentBar.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 3
accentBar.Parent = container

-- Content Container (for hiding when minimized)
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(1, 0, 1, -40)
contentContainer.Position = UDim2.new(0, 0, 0, 40)
contentContainer.BackgroundTransparency = 1
contentContainer.ZIndex = 2
contentContainer.Parent = container

-- Title Container
local titleContainer = Instance.new("Frame")
titleContainer.Size = UDim2.new(1, -16, 0, 32)
titleContainer.Position = UDim2.new(0, 8, 0, 8)
titleContainer.BackgroundTransparency = 1
titleContainer.ZIndex = 2
titleContainer.Active = false
titleContainer.Parent = container

-- Target icon (SVG-style)
local titleIcon = Instance.new("Frame")
titleIcon.Size = UDim2.new(0, 20, 0, 20)
titleIcon.Position = UDim2.new(0, 2, 0, 6)
titleIcon.BackgroundTransparency = 1
titleIcon.ZIndex = 2
titleIcon.Parent = titleContainer

local iconOuter = Instance.new("Frame")
iconOuter.Size = UDim2.new(1, 0, 1, 0)
iconOuter.Position = UDim2.new(0.5, 0, 0.5, 0)
iconOuter.AnchorPoint = Vector2.new(0.5, 0.5)
iconOuter.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
iconOuter.BorderSizePixel = 0
iconOuter.ZIndex = 2
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
iconInner.ZIndex = 2
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
title.ZIndex = 2
title.Parent = titleContainer

-- Close button (X)
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -28, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
closeBtn.Text = ""
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 5
closeBtn.Parent = titleContainer

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 6)
closeBtnCorner.Parent = closeBtn

-- X icon
local closeX1 = Instance.new("Frame")
closeX1.Size = UDim2.new(0, 12, 0, 2)
closeX1.Position = UDim2.new(0.5, 0, 0.5, 0)
closeX1.AnchorPoint = Vector2.new(0.5, 0.5)
closeX1.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeX1.BorderSizePixel = 0
closeX1.Rotation = 45
closeX1.ZIndex = 6
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
closeX2.ZIndex = 6
closeX2.Parent = closeBtn

local closeX2Corner = Instance.new("UICorner")
closeX2Corner.CornerRadius = UDim.new(0, 1)
closeX2Corner.Parent = closeX2

-- Minimize button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Size = UDim2.new(0, 24, 0, 24)
minimizeBtn.Position = UDim2.new(1, -56, 0, 4)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
minimizeBtn.Text = ""
minimizeBtn.AutoButtonColor = false
minimizeBtn.ZIndex = 5
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
minimizeIcon.ZIndex = 6
minimizeIcon.Parent = minimizeBtn

local minimizeIconCorner = Instance.new("UICorner")
minimizeIconCorner.CornerRadius = UDim.new(0, 1)
minimizeIconCorner.Parent = minimizeIcon

-- Minimize icon vertical bar (for + sign)
local minimizeIconV = Instance.new("Frame")
minimizeIconV.Size = UDim2.new(0, 2, 0, 10)
minimizeIconV.Position = UDim2.new(0.5, 0, 0.5, 0)
minimizeIconV.AnchorPoint = Vector2.new(0.5, 0.5)
minimizeIconV.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
minimizeIconV.BorderSizePixel = 0
minimizeIconV.Visible = false
minimizeIconV.ZIndex = 6
minimizeIconV.Parent = minimizeBtn

local minimizeIconVCorner = Instance.new("UICorner")
minimizeIconVCorner.CornerRadius = UDim.new(0, 1)
minimizeIconVCorner.Parent = minimizeIconV

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 110, 0, 36)
toggleBtn.Position = UDim2.new(1, -118, 0, 8)
toggleBtn.AnchorPoint = Vector2.new(0, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
toggleBtn.Text = ""
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 2
toggleBtn.Parent = contentContainer

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggleBtn

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(60, 60, 70)
toggleStroke.Thickness = 1.5
toggleStroke.Parent = toggleBtn

local toggleLabel = Instance.new("TextLabel")
toggleLabel.Size = UDim2.new(1, -8, 1, 0)
toggleLabel.Position = UDim2.new(0, 4, 0, 0)
toggleLabel.BackgroundTransparency = 1
toggleLabel.Text = "OFF"
toggleLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
toggleLabel.Font = Enum.Font.GothamBold
toggleLabel.TextSize = 14
toggleLabel.ZIndex = 3
toggleLabel.Parent = toggleBtn

-- Lock Button (better lock design)
local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(0, 100, 0, 32)
lockBtn.Position = UDim2.new(0, 8, 0, 8)
lockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
lockBtn.Text = ""
lockBtn.AutoButtonColor = false
lockBtn.ZIndex = 2
lockBtn.Parent = contentContainer

local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 8)
lockCorner.Parent = lockBtn

local lockStroke = Instance.new("UIStroke")
lockStroke.Color = Color3.fromRGB(60, 60, 70)
lockStroke.Thickness = 1.5
lockStroke.Parent = lockBtn

-- Better lock icon
local lockIcon = Instance.new("Frame")
lockIcon.Size = UDim2.new(0, 14, 0, 16)
lockIcon.Position = UDim2.new(0, 10, 0.5, -8)
lockIcon.BackgroundTransparency = 1
lockIcon.ZIndex = 3
lockIcon.Parent = lockBtn

-- Lock body (main rectangular part)
local lockBody = Instance.new("Frame")
lockBody.Size = UDim2.new(0, 14, 0, 10)
lockBody.Position = UDim2.new(0, 0, 1, -10)
lockBody.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
lockBody.BorderSizePixel = 0
lockBody.ZIndex = 3
lockBody.Name = "LockBody"
lockBody.Parent = lockIcon

local lockBodyCorner = Instance.new("UICorner")
lockBodyCorner.CornerRadius = UDim.new(0, 3)
lockBodyCorner.Parent = lockBody

-- Keyhole
local lockKeyhole = Instance.new("Frame")
lockKeyhole.Size = UDim2.new(0, 3, 0, 4)
lockKeyhole.Position = UDim2.new(0.5, 0, 0.4, 0)
lockKeyhole.AnchorPoint = Vector2.new(0.5, 0)
lockKeyhole.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
lockKeyhole.BorderSizePixel = 0
lockKeyhole.ZIndex = 4
lockKeyhole.Parent = lockBody

local lockKeyholeCorner = Instance.new("UICorner")
lockKeyholeCorner.CornerRadius = UDim.new(1, 0)
lockKeyholeCorner.Parent = lockKeyhole

-- Lock shackle (the U-shaped part on top)
local lockShackle = Instance.new("Frame")
lockShackle.Size = UDim2.new(0, 10, 0, 8)
lockShackle.Position = UDim2.new(0.5, 0, 0, 0)
lockShackle.AnchorPoint = Vector2.new(0.5, 0)
lockShackle.BackgroundTransparency = 1
lockShackle.BorderSizePixel = 0
lockShackle.ZIndex = 3
lockShackle.Name = "LockShackle"
lockShackle.Parent = lockIcon

local lockShackleStroke = Instance.new("UIStroke")
lockShackleStroke.Color = Color3.fromRGB(200, 200, 210)
lockShackleStroke.Thickness = 2.5
lockShackleStroke.Parent = lockShackle

local lockShackleCorner = Instance.new("UICorner")
lockShackleCorner.CornerRadius = UDim.new(1, 0)
lockShackleCorner.Parent = lockShackle

local lockLabel = Instance.new("TextLabel")
lockLabel.Size = UDim2.new(1, -36, 1, 0)
lockLabel.Position = UDim2.new(0, 28, 0, 0)
lockLabel.BackgroundTransparency = 1
lockLabel.Text = "LOCK"
lockLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
lockLabel.Font = Enum.Font.GothamBold
lockLabel.TextSize = 12
lockLabel.TextXAlignment = Enum.TextXAlignment.Left
lockLabel.ZIndex = 3
lockLabel.Parent = lockBtn

-- Team Selector
local teamLabel = Instance.new("TextLabel")
teamLabel.Size = UDim2.new(1, -16, 0, 18)
teamLabel.Position = UDim2.new(0, 8, 0, 48)
teamLabel.BackgroundTransparency = 1
teamLabel.Text = "TARGET TEAM"
teamLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
teamLabel.Font = Enum.Font.GothamBold
teamLabel.TextSize = 11
teamLabel.TextXAlignment = Enum.TextXAlignment.Left
teamLabel.ZIndex = 2
teamLabel.Parent = contentContainer

local teamDropdown = Instance.new("TextButton")
teamDropdown.Size = UDim2.new(1, -16, 0, 32)
teamDropdown.Position = UDim2.new(0, 8, 0, 68)
teamDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
teamDropdown.Text = ""
teamDropdown.AutoButtonColor = false
teamDropdown.ZIndex = 2
teamDropdown.Parent = contentContainer

local teamDropdownCorner = Instance.new("UICorner")
teamDropdownCorner.CornerRadius = UDim.new(0, 8)
teamDropdownCorner.Parent = teamDropdown

local teamDropdownStroke = Instance.new("UIStroke")
teamDropdownStroke.Color = Color3.fromRGB(60, 60, 70)
teamDropdownStroke.Thickness = 1.5
teamDropdownStroke.Parent = teamDropdown

local teamDropdownLabel = Instance.new("TextLabel")
teamDropdownLabel.Size = UDim2.new(1, -40, 1, 0)
teamDropdownLabel.Position = UDim2.new(0, 12, 0, 0)
teamDropdownLabel.BackgroundTransparency = 1
teamDropdownLabel.Text = selectedTeam
teamDropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
teamDropdownLabel.Font = Enum.Font.GothamMedium
teamDropdownLabel.TextSize = 13
teamDropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
teamDropdownLabel.ZIndex = 3
teamDropdownLabel.Parent = teamDropdown

local teamDropdownArrow = Instance.new("TextLabel")
teamDropdownArrow.Size = UDim2.new(0, 20, 1, 0)
teamDropdownArrow.Position = UDim2.new(1, -28, 0, 0)
teamDropdownArrow.BackgroundTransparency = 1
teamDropdownArrow.Text = "▼"
teamDropdownArrow.TextColor3 = Color3.fromRGB(150, 150, 160)
teamDropdownArrow.Font = Enum.Font.GothamBold
teamDropdownArrow.TextSize = 10
teamDropdownArrow.ZIndex = 3
teamDropdownArrow.Parent = teamDropdown

-- Team dropdown menu
local teamMenu = Instance.new("ScrollingFrame")
teamMenu.Size = UDim2.new(1, -16, 0, 0)
teamMenu.Position = UDim2.new(0, 8, 0, 102)
teamMenu.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
teamMenu.BorderSizePixel = 0
teamMenu.ClipsDescendants = true
teamMenu.Visible = false
teamMenu.ZIndex = 10
teamMenu.ScrollBarThickness = 4
teamMenu.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
teamMenu.Parent = contentContainer

local teamMenuCorner = Instance.new("UICorner")
teamMenuCorner.CornerRadius = UDim.new(0, 8)
teamMenuCorner.Parent = teamMenu

local teamMenuStroke = Instance.new("UIStroke")
teamMenuStroke.Color = Color3.fromRGB(80, 80, 100)
teamMenuStroke.Thickness = 1.5
teamMenuStroke.Parent = teamMenu

local teamMenuList = Instance.new("UIListLayout")
teamMenuList.SortOrder = Enum.SortOrder.LayoutOrder
teamMenuList.Padding = UDim.new(0, 0)
teamMenuList.Parent = teamMenu

-- Crosshair Selector
local crosshairLabel = Instance.new("TextLabel")
crosshairLabel.Size = UDim2.new(1, -16, 0, 18)
crosshairLabel.Position = UDim2.new(0, 8, 0, 108)
crosshairLabel.BackgroundTransparency = 1
crosshairLabel.Text = "CROSSHAIR TYPE"
crosshairLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
crosshairLabel.Font = Enum.Font.GothamBold
crosshairLabel.TextSize = 11
crosshairLabel.TextXAlignment = Enum.TextXAlignment.Left
crosshairLabel.ZIndex = 2
crosshairLabel.Parent = contentContainer

local crosshairDropdown = Instance.new("TextButton")
crosshairDropdown.Size = UDim2.new(1, -16, 0, 32)
crosshairDropdown.Position = UDim2.new(0, 8, 0, 128)
crosshairDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
crosshairDropdown.Text = ""
crosshairDropdown.AutoButtonColor = false
crosshairDropdown.ZIndex = 2
crosshairDropdown.Parent = contentContainer

local crosshairDropdownCorner = Instance.new("UICorner")
crosshairDropdownCorner.CornerRadius = UDim.new(0, 8)
crosshairDropdownCorner.Parent = crosshairDropdown

local crosshairDropdownStroke = Instance.new("UIStroke")
crosshairDropdownStroke.Color = Color3.fromRGB(60, 60, 70)
crosshairDropdownStroke.Thickness = 1.5
crosshairDropdownStroke.Parent = crosshairDropdown

local crosshairDropdownLabel = Instance.new("TextLabel")
crosshairDropdownLabel.Size = UDim2.new(1, -40, 1, 0)
crosshairDropdownLabel.Position = UDim2.new(0, 12, 0, 0)
crosshairDropdownLabel.BackgroundTransparency = 1
crosshairDropdownLabel.Text = "Default"
crosshairDropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
crosshairDropdownLabel.Font = Enum.Font.GothamMedium
crosshairDropdownLabel.TextSize = 13
crosshairDropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
crosshairDropdownLabel.ZIndex = 3
crosshairDropdownLabel.Parent = crosshairDropdown

local crosshairDropdownArrow = Instance.new("TextLabel")
crosshairDropdownArrow.Size = UDim2.new(0, 20, 1, 0)
crosshairDropdownArrow.Position = UDim2.new(1, -28, 0, 0)
crosshairDropdownArrow.BackgroundTransparency = 1
crosshairDropdownArrow.Text = "▼"
crosshairDropdownArrow.TextColor3 = Color3.fromRGB(150, 150, 160)
crosshairDropdownArrow.Font = Enum.Font.GothamBold
crosshairDropdownArrow.TextSize = 10
crosshairDropdownArrow.ZIndex = 3
crosshairDropdownArrow.Parent = crosshairDropdown

-- Crosshair dropdown menu
local crosshairMenu = Instance.new("Frame")
crosshairMenu.Size = UDim2.new(1, -16, 0, 0)
crosshairMenu.Position = UDim2.new(0, 8, 0, 162)
crosshairMenu.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
crosshairMenu.BorderSizePixel = 0
crosshairMenu.ClipsDescendants = true
crosshairMenu.Visible = false
crosshairMenu.ZIndex = 10
crosshairMenu.Parent = contentContainer

local crosshairMenuCorner = Instance.new("UICorner")
crosshairMenuCorner.CornerRadius = UDim.new(0, 8)
crosshairMenuCorner.Parent = crosshairMenu

local crosshairMenuStroke = Instance.new("UIStroke")
crosshairMenuStroke.Color = Color3.fromRGB(80, 80, 100)
crosshairMenuStroke.Thickness = 1.5
crosshairMenuStroke.Parent = crosshairMenu

local crosshairMenuList = Instance.new("UIListLayout")
crosshairMenuList.SortOrder = Enum.SortOrder.LayoutOrder
crosshairMenuList.Padding = UDim.new(0, 0)
crosshairMenuList.Parent = crosshairMenu

-- Info Panel
local infoPanel = Instance.new("Frame")
infoPanel.Size = UDim2.new(1, -16, 0, 60)
infoPanel.Position = UDim2.new(0, 8, 0, 170)
infoPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
infoPanel.BorderSizePixel = 0
infoPanel.ZIndex = 2
infoPanel.Parent = contentContainer

local infoPanelCorner = Instance.new("UICorner")
infoPanelCorner.CornerRadius = UDim.new(0, 8)
infoPanelCorner.Parent = infoPanel

local infoPanelStroke = Instance.new("UIStroke")
infoPanelStroke.Color = Color3.fromRGB(50, 50, 60)
infoPanelStroke.Thickness = 1
infoPanelStroke.Transparency = 0.6
infoPanelStroke.Parent = infoPanel

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -16, 0, 24)
nameLabel.Position = UDim2.new(0, 8, 0, 8)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "● No Target"
nameLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
nameLabel.Font = Enum.Font.GothamMedium
nameLabel.TextSize = 13
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.ZIndex = 3
nameLabel.Parent = infoPanel

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(1, -16, 0, 20)
distLabel.Position = UDim2.new(0, 8, 0, 32)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Range: -- studs"
distLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
distLabel.Font = Enum.Font.Gotham
distLabel.TextSize = 11
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.ZIndex = 3
distLabel.Parent = infoPanel

-- Status Indicator
local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(1, -16, 0, 16)
statusDot.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
statusDot.BorderSizePixel = 0
statusDot.ZIndex = 4
statusDot.Parent = container

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(1, 0)
statusCorner.Parent = statusDot

-- Crosshair Container
local crosshairContainer = Instance.new("Frame")
crosshairContainer.Size = UDim2.new(0, 40, 0, 40)
crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairContainer.BackgroundTransparency = 1
crosshairContainer.Visible = false
crosshairContainer.ZIndex = 10
crosshairContainer.Parent = screenGui

-- Default Crosshair
local crosshairDefault = Instance.new("Frame")
crosshairDefault.Size = UDim2.new(1, 0, 1, 0)
crosshairDefault.BackgroundTransparency = 1
crosshairDefault.Name = "Default"
crosshairDefault.Parent = crosshairContainer

local crosshairH = Instance.new("Frame")
crosshairH.Size = UDim2.new(0, 14, 0, 2)
crosshairH.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairH.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshairH.BorderSizePixel = 0
crosshairH.ZIndex = 10
crosshairH.Parent = crosshairDefault

local crosshairV = Instance.new("Frame")
crosshairV.Size = UDim2.new(0, 2, 0, 14)
crosshairV.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairV.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshairV.BorderSizePixel = 0
crosshairV.ZIndex = 10
crosshairV.Parent = crosshairDefault

local crosshairCenter = Instance.new("Frame")
crosshairCenter.Size = UDim2.new(0, 3, 0, 3)
crosshairCenter.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairCenter.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
crosshairCenter.BorderSizePixel = 0
crosshairCenter.ZIndex = 10
crosshairCenter.Parent = crosshairDefault

local crosshairCenterCorner = Instance.new("UICorner")
crosshairCenterCorner.CornerRadius = UDim.new(1, 0)
crosshairCenterCorner.Parent = crosshairCenter

-- Circle Crosshair
local crosshairCircle = Instance.new("Frame")
crosshairCircle.Size = UDim2.new(1, 0, 1, 0)
crosshairCircle.BackgroundTransparency = 1
crosshairCircle.Name = "Circle"
crosshairCircle.Visible = false
crosshairCircle.Parent = crosshairContainer

local circleOuter = Instance.new("Frame")
circleOuter.Size = UDim2.new(0, 24, 0, 24)
circleOuter.AnchorPoint = Vector2.new(0.5, 0.5)
circleOuter.Position = UDim2.new(0.5, 0, 0.5, 0)
circleOuter.BackgroundTransparency = 1
circleOuter.BorderSizePixel = 0
circleOuter.ZIndex = 10
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
circleDot.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
circleDot.BorderSizePixel = 0
circleDot.ZIndex = 10
circleDot.Parent = crosshairCircle

local circleDotCorner = Instance.new("UICorner")
circleDotCorner.CornerRadius = UDim.new(1, 0)
circleDotCorner.Parent = circleDot

-- Box Crosshair
local crosshairBox = Instance.new("Frame")
crosshairBox.Size = UDim2.new(1, 0, 1, 0)
crosshairBox.BackgroundTransparency = 1
crosshairBox.Name = "Box"
crosshairBox.Visible = false
crosshairBox.Parent = crosshairContainer

local boxOuter = Instance.new("Frame")
boxOuter.Size = UDim2.new(0, 20, 0, 20)
boxOuter.AnchorPoint = Vector2.new(0.5, 0.5)
boxOuter.Position = UDim2.new(0.5, 0, 0.5, 0)
boxOuter.BackgroundTransparency = 1
boxOuter.BorderSizePixel = 0
boxOuter.ZIndex = 10
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
boxDot.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
boxDot.BorderSizePixel = 0
boxDot.ZIndex = 10
boxDot.Parent = crosshairBox

local boxDotCorner = Instance.new("UICorner")
boxDotCorner.CornerRadius = UDim.new(1, 0)
boxDotCorner.Parent = boxDot

-- RGB Animation
local hue = 0
RunService.RenderStepped:Connect(function(dt)
    hue = (hue + dt * 60) % 360
    rgbBorder.Color = Color3.fromHSV(hue / 360, 1, 1)
end)

-- Animation Functions
local function toggleMinimize()
    isMinimized = not isMinimized
    
    if isMinimized then
        contentContainer.Visible = false
        minimizeIconV.Visible = true
        container.Size = UDim2.new(0, 280, 0, 40)
    else
        contentContainer.Visible = true
        minimizeIconV.Visible = false
        container.Size = UDim2.new(0, 280, 0, 280)
    end
end

local function tweenButton(button, active)
    local color = active and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(40, 40, 50)
    local strokeColor = active and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(60, 60, 70)
    
    TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = color
    }):Play()
    
    local stroke = button:FindFirstChildOfClass("UIStroke")
    if stroke then
        TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Color = strokeColor,
            Thickness = active and 2 or 1.5
        }):Play()
    end
end

local function animateAccentBar(active)
    local targetSize = active and UDim2.new(1, 0, 0, 3) or UDim2.new(0, 0, 0, 3)
    TweenService:Create(accentBar, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = targetSize
    }):Play()
end

local function animateStatusDot(active)
    local color = active and Color3.fromRGB(100, 255, 150) or Color3.fromRGB(100, 100, 110)
    TweenService:Create(statusDot, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundColor3 = color
    }):Play()
    
    if active then
        spawn(function()
            while povActive do
                TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    BackgroundTransparency = 0.5
                }):Play()
                wait(0.8)
                if povActive then
                    TweenService:Create(statusDot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                        BackgroundTransparency = 0
                    }):Play()
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
    
    local displayNames = {
        default = "Default",
        circle = "Circle",
        box = "Box"
    }
    crosshairDropdownLabel.Text = displayNames[type] or "Default"
end

-- Dragging
local dragging = false
local dragStart
local startPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    container.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

titleContainer.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = container.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateDrag(input)
    end
end)

-- Team Functions
local function getTeams()
    local teamList = {}
    for _, team in pairs(Teams:GetTeams()) do
        table.insert(teamList, team.Name)
    end
    return teamList
end

local function populateTeamDropdown()
    for _, child in pairs(teamMenu:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local teams = getTeams()
    local itemHeight = 32
    
    for i, teamName in ipairs(teams) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, itemHeight)
        item.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        item.BorderSizePixel = 0
        item.Text = ""
        item.AutoButtonColor = false
        item.ZIndex = 11
        item.LayoutOrder = i
        item.Parent = teamMenu
        
        local itemLabel = Instance.new("TextLabel")
        itemLabel.Size = UDim2.new(1, -16, 1, 0)
        itemLabel.Position = UDim2.new(0, 12, 0, 0)
        itemLabel.BackgroundTransparency = 1
        itemLabel.Text = teamName
        itemLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
        itemLabel.Font = Enum.Font.GothamMedium
        itemLabel.TextSize = 12
        itemLabel.TextXAlignment = Enum.TextXAlignment.Left
        itemLabel.ZIndex = 12
        itemLabel.Parent = item
        
        item.MouseEnter:Connect(function()
            TweenService:Create(item, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
        end)
        
        item.MouseLeave:Connect(function()
            TweenService:Create(item, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 42)}):Play()
        end)
        
        item.MouseButton1Click:Connect(function()
            selectedTeam = teamName
            teamDropdownLabel.Text = teamName
            saveSettings()
            
            TweenService:Create(teamMenu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, -16, 0, 0)
            }):Play()
            
            task.wait(0.3)
            teamMenu.Visible = false
        end)
    end
    
    teamMenu.CanvasSize = UDim2.new(0, 0, 0, #teams * itemHeight)
end

local function populateCrosshairDropdown()
    for _, child in pairs(crosshairMenu:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local crosshairs = {
        {id = "default", name = "Default"},
        {id = "circle", name = "Circle"},
        {id = "box", name = "Box"},
        {id = "soon", name = "More Soon to Come!", disabled = true}
    }
    local itemHeight = 32
    
    for i, crosshairData in ipairs(crosshairs) do
        local item = Instance.new("TextButton")
        item.Size = UDim2.new(1, 0, 0, itemHeight)
        item.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        item.BorderSizePixel = 0
        item.Text = ""
        item.AutoButtonColor = false
        item.ZIndex = 11
        item.LayoutOrder = i
        item.Parent = crosshairMenu
        
        local itemLabel = Instance.new("TextLabel")
        itemLabel.Size = UDim2.new(1, -16, 1, 0)
        itemLabel.Position = UDim2.new(0, 12, 0, 0)
        itemLabel.BackgroundTransparency = 1
        itemLabel.Text = crosshairData.name
        itemLabel.TextColor3 = crosshairData.disabled and Color3.fromRGB(120, 120, 130) or Color3.fromRGB(200, 200, 210)
        itemLabel.Font = crosshairData.disabled and Enum.Font.GothamItalic or Enum.Font.GothamMedium
        itemLabel.TextSize = 12
        itemLabel.TextXAlignment = Enum.TextXAlignment.Left
        itemLabel.ZIndex = 12
        itemLabel.Parent = item
        
        if not crosshairData.disabled then
            item.MouseEnter:Connect(function()
                TweenService:Create(item, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
            end)
            
            item.MouseLeave:Connect(function()
                TweenService:Create(item, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 35, 42)}):Play()
            end)
            
            item.MouseButton1Click:Connect(function()
                crosshairType = crosshairData.id
                updateCrosshair(crosshairType)
                saveSettings()
                
                TweenService:Create(crosshairMenu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, -16, 0, 0)
                }):Play()
                
                task.wait(0.3)
                crosshairMenu.Visible = false
            end)
        end
    end
end

-- Core Functions
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
        TweenService:Create(shackle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, -3)
        }):Play()
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
    local closest = nil
    local shortest = lockDistance
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Team and player.Team.Name == selectedTeam then
                local char = player.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local myChar = LocalPlayer.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                
                if hrp and myHrp then
                    local dist = (myHrp.Position - hrp.Position).Magnitude
                    if dist < shortest then
                        if canSee(hrp) then
                            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
                            if humanoid and humanoid.Health > 0 then
                                closest = hrp
                                shortest = dist
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
        TweenService:Create(shackle, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0, 0)
        }):Play()
    end
    
    tweenButton(lockBtn, true)
    
    lockedConn = humanoid.Died:Connect(function()
        clearLocked()
    end)
end

-- Main Loop
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
end)

-- Button Events
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
    crosshairContainer.Visible = povActive
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

teamDropdown.MouseButton1Click:Connect(function()
    if teamMenu.Visible then
        TweenService:Create(teamMenu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -16, 0, 0)
        }):Play()
        task.wait(0.3)
        teamMenu.Visible = false
    else
        populateTeamDropdown()
        teamMenu.Visible = true
        local teams = getTeams()
        local targetHeight = math.min(#teams * 32, 96)
        TweenService:Create(teamMenu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -16, 0, targetHeight)
        }):Play()
    end
end)

crosshairDropdown.MouseButton1Click:Connect(function()
    if crosshairMenu.Visible then
        TweenService:Create(crosshairMenu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -16, 0, 0)
        }):Play()
        task.wait(0.3)
        crosshairMenu.Visible = false
    else
        populateCrosshairDropdown()
        crosshairMenu.Visible = true
        TweenService:Create(crosshairMenu, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -16, 0, 128)
        }):Play()
    end
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
        crosshairContainer.Visible = povActive
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
            crosshairContainer.Visible = false
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

-- Hover effects
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

teamDropdown.MouseEnter:Connect(function()
    TweenService:Create(teamDropdown, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
end)

teamDropdown.MouseLeave:Connect(function()
    TweenService:Create(teamDropdown, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
end)

crosshairDropdown.MouseEnter:Connect(function()
    TweenService:Create(crosshairDropdown, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
end)

crosshairDropdown.MouseLeave:Connect(function()
    TweenService:Create(crosshairDropdown, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
end)

-- Initialize
loadSettings()
populateTeamDropdown()
populateCrosshairDropdown()
updateCrosshair(crosshairType)
teamDropdownLabel.Text = selectedTeam

print("POV Lock GUI Loaded Successfully!")
print("Press 'P' to toggle POV Lock")
print("Settings saved to: pov_lock_settings.json")