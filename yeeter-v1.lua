-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local SoundService = game:GetService("SoundService")

-- Sound Effects
local function playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://" .. soundId
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

playSound("9118025346")

-- GUI Setup
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "FlingGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 280)
frame.Position = UDim2.new(0.5, -160, 0.5, -100)
frame.BackgroundColor3 = Color3.fromRGB(255, 248, 220)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "Yeeter v1"
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextScaled = true
title.TextColor3 = Color3.new(0, 0, 0)

-- Minimize / Restore
local originalHeight = 280

local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 30, 0, 25)
minimizeBtn.Position = UDim2.new(1, -35, 0, 5)
minimizeBtn.Text = "-"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextScaled = true
minimizeBtn.BackgroundColor3 = Color3.fromRGB(240, 200, 120)
minimizeBtn.BorderSizePixel = 0
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

local restoreBtn = minimizeBtn:Clone()
restoreBtn.Text = "+"
restoreBtn.Visible = false
restoreBtn.Parent = frame

-- Toggle logic
minimizeBtn.MouseButton1Click:Connect(function()
    originalHeight = frame.Size.Y.Offset
    frame.Size = UDim2.new(0, 320, 0, 40)
    minimizeBtn.Visible = false
    restoreBtn.Visible = true
end)

restoreBtn.MouseButton1Click:Connect(function()
    frame.Size = UDim2.new(0, 320, 0, originalHeight)
    restoreBtn.Visible = false
    minimizeBtn.Visible = true
end)

-- Container
local container = Instance.new("Frame", frame)
container.Size = UDim2.new(1, -24, 1, 24)
container.Position = UDim2.new(0, 12, 0, 45)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 14)
layout.FillDirection = Enum.FillDirection.Vertical
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- TextBox
local textBox = Instance.new("TextBox")
textBox.PlaceholderText = "Enter Player"
textBox.Text = ""
textBox.Size = UDim2.new(1, 0, 0, 40)
textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 240)
textBox.TextColor3 = Color3.new(0, 0, 0)
textBox.TextScaled = true
textBox.Font = Enum.Font.Gotham
textBox.ClearTextOnFocus = false
textBox.BorderSizePixel = 0
textBox.Parent = container
Instance.new("UICorner", textBox).CornerRadius = UDim.new(0, 12)

-- Button Factory
local function createButton(text, color)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 40)
        button.Text = text
        button.Font = Enum.Font.GothamSemibold
        button.TextScaled = true
        button.BackgroundColor3 = color
        button.TextColor3 = Color3.new(0, 0, 0)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 12)

        local hover = color:lerp(Color3.new(1, 1, 1), 0.2)
        local click = color:lerp(Color3.new(0.5, 0.5, 0.5), 0.3)

        button.MouseEnter:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hover}):Play()
        end)
        button.MouseLeave:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play()
        end)
        button.MouseButton1Down:Connect(function()
                button.BackgroundColor3 = click
        end)
        button.MouseButton1Up:Connect(function()
                TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hover}):Play()
        end)

        return button
end

local flingBtn = createButton("Fling Selected Player", Color3.fromRGB(255, 160, 122))
flingBtn.Parent = container

local loopFlingBtn = createButton("Loop Fling [OFF]", Color3.fromRGB(173, 216, 230))
loopFlingBtn.Parent = container

local flingAllBtn = createButton("Fling All [OFF]", Color3.fromRGB(144, 238, 144))
flingAllBtn.Parent = container

-- Noclip logic
local noclipConn
local function enableNoclip()
        if noclipConn then return end
        noclipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                        for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") and part.CanCollide then
                                        part.CanCollide = false
                                end
                        end
                end
        end)
end

local function disableNoclip()
        if noclipConn then
                noclipConn:Disconnect()
                noclipConn = nil
        end
        local char = LocalPlayer.Character
        if char then
                for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                                part.CanCollide = true
                        end
                end
        end
end

-- Fling
local function attachFling()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(0, 1e12, 0)
        bav.MaxTorque = Vector3.new(1e14, 1e14, 1e14)
        bav.P = 1e7
        bav.Name = "FlingVelocity"
        bav.Parent = hrp

        task.delay(1, function()
                if bav and bav.Parent then bav:Destroy() end
        end)
end

local function flingTargetPlayer(target)
        local char = LocalPlayer.Character
        local targetChar = target.Character
        if not char or not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local tHrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not hrp or not tHrp then return end

        enableNoclip()
        hrp.CFrame = tHrp.CFrame
        attachFling()

        local conn; conn = LocalPlayer.CharacterAdded:Connect(function()
                disableNoclip()
                if conn then conn:Disconnect() end
        end)

        task.delay(1.2, function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        disableNoclip()
                end
        end)
end

-- Toggle Fling All
local flingAllRunning = false
local loopFlingRunning = false
local loopFlingTarget = nil

flingAllBtn.MouseButton1Click:Connect(function()
        flingAllRunning = not flingAllRunning
        flingAllBtn.Text = flingAllRunning and "Fling All [ON]" or "Fling All [OFF]"
        playSound("8394620892")

        if flingAllRunning then
                task.spawn(function()
                        while flingAllRunning do
                                for _, p in ipairs(Players:GetPlayers()) do
                                        if not flingAllRunning then break end
                                        if p ~= LocalPlayer then
                                                flingTargetPlayer(p)
                                                task.wait(0.2)
                                        end
                                end
                                task.wait(0.2)
                        end
                end)
        end
end)

