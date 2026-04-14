-- FlossDance.lua | LocalScript
-- Place inside StarterCharacterScripts
-- Animates the Floss dance via Motor6D C0 CFrame manipulation.
-- Supports R6 and R15. Loops on RenderStepped. Resets on death/respawn.

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local activeConn = nil

-- ────────────────────────────────────────────────────────────────────────────
-- Rig Detection
-- ────────────────────────────────────────────────────────────────────────────

local function detectRig(char)
	if char:FindFirstChild("UpperTorso") then return "R15" end
	if char:FindFirstChild("Torso")      then return "R6"  end
	return nil
end

-- ────────────────────────────────────────────────────────────────────────────
-- Notification GUI
-- ────────────────────────────────────────────────────────────────────────────

local function showNotification(rigType)
	local prev = player.PlayerGui:FindFirstChild("FlossDanceGui")
	if prev then prev:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name           = "FlossDanceGui"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent         = player.PlayerGui

	local frame = Instance.new("Frame", gui)
	frame.AnchorPoint            = Vector2.new(0.5, 0)
	frame.Size                   = UDim2.new(0, 268, 0, 68)
	frame.Position               = UDim2.new(0.5, 0, 0, 22)
	frame.BackgroundColor3       = Color3.fromRGB(12, 12, 12)
	frame.BackgroundTransparency = 0.06
	frame.BorderSizePixel        = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color     = Color3.fromRGB(72, 210, 115)
	stroke.Thickness = 1.5

	local dot = Instance.new("Frame", frame)
	dot.Size             = UDim2.new(0, 8, 0, 8)
	dot.Position         = UDim2.new(0, 14, 0.5, -4)
	dot.BackgroundColor3 = Color3.fromRGB(72, 210, 115)
	dot.BorderSizePixel  = 0
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

	local label = Instance.new("TextLabel", frame)
	label.Size                   = UDim2.new(1, -38, 1, 0)
	label.Position               = UDim2.new(0, 30, 0, 0)
	label.BackgroundTransparency = 1
	label.Text                   = ("Detected: %s\nUsing %s Mode"):format(rigType, rigType)
	label.TextColor3             = Color3.fromRGB(238, 238, 238)
	label.Font                   = Enum.Font.GothamBold
	label.TextSize               = 14
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.LineHeight             = 1.45

	task.delay(2.2, function()
		local ti = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
		TweenService:Create(frame,  ti, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(label,  ti, { TextTransparency       = 1 }):Play()
		TweenService:Create(stroke, ti, { Transparency           = 1 }):Play()
		TweenService:Create(dot,    ti, { BackgroundTransparency = 1 }):Play()
		task.delay(0.65, function() gui:Destroy() end)
	end)
end

-- ────────────────────────────────────────────────────────────────────────────
-- C0 Snapshot & Restore
-- ────────────────────────────────────────────────────────────────────────────

local function snapshot(joints)
	local snap = {}
	for k, j in pairs(joints) do
		if j then snap[k] = j.C0 end
	end
	return snap
end

local function restore(joints, snap)
	for k, j in pairs(joints) do
		if j and snap[k] then j.C0 = snap[k] end
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Joint Collection
-- ────────────────────────────────────────────────────────────────────────────

local function collectR6(char)
	local torso = char:FindFirstChild("Torso")
	local hrp   = char:FindFirstChild("HumanoidRootPart")
	if not (torso and hrp) then return nil end

	local joints = {
		rootJoint     = hrp:FindFirstChild("RootJoint"),
		neck          = torso:FindFirstChild("Neck"),
		rightShoulder = torso:FindFirstChild("Right Shoulder"),
		leftShoulder  = torso:FindFirstChild("Left Shoulder"),
		rightHip      = torso:FindFirstChild("Right Hip"),
		leftHip       = torso:FindFirstChild("Left Hip"),
	}

	for _, j in pairs(joints) do
		if not j then return nil end
	end
	return joints
end

local function collectR15(char)
	local hrp        = char:FindFirstChild("HumanoidRootPart")
	local lowerTorso = char:FindFirstChild("LowerTorso")
	local upperTorso = char:FindFirstChild("UpperTorso")
	if not (hrp and lowerTorso and upperTorso) then return nil end

	local lUA = char:FindFirstChild("LeftUpperArm")
	local rUA = char:FindFirstChild("RightUpperArm")
	local lUL = char:FindFirstChild("LeftUpperLeg")
	local rUL = char:FindFirstChild("RightUpperLeg")

	return {
		rootJoint     = hrp:FindFirstChild("RootJoint"),
		waist         = lowerTorso:FindFirstChild("Waist"),
		neck          = upperTorso:FindFirstChild("Neck"),
		leftShoulder  = upperTorso:FindFirstChild("LeftShoulder"),
		rightShoulder = upperTorso:FindFirstChild("RightShoulder"),
		leftElbow     = lUA and lUA:FindFirstChild("LeftElbow"),
		rightElbow    = rUA and rUA:FindFirstChild("RightElbow"),
		leftHip       = lowerTorso:FindFirstChild("LeftHip"),
		rightHip      = lowerTorso:FindFirstChild("RightHip"),
		leftKnee      = lUL and lUL:FindFirstChild("LeftKnee"),
		rightKnee     = rUL and rUL:FindFirstChild("RightKnee"),
	}
end

-- ────────────────────────────────────────────────────────────────────────────
-- Floss Animation Math
--
-- Core Floss rhythm (per half-cycle):
--   • Root/Waist yaws left or right  →  hip pop
--   • Both arms pitch forward/back in OPPOSITE directions  →  one arm leads,
--     one arm trails, and they swap every half-cycle
--   • Both arms tilt laterally in sync with arm pitch  →  arms follow the
--     character's own swing direction
--   • Legs absorb weight on a double-frequency bounce
--
-- All motion is sinusoidal → guaranteed smooth, gapless loop.
-- ────────────────────────────────────────────────────────────────────────────

local SPEED = 3.0   -- radians per second (controls BPM of the dance)

local function animateR6(joints, snap, t)
	local s  = t * SPEED
	local sw = math.sin(s)        -- primary oscillator: drives hip pop & arm swing
	local s2 = math.sin(s * 2)   -- double frequency: drives leg bounce

	-- Root: yaw pop + tiny lateral COM shift
	joints.rootJoint.C0 = snap.rootJoint
		* CFrame.new(sw * 0.06, 0, 0)
		* CFrame.Angles(0, sw * 0.42, 0)

	-- Neck: counter-rotate so the head stays roughly forward-facing
	joints.neck.C0 = snap.neck
		* CFrame.Angles(0, -sw * 0.20, 0)

	-- Right shoulder:  pitch forward  when sw > 0  (arms going left)
	-- Left  shoulder:  pitch backward when sw > 0  (creates one-front / one-back shape)
	-- Both shoulders also tilt inward/outward with the swing (-sw * Z)
	joints.rightShoulder.C0 = snap.rightShoulder
		* CFrame.Angles( sw * 1.10, 0, -sw * 0.50)

	joints.leftShoulder.C0 = snap.leftShoulder
		* CFrame.Angles(-sw * 1.10, 0, -sw * 0.50)

	-- Hips/Legs: subtle alternating knee-dip on the double beat
	joints.rightHip.C0 = snap.rightHip * CFrame.Angles( s2 * 0.05, 0, 0)
	joints.leftHip.C0  = snap.leftHip  * CFrame.Angles(-s2 * 0.05, 0, 0)
end

local function animateR15(joints, snap, t)
	local s  = t * SPEED
	local sw = math.sin(s)
	local s2 = math.sin(s * 2)
	local as = math.abs(sw)

	-- Waist: primary hip pop driver (LowerTorso → UpperTorso joint)
	if joints.waist then
		joints.waist.C0 = snap.waist
			* CFrame.new(sw * 0.06, 0, 0)
			* CFrame.Angles(0, sw * 0.42, 0)
	end

	if joints.neck then
		joints.neck.C0 = snap.neck
			* CFrame.Angles(0, -sw * 0.18, 0)
	end

	-- Shoulders: identical Floss arm logic as R6
	if joints.rightShoulder then
		joints.rightShoulder.C0 = snap.rightShoulder
			* CFrame.Angles( sw * 1.10, 0, -sw * 0.50)
	end
	if joints.leftShoulder then
		joints.leftShoulder.C0 = snap.leftShoulder
			* CFrame.Angles(-sw * 1.10, 0, -sw * 0.50)
	end

	-- Elbows: held in a bent fist position; depth pulses with swing intensity
	local elbowBend = 1.15 + as * 0.20
	if joints.rightElbow then
		joints.rightElbow.C0 = snap.rightElbow * CFrame.Angles(elbowBend, 0, 0)
	end
	if joints.leftElbow then
		joints.leftElbow.C0 = snap.leftElbow * CFrame.Angles(elbowBend, 0, 0)
	end

	-- Hip joints: alternating double-beat bounce
	if joints.rightHip then
		joints.rightHip.C0 = snap.rightHip * CFrame.Angles( s2 * 0.06, 0, 0)
	end
	if joints.leftHip then
		joints.leftHip.C0 = snap.leftHip * CFrame.Angles(-s2 * 0.06, 0, 0)
	end

	-- Knees: flex proportional to swing magnitude → deepens at peak of each pop
	local kneeFlex = as * 0.11
	if joints.rightKnee then
		joints.rightKnee.C0 = snap.rightKnee * CFrame.Angles(kneeFlex, 0, 0)
	end
	if joints.leftKnee then
		joints.leftKnee.C0 = snap.leftKnee * CFrame.Angles(kneeFlex, 0, 0)
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Default Animation Suppression
-- Stops any running AnimationTracks so they don't fight our C0 writes.
-- ────────────────────────────────────────────────────────────────────────────

local function pauseDefaultAnimations(humanoid)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:Stop(0)
	end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Dance Lifecycle
-- ────────────────────────────────────────────────────────────────────────────

local function stopDance()
	if activeConn then
		activeConn:Disconnect()
		activeConn = nil
	end
end

local function startDance(char)
	stopDance()

	local rigType = detectRig(char)
	if not rigType then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	showNotification(rigType)
	task.wait(0.15)
	if not char.Parent then return end

	pauseDefaultAnimations(humanoid)

	local joints = (rigType == "R6") and collectR6(char) or collectR15(char)
	if not joints then return end

	local snap   = snapshot(joints)
	local t0     = tick()
	local animFn = (rigType == "R6") and animateR6 or animateR15

	humanoid.Died:Once(function()
		stopDance()
		restore(joints, snap)
	end)

	activeConn = RunService.RenderStepped:Connect(function()
		if not char.Parent or humanoid.Health <= 0 then
			stopDance()
			restore(joints, snap)
			return
		end
		animFn(joints, snap, tick() - t0)
	end)
end

-- ────────────────────────────────────────────────────────────────────────────
-- Bootstrap
-- ────────────────────────────────────────────────────────────────────────────

task.wait(0.1)
startDance(character)

player.CharacterAdded:Connect(function(newChar)
	task.wait(0.6)
	startDance(newChar)
end)
