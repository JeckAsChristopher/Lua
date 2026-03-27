local MODEL             = "openai/gpt-oss-20b"
local BOT_NAME          = "Oracle"
local MAX_HISTORY_TURNS = 10
local SAVE_FILE         = "aichat_key.txt"  

local Players         = game:GetService("Players")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer     = Players.LocalPlayer
local TS              = TweenService

local httpRequest = (syn and syn.request)
    or (http and http.request)
    or (request)
    or error("[AIChat] No HTTP function found.")

local function saveKey(key)
    pcall(function() writefile(SAVE_FILE, key) end)
end

local function loadSavedKey()
    local ok, result = pcall(function() return readfile(SAVE_FILE) end)
    if ok and result and result ~= "" then
        return result
    end
    return nil
end

local API_KEY = ""

local function pingAPI(key)
    local ok, res = pcall(function()
        return httpRequest({
            Url     = "https://api.groq.com/openai/v1/models",
            Method  = "GET",
            Headers = { ["Authorization"] = "Bearer " .. key },
        })
    end)
    if not ok then return false, "Request failed" end
    if res.StatusCode == 200 then return true, "Key valid" end
    if res.StatusCode == 401 then return false, "Invalid API key" end
    return false, "Status " .. tostring(res.StatusCode)
end

local history = {}

local function trimHistory()
    local max = MAX_HISTORY_TURNS * 2
    while #history > max do table.remove(history, 1) end
end

local function buildMessages(userText)
    table.insert(history, { role = "user", content = userText })
    trimHistory()
    local msgs = {{
        role    = "system",
        content = "You are a helpful AI inside a Roblox game. "
               .. "Keep every reply under 2 sentences. "
               .. "Plain text only — no markdown, asterisks, bullet points, or headers.",
    }}
    for _, m in ipairs(history) do table.insert(msgs, m) end
    return msgs
end

local function recordReply(reply)
    table.insert(history, { role = "assistant", content = reply })
end

local function askGroq(userText)
    local messages = buildMessages(userText)
    local t0 = os.clock()

    local ok, res = pcall(function()
        return httpRequest({
            Url    = "https://api.groq.com/openai/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Content-Type"]  = "application/json",
                ["Authorization"] = "Bearer " .. API_KEY,
            },
            Body = HttpService:JSONEncode({
                model       = MODEL,
                max_tokens  = 80,
                temperature = 0.7,
                stream      = false,
                messages    = messages,
            }),
        })
    end)

    local elapsed = math.floor((os.clock() - t0) * 1000)
    if not ok then table.remove(history); return "Request error: "..tostring(res), elapsed, 0, 0 end

    local data
    local pOk, pErr = pcall(function() data = HttpService:JSONDecode(res.Body) end)
    if not pOk then table.remove(history); return "Parse error: "..tostring(pErr), elapsed, 0, 0 end
    if data.error then table.remove(history); return tostring(data.error.message or data.error), elapsed, 0, 0 end

    if data.choices and data.choices[1] and data.choices[1].message then
        local reply = data.choices[1].message.content or "..."
        local usage = data.usage or {}
        recordReply(reply)
        return reply, elapsed, usage.prompt_tokens or 0, usage.completion_tokens or 0
    end
    table.remove(history)
    return "Unexpected response.", elapsed, 0, 0
end

local function getModels()
    local ok, res = pcall(function()
        return httpRequest({
            Url     = "https://api.groq.com/openai/v1/models",
            Method  = "GET",
            Headers = { ["Authorization"] = "Bearer " .. API_KEY },
        })
    end)
    if not ok then return {"request failed"} end
    local data
    pcall(function() data = HttpService:JSONDecode(res.Body) end)
    if not data or not data.data then return {"parse failed"} end
    local names = {}
    for _, m in ipairs(data.data) do table.insert(names, m.id or "?") end
    table.sort(names)
    return names
end

local coreGui = game:GetService("CoreGui")
if coreGui:FindFirstChild("AIChatGui") then
    coreGui:FindFirstChild("AIChatGui"):Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "AIChatGui"; gui.ResetOnSpawn = false
gui.DisplayOrder = 999; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = coreGui

