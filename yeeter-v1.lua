-- Services
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

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

playSound("7145942916")

-- GUI Setup
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "FlingGui"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 200)
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
local minimizeBtn = Instance.new("TextButton", frame)
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
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

-- Container
local container = Instance.new("Frame", frame)
container.Size = UDim2.new(1, -24, 1, -50)
container.Position = UDim2.new(0, 12, 0, 40)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", container)
layout.Padding = UDim.new(0, 12)
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- TextBox
local textBox = Instance.new("TextBox", container)
textBox.PlaceholderText = "Enter Player"
textBox.Size = UDim2.new(1, 0, 0, 40)
textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 240)
textBox.TextColor3 = Color3.new(0, 0, 0)
textBox.TextScaled = true
textBox.Font = Enum.Font.Gotham
textBox.ClearTextOnFocus = false
textBox.BorderSizePixel = 0
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
        bav.AngularVelocity = Vector3.new(0, 1e20, 0)
        bav.MaxTorque = Vector3.new(1e20, 1e20, 1e20)
        bav.P = 1e9
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

flingAllBtn.MouseButton1Click:Connect(function()
        flingAllRunning = not flingAllRunning
        flingAllBtn.Text = flingAllRunning and "Fling All [ON]" or "Fling All [OFF]"

        if flingAllRunning then
                task.spawn(function()
                        while flingAllRunning do
                                for _, p in ipairs(Players:GetPlayers()) do
                                        if not flingAllRunning then break end
                                        if p ~= LocalPlayer then
                                                flingTargetPlayer(p)
                                                task.wait(0.5)
                                        end
                                end
                                task.wait(0.5)
                        end
                end)
        end
end)

-- One player fling
flingBtn.MouseButton1Click:Connect(function()
        local name = textBox.Text
        local target = Players:FindFirstChild(name)
        if target and target ~= LocalPlayer then
                flingTargetPlayer(target)
        end
end)

-- Minimize / Restore
minimizeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.25), {Size = UDim2.new(0, 290, 0, 50)}):Play()
        container.Visible = false
        minimizeBtn.Visible = false
        restoreBtn.Visible = true
        playSound("8394620892)
end)

restoreBtn.MouseButton1Click:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.25), {Size = UDim2.new(0, 320, 0, 200)}):Play()
        task.delay(0.25, function()
                container.Visible = true
        end)
        restoreBtn.Visible = false
        minimizeBtn.Visible = true
        playSound("8394620892)
end)

-- Custom Notification
local function customNotif()
        local notif = Instance.new("Frame")
        notif.Size = UDim2.new(0, 320, 0, 100)
        notif.Position = UDim2.new(0.5, -160, 1, -110)
        notif.AnchorPoint = Vector2.new(0.5, 1)
        notif.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        notif.BorderSizePixel = 0
        notif.Parent = gui
        Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 14)

        local thumb = Instance.new("ImageLabel", notif)
        thumb.Size = UDim2.new(0, 60, 0, 60)
        thumb.Position = UDim2.new(0, 10, 0, 20)
        thumb.BackgroundTransparency = 1
        thumb.ScaleType = Enum.ScaleType.Crop
        thumb.Image = Players:GetUserThumbnailAsync(Players:GetUserIdFromNameAsync("youcannotsth"), Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)

        local title = Instance.new("TextLabel", notif)
        title.Text = "Made by youcannotsth!"
        title.Size = UDim2.new(1, -80, 0, 30)
        title.Position = UDim2.new(0, 80, 0, 15)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamBold
        title.TextScaled = true
        title.TextColor3 = Color3.fromRGB(0, 0, 0)

        local desc = Instance.new("TextLabel", notif)
        desc.Text = "Enjoy!"
        desc.Size = UDim2.new(1, -80, 0, 20)
        desc.Position = UDim2.new(0, 80, 0, 50)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.TextScaled = true
        desc.TextColor3 = Color3.fromRGB(60, 60, 60)

        local bar = Instance.new("Frame", notif)
        bar.Size = UDim2.new(1, 0, 0, 3)
        bar.Position = UDim2.new(0, 0, 1, -3)
        bar.BackgroundColor3 = Color3.fromRGB(120, 190, 255)
        bar.BorderSizePixel = 0

        TweenService:Create(bar, TweenInfo.new(5), {Size = UDim2.new(0, 0, 0, 3)}):Play()
        TweenService:Create(notif, TweenInfo.new(0.4), {Position = notif.Position - UDim2.new(0, 0, 0, 20)}):Play()

        task.delay(5, function()
                TweenService:Create(notif, TweenInfo.new(0.4), {Position = notif.Position + UDim2.new(0, 0, 0, 40)}):Play()
                task.delay(0.4, function()
                        notif:Destroy()
                end)
        end)
end

-- Show notification
customNotif()