-- One player fling
flingBtn.MouseButton1Click:Connect(function()
        local name = textBox.Text
        local target = Players:FindFirstChild(name)
        if target and target ~= LocalPlayer then
            playSound("8394620892")
                flingTargetPlayer(target)
        end
end)

loopFlingBtn.MouseButton1Click:Connect(function()
    loopFlingRunning = not loopFlingRunning
    loopFlingBtn.Text = loopFlingRunning and "Loop Fling [ON]" or "Loop Fling [OFF]"
    playSound("8394620892")

    if loopFlingRunning then
        local name = textBox.Text
        local target = Players:FindFirstChild(name)
        if not target or target == LocalPlayer then
            loopFlingRunning = false
            loopFlingBtn.Text = "Loop Fling [OFF]"
            return
        end
        loopFlingTarget = target

        task.spawn(function()
            while loopFlingRunning do
                if not loopFlingTarget or not Players:FindFirstChild(loopFlingTarget.Name) then break end
                flingTargetPlayer(loopFlingTarget)
                task.wait(0.4)
            end
            loopFlingRunning = false
            loopFlingBtn.Text = "Loop Fling [OFF]"
        end)
    else
        loopFlingTarget = nil
    end
end)

-- Minimize / Restore
minimizeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.25), {Size = UDim2.new(0, 290, 0, 50)}):Play()
        container.Visible = false
        minimizeBtn.Visible = false
        restoreBtn.Visible = true
        playSound("8394620892")
end)

restoreBtn.MouseButton1Click:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.25), {Size = UDim2.new(0, 320, 0, 200)}):Play()
        task.delay(0.25, function()
                container.Visible = true
        end)
        restoreBtn.Visible = false
        minimizeBtn.Visible = true
        playSound("8394620892")
end)

-- Custom Notification
local function customNotif()
    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 340, 0, 100)
    notif.Position = UDim2.new(0.5, 0, 1, -120)
    notif.AnchorPoint = Vector2.new(0.5, 1)
    notif.BackgroundColor3 = Color3.fromRGB(250, 250, 250)
    notif.BorderSizePixel = 0
    notif.BackgroundTransparency = 1
    notif.Parent = gui

    local bg = Instance.new("Frame", notif)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 16)

    local thumb = Instance.new("ImageLabel", bg)
    thumb.Size = UDim2.new(0, 60, 0, 60)
    thumb.Position = UDim2.new(0, 15, 0, 20)
    thumb.BackgroundTransparency = 1
    thumb.ImageTransparency = 1
    thumb.ScaleType = Enum.ScaleType.Crop
    thumb.Image = Players:GetUserThumbnailAsync(
        Players:GetUserIdFromNameAsync("youcannotsth"),
        Enum.ThumbnailType.HeadShot,
        Enum.ThumbnailSize.Size100x100
    )
    TweenService:Create(thumb, TweenInfo.new(0.4), {ImageTransparency = 0}):Play()

    local title = Instance.new("TextLabel", bg)
    title.Text = "Made by youcannotsth!"
    title.Size = UDim2.new(1, -100, 0, 28)
    title.Position = UDim2.new(0, 85, 0, 20)
    title.BackgroundTransparency = 1
    title.TextColor3 = Color3.fromRGB(20, 20, 20)
    title.Font = Enum.Font.GothamBold
    title.TextScaled = true
    title.TextTransparency = 1
    TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

    local desc = Instance.new("TextLabel", bg)
    desc.Text = "Enjoy! Use fly for best experience!"
    desc.Size = UDim2.new(1, -100, 0, 20)
    desc.Position = UDim2.new(0, 85, 0, 52)
    desc.BackgroundTransparency = 1
    desc.TextColor3 = Color3.fromRGB(80, 80, 80)
    desc.Font = Enum.Font.Gotham
    desc.TextScaled = true
    desc.TextTransparency = 1
    TweenService:Create(desc, TweenInfo.new(0.3), {TextTransparency = 0}):Play()

    local bar = Instance.new("Frame", bg)
    bar.Size = UDim2.new(1, 0, 0, 4)
    bar.Position = UDim2.new(0, 0, 1, -4)
    bar.BackgroundColor3 = Color3.fromRGB(120, 190, 255)
    bar.BorderSizePixel = 0
    bar.BackgroundTransparency = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    -- Animate in
    TweenService:Create(bg, TweenInfo.new(0.4), {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(notif, TweenInfo.new(0.4), {
        Position = notif.Position - UDim2.new(0, 0, 0, 20)
    }):Play()

    -- Progress bar
    TweenService:Create(bar, TweenInfo.new(5), {
        Size = UDim2.new(0, 0, 0, 4)
    }):Play()

    task.delay(5, function()
        -- Animate out
        TweenService:Create(title, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(desc, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        TweenService:Create(thumb, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
        TweenService:Create(bg, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        TweenService:Create(notif, TweenInfo.new(0.4), {
            Position = notif.Position + UDim2.new(0, 0, 0, 40)
        }):Play()

        task.delay(0.4, function()
            notif:Destroy()
        end)
    end)
end

-- Show notification
customNotif()