local keyPanel = Instance.new("Frame")
keyPanel.Name = "KeyPanel"
keyPanel.Size = UDim2.new(0, 320, 0, 210)
keyPanel.Position = UDim2.new(0.5, -160, 0.5, -105)
keyPanel.BackgroundColor3 = Color3.fromRGB(8, 10, 10)
keyPanel.BorderSizePixel = 0
keyPanel.Parent = gui
Instance.new("UICorner", keyPanel).CornerRadius = UDim.new(0, 12)
local kStroke = Instance.new("UIStroke", keyPanel)
kStroke.Color = Color3.fromRGB(255, 130, 30); kStroke.Thickness = 1.2; kStroke.Transparency = 0.4

local kHeader = Instance.new("Frame", keyPanel)
kHeader.Size = UDim2.new(1, 0, 0, 38)
kHeader.BackgroundColor3 = Color3.fromRGB(16, 14, 10)
kHeader.BorderSizePixel = 0
Instance.new("UICorner", kHeader).CornerRadius = UDim.new(0, 12)
local kHFix = Instance.new("Frame", kHeader)
kHFix.Size = UDim2.new(1, 0, 0, 12); kHFix.Position = UDim2.new(0, 0, 1, -12)
kHFix.BackgroundColor3 = Color3.fromRGB(16, 14, 10); kHFix.BorderSizePixel = 0

local kDot = Instance.new("Frame", kHeader)
kDot.Size = UDim2.new(0, 7, 0, 7); kDot.Position = UDim2.new(0, 12, 0.5, -3.5)
kDot.BackgroundColor3 = Color3.fromRGB(255, 130, 30); kDot.BorderSizePixel = 0
Instance.new("UICorner", kDot).CornerRadius = UDim.new(1, 0)

local kTitle = Instance.new("TextLabel", kHeader)
kTitle.Text = "ORACLE  ·  API KEY SETUP"
kTitle.Size = UDim2.new(1, -20, 1, 0); kTitle.Position = UDim2.new(0, 26, 0, 0)
kTitle.BackgroundTransparency = 1; kTitle.Font = Enum.Font.GothamBold
kTitle.TextSize = 10; kTitle.TextColor3 = Color3.fromRGB(255, 210, 170)
kTitle.TextXAlignment = Enum.TextXAlignment.Left

local kInstruct = Instance.new("TextLabel", keyPanel)
kInstruct.Text = "Enter your Groq API key to continue.\nGet a free key at console.groq.com"
kInstruct.Size = UDim2.new(1, -24, 0, 36); kInstruct.Position = UDim2.new(0, 12, 0, 46)
kInstruct.BackgroundTransparency = 1; kInstruct.Font = Enum.Font.Gotham
kInstruct.TextSize = 10; kInstruct.TextColor3 = Color3.fromRGB(140, 120, 90)
kInstruct.TextWrapped = true; kInstruct.TextXAlignment = Enum.TextXAlignment.Left

local kInputFrame = Instance.new("Frame", keyPanel)
kInputFrame.Size = UDim2.new(1, -24, 0, 34); kInputFrame.Position = UDim2.new(0, 12, 0, 90)
kInputFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 16); kInputFrame.BorderSizePixel = 0
Instance.new("UICorner", kInputFrame).CornerRadius = UDim.new(0, 7)
local kInputStroke = Instance.new("UIStroke", kInputFrame)
kInputStroke.Color = Color3.fromRGB(80, 60, 30); kInputStroke.Thickness = 1

local kInput = Instance.new("TextBox", kInputFrame)
kInput.Size = UDim2.new(1, -12, 1, 0); kInput.Position = UDim2.new(0, 6, 0, 0)
kInput.BackgroundTransparency = 1; kInput.Font = Enum.Font.Code
kInput.TextSize = 10; kInput.TextColor3 = Color3.fromRGB(220, 200, 160)
kInput.PlaceholderText = "gsk_..."
kInput.PlaceholderColor3 = Color3.fromRGB(70, 60, 40)
kInput.Text = ""; kInput.ClearTextOnFocus = false
kInput.TextXAlignment = Enum.TextXAlignment.Left
kInput.TextTruncate = Enum.TextTruncate.AtEnd

local kStatus = Instance.new("TextLabel", keyPanel)
kStatus.Text = ""; kStatus.Size = UDim2.new(1, -24, 0, 18)
kStatus.Position = UDim2.new(0, 12, 0, 128)
kStatus.BackgroundTransparency = 1; kStatus.Font = Enum.Font.Gotham
kStatus.TextSize = 10; kStatus.TextColor3 = Color3.fromRGB(180, 80, 50)
kStatus.TextXAlignment = Enum.TextXAlignment.Left

local kBtn = Instance.new("TextButton", keyPanel)
kBtn.Size = UDim2.new(1, -24, 0, 36); kBtn.Position = UDim2.new(0, 12, 0, 152)
kBtn.BackgroundColor3 = Color3.fromRGB(200, 95, 20); kBtn.BorderSizePixel = 0
kBtn.Font = Enum.Font.GothamBold; kBtn.TextSize = 11
kBtn.TextColor3 = Color3.fromRGB(255, 240, 220); kBtn.Text = "CONFIRM KEY"
Instance.new("UICorner", kBtn).CornerRadius = UDim.new(0, 7)

kBtn.MouseEnter:Connect(function()
    TS:Create(kBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(230, 115, 30)}):Play()
end)
kBtn.MouseLeave:Connect(function()
    TS:Create(kBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 95, 20)}):Play()
end)

local mainPanel = Instance.new("Frame")
mainPanel.Name = "Panel"
mainPanel.Size = UDim2.new(0, 310, 0, 420)
mainPanel.Position = UDim2.new(1, -330, 0.5, -210)
mainPanel.BackgroundColor3 = Color3.fromRGB(8, 10, 10)
mainPanel.BorderSizePixel = 0
mainPanel.ClipsDescendants = true
mainPanel.Visible = false  

mainPanel.Parent = gui
Instance.new("UICorner", mainPanel).CornerRadius = UDim.new(0, 10)
local mStroke = Instance.new("UIStroke", mainPanel)
mStroke.Color = Color3.fromRGB(255, 130, 30); mStroke.Thickness = 1.2; mStroke.Transparency = 0.4

local header = Instance.new("Frame", mainPanel)
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(16, 14, 10); header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)
local hFix = Instance.new("Frame", header)
hFix.Size = UDim2.new(1, 0, 0, 10); hFix.Position = UDim2.new(0, 0, 1, -10)
hFix.BackgroundColor3 = Color3.fromRGB(16, 14, 10); hFix.BorderSizePixel = 0

local dot = Instance.new("Frame", header)
dot.Size = UDim2.new(0, 7, 0, 7); dot.Position = UDim2.new(0, 12, 0.5, -3.5)
dot.BackgroundColor3 = Color3.fromRGB(255, 130, 30); dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Text = BOT_NAME:upper() .. "  ·  GROQ"
titleLabel.Size = UDim2.new(1, -70, 1, 0); titleLabel.Position = UDim2.new(0, 26, 0, 0)
titleLabel.BackgroundTransparency = 1; titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 10; titleLabel.TextColor3 = Color3.fromRGB(255, 210, 170)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local statusLabel = Instance.new("TextLabel", header)
statusLabel.Text = "READY"; statusLabel.Size = UDim2.new(0, 60, 1, 0)
statusLabel.Position = UDim2.new(1, -64, 0, 0); statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham; statusLabel.TextSize = 9
statusLabel.TextColor3 = Color3.fromRGB(255, 130, 30)
statusLabel.TextXAlignment = Enum.TextXAlignment.Right

local infoBar = Instance.new("Frame", mainPanel)
infoBar.Size = UDim2.new(1, 0, 0, 20); infoBar.Position = UDim2.new(0, 0, 0, 36)
infoBar.BackgroundColor3 = Color3.fromRGB(14, 12, 8); infoBar.BorderSizePixel = 0

local infoLabel = Instance.new("TextLabel", infoBar)
infoLabel.Text = MODEL .. "  ·  turns: 0  ·  tokens: —  ·  —ms"
infoLabel.Size = UDim2.new(1, -8, 1, 0); infoLabel.Position = UDim2.new(0, 6, 0, 0)
infoLabel.BackgroundTransparency = 1; infoLabel.Font = Enum.Font.Gotham
infoLabel.TextSize = 8; infoLabel.TextColor3 = Color3.fromRGB(100, 75, 35)
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextTruncate = Enum.TextTruncate.AtEnd

local scroll = Instance.new("ScrollingFrame", mainPanel)
scroll.Size = UDim2.new(1, -12, 1, -110); scroll.Position = UDim2.new(0, 6, 0, 58)
scroll.BackgroundTransparency = 1; scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 130, 30)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 6); layout.SortOrder = Enum.SortOrder.LayoutOrder
local lpad = Instance.new("UIPadding", scroll)
lpad.PaddingTop = UDim.new(0, 4); lpad.PaddingBottom = UDim.new(0, 4)

local sep = Instance.new("Frame", mainPanel)
sep.Size = UDim2.new(1, -12, 0, 1); sep.Position = UDim2.new(0, 6, 1, -48)
sep.BackgroundColor3 = Color3.fromRGB(50, 35, 15); sep.BorderSizePixel = 0

local footer = Instance.new("TextLabel", mainPanel)
footer.Text = "Watching chat  ·  type /ai help for commands"
footer.Size = UDim2.new(1, -12, 0, 42); footer.Position = UDim2.new(0, 6, 1, -46)
footer.BackgroundTransparency = 1; footer.Font = Enum.Font.Gotham
footer.TextSize = 9; footer.TextColor3 = Color3.fromRGB(70, 50, 25)
footer.TextWrapped = true; footer.TextXAlignment = Enum.TextXAlignment.Left

local totalTokens = 0
local bubbleCount = 0

local function setStatus(text, color)
    statusLabel.Text = text
    statusLabel.TextColor3 = color
    TS:Create(dot, TweenInfo.new(0.3), {BackgroundColor3 = color}):Play()
end

local function updateInfoBar(latMs, pTok, cTok)
    totalTokens = totalTokens + pTok + cTok
    local turns = math.floor(#history / 2)
    infoLabel.Text = string.format("%s  ·  turns: %d  ·  tokens: %d  ·  %dms",
        MODEL, turns, totalTokens, latMs)
end

local function scrollToBottom()
    task.delay(0.15, function()
        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
    end)
end

local function addBubble(who, msg, isAI, meta)
    bubbleCount = bubbleCount + 1
    local bubble = Instance.new("Frame", scroll)
    bubble.LayoutOrder = bubbleCount
    bubble.BackgroundColor3 = isAI and Color3.fromRGB(22, 16, 10) or Color3.fromRGB(14, 14, 12)
    bubble.BorderSizePixel = 0; bubble.AutomaticSize = Enum.AutomaticSize.Y
    bubble.Size = UDim2.new(1, 0, 0, 0)
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 7)
    if isAI then
        local s = Instance.new("UIStroke", bubble)
        s.Color = Color3.fromRGB(200, 100, 20); s.Thickness = 1; s.Transparency = 0.55
    end
    local bp = Instance.new("UIPadding", bubble)
    bp.PaddingLeft = UDim.new(0, 9); bp.PaddingRight = UDim.new(0, 9)
    bp.PaddingTop = UDim.new(0, 5); bp.PaddingBottom = UDim.new(0, 7)
    local bl = Instance.new("UIListLayout", bubble)
    bl.Padding = UDim.new(0, 2); bl.SortOrder = Enum.SortOrder.LayoutOrder

    local whoL = Instance.new("TextLabel", bubble)
    whoL.LayoutOrder = 1
    whoL.Text = isAI and ("◈ " .. BOT_NAME) or ("◇ " .. who)
    whoL.BackgroundTransparency = 1; whoL.Size = UDim2.new(1, 0, 0, 13)
    whoL.AutomaticSize = Enum.AutomaticSize.Y; whoL.Font = Enum.Font.GothamBold
    whoL.TextSize = 9
    whoL.TextColor3 = isAI and Color3.fromRGB(255, 150, 50) or Color3.fromRGB(160, 145, 125)
    whoL.TextXAlignment = Enum.TextXAlignment.Left

    local msgL = Instance.new("TextLabel", bubble)
    msgL.LayoutOrder = 2; msgL.Text = msg
    msgL.BackgroundTransparency = 1; msgL.Size = UDim2.new(1, 0, 0, 0)
    msgL.AutomaticSize = Enum.AutomaticSize.Y; msgL.Font = Enum.Font.Gotham
    msgL.TextSize = 12
    msgL.TextColor3 = isAI and Color3.fromRGB(255, 230, 200) or Color3.fromRGB(185, 178, 165)
    msgL.TextWrapped = true; msgL.TextXAlignment = Enum.TextXAlignment.Left

    if isAI and meta then
        local mL = Instance.new("TextLabel", bubble)
        mL.LayoutOrder = 3; mL.Text = meta
        mL.BackgroundTransparency = 1; mL.Size = UDim2.new(1, 0, 0, 11)
        mL.AutomaticSize = Enum.AutomaticSize.Y; mL.Font = Enum.Font.Gotham
        mL.TextSize = 8; mL.TextColor3 = Color3.fromRGB(90, 65, 30)
        mL.TextXAlignment = Enum.TextXAlignment.Left
    end

    bubble.BackgroundTransparency = 1
    whoL.TextTransparency = 1; msgL.TextTransparency = 1
    task.defer(function()
        TS:Create(bubble, TweenInfo.new(0.2),  {BackgroundTransparency = 0}):Play()
        TS:Create(whoL,   TweenInfo.new(0.25), {TextTransparency = 0}):Play()
        TS:Create(msgL,   TweenInfo.new(0.3),  {TextTransparency = 0}):Play()
    end)
    scrollToBottom()
end

local function addSystem(msg)
    addBubble("SYSTEM", msg, false)
end

local HELP_TEXT = "/ai ping | clear | history | models | model <n> | help"

local function handleCommand(args)
    local cmd = (args[1] or ""):lower()

    if cmd == "ping" then
        setStatus("PING…", Color3.fromRGB(255, 210, 40))
        task.spawn(function()
            local ok, msg = pingAPI(API_KEY)
            addSystem((ok and "✓ " or "✗ ") .. msg)
            setStatus(ok and "READY" or "ERROR",
                ok and Color3.fromRGB(255, 130, 30) or Color3.fromRGB(255, 50, 50))
        end)

    elseif cmd == "clear" then
        history = {}; totalTokens = 0
        infoLabel.Text = MODEL .. "  ·  turns: 0  ·  tokens: 0  ·  —ms"
        addSystem("History cleared.")

    elseif cmd == "history" then
        addSystem(string.format("History: %d turn(s), %d messages, %d tokens",
            math.floor(#history / 2), #history, totalTokens))

    elseif cmd == "models" then
        setStatus("LOADING", Color3.fromRGB(255, 210, 40))
        task.spawn(function()
            for _, m in ipairs(getModels()) do
                addSystem((m == MODEL and "► " or "  ") .. m)
            end
            setStatus("READY", Color3.fromRGB(255, 130, 30))
        end)

    elseif cmd == "model" then
        if args[2] and args[2] ~= "" then
            MODEL = args[2]; history = {}; totalTokens = 0
            infoLabel.Text = MODEL .. "  ·  turns: 0  ·  tokens: 0  ·  —ms"
            addSystem("Switched to: " .. MODEL .. " (history cleared)")
        else
            addSystem("Usage: /ai model <model-name>")
        end

    elseif cmd == "help" then
        addSystem(HELP_TEXT)

    else
        addSystem("Unknown command. " .. HELP_TEXT)
    end
end

local USER_COOLDOWN    = 12   

local MAX_PENDING      = 2    

local GLOBAL_WINDOW    = 6    

local GLOBAL_THRESHOLD = 5    

local userLastReply  = {}  

local pendingCount   = 0   

local globalMsgTimes = {}  

local function isGlobalFlood()
    local now = os.clock()

    local fresh = {}
    for _, t in ipairs(globalMsgTimes) do
        if now - t < GLOBAL_WINDOW then
            table.insert(fresh, t)
        end
    end
    globalMsgTimes = fresh
    return #globalMsgTimes >= GLOBAL_THRESHOLD
end

local function userOnCooldown(userId)
    local last = userLastReply[userId]
    return last and (os.clock() - last) < USER_COOLDOWN
end

TextChatService.MessageReceived:Connect(function(msg)
    if not mainPanel.Visible then return end
    local sender = msg.TextSource
    if not sender then return end
    local text = msg.Text
    if not text or text == "" then return end

    if sender.UserId == LocalPlayer.UserId then
        if text:lower():sub(1, 3) == "/ai" then
            local parts = {}
            for word in text:sub(4):gmatch("%S+") do table.insert(parts, word) end
            handleCommand(parts)
        end
        return
    end

    table.insert(globalMsgTimes, os.clock())

    if isGlobalFlood() then
        addBubble(sender.Name, text, false)
        addSystem("⚡ Chat flood — skipping reply.")
        return
    end

    if userOnCooldown(sender.UserId) then
        addBubble(sender.Name, text, false)

        return
    end

    if pendingCount >= MAX_PENDING then
        addBubble(sender.Name, text, false)
        addSystem("⚡ Busy — skipping reply.")
        return
    end

    addBubble(sender.Name, text, false)
    setStatus("THINKING", Color3.fromRGB(255, 210, 40))
    userLastReply[sender.UserId] = os.clock()
    pendingCount = pendingCount + 1

    task.spawn(function()
        local reply, latMs, pTok, cTok = askGroq(sender.Name .. " said: " .. text)
        pendingCount = math.max(0, pendingCount - 1)
        addBubble(BOT_NAME, reply, true, string.format("%dms  ·  +%d tokens", latMs, pTok + cTok))
        updateInfoBar(latMs, pTok, cTok)
        setStatus("READY", Color3.fromRGB(255, 130, 30))
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then
            local t = #reply > 200 and reply:sub(1, 197) .. "..." or reply
            pcall(function() channel:SendAsync(t) end)
        end
    end)
end)

do
    local dragging, dragStart, startPos
    mainPanel.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = mainPanel.Position
        end
    end)
    mainPanel.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            mainPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                           startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    mainPanel.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

do
    local dragging, dragStart, startPos
    keyPanel.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = keyPanel.Position
        end
    end)
    keyPanel.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            keyPanel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                          startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    keyPanel.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function launchMainPanel(key)
    API_KEY = key

    TS:Create(keyPanel, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    for _, child in ipairs(keyPanel:GetDescendants()) do
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            TS:Create(child, TweenInfo.new(0.25), {TextTransparency = 1}):Play()
            TS:Create(child, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
        elseif child:IsA("Frame") then
            TS:Create(child, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
        elseif child:IsA("UIStroke") then
            TS:Create(child, TweenInfo.new(0.25), {Transparency = 1}):Play()
        end
    end
    task.delay(0.35, function()
        keyPanel.Visible = false
    end)

    mainPanel.Visible = true
    mainPanel.BackgroundTransparency = 1
    TS:Create(mainPanel, TweenInfo.new(0.35), {BackgroundTransparency = 0}):Play()

    addSystem("Loaded  ·  " .. MODEL)
    addSystem("Key saved — will auto-load next time.")
    addSystem(HELP_TEXT)
    setStatus("READY", Color3.fromRGB(255, 130, 30))
    print("[AIChat] Loaded —", MODEL)
end

local function tryValidateKey(key)
    key = key:match("^%s*(.-)%s*$")  

    if key == "" then
        kStatus.Text = "Please enter a key."
        kStatus.TextColor3 = Color3.fromRGB(200, 80, 50)
        return
    end

    kStatus.Text = "Checking key…"
    kStatus.TextColor3 = Color3.fromRGB(200, 170, 60)
    kBtn.Text = "CHECKING…"
    kBtn.BackgroundColor3 = Color3.fromRGB(100, 80, 30)

    task.spawn(function()
        local ok, msg = pingAPI(key)
        if ok then
            kStatus.Text = "✓ " .. msg .. " — loading…"
            kStatus.TextColor3 = Color3.fromRGB(80, 200, 100)
            saveKey(key)
            task.wait(0.5)
            launchMainPanel(key)
        else
            kStatus.Text = "✗ " .. msg .. " — try again."
            kStatus.TextColor3 = Color3.fromRGB(220, 70, 50)
            kBtn.Text = "CONFIRM KEY"
            kBtn.BackgroundColor3 = Color3.fromRGB(200, 95, 20)
        end
    end)
end

kBtn.MouseButton1Click:Connect(function()
    tryValidateKey(kInput.Text)
end)

kInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        tryValidateKey(kInput.Text)
    end
end)

local saved = loadSavedKey()
if saved then

    kInput.Text = saved
    kStatus.Text = "Saved key found — verifying…"
    kStatus.TextColor3 = Color3.fromRGB(200, 170, 60)
    task.spawn(function()
        task.wait(0.3)  

        tryValidateKey(saved)
    end)
end