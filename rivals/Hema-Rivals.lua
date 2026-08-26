--[[
  Noir Hub · Rivals | Black & White
  VERSION: 2026.08.25-noir-elo-spoof
  1) 啟動跑戰鬥核心
  2) 自動載入 Linoria 並建立選單
  3) RightShift 開關選單
  4) 選單開啟時暫停戰鬥/ESP 迴圈，減少卡住
  5) 隊友檢查：Lunara 多層（Team/Attr/Character）
]]
-- HEMA Rivals boot
print("[Noir Hub] ========== FILE EXECUTING ==========")
print("[HEMA] if you see this, Delta ran the file")


local HEMA_VERSION = "2026.08.25-noir-elo-spoof"
if type(getgenv) ~= "function" then
	warn("[HEMA] getgenv missing — executor incomplete")
end
local function gset(k, v)
	pcall(function() getgenv()[k] = v end)
end
local function gget(k)
	local ok, v = pcall(function() return getgenv()[k] end)
	return ok and v or nil
end
-- 強制刪除舊版實例 / autoexec / GUI
do
	print("[HEMA] 清除舊版中…", tostring(getgenv().HEMA_VERSION or "none"))
	getgenv().HEMA_KILL = true
	pcall(function()
		if getgenv().Library and getgenv().Library.Unload then
			getgenv().Library:Unload()
		end
	end)
	-- 刪除可能殘留的 GUI
	pcall(function()
		local roots = {}
		pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
		pcall(function() if gethui then table.insert(roots, gethui()) end end)
		local lp = game:GetService("Players").LocalPlayer
		if lp then pcall(function() table.insert(roots, lp:FindFirstChild("PlayerGui")) end) end
		for _, root in ipairs(roots) do
			if root then
				for _, ch in ipairs(root:GetChildren()) do
					local n = string.lower(ch.Name)
					if n:find("hema") or n:find("linoria") or n:find("oblivion") or n:find("window") and n:find("rivals") then
						pcall(function() ch:Destroy() end)
					end
				end
			end
		end
	end)
	-- 刪 autoexec 舊檔
	pcall(function()
		if type(delfile) ~= "function" and type(writefile) ~= "function" then return end
		local names = {
			-- 只清 autoexec，绝不覆写用户正在执行的 Hema-Rivals.lua
			"autoexec/HemaRivals_Auto.lua",
			"Autoexec/HemaRivals_Auto.lua",
			"workspace/autoexec/HemaRivals_Auto.lua",
			"HemaTech/HemaRivals_Auto.lua",
		}
		for _, path in ipairs(names) do
			if type(delfile) == "function" then pcall(delfile, path) end
			if type(writefile) == "function" then pcall(writefile, path, "-- cleared by HEMA\nreturn\n") end
		end
	end)
	-- 清 getgenv 舊鍵
	for _, k in ipairs({"HEMA_RIVALS_RUNNING","Library","ThemeManager","SaveManager","HEMA_SCRIPT_URL"}) do
		pcall(function() getgenv()[k] = nil end)
	end
	task.wait(0.2)
	getgenv().HEMA_KILL = false
end
getgenv().HEMA_VERSION = HEMA_VERSION
getgenv().HEMA_RIVALS_RUNNING = true
print("[HEMA] 版本", HEMA_VERSION, "舊版已清除 — 排程 0.5s…")

task.delay(0.5, function()
local okBoot, errBoot = pcall(function()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local lp = Players.LocalPlayer
if not lp then
	local t0 = tick()
	while not lp and tick() - t0 < 8 do task.wait(0.25) lp = Players.LocalPlayer end
end
if not lp then
	warn("[HEMA] no LocalPlayer")
	getgenv().HEMA_RIVALS_RUNNING = false
	return
end
print("[HEMA] start")

local menuOpenWanted = false -- 提前宣告，避免 RenderStepped 閉包錯誤

local CONFIG_DIR = "HemaTech/configs"
local CFG = {
	AimOn = false, Silent = false, SilentAuto = false, Triggerbot = false,
	TeamCheck = true, WallCheck = false, AntiKatana = true,
	AntiKatanaStrict = true,
	FOV = 200, ShowFOV = false, Smooth = 0.25, MaxDist = 300,
	Part = "Head", PixelY = 0, PixelX = 0,
	HitChance = 100, FireRate = 0.05, AutoSwap = false,
	TargetMode = "FOV",
	SoftMode = false, -- Lunara 預設不鎖速
	SoftFireRate = 0.05,
	SoftHitChance = 100,
	Hitmarker = false,
	ShowStats = false,
	EspName = false, EspDist = false, EspChams = false, EspHp = false,
	EspBox = false, EspFill = false, EspSkel = false, EspTracer = false, EspTools = false, EspGlow = false,
	EspTeamCheck = false, EspMaxDist = 800, EspTarget = false, Crosshair = false,
	Fly = false, FlySpeed = 50, SpeedOn = false, SpeedVal = 20,
	Danger = false, DangerDist = 5, BodySplit = false, BodySplitDist = 4,
	BodyJitter = false, BodyJitterAmt = 0.12, BodyJitterSpeed = 18,
	WeaponVote = false,
	VotePrimary = "Assault Rifle", VoteSecondary = "Handgun",
	VoteMelee = "Fists", VoteUtility = "Grenade",
	AutoQueue = false, QueueMode = "1v1", RankedQueue = false,
	Fullbright = false, NoFog = false, AmbientBoost = false,
	NoShadows = false, BrightWorld = false,
	BulletTracers = false, HitMarkers = false, HitNotifs = false,
	ChinaHat = false, TargetHighlight = true,
	NoFlash = false, NoSmoke = false, HitSound = false,
	HitSoundId = "rbxassetid://5043539486", HitSoundVol = 1,
	HitSoundName = "Rust HS",
	-- Lunara Profile（等級 / 連勝，僅本地視覺）
	LevelSpoof = false,
	LevelValue = 9999,
	WinStreakSpoof = false,
	WinStreakValue = 9999,
	FakeRankOn = false,
	DisplayELO = 2400, -- Diamond I 門檻
	FakeRankPreset = "Diamond I",
	NameSpoof = false,
	NameSpoofValue = "hi",
	NameSpoofVerified = false,
	NameSpoofPremium = false,
	DeviceSpoof = false,
	DeviceType = "Console",
	RapidFire = false,
	NoSpread = false,
	NoRecoil = false,
	MaxAccuracy = false,
	ShowSilentFOV = false,
	HitChance = 100,
	SkyOn = false, SkyName = "Nebula",
	GunChams = false, ArmChams = false, HideArms = false,
	GunChamsColor = Color3.fromRGB(255, 255, 255),
	ArmChamsColor = Color3.fromRGB(220, 220, 220),
	LightingBright = 2, ClockTime = 14,
	FogStart = 0, FogEnd = 1e6,
	BloomOn = false, CCOn = false, CCSat = 0.2, CCBright = 0.05,
	SunRays = false, Atmosphere = false, DepthOfField = false,
	Rain = false, RainRate = 200,
	Crosshair = false, CrosshairSize = 8, CrosshairGap = 4,
	BulletTracer = false, TracerColor = Color3.fromRGB(0, 255, 180),
	ShowSilentFOV = false, SilentFOV = 200,
	FOVFill = false, FOVThickness = 2,
	AspectRatio = false, AspectVal = 1.6,
	UnlockAllSkins = false,
	-- 快捷鍵：預設空白（不綁定），可在設定自訂
	KeyAim = "", KeySilent = "", KeySilentAuto = "",
	KeyTrigger = "", KeyEsp = "", KeyFly = "", KeySpeed = "",
	KeyMenu = "RightShift", KeyPanic = "", KeyRage = "",
	-- Ragebot（取代危險模式）
	RageOn = false,
	RagePos = "behind", -- behind | under | above | front | random
	RageDist = 5,
	RageUnder = 8,
	RageAutoShoot = true,
	RageReturn = true,
	RageStatus = true,
	RageVoid = false,
	AutoKnife = false,
	AutoKnifeCD = 0.15, -- 循環間隔（無冷卻時可很低）
	NoMeleeCD = true, -- 近戰突刺無冷卻

	AutoKnifeDist = 3.5, -- 站在背後距離
	AutoKnifeVoidY = -120, -- 躲進虛空的高度
	AutoKnifeVoidTime = 0.45, -- 待在虛空秒數

	RageViewCheck = false, -- 可見檢查（牆）
	RageViewAngle = true, -- 視角留原地、身體到對面（相機分離）
	AntiVoid = true, -- 反虛空/出界拉回
	AntiVoidY = -50, -- Y 低於此視為出界
	AntiVoidMaxFall = 90, -- 離安全點垂直掉落超過此距離也拉回
	AntiVoidMaxDist = 280, -- 離安全點水平過遠也拉回
	AntiVoidCheckMap = true, -- 偵測 Void/Kill 零件與腳下無地

	RageFireRate = 0.03, -- Lunara 風格高攻速（越小越快）
	RageHitChance = 100,
	RageAutoSwap = true, -- 子彈打完自動換下一把（僅 Rage）
	-- 語言
	Lang = "zh", -- zh | en
	AutoLoadConfig = true, -- 啟動時自動載入「設為自動載入」的設定檔
	AutoExecScript = false, -- 自動開啟腳本（autoexec + 傳送再載）
	AutoExecDelay = 10, -- 自動執行延遲秒數
}


local HIT_SOUNDS = {
	["Rust HS"] = "rbxassetid://5043539486",
	["Neverlose"] = "rbxassetid://97643101798871",
	["Minecraft Bow"] = "rbxassetid://3442683707",
	["Minecraft Hit"] = "rbxassetid://8766809464",
	["CSGO"] = "rbxassetid://5764885315",
	["Bubble"] = "rbxassetid://6534947588",
	["Pop"] = "rbxassetid://198598793",
	["Rust"] = "rbxassetid://1255040462",
	["Sans"] = "rbxassetid://3188795283",
	["Fart"] = "rbxassetid://130833677",
	["Vine"] = "rbxassetid://5332680810",
	["Bruh"] = "rbxassetid://4578740568",
	["Skeet"] = "rbxassetid://5633695679",
	["Fatality"] = "rbxassetid://6534947869",
	["Bonk"] = "rbxassetid://5766898159",
	["Minecraft"] = "rbxassetid://5869422451",
	["Gamesense"] = "rbxassetid://4817809188",
	["Click"] = "rbxassetid://8053704437",
	["Ding"] = "rbxassetid://7149516994",
	["TF2 Critical"] = "rbxassetid://296102734",
	["Osu"] = "rbxassetid://7149255551",
	["Beep"] = "rbxassetid://8177256015",
}
local HIT_SOUND_NAMES = {}
for n in pairs(HIT_SOUNDS) do table.insert(HIT_SOUND_NAMES, n) end
table.sort(HIT_SOUND_NAMES)

local SKY_PRESETS = {
	Default = { SkyboxBk = "rbxassetid://91458024", SkyboxDn = "rbxassetid://91457980", SkyboxFt = "rbxassetid://91458024", SkyboxLf = "rbxassetid://91458024", SkyboxRt = "rbxassetid://91458024", SkyboxUp = "rbxassetid://91458002" },
	Neptune = { SkyboxBk = "rbxassetid://218955819", SkyboxDn = "rbxassetid://218953419", SkyboxFt = "rbxassetid://218954524", SkyboxLf = "rbxassetid://218958493", SkyboxRt = "rbxassetid://218957134", SkyboxUp = "rbxassetid://218950090" },
	["Among Us"] = { SkyboxBk = "rbxassetid://5752463190", SkyboxDn = "rbxassetid://5752463190", SkyboxFt = "rbxassetid://5752463190", SkyboxLf = "rbxassetid://5752463190", SkyboxRt = "rbxassetid://5752463190", SkyboxUp = "rbxassetid://5752463190" },
	Nebula = { SkyboxBk = "rbxassetid://159454299", SkyboxDn = "rbxassetid://159454296", SkyboxFt = "rbxassetid://159454293", SkyboxLf = "rbxassetid://159454286", SkyboxRt = "rbxassetid://159454300", SkyboxUp = "rbxassetid://159454288" },
	Vaporwave = { SkyboxBk = "rbxassetid://1417494030", SkyboxDn = "rbxassetid://1417494146", SkyboxFt = "rbxassetid://1417494253", SkyboxLf = "rbxassetid://1417494402", SkyboxRt = "rbxassetid://1417494499", SkyboxUp = "rbxassetid://1417494643" },
	Clouds = { SkyboxBk = "rbxassetid://570557514", SkyboxDn = "rbxassetid://570557775", SkyboxFt = "rbxassetid://570557559", SkyboxLf = "rbxassetid://570557620", SkyboxRt = "rbxassetid://570557672", SkyboxUp = "rbxassetid://570557727" },
	Twilight = { SkyboxBk = "rbxassetid://264908339", SkyboxDn = "rbxassetid://264907909", SkyboxFt = "rbxassetid://264909420", SkyboxLf = "rbxassetid://264909758", SkyboxRt = "rbxassetid://264908886", SkyboxUp = "rbxassetid://264907379" },
	Minecraft = { SkyboxBk = "rbxassetid://1876545003", SkyboxDn = "rbxassetid://1876544331", SkyboxFt = "rbxassetid://1876542941", SkyboxLf = "rbxassetid://1876543392", SkyboxRt = "rbxassetid://1876543764", SkyboxUp = "rbxassetid://1876544642" },
	Chill = { SkyboxBk = "rbxassetid://5084575798", SkyboxDn = "rbxassetid://5084575916", SkyboxFt = "rbxassetid://5103949679", SkyboxLf = "rbxassetid://5103948542", SkyboxRt = "rbxassetid://5103948784", SkyboxUp = "rbxassetid://5084576400" },
}
local SKY_NAMES = {}
for n in pairs(SKY_PRESETS) do table.insert(SKY_NAMES, n) end
table.sort(SKY_NAMES)

local function playHitSoundNow()
	local id = HIT_SOUNDS[CFG.HitSoundName or "Rust HS"] or CFG.HitSoundId or "rbxassetid://5043539486"
	pcall(function()
		local s = Instance.new("Sound")
		s.Name = "HemaHit"
		s.SoundId = id
		s.Volume = math.clamp(CFG.HitSoundVol or 1, 0.1, 3)
		s.Parent = workspace.CurrentCamera or game:GetService("SoundService")
		s:Play()
		task.delay(3, function() pcall(function() s:Destroy() end) end)
	end)
end

local function applySkyPreset(name)
	name = name or CFG.SkyName or "Nebula"
	local preset = SKY_PRESETS[name]
	if not preset then return end
	pcall(function()
		local old = Lighting:FindFirstChild("HemaSky")
		if old then old:Destroy() end
		local sky = Instance.new("Sky")
		sky.Name = "HemaSky"
		for k, v in pairs(preset) do
			pcall(function() sky[k] = v end)
		end
		sky.Parent = Lighting
	end)
end

local function L(zh, en)
	if CFG.Lang == "en" then return en or zh end
	return zh
end

local function hrp()
	local c = lp.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local rmb, lmb = false, false
UIS.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 then rmb = true end
	if i.UserInputType == Enum.UserInputType.MouseButton1 then lmb = true end
end)
UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton2 then rmb = false end
	if i.UserInputType == Enum.UserInputType.MouseButton1 then lmb = false end
end)
local function holdRMB()
	return rmb or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end
local function holdLMB()
	return lmb or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end

local katanausers = {}
local function nameLooksWeapon(n, keys)
	n = tostring(n or ""):lower():gsub("%s+", "")
	if n == "" then return false end
	for _, k in ipairs(keys) do
		if n:find(k, 1, true) then return true end
	end
	return false
end
local KATANA_KEYS = { "katana", "katan", "武士刀" }
local KNIFE_KEYS = { "knife", "小刀", "匕首" }
local SHIELD_KEYS = { "shield", "riotshield", "riot", "盾" }

-- 掃描角色/背包/模型名稱，回傳目前像是裝備的近戰名
local function scanPlayerGear(plr)
	local info = { katana = false, knife = false, shield = false, names = {} }
	if not plr then return info end
	local function consider(name)
		if not name then return end
		local n = tostring(name)
		table.insert(info.names, n)
		local nl = n:lower()
		if nameLooksWeapon(nl, KATANA_KEYS) then info.katana = true end
		if nameLooksWeapon(nl, KNIFE_KEYS) then info.knife = true end
		if nameLooksWeapon(nl, SHIELD_KEYS) then info.shield = true end
	end
	local ch = plr.Character
	if ch then
		for _, t in ipairs(ch:GetChildren()) do
			if t:IsA("Tool") or t:IsA("Model") or t:IsA("Folder") then
				consider(t.Name)
			end
			-- 有些皮膚/武器掛在配件
			if t:IsA("Accessory") then consider(t.Name) end
		end
		-- 屬性
		pcall(function()
			consider(ch:GetAttribute("Weapon"))
			consider(ch:GetAttribute("Equipped"))
			consider(ch:GetAttribute("Item"))
			consider(ch:GetAttribute("HeldItem"))
		end)
		-- StringValue 常見
		for _, d in ipairs(ch:GetDescendants()) do
			if d:IsA("StringValue") or d:IsA("StringAttribute") then
				local nm = tostring(d.Name or ""):lower()
				if nm:find("weapon") or nm:find("item") or nm:find("equip") or nm == "name" then
					consider(d.Value)
				end
			end
			-- 武器模型名稱
			if d:IsA("Model") or d:IsA("MeshPart") or d:IsA("BasePart") then
				local dn = tostring(d.Name or ""):lower()
				if nameLooksWeapon(dn, KATANA_KEYS) or nameLooksWeapon(dn, KNIFE_KEYS) or nameLooksWeapon(dn, SHIELD_KEYS) then
					consider(d.Name)
				end
			end
		end
	end
	local bp = plr:FindFirstChild("Backpack")
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") then consider(t.Name) end
		end
	end
	-- PlayerGui / 狀態備援（部分客戶端會同步）
	pcall(function()
		consider(plr:GetAttribute("Weapon"))
		consider(plr:GetAttribute("EquippedItem"))
	end)
	return info
end

local function toolLooksKatana(tool)
	if not tool then return false end
	return nameLooksWeapon(tool.Name, KATANA_KEYS)
end

local function isKatanaDeflecting(plr)
	if not CFG.AntiKatana or not plr then return false end
	if katanausers[plr] then return true end
	local gear = scanPlayerGear(plr)
	if not gear.katana then return false end
	if CFG.AntiKatanaStrict ~= false then
		return true -- 持刀/身上有 katana 即不鎖
	end
	local ch = plr.Character
	if not ch then return true end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local animator = hum and (hum:FindFirstChildOfClass("Animator") or hum:FindFirstChild("Animator"))
	if animator then
		local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
		if ok and tracks then
			for _, track in ipairs(tracks) do
				local tn = tostring(track.Name or ""):lower()
				if tn:find("deflect") or tn:find("block") or tn:find("parry") or tn:find("guard") or tn:find("slash") then
					return true
				end
			end
		end
	end
	-- 非嚴格且沒動畫：仍跳過（卡塔納反彈風險高）
	return true
end

-- 週期標記 katana 使用者（備援，較短間隔）
task.spawn(function()
	while true do
		task.wait(0.25)
		if not CFG.AntiKatana then
			katanausers = {}
		else
			local now = {}
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= lp then
					local g = scanPlayerGear(plr)
					if g.katana then now[plr] = true end
				end
			end
			katanausers = now
		end
	end
end)

-- ===== Lunara 戰鬥：隊友判定（TeamID）=====
local function isteammate(targetplayer)
	if not targetplayer then return false end
	return lp:GetAttribute("TeamID") == targetplayer:GetAttribute("TeamID")
end
local function checkteammate(player)
	if not player or player == lp then return true end
	local myTeam = lp:GetAttribute("TeamID")
	local theirTeam = player:GetAttribute("TeamID")
	if myTeam ~= nil and theirTeam ~= nil then
		return myTeam == theirTeam
	end
	return lp.Team and player.Team and lp.Team == player.Team
end
local function sameTeam(plr)
	if not plr or plr == lp then return true end
	if checkteammate(plr) then return true end
	if isteammate(plr) then return true end
	return false
end

local function isEnemy(plr)
	if not plr or plr == lp then return false end
	if CFG.TeamCheck ~= false and sameTeam(plr) then return false end
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return true
end

local function partOf(plr)
	local ch = plr.Character
	if not ch then return nil end
	local p = ch:FindFirstChild(CFG.Part or "Head")
	if p and p:IsA("BasePart") then return p end
	return ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
end

local function visible(part)
	-- 牆壁檢查 / Lunara 檢查視角（Rage 只打看得見的）
	local needCheck = CFG.WallCheck or (CFG.RageViewCheck and CFG.RageOn)
	if not needCheck or not part then return true end
	local cam = workspace.CurrentCamera
	if not cam then return true end
	local origin = cam.CFrame.Position
	local target = part.Position
	local delta = target - origin
	local dist = delta.Magnitude
	if dist < 1 then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { lp.Character, cam }
	params.IgnoreWater = true
	local hit = workspace:Raycast(origin, delta.Unit * dist, params)
	if not hit then return true end
	return hit.Instance and part.Parent and hit.Instance:IsDescendantOf(part.Parent)
end

local function worldToScreen(pos)
	local cam = workspace.CurrentCamera
	if not cam then return nil, false end
	local v, on = cam:WorldToViewportPoint(pos)
	if not on or v.Z <= 0 then return nil, false end
	return Vector2.new(v.X, v.Y), true
end

local function hitpartfromname(char, partName)
	if not char then return nil end
	local function fc(n) return char:FindFirstChild(n) end
	partName = partName or CFG.Part or "Head"
	if partName == "Head" or partName == "頭部" then
		return fc("Head") or fc("頭部")
	elseif partName == "HumanoidRootPart" then
		return fc("HumanoidRootPart")
	elseif partName == "UpperTorso" or partName == "Torso" then
		return fc("UpperTorso") or fc("Torso")
	elseif partName == "LowerTorso" then
		return fc("LowerTorso")
	elseif partName == "Closest" then
		local cam = workspace.CurrentCamera
		if not cam then return fc("Head") or fc("HumanoidRootPart") end
		local camPos, camLook = cam.CFrame.Position, cam.CFrame.LookVector
		local best, bestD = nil, math.huge
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") then
				local dir = part.Position - camPos
				if dir.Magnitude > 0.05 then
					local d = 1 - camLook:Dot(dir.Unit)
					if d < bestD then bestD, best = d, part end
				end
			end
		end
		return best or fc("Head") or fc("HumanoidRootPart")
	end
	return fc(partName) or fc("Head") or fc("HumanoidRootPart")
end

local function lunaraValidChar(char)
	if not char or not char.Parent then return false end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	if not char:FindFirstChild("HumanoidRootPart") then return false end
	local targetplayer = Players:GetPlayerFromCharacter(char)
	if not targetplayer then return false end
	if CFG.TeamCheck and sameTeam(targetplayer) then return false end
	if CFG.AntiKatana and katanausers and katanausers[targetplayer] then return false end
	return true
end

-- Lunara closestplayerinfov
local function getTarget()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local center = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
	local mouse = UIS:GetMouseLocation()
	if mouse then center = Vector2.new(mouse.X, mouse.Y) end
	local maxFov = CFG.FOV or 200
	local best, bestD = nil, maxFov
	local me = hrp()
	local maxDist = CFG.MaxDist or 300
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and plr.Character and lunaraValidChar(plr.Character) then
			local part = hitpartfromname(plr.Character, CFG.Part)
			if part then
				if me and (part.Position - me.Position).Magnitude > maxDist then
					-- skip far
				else
					if visible(part) then
						local sp, on = worldToScreen(part.Position)
						if on and sp then
							local d = (sp - center).Magnitude
							if d <= bestD then
								bestD, best = d, part
							end
						end
					end
				end
			end
		end
	end
	return best
end


local function ensureMods()
	pcall(function() UseItem = RS.Remotes.Replication.Fighter.UseItem end)
	pcall(function()
		local m = RS:FindFirstChild("Modules")
		if not m then return end
		if not Utility and m:FindFirstChild("Utility") then
			local ok, mod = pcall(require, m.Utility)
			if ok then Utility = mod end
		end
		if not EnumLibrary and m:FindFirstChild("EnumLibrary") then
			local ok, mod = pcall(require, m.EnumLibrary)
			if ok then EnumLibrary = mod end
		end
	end)
	pcall(function()
		if FighterCtrl then return end
		local ps = lp:FindFirstChild("PlayerScripts")
		local fc = ps and ps:FindFirstChild("Controllers") and ps.Controllers:FindFirstChild("FighterController")
		if fc then
			local ok, mod = pcall(require, fc)
			if ok then FighterCtrl = mod end
		end
	end)
end

local function getObjectId()
	local id
	pcall(function()
		ensureMods()
		local eq = FighterCtrl and FighterCtrl.LocalFighter and FighterCtrl.LocalFighter.EquippedItem
		if eq and eq.Get then id = eq:Get("ObjectID") end
	end)
	return id
end


-- 近戰無冷卻：普攻 + 突刺/特殊 全部清 CD
local meleeHooked = false
local function wipeCooldownInfo(info)
	if type(info) ~= "table" then return end
	for k, v in pairs(info) do
		local ks = tostring(k):lower()
		if type(v) == "number" then
			if ks:find("cool") or ks:find("cd") or ks:find("delay") or ks:find("thrust")
				or ks:find("lunge") or ks:find("stab") or ks:find("special") or ks:find("heavy")
				or ks:find("charge") or ks:find("ability") or ks:find("attack") or ks:find("swing")
				or ks:find("recover") or ks:find("interval") then
				info[k] = 0
			end
		elseif type(v) == "table" then
			wipeCooldownInfo(v)
		end
	end
	pcall(function()
		info.AttackCooldown = 0
		info.ShootCooldown = 0
		info.Cooldown = 0
		info.ThrustCooldown = 0
		info.LungeCooldown = 0
		info.SpecialCooldown = 0
		info.HeavyCooldown = 0
		info.AbilityCooldown = 0
		info.SecondaryCooldown = 0
		info.AltCooldown = 0
		info.ChargeCooldown = 0
	end)
end
local function wipeEquippedMeleeCD()
	if not CFG.NoMeleeCD then return end
	ensureMods()
	pcall(function()
		local eq = FighterCtrl and FighterCtrl.LocalFighter and FighterCtrl.LocalFighter.EquippedItem
		if not eq then return end
		if eq.Info then wipeCooldownInfo(eq.Info) end
		if eq.Get then
			local info = eq:Get("Info")
			if type(info) == "table" then wipeCooldownInfo(info) end
		end
	end)
end
local function ensureMeleeNoCD()
	if not CFG.NoMeleeCD then return end
	pcall(function()
		local itRoot = lp:FindFirstChild("PlayerScripts")
		itRoot = itRoot and itRoot:FindFirstChild("Modules")
		itRoot = itRoot and itRoot:FindFirstChild("ItemTypes")
		if not itRoot then return end
		for _, child in ipairs(itRoot:GetChildren()) do
			if child:IsA("ModuleScript") then
				pcall(function()
					local ok, M = pcall(require, child)
					if not ok or type(M) ~= "table" then return end
					for _, fnName in ipairs({ "StartShooting", "StopShooting", "Shoot", "Attack", "Thrust", "Lunge", "Special", "HeavyAttack", "UseAbility", "SecondaryFire" }) do
						local fn = M[fnName]
						if type(fn) == "function" and not M["_HEMA_NoCD_" .. fnName] then
							M[fnName] = function(self, ...)
								pcall(function()
									if self and self.Info then wipeCooldownInfo(self.Info) end
									wipeEquippedMeleeCD()
								end)
								return fn(self, ...)
							end
							M["_HEMA_NoCD_" .. fnName] = true
							print("[HEMA] 無冷卻 hook:", child.Name, fnName)
							meleeHooked = true
						end
					end
				end)
			end
		end
	end)
	wipeEquippedMeleeCD()
end
task.spawn(function()
	for _ = 1, 40 do
		task.wait(0.4)
		ensureMeleeNoCD()
		if meleeHooked then break end
	end
end)
-- 每幀清裝備近戰 CD（突刺常在 Info 另欄）
RunService.Heartbeat:Connect(function()
	if CFG and CFG.NoMeleeCD then
		wipeEquippedMeleeCD()
	end
end)


local lastFire = 0
local lastSilentPart, lastSilentAt = nil, 0
local STATS = { Damage = 0, Kills = 0, Hits = 0 }
local hpWatch = {}
-- Lunara firesilent
local function trySilent(part, forceRage)
	if not part then return end
	if not forceRage then
		if not CFG.SilentAuto and not (CFG.Silent and holdLMB()) then return end
	end
	-- 隊友二次檢查（Lunara valid）
	local model = part:FindFirstAncestorOfClass("Model")
	local tplr = model and Players:GetPlayerFromCharacter(model)
	if tplr and CFG.TeamCheck and sameTeam(tplr) then return end
	if CFG.AntiKatana and tplr and katanausers and katanausers[tplr] then return end

	local chance = CFG.HitChance or 100
	local rate = CFG.FireRate or 0.05
	if CFG.RapidFire then rate = math.min(rate, 0.02) end
	if forceRage or CFG.RageOn then
		chance = CFG.RageHitChance or 100
		rate = CFG.RageFireRate or 0.03
	elseif CFG.SoftMode then
		chance = math.min(chance, CFG.SoftHitChance or 100)
		rate = math.max(rate, CFG.SoftFireRate or 0.05)
	end
	if math.random(1, 100) > chance then return end
	local now = tick()
	if now - lastFire < rate then return end
	ensureMods()
	if not UseItem then return end
	local root = hrp()
	if not root then return end

	-- Lunara：ObjectID from LocalFighter.EquippedItem
	local objId = getObjectId and getObjectId() or nil
	if not objId then
		pcall(function()
			if FighterCtrl and FighterCtrl.LocalFighter and FighterCtrl.LocalFighter.EquippedItem then
				objId = FighterCtrl.LocalFighter.EquippedItem:Get("ObjectID")
			end
		end)
	end

	lastFire = now
	local shootPos = root.Position
	local targetPos = part.Position
	local action = "StartShooting"
	pcall(function()
		if EnumLibrary and EnumLibrary.ToEnum then
			action = EnumLibrary:ToEnum("StartShooting")
		end
	end)
	local data
	if Utility and Utility.EncodeCFrame then
		data = {
			[utf8.char(1)] = {
				[utf8.char(0)] = Utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
				[utf8.char(1)] = Utility:EncodeCFrame(CFrame.new(shootPos, targetPos)),
				[utf8.char(2)] = part,
				[utf8.char(3)] = Utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
			},
		}
	else
		local look = CFrame.new(shootPos, targetPos)
		data = {
			[utf8.char(1)] = {
				[utf8.char(0)] = look,
				[utf8.char(1)] = look,
				[utf8.char(2)] = part,
			},
		}
	end
	pcall(function()
		UseItem:FireServer(objId, action, data, nil)
	end)
	lastSilentPart = part
	lastSilentAt = now
end


-- Hitmarker + 傷害／擊殺計數
local hitmarkerGui, hitmarkerFrame, statsLabel
pcall(function()
	hitmarkerGui = Instance.new("ScreenGui")
	hitmarkerGui.Name = "HemaHitFX"
	hitmarkerGui.IgnoreGuiInset = true
	hitmarkerGui.ResetOnSpawn = false
	hitmarkerGui.DisplayOrder = 60
	pcall(function() hitmarkerGui.Parent = game:GetService("CoreGui") end)
	if not hitmarkerGui.Parent then
		hitmarkerGui.Parent = lp:WaitForChild("PlayerGui", 3)
	end
	hitmarkerFrame = Instance.new("Frame")
	hitmarkerFrame.Size = UDim2.fromOffset(18, 18)
	hitmarkerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	hitmarkerFrame.Position = UDim2.fromScale(0.5, 0.5)
	hitmarkerFrame.BackgroundTransparency = 1
	hitmarkerFrame.Visible = false
	hitmarkerFrame.Parent = hitmarkerGui
	for _, rot in ipairs({45, -45}) do
		local ln = Instance.new("Frame")
		ln.Size = UDim2.fromOffset(14, 2)
		ln.AnchorPoint = Vector2.new(0.5, 0.5)
		ln.Position = UDim2.fromScale(0.5, 0.5)
		ln.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ln.BorderSizePixel = 0
		ln.Rotation = rot
		ln.Parent = hitmarkerFrame
	end
	statsLabel = Instance.new("TextLabel")
	statsLabel.Size = UDim2.fromOffset(200, 54)
	statsLabel.Position = UDim2.fromOffset(12, 80)
	statsLabel.BackgroundTransparency = 0.35
	statsLabel.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
	statsLabel.TextColor3 = Color3.fromRGB(220, 210, 255)
	statsLabel.Font = Enum.Font.GothamBold
	statsLabel.TextSize = 13
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Text = "DMG 0 | KILLS 0 | HITS 0"
	statsLabel.Visible = false
	statsLabel.Parent = hitmarkerGui
	Instance.new("UICorner", statsLabel).CornerRadius = UDim.new(0, 6)
end)
local function flashHitmarker()
	if not CFG.Hitmarker or not hitmarkerFrame then return end
	hitmarkerFrame.Visible = true
	task.delay(0.12, function()
		if hitmarkerFrame then hitmarkerFrame.Visible = false end
	end)
end
local function refreshStatsLabel()
	if not statsLabel then return end
	statsLabel.Visible = CFG.ShowStats == true
	if CFG.ShowStats then
		statsLabel.Text = string.format("DMG %d | KILLS %d | HITS %d", STATS.Damage, STATS.Kills, STATS.Hits)
	end
end
-- 監聽敵人血量變化 → 計傷害／擊殺／Hitmarker
task.spawn(function()
	while true do
		task.wait(0.25)
		if CFG.ShowStats or CFG.Hitmarker or CFG.HitSound then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= lp and isEnemy(plr) then
					local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						local prev = hpWatch[plr]
						local hp = hum.Health
						if prev ~= nil and hp < prev - 0.5 then
							local dmg = math.floor(prev - hp + 0.5)
							local me = hrp()
							local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
							local near = me and root and (root.Position - me.Position).Magnitude < (CFG.MaxDist or 300)
							-- 放寬：Silent 剛開火 / 按住左鍵 / 僅開 HitSound 且在距離內
							local myHit = false
							if lastSilentAt and (tick() - lastSilentAt) < 0.8 then
								myHit = true
							elseif holdLMB() and (tick() - (lastFire or 0)) < 0.6 then
								myHit = true
							elseif CFG.HitSound and near and holdLMB() then
								myHit = true
							elseif CFG.HitSound and near and (CFG.Silent or CFG.SilentAuto or CFG.AimOn) then
								myHit = true
							end
							if myHit and dmg > 0 and dmg < 250 then
								STATS.Damage = STATS.Damage + dmg
								STATS.Hits = STATS.Hits + 1
								flashHitmarker()
								if CFG.HitSound then
									playHitSoundNow()
								end
							end
							if hp <= 0 and prev > 0 and myHit then
								STATS.Kills = STATS.Kills + 1
							end
							refreshStatsLabel()
						end
						hpWatch[plr] = hp
					end
				elseif plr ~= lp then
					local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
					if hum then hpWatch[plr] = hum.Health end
				end
			end
		end
		refreshStatsLabel()
	end
end)

local function aimAt(part)
	if not part then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local sp, on = cam:WorldToViewportPoint(part.Position)
	if not on or sp.Z <= 0 then return end
	local center = cam.ViewportSize * 0.5
	local s = math.clamp(tonumber(CFG.Smooth) or 0.25, 0.05, 0.7)
	local dx = (sp.X - center.X + (CFG.PixelX or 0)) * s
	local dy = (sp.Y - center.Y + (CFG.PixelY or 0)) * s
	if typeof(mousemoverel) == "function" then
		pcall(mousemoverel, dx, dy)
	else
		local goal = (part.Position - cam.CFrame.Position).Unit
		cam.CFrame = CFrame.new(cam.CFrame.Position, cam.CFrame.Position + cam.CFrame.LookVector:Lerp(goal, s))
	end
end


-- Lunara 風格：檢查視角（目標是否真的看得見）
local function isTargetVisible(part)
	if not part then return false end
	local cam = workspace.CurrentCamera
	if not cam then return false end
	local origin = cam.CFrame.Position
	local target = part.Position
	local dir = target - origin
	local dist = dir.Magnitude
	if dist < 1 then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {}
	local ch = lp.Character
	if ch then table.insert(filter, ch) end
	local tchar = part.Parent
	if tchar and tchar:IsA("Model") then table.insert(filter, tchar) end
	params.FilterDescendantsInstances = filter
	params.IgnoreWater = true
	local hit = workspace:Raycast(origin, dir.Unit * dist, params)
	if not hit then return true end
	-- 打到目標自己的部位也算可見
	local inst = hit.Instance
	if inst and tchar and inst:IsDescendantOf(tchar) then return true end
	return false
end

-- FOV 視覺（自瞄 + Silent，Lunara 風格圓環）
local fovGui, aimFovRing, silentFovRing
local function makeFovRing(parent, name, color)
	local ring = Instance.new("Frame")
	ring.Name = name
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.BackgroundTransparency = 1
	ring.Visible = false
	ring.Parent = parent
	Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BackgroundTransparency = 0.85
	fill.Visible = false
	fill.Parent = ring
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local st = Instance.new("UIStroke", ring)
	st.Name = "Stroke"
	st.Thickness = 2
	st.Color = color
	st.Transparency = 0.25
	return ring
end
pcall(function()
	fovGui = Instance.new("ScreenGui")
	fovGui.Name = "HemaFOV"
	fovGui.IgnoreGuiInset = true
	fovGui.ResetOnSpawn = false
	fovGui.DisplayOrder = 40
	fovGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	-- 優先 CoreGui / gethui，避免被遊戲 UI 縮放偏移
	local parent = nil
	pcall(function() if gethui then parent = gethui() end end)
	if not parent then pcall(function() parent = game:GetService("CoreGui") end) end
	if not parent then parent = lp:WaitForChild("PlayerGui", 5) end
	fovGui.Parent = parent
	aimFovRing = makeFovRing(fovGui, "AimFOV", Color3.fromRGB(255, 255, 255))
	silentFovRing = makeFovRing(fovGui, "SilentFOV", Color3.fromRGB(100, 220, 255))
end)
local function setFovRing(ring, show, radius)
	if not ring then return end
	ring.Visible = not not show
	if show then
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1920, 1080)
		-- FOV 數值當「像素半徑」較直覺；限制不超出螢幕
		local d = math.clamp((radius or 200) * 2, 40, math.min(vs.X, vs.Y) * 0.95)
		ring.AnchorPoint = Vector2.new(0.5, 0.5)
		ring.Position = UDim2.fromScale(0.5, 0.5)
		ring.Size = UDim2.fromOffset(d, d)
		local st = ring:FindFirstChild("Stroke")
		if st then st.Thickness = CFG.FOVThickness or 2 end
		local fill = ring:FindFirstChild("Fill")
		if fill then fill.Visible = CFG.FOVFill == true end
	end
end
local function setFov(showAim, showSilent)
	setFovRing(aimFovRing, showAim, CFG.FOV)
	setFovRing(silentFovRing, showSilent, CFG.SilentFOV or CFG.FOV)
end

-- ESP（Drawing，對齊 Lunara）
local HAS_DRAWING = typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
local ESPObjects = {}
local r15bones = {
	{"UpperTorso","Head"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local r6bones = {
	{"Torso","Head"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local function dnew(ty)
	if not HAS_DRAWING then return nil end
	local ok, o = pcall(function() return Drawing.new(ty) end)
	return ok and o or nil
end
local function drem(o)
	if not o then return end
	pcall(function() if o.Remove then o:Remove() elseif o.Destroy then o:Destroy() end end)
end
local function createEsp(player)
	if ESPObjects[player] then return ESPObjects[player] end
	local box = {
		sq = dnew("Square"), sqo = dnew("Square"),
		name = dnew("Text"), dist = dnew("Text"), tool = dnew("Text"),
		hpO = dnew("Square"), hpF = dnew("Square"),
		tracer = dnew("Line"),
		skel = {}, skelo = {},
		cham = nil,
	}
	for i = 1, 14 do box.skel[i] = dnew("Line") box.skelo[i] = dnew("Line") end
	if box.sq then box.sq.Filled = (CFG.EspFill == true) box.sq.Thickness = 1 box.sq.Color = Color3.fromRGB(255,255,255) box.sq.Visible = false end
	if box.sqo then box.sqo.Filled = false box.sqo.Thickness = 2 box.sqo.Color = Color3.fromRGB(0,0,0) box.sqo.Visible = false end
	for _, t in pairs({box.name, box.dist, box.tool}) do
		if t then t.Size = 14 t.Center = true t.Outline = true t.Color = Color3.fromRGB(255,255,255) t.Visible = false end
	end
	if box.hpO then box.hpO.Filled = true box.hpO.Color = Color3.fromRGB(0,0,0) box.hpO.Visible = false end
	if box.hpF then box.hpF.Filled = true box.hpF.Color = Color3.fromRGB(0,255,100) box.hpF.Visible = false end
	if box.tracer then box.tracer.Thickness = 1 box.tracer.Color = Color3.fromRGB(255,255,255) box.tracer.Visible = false end
	for i = 1, 14 do
		if box.skel[i] then box.skel[i].Thickness = 1 box.skel[i].Color = Color3.fromRGB(255,255,255) box.skel[i].Visible = false end
		if box.skelo[i] then box.skelo[i].Thickness = 2 box.skelo[i].Color = Color3.fromRGB(0,0,0) box.skelo[i].Visible = false end
	end
	ESPObjects[player] = box
	return box
end
local function hideEsp(player)
	local box = ESPObjects[player]
	if not box then return end
	local function h(o) if o and o.Visible ~= nil then o.Visible = false end end
	h(box.sq) h(box.sqo) h(box.name) h(box.dist) h(box.tool) h(box.hpO) h(box.hpF) h(box.tracer)
	for i = 1, 14 do h(box.skel[i]) h(box.skelo[i]) end
	if box.cham then pcall(function() box.cham.Enabled = false end) end
end
local function removeEsp(player)
	local box = ESPObjects[player]
	if not box then return end
	hideEsp(player)
	drem(box.sq) drem(box.sqo) drem(box.name) drem(box.dist) drem(box.tool) drem(box.hpO) drem(box.hpF) drem(box.tracer)
	for i = 1, 14 do drem(box.skel[i]) drem(box.skelo[i]) end
	if box.cham then pcall(function() box.cham:Destroy() end) end
	ESPObjects[player] = nil
end
local function clearEsp()
	for plr in pairs(ESPObjects) do removeEsp(plr) end
end
Players.PlayerRemoving:Connect(removeEsp)
local function w2s(pos)
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local v, on = cam:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), on, v.Z
end
local function updateOneEsp(player)
	local any = CFG.EspName or CFG.EspDist or CFG.EspChams or CFG.EspGlow or CFG.EspHp or CFG.EspBox or CFG.EspFill or CFG.EspSkel or CFG.EspTracer or CFG.EspTools
	if not any then hideEsp(player) return end
	if player == lp then return end
	if CFG.EspTeamCheck and sameTeam(player) then hideEsp(player) return end
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Head"))
	local head = ch and ch:FindFirstChild("Head") or root
	if not hum or hum.Health <= 0 or not root then hideEsp(player) return end
	local me = hrp()
	if me and (root.Position - me.Position).Magnitude > (CFG.EspMaxDist or 800) then hideEsp(player) return end
	local box = createEsp(player)
	local top2, on1, z1 = w2s(head.Position + Vector3.new(0, 1.2, 0))
	local bot2, on2, z2 = w2s(root.Position - Vector3.new(0, 2.5, 0))
	if not top2 or not bot2 or (z1 and z1 < 0 and z2 and z2 < 0) then hideEsp(player) return end
	local h = math.abs(bot2.Y - top2.Y)
	local w = h * 0.55
	local cx = (top2.X + bot2.X) * 0.5
	local x, y = cx - w * 0.5, math.min(top2.Y, bot2.Y)
	if CFG.EspBox and HAS_DRAWING and box.sq then
		box.sqo.Size = Vector2.new(w + 2, h + 2)
		box.sqo.Position = Vector2.new(x - 1, y - 1)
		box.sqo.Visible = true
		box.sq.Size = Vector2.new(w, h)
		box.sq.Position = Vector2.new(x, y)
		box.sq.Visible = true
	else
		if box.sq then box.sq.Visible = false end
		if box.sqo then box.sqo.Visible = false end
	end
	if CFG.EspHp and HAS_DRAWING and box.hpF then
		local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		local bh = h * pct
		box.hpO.Size = Vector2.new(4, h + 2)
		box.hpO.Position = Vector2.new(x - 7, y - 1)
		box.hpO.Visible = true
		box.hpF.Size = Vector2.new(2, bh)
		box.hpF.Position = Vector2.new(x - 6, y + (h - bh))
		box.hpF.Color = Color3.fromRGB(255 * (1 - pct), 255 * pct, 40)
		box.hpF.Visible = true
	else
		if box.hpO then box.hpO.Visible = false end
		if box.hpF then box.hpF.Visible = false end
	end
	local dist = me and (root.Position - me.Position).Magnitude or 0
	if CFG.EspName and box.name then
		box.name.Text = player.DisplayName ~= "" and player.DisplayName or player.Name
		box.name.Position = Vector2.new(cx, y - 16)
		box.name.Visible = true
	elseif box.name then box.name.Visible = false end
	if CFG.EspDist and box.dist then
		box.dist.Text = string.format("[%dm]", math.floor(dist))
		box.dist.Position = Vector2.new(cx, y + h + 2)
		box.dist.Visible = true
	elseif box.dist then box.dist.Visible = false end
	if CFG.EspTools and box.tool then
		local tool = ch:FindFirstChildOfClass("Tool")
		box.tool.Text = tool and tool.Name or ""
		box.tool.Position = Vector2.new(cx, y + h + 16)
		box.tool.Visible = tool ~= nil
	elseif box.tool then box.tool.Visible = false end
	if CFG.EspTracer and HAS_DRAWING and box.tracer then
		local cam = workspace.CurrentCamera
		local vs = cam.ViewportSize
		box.tracer.From = Vector2.new(vs.X * 0.5, vs.Y)
		box.tracer.To = Vector2.new(cx, y + h)
		box.tracer.Visible = true
	elseif box.tracer then box.tracer.Visible = false end
	if CFG.EspSkel and HAS_DRAWING then
		local bones = ch:FindFirstChild("UpperTorso") and r15bones or r6bones
		for i, pair in ipairs(bones) do
			local a, b = ch:FindFirstChild(pair[1]), ch:FindFirstChild(pair[2])
			local ln, ol = box.skel[i], box.skelo[i]
			if a and b and ln then
				local p1, o1 = w2s(a.Position)
				local p2, o2 = w2s(b.Position)
				if o1 and o2 and p1 and p2 then
					if ol then ol.From = p1 ol.To = p2 ol.Visible = true end
					ln.From = p1 ln.To = p2 ln.Visible = true
				else
					if ol then ol.Visible = false end
					ln.Visible = false
				end
			elseif ln then
				ln.Visible = false
				if ol then ol.Visible = false end
			end
		end
	else
		for i = 1, 14 do
			if box.skel[i] then box.skel[i].Visible = false end
			if box.skelo[i] then box.skelo[i].Visible = false end
		end
	end
	if CFG.EspChams or CFG.EspGlow then
		if not box.cham or not box.cham.Parent then
			pcall(function()
				local h = Instance.new("Highlight")
				h.Name = "HemaCham"
				h.FillColor = Color3.fromRGB(255, 80, 120)
				h.OutlineColor = Color3.fromRGB(255, 255, 255)
				h.FillTransparency = 0.45
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Adornee = ch
				h.Parent = ch
				box.cham = h
			end)
		else
			box.cham.Adornee = ch
			box.cham.Enabled = true
		end
	elseif box.cham then
		pcall(function() box.cham.Enabled = false end)
	end
end
local function updateEsp()
	local any = CFG.EspName or CFG.EspDist or CFG.EspChams or CFG.EspGlow or CFG.EspHp or CFG.EspBox or CFG.EspFill or CFG.EspSkel or CFG.EspTracer or CFG.EspTools
	if not any then
		for plr in pairs(ESPObjects) do hideEsp(plr) end
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp then pcall(updateOneEsp, plr) end
	end
end

-- Fly / body / danger（CFrame + 速度，不依賴過時 BodyVelocity）
local bv, bg, flyConn
local flyGui, flyBtnUp, flyBtnDown
local flyTouchUp, flyTouchDown = false, false
local function destroyFlyGui()
	flyTouchUp, flyTouchDown = false, false
	if flyGui then pcall(function() flyGui:Destroy() end) flyGui = nil end
	flyBtnUp, flyBtnDown = nil, nil
end
local function stopFly()
	if flyConn then pcall(function() flyConn:Disconnect() end) flyConn = nil end
	if bv then pcall(function() bv:Destroy() end) bv = nil end
	if bg then pcall(function() bg:Destroy() end) bg = nil end
	pcall(destroyFlyGui)
	local ch = lp.Character
	local h = ch and ch:FindFirstChildOfClass("Humanoid")
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if h then
		pcall(function()
			h.PlatformStand = false
			h:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
	end
	if root then
		pcall(function()
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
	end
end

-- 手機飛行按鈕
local function ensureFlyGui()
	local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
	-- 有觸控就顯示（平板/模擬器也可用）
	if not UIS.TouchEnabled then
		destroyFlyGui()
		return
	end
	if flyGui and flyGui.Parent then return end
	pcall(function()
		local parent = gethui and gethui() or game:GetService("CoreGui")
		flyGui = Instance.new("ScreenGui")
		flyGui.Name = "HEMA_FlyPad"
		flyGui.ResetOnSpawn = false
		flyGui.IgnoreGuiInset = true
		flyGui.DisplayOrder = 80
		flyGui.Parent = parent
		local function mk(text, yScale)
			local b = Instance.new("TextButton")
			b.Size = UDim2.fromOffset(64, 64)
			b.Position = UDim2.new(1, -78, yScale, 0)
			b.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			b.BackgroundTransparency = 0.25
			b.Text = text
			b.TextColor3 = Color3.new(1, 1, 1)
			b.TextSize = 22
			b.Font = Enum.Font.GothamBold
			b.Parent = flyGui
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 12)
			c.Parent = b
			return b
		end
		flyBtnUp = mk("↑", 0.55)
		flyBtnDown = mk("↓", 0.55)
		flyBtnDown.Position = UDim2.new(1, -78, 0.55, 72)
		flyBtnUp.MouseButton1Down:Connect(function() flyTouchUp = true end)
		flyBtnUp.MouseButton1Up:Connect(function() flyTouchUp = false end)
		flyBtnUp.MouseLeave:Connect(function() flyTouchUp = false end)
		flyBtnDown.MouseButton1Down:Connect(function() flyTouchDown = true end)
		flyBtnDown.MouseButton1Up:Connect(function() flyTouchDown = false end)
		flyBtnDown.MouseLeave:Connect(function() flyTouchDown = false end)
		-- 觸控
		flyBtnUp.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then flyTouchUp = true end end)
		flyBtnUp.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then flyTouchUp = false end end)
		flyBtnDown.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then flyTouchDown = true end end)
		flyBtnDown.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch then flyTouchDown = false end end)
	end)
end

local function startFly()
	if flyConn then return end
	ensureFlyGui()
	flyConn = RunService.Heartbeat:Connect(function(dt)
		if not CFG or not CFG.Fly then
			stopFly()
			return
		end
		ensureFlyGui()
		local cam = workspace.CurrentCamera
		local ch = lp.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		local h = ch and ch:FindFirstChildOfClass("Humanoid")
		if not cam or not root or not h then return end
		pcall(function()
			h.PlatformStand = true
			h:ChangeState(Enum.HumanoidStateType.Physics)
		end)
		local spd = tonumber(CFG.FlySpeed) or 50
		dt = math.clamp(dt or 0.016, 0, 0.05)

		-- 水平：鍵盤 WASD + 手機搖桿 MoveDirection（通用）
		local flat = Vector3.zero
		local look = cam.CFrame.LookVector
		local right = cam.CFrame.RightVector
		local lookFlat = Vector3.new(look.X, 0, look.Z)
		local rightFlat = Vector3.new(right.X, 0, right.Z)
		if lookFlat.Magnitude > 0.05 then lookFlat = lookFlat.Unit end
		if rightFlat.Magnitude > 0.05 then rightFlat = rightFlat.Unit end

		if UIS:IsKeyDown(Enum.KeyCode.W) then flat = flat + lookFlat end
		if UIS:IsKeyDown(Enum.KeyCode.S) then flat = flat - lookFlat end
		if UIS:IsKeyDown(Enum.KeyCode.A) then flat = flat - rightFlat end
		if UIS:IsKeyDown(Enum.KeyCode.D) then flat = flat + rightFlat end

		-- 手機虛擬搖桿
		pcall(function()
			local md = h.MoveDirection
			if md and md.Magnitude > 0.05 then
				-- MoveDirection 是世界座標水平
				flat = flat + Vector3.new(md.X, 0, md.Z)
			end
		end)

		-- 垂直：鍵盤 + 手機按鈕 + 跳躍鍵
		local up = 0
		if UIS:IsKeyDown(Enum.KeyCode.Space) or flyTouchUp then up = up + 1 end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) or flyTouchDown then
			up = up - 1
		end
		-- 手機跳躍鍵當上升
		pcall(function()
			if h.Jump or UIS:IsKeyDown(Enum.KeyCode.ButtonA) then
				up = up + 1
			end
		end)

		local move = Vector3.new(flat.X, 0, flat.Z)
		if move.Magnitude > 1 then move = move.Unit end
		local vel = Vector3.new(move.X * spd, up * spd, move.Z * spd)

		pcall(function()
			-- 強制速度（含 Y=0 時鎖高，避免慢慢掉）
			root.AssemblyLinearVelocity = vel
			root.AssemblyAngularVelocity = Vector3.zero
			local delta = Vector3.new(move.X * spd * dt, up * spd * dt, move.Z * spd * dt)
			root.CFrame = CFrame.new(root.Position + delta) * (root.CFrame - root.CFrame.Position)
			-- 面向鏡頭水平
			if lookFlat.Magnitude > 0.05 then
				root.CFrame = CFrame.new(root.Position, root.Position + lookFlat)
			end
		end)
	end)
	print("[HEMA] Fly ON (PC+Mobile)")
end

-- 身體分離：四肢 C0 外推 + 可轉圈，不關 Root/Waist/Neck
local bodyMotors, bodySplitOn = {}, false
local bodySplitConn = nil
local bodyJitterOn = false
local bodyJitterConn = nil
local KEEP_JOINT = {
	Root = true, RootJoint = true, Waist = true, Neck = true,
	["Root Hip"] = true, HumanoidRootPart = true,
}

local function stopBodySplit()
	bodySplitOn = false
	if bodySplitConn then
		pcall(function() bodySplitConn:Disconnect() end)
		bodySplitConn = nil
	end
	for m, data in pairs(bodyMotors) do
		pcall(function()
			if not m or not m.Parent then return end
			if data.C0 then m.C0 = data.C0 end
			if data.C1 then m.C1 = data.C1 end
			if data.Enabled ~= nil and (m:IsA("Motor6D") or m:IsA("Weld")) then
				m.Enabled = data.Enabled
			end
		end)
	end
	bodyMotors = {}
	pcall(function()
		local ch = lp.Character
		local root = ch and ch:FindFirstChild("HumanoidRootPart")
		if root then
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end)
end

local function startBodySplit()
	local ch = lp.Character
	if not ch then return end
	stopBodySplit()
	bodySplitOn = true
	bodyMotors = {}
	local dist = tonumber(CFG.BodySplitDist) or 4
	local offsets = {
		["Left Shoulder"] = CFrame.new(-dist * 0.35, 0, 0),
		["Right Shoulder"] = CFrame.new(dist * 0.35, 0, 0),
		["Left Hip"] = CFrame.new(-dist * 0.2, -dist * 0.15, 0),
		["Right Hip"] = CFrame.new(dist * 0.2, -dist * 0.15, 0),
		LeftShoulder = CFrame.new(-dist * 0.35, 0, 0),
		RightShoulder = CFrame.new(dist * 0.35, 0, 0),
		LeftHip = CFrame.new(-dist * 0.2, -dist * 0.15, 0),
		RightHip = CFrame.new(dist * 0.2, -dist * 0.15, 0),
		LeftArm = CFrame.new(-dist * 0.3, 0, 0),
		RightArm = CFrame.new(dist * 0.3, 0, 0),
		LeftLeg = CFrame.new(-dist * 0.15, -dist * 0.2, 0),
		RightLeg = CFrame.new(dist * 0.15, -dist * 0.2, 0),
	}
	for _, m in ipairs(ch:GetDescendants()) do
		if m:IsA("Motor6D") then
			local n = m.Name
			if not KEEP_JOINT[n] then
				local data = {
					C0 = m.C0,
					C1 = m.C1,
					Enabled = m.Enabled,
					BaseOff = offsets[n] or CFrame.new(
						(math.random() - 0.5) * dist * 0.15,
						(math.random() - 0.5) * dist * 0.1,
						(math.random() - 0.5) * dist * 0.1
					),
					SpinDir = (math.random() < 0.5) and 1 or -1,
					SpinAxis = math.random(1, 3),
				}
				bodyMotors[m] = data
				pcall(function()
					m.C0 = data.C0 * data.BaseOff
				end)
			end
		end
	end
	pcall(function()
		local root = ch:FindFirstChild("HumanoidRootPart")
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		if hum then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)

	-- 分離後身體轉圈（轉四肢 C0，可選整身 Y 軸慢轉）
	local t0 = os.clock()
	bodySplitConn = RunService.Heartbeat:Connect(function()
		if not bodySplitOn or not CFG.BodySplit then return end
		if menuOpenWanted then return end
		local spd = tonumber(CFG.BodySplitSpinSpeed) or 8
		if CFG.BodySplitSpin == false then return end
		local ang = (os.clock() - t0) * spd
		for m, data in pairs(bodyMotors) do
			pcall(function()
				if not m or not m.Parent or not data.C0 then return end
				local rot
				local a = ang * (data.SpinDir or 1)
				if data.SpinAxis == 1 then
					rot = CFrame.Angles(a, 0, 0)
				elseif data.SpinAxis == 2 then
					rot = CFrame.Angles(0, a, 0)
				else
					rot = CFrame.Angles(0, 0, a)
				end
				m.C0 = data.C0 * data.BaseOff * rot
			end)
		end
		-- 輕微整身水平轉（不猛轉，避免飛出地圖）
		pcall(function()
			local ch2 = lp.Character
			local root = ch2 and ch2:FindFirstChild("HumanoidRootPart")
			if root then
				root.AssemblyAngularVelocity = Vector3.new(0, spd * 0.35, 0)
			end
		end)
	end)
	print("[HEMA] BodySplit ON + spin")
end

local function stopBodyJitter()
	bodyJitterOn = false
	if bodyJitterConn then
		pcall(function() bodyJitterConn:Disconnect() end)
		bodyJitterConn = nil
	end
end

local function startBodyJitter()
	if bodyJitterOn then return end
	bodyJitterOn = true
	if bodyJitterConn then
		pcall(function() bodyJitterConn:Disconnect() end)
	end
	local t0 = os.clock()
	bodyJitterConn = RunService.Heartbeat:Connect(function()
		if not CFG.BodyJitter or menuOpenWanted then return end
		local ch = lp.Character
		if not ch then return end
		local root = ch:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local amt = tonumber(CFG.BodyJitterAmt) or 0.12
		local spd = tonumber(CFG.BodyJitterSpeed) or 18
		local tm = os.clock() - t0
		-- 用微小位移抖動，不瞬移、不進虛空
		local ox = math.sin(tm * spd) * amt
		local oy = math.cos(tm * spd * 1.3) * amt * 0.5
		local oz = math.sin(tm * spd * 0.7) * amt
		pcall(function()
			-- 只抖角速度／輕推，避免 CFrame 傳送殺腳本
			root.AssemblyAngularVelocity = Vector3.new(ox * 8, oy * 12, oz * 8)
		end)
		-- 四肢 C0 微抖（若沒在分離）
		if not bodySplitOn then
			for _, m in ipairs(ch:GetDescendants()) do
				if m:IsA("Motor6D") and not KEEP_JOINT[m.Name] then
					pcall(function()
						if not m:GetAttribute("HemaBaseC0") then
							m:SetAttribute("HemaBaseC0", 1)
							m:SetAttribute("HemaC0X", m.C0.X)
							-- store via table
						end
					end)
				end
			end
		end
	end)
	print("[HEMA] BodyJitter ON")
end

local dangerOrigin, dangerActive = nil, false
local function dangerReturn()
	if dangerOrigin and hrp() then
		pcall(function() hrp().CFrame = dangerOrigin end)
	end
	dangerActive = false
	dangerOrigin = nil
end

-- Loadout：用戶確認可用版（fireFullLoadout + 5 秒補投）
local voteThread = nil
local voteEnabled = false

local function getLoadoutList()
	local list = {}
	for _, w in ipairs({ CFG.VotePrimary, CFG.VoteSecondary, CFG.VoteMelee, CFG.VoteUtility }) do
		if type(w) == "string" and w ~= "" then
			table.insert(list, w)
		end
	end
	return list
end

local function getVoteList()
	return getLoadoutList()
end

local function getRemotes()
	local remotes = RS:FindFirstChild("Remotes")
	if not remotes then return nil, nil, nil end
	local duels = remotes:FindFirstChild("Duels")
	local repl = remotes:FindFirstChild("Replication")
	local fighter = repl and repl:FindFirstChild("Fighter")
	local vote = duels and duels:FindFirstChild("Vote")
	local ahead = duels and duels:FindFirstChild("PickWeaponsAheadOfTime")
	local pick = fighter and fighter:FindFirstChild("PickWeapons")
	return vote, ahead, pick
end

-- 只送「最可能」的幾種，避免狂 Fire 卡死
local function fireFullLoadout(list)
	if not list or #list == 0 then return end
	local vote, ahead, pick = getRemotes()
	local p, s, m, u = list[1], list[2], list[3], list[4]
	local pack = { p, s, m, u }

	-- 1) 整包（提前選槍）
	if ahead then
		pcall(function() ahead:FireServer(pack) end)
		pcall(function() ahead:FireServer(p, s, m, u) end)
	end
	-- 2) 對戰選槍
	if pick then
		pcall(function() pick:FireServer(pack) end)
		pcall(function() pick:FireServer(p, s, m, u) end)
	end
	-- 3) Vote 逐把（間隔，避免同一幀打爆）
	if vote then
		for _, w in ipairs(list) do
			pcall(function() vote:FireServer(w) end)
			task.wait(0.15)
		end
	end
end

local function stopVoteThread()
	voteThread = nil
	voteEnabled = false
end

local function startVoteThread()
	stopVoteThread()
	voteEnabled = true
	voteThread = task.spawn(function()
		local vote, ahead, pick = getRemotes()
		print("[HEMA] Loadout ON")
		print("  Vote=", vote and "OK" or "nil", "Ahead=", ahead and "OK" or "nil", "Pick=", pick and "OK" or "nil")
		local list = getLoadoutList()
		print("[HEMA] weapons:", table.concat(list, " | "))
		-- 開啟時只送一次
		pcall(function() fireFullLoadout(list) end)
		-- 之後很慢地再補（選槍階段通常要等 UI 出現）
		while voteEnabled and voteThread do
			task.wait(5)
			if not voteEnabled or not voteThread then break end
			list = getLoadoutList()
			pcall(function() fireFullLoadout(list) end)
		end
		voteThread = nil
		print("[HEMA] Loadout OFF")
	end)
end

local function fireVoteOnce()
	local list = getLoadoutList()
	pcall(function() fireFullLoadout(list) end)
	print("[HEMA] Loadout once x", #list)
end

local hpCache = {}
local _lit

local cached, lastT, lastEsp, lastSlow = nil, 0, 0, 0
local rageTick, rageOrigCF

local crossLines

-- ========== ANTI_VOID_LOOP：反虛空 / 出界檢測（加強） ==========
local lastSafeCF, lastSafeT = nil, 0
local lastVoidPull = 0
local function isVoidishPart(inst)
	if not inst then return false end
	local n = string.lower(tostring(inst.Name or ""))
	if n:find("void") or n:find("kill") or n:find("outofbounds") or n:find("out.of.bounds")
		or n:find("death") or n:find("pit") or n:find("fallkill") then
		return true
	end
	local p = inst.Parent
	if p then
		local pn = string.lower(tostring(p.Name or ""))
		if pn:find("void") or pn:find("kill") then return true end
	end
	return false
end
task.spawn(function()
	while true do
		task.wait(0.1)
		if getgenv().HEMA_KILL then break end
		local r = hrp()
		local h = hum()
		if not r or not h or h.Health <= 0 then
			-- skip
		else
			local pos = r.Position
			local pr = RaycastParams.new()
			pr.FilterType = Enum.RaycastFilterType.Exclude
			if lp.Character then pr.FilterDescendantsInstances = { lp.Character } end

			-- 更新安全點（有地、非墜落、高度合理）
			local grounded = false
			local underBad = false
			pcall(function()
				local st = h:GetState()
				if st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.Landed
					or st == Enum.HumanoidStateType.RunningNoPhysics or st == Enum.HumanoidStateType.Climbing
					or st == Enum.HumanoidStateType.Swimming then
					grounded = true
				end
				local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), pr)
				if hit then
					grounded = true
					if isVoidishPart(hit.Instance) then underBad = true end
				end
			end)
			if grounded and not underBad and pos.Y > (CFG.AntiVoidY or -50) + 8 then
				lastSafeCF = r.CFrame
				lastSafeT = tick()
			end

			if CFG.AntiVoid and not CFG.Fly then
				local out, reason = false, ""
				if pos.Y < (CFG.AntiVoidY or -50) then
					out, reason = true, "Y過低"
				elseif lastSafeCF then
					local dy = lastSafeCF.Position.Y - pos.Y
					if dy > (CFG.AntiVoidMaxFall or 90) then
						out, reason = true, "墜落過深"
					end
					local dxz = Vector3.new(pos.X - lastSafeCF.Position.X, 0, pos.Z - lastSafeCF.Position.Z).Magnitude
					if dxz > (CFG.AntiVoidMaxDist or 280) then
						out, reason = true, "離安全區過遠"
					end
				end
				-- 腳下是 void/kill 零件
				if CFG.AntiVoidCheckMap and not out then
					pcall(function()
						local hit = workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, -6, 0), pr)
						if hit and isVoidishPart(hit.Instance) then
							out, reason = true, "腳下危險區"
						end
						-- 四周無碰撞且高度暴跌傾向
						if not out and h:GetState() == Enum.HumanoidStateType.Freefall then
							local hit2 = workspace:Raycast(pos, Vector3.new(0, -200, 0), pr)
							if not hit2 and pos.Y < (lastSafeCF and lastSafeCF.Position.Y or pos.Y) - 40 then
								out, reason = true, "下方無地(疑似虛空)"
							end
						end
					end)
				end
				if out and lastSafeCF and (tick() - lastVoidPull) > 0.45 then
					lastVoidPull = tick()
					pcall(function()
						r.AssemblyLinearVelocity = Vector3.zero
						r.AssemblyAngularVelocity = Vector3.zero
						r.CFrame = lastSafeCF + Vector3.new(0, 3, 0)
					end)
					print("[HEMA] 反虛空拉回:", reason)
				end
			end
		end
	end
end)


RunService.RenderStepped:Connect(function()
	-- 選單開啟時：只更新游標，跳過戰鬥/ESP，避免卡頓
	if menuOpenWanted then
		return
	end
	local need = CFG.AimOn or CFG.Silent or CFG.SilentAuto or CFG.Triggerbot
	local anyEsp = CFG.EspName or CFG.EspDist or CFG.EspChams or CFG.EspGlow or CFG.EspHp or CFG.EspBox or CFG.EspFill or CFG.EspSkel or CFG.EspTracer or CFG.EspTools
	-- 防卡：Lighting/HitSound 走慢迴圈，不佔每幀
	local anyVisual = CFG.Fullbright or CFG.NoFog or CFG.AmbientBoost or CFG.BloomOn or CFG.CCOn
		or CFG.SunRays or CFG.Atmosphere or CFG.DepthOfField or CFG.Rain or CFG.SkyOn
		or CFG.NoFlash or CFG.NoSmoke or CFG.HitSound or CFG.AspectRatio
		or CFG.GunChams or CFG.ArmChams or CFG.HideArms or CFG.Crosshair
		or CFG.ShowFOV or CFG.ShowSilentFOV or CFG.ShowStats or CFG.Hitmarker
	local busy = need or anyEsp or anyVisual or CFG.Fly or CFG.SpeedOn or CFG.RageOn or CFG.BodySplit or CFG.BodyJitter
	if not busy then
		return
	end

	local now = tick()
	local cam = workspace.CurrentCamera
	setFov(CFG.ShowFOV and CFG.AimOn, CFG.ShowSilentFOV and (CFG.Silent or CFG.SilentAuto))

	-- 雨位置每幀跟隨（開雨時）
	if CFG.Rain and cam then
		pcall(function()
			local rain = cam:FindFirstChild("HemaRainLocal")
			if rain then rain.CFrame = cam.CFrame end
		end)
	end

	-- Crosshair
	if CFG.Crosshair then
		local cam = workspace.CurrentCamera
		if cam then
			if not crossLines then
				crossLines = {}
				if HAS_DRAWING then
					for i = 1, 4 do
						local ln = Drawing.new("Line")
						ln.Thickness = 1
						ln.Color = Color3.fromRGB(0, 255, 140)
						ln.Visible = true
						crossLines[i] = ln
					end
				end
			end
			local vs = cam.ViewportSize
			local cx, cy = vs.X * 0.5, vs.Y * 0.5
			local s, g = CFG.CrosshairSize or 8, CFG.CrosshairGap or 4
			if crossLines and crossLines[1] then
				crossLines[1].From = Vector2.new(cx - g - s, cy) crossLines[1].To = Vector2.new(cx - g, cy) crossLines[1].Visible = true
				crossLines[2].From = Vector2.new(cx + g, cy) crossLines[2].To = Vector2.new(cx + g + s, cy) crossLines[2].Visible = true
				crossLines[3].From = Vector2.new(cx, cy - g - s) crossLines[3].To = Vector2.new(cx, cy - g) crossLines[3].Visible = true
				crossLines[4].From = Vector2.new(cx, cy + g) crossLines[4].To = Vector2.new(cx, cy + g + s) crossLines[4].Visible = true
			end
		end
	elseif crossLines then
		for _, ln in pairs(crossLines) do pcall(function() ln.Visible = false end) end
	end


	-- Lunara：戰鬥每幀取目標（不節流），更跟手
	if need then
		cached = getTarget()
		lastT = now
	else
		cached = nil
	end
	local t = cached
	if CFG.AimOn and holdRMB() and t then aimAt(t) end
	if (CFG.Silent or CFG.SilentAuto) and t then trySilent(t) end
	if CFG.Triggerbot and t and holdLMB() then trySilent(t) end

	if anyEsp and now - lastEsp > 0.75 then
		lastEsp = now
		pcall(updateEsp)
	end

	if CFG.SpeedOn then
		local h = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
		if h then pcall(function() h.WalkSpeed = CFG.SpeedVal end) end
	end
	if CFG.Fly then
		if not flyConn then startFly() end
	elseif flyConn or bv or bg then
		stopFly()
	end

	if CFG.BodySplit and not bodySplitOn then startBodySplit()
	elseif not CFG.BodySplit and bodySplitOn then stopBodySplit() end
	if CFG.BodyJitter and not bodyJitterOn then startBodyJitter()
	elseif not CFG.BodyJitter and bodyJitterOn then stopBodyJitter() end

	if CFG.RageOn and now - lastSlow > 0.12 then
		lastSlow = now
		pcall(rageTick)
	elseif not CFG.RageOn then
		pcall(function()
			if rageOrigCF and CFG.RageReturn then
				local r = hrp()
				if r then r.CFrame = rageOrigCF end
				rageOrigCF = nil
			end
		end)
	end
end)

-- Slow systems
task.spawn(function()
	while true do
		task.wait(1.25)
		-- Loadout 改由 startVoteThread 專用迴圈
		if CFG.AutoQueue then
			pcall(function()
				local join = RS.Remotes.Matchmaking.JoinQueue
				if CFG.RankedQueue then join:InvokeServer(CFG.QueueMode or "1v1", true)
				else join:InvokeServer(CFG.QueueMode or "1v1") end
			end)
		end
		if CFG.AutoSwap then
			pcall(function()
				local ch = lp.Character
				local tool = ch and ch:FindFirstChildOfClass("Tool")
				if tool then
					local ammo = tool:GetAttribute("Ammo") or tool:GetAttribute("ammo")
					if ammo == 0 then
						UIS.InputBegan:Fire() -- no-op fallback
						pcall(function()
							local vim = game:GetService("VirtualInputManager")
							vim:SendKeyEvent(true, Enum.KeyCode.Two, false, game)
							vim:SendKeyEvent(false, Enum.KeyCode.Two, false, game)
						end)
					end
				end
			end)
		end
		if CFG.AspectRatio then
			pcall(function()
				local cam = workspace.CurrentCamera
				if cam then
					local av = math.max(CFG.AspectVal or 1.6, 0.8)
					cam.FieldOfView = math.clamp(70 * (1.6 / av), 40, 120)
				end
			end)
		end
		-- Lighting 完整
		pcall(function()
			if not _lit then
				_lit = {
					A = Lighting.Ambient, O = Lighting.OutdoorAmbient, B = Lighting.Brightness,
					F = Lighting.FogEnd, FS = Lighting.FogStart, CT = Lighting.ClockTime,
				}
			end
			
			if CFG.NoShadows then
				pcall(function() Lighting.GlobalShadows = false end)
			end
			if CFG.BrightWorld or CFG.Fullbright then
				pcall(function()
					Lighting.Brightness = math.max(Lighting.Brightness, 2)
					Lighting.Ambient = Color3.fromRGB(180, 180, 180)
					Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
				end)
			end

			if CFG.Fullbright then
				Lighting.Ambient = Color3.new(1, 1, 1)
				Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
				Lighting.Brightness = CFG.LightingBright or 2
				Lighting.ClockTime = CFG.ClockTime or 14
			elseif CFG.AmbientBoost then
				Lighting.Ambient = Color3.fromRGB(200, 200, 200)
				Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
			end
			if CFG.NoFog then
				Lighting.FogStart = CFG.FogStart or 0
				Lighting.FogEnd = CFG.FogEnd or 1e6
			end
			-- Bloom
			local bloom = Lighting:FindFirstChild("HemaBloom")
			if CFG.BloomOn then
				if not bloom then
					bloom = Instance.new("BloomEffect")
					bloom.Name = "HemaBloom"
					bloom.Intensity = 0.4
					bloom.Size = 24
					bloom.Threshold = 0.9
					bloom.Parent = Lighting
				end
				bloom.Enabled = true
			elseif bloom then
				bloom.Enabled = false
			end
			-- ColorCorrection
			local cc = Lighting:FindFirstChild("HemaCC")
			if CFG.CCOn then
				if not cc then
					cc = Instance.new("ColorCorrectionEffect")
					cc.Name = "HemaCC"
					cc.Parent = Lighting
				end
				cc.Enabled = true
				cc.Saturation = CFG.CCSat or 0.2
				cc.Brightness = CFG.CCBright or 0.05
			elseif cc then
				cc.Enabled = false
			end
			-- SunRays
			local sr = Lighting:FindFirstChild("HemaSunRays")
			if CFG.SunRays then
				if not sr then
					sr = Instance.new("SunRaysEffect")
					sr.Name = "HemaSunRays"
					sr.Intensity = 0.12
					sr.Spread = 0.8
					sr.Parent = Lighting
				end
				sr.Enabled = true
			elseif sr then sr.Enabled = false end
			-- Atmosphere
			local at = Lighting:FindFirstChildOfClass("Atmosphere")
			if CFG.Atmosphere then
				if not at then
					at = Instance.new("Atmosphere")
					at.Parent = Lighting
				end
				at.Density = 0.35
				at.Offset = 0.2
				at.Color = Color3.fromRGB(180, 190, 210)
				at.Decay = Color3.fromRGB(100, 110, 140)
				at.Glare = 0.2
				at.Haze = 1.5
			elseif at then
				pcall(function() at:Destroy() end)
			end
			-- DepthOfField
			local dof = Lighting:FindFirstChild("HemaDOF")
			if CFG.DepthOfField then
				if not dof then
					dof = Instance.new("DepthOfFieldEffect")
					dof.Name = "HemaDOF"
					dof.FarIntensity = 0.3
					dof.FocusDistance = 40
					dof.InFocusRadius = 20
					dof.NearIntensity = 0.1
					dof.Parent = Lighting
				end
				dof.Enabled = true
			elseif dof then dof.Enabled = false end
		end)
		-- 下雨：相機本地部件 + 高密度粒子（部分遊戲會清 Workspace 粒子）
		pcall(function()
			local cam = workspace.CurrentCamera
			if not cam then return end
			local rain = cam:FindFirstChild("HemaRainLocal")
			if CFG.Rain then
				if not rain then
					rain = Instance.new("Part")
					rain.Name = "HemaRainLocal"
					rain.Anchored = true
					rain.CanCollide = false
					rain.CanQuery = false
					rain.CanTouch = false
					rain.Massless = true
					rain.Transparency = 1
					rain.Size = Vector3.new(1, 1, 1)
					rain.Parent = cam
					for i = 1, 3 do
						local att = Instance.new("Attachment")
						att.Name = "A" .. i
						att.Position = Vector3.new((i - 2) * 8, 12, -6)
						att.Parent = rain
						local pe = Instance.new("ParticleEmitter")
						pe.Name = "Drops"
						pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
						pe.Rate = math.floor((CFG.RainRate or 300) / 2)
						pe.Lifetime = NumberRange.new(0.5, 0.9)
						pe.Speed = NumberRange.new(60, 100)
						pe.SpreadAngle = Vector2.new(25, 25)
						pe.Size = NumberSequence.new(0.12, 0.03)
						pe.Transparency = NumberSequence.new(0.2, 1)
						pe.Color = ColorSequence.new(Color3.fromRGB(200, 220, 255))
						pe.EmissionDirection = Enum.NormalId.Bottom
						pe.Acceleration = Vector3.new(0, -120, 0)
						pe.LockedToPart = false
						pe.Parent = att
					end
				end
				rain.CFrame = cam.CFrame
				for _, att in ipairs(rain:GetChildren()) do
					if att:IsA("Attachment") then
						local pe = att:FindFirstChild("Drops")
						if pe then
							pe.Enabled = true
							pe.Rate = math.floor((CFG.RainRate or 300) / 2)
						end
					end
				end
				-- 加一點霧感
				Lighting.FogEnd = math.min(Lighting.FogEnd, 400)
			else
				if rain then rain:Destroy() end
			end
		end)
		if false and CFG.HitSound then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= lp then
					local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
					if hum then
						local prev = hpCache[plr]
						if prev and hum.Health < prev then
							pcall(function()
								local s = Instance.new("Sound")
								s.SoundId = CFG.HitSoundId or "rbxassetid://12222253"
								s.Volume = CFG.HitSoundVol or 1
								s.Parent = SoundService
								s:Play()
								task.delay(2, function() s:Destroy() end)
							end)
						end
						hpCache[plr] = hum.Health
					end
				end
			end
		end
		if CFG.SkyOn then
			if not Lighting:FindFirstChild("HemaSky") then
				applySkyPreset(CFG.SkyName)
			end
		else
			pcall(function()
				local s = Lighting:FindFirstChild("HemaSky")
				if s then s:Destroy() end
			end)
		end
		if CFG.GunChams or CFG.ArmChams or CFG.HideArms then
			pcall(function()
				local targets = {}
				local cam = workspace.CurrentCamera
				if cam then table.insert(targets, cam) end
				local vm = workspace:FindFirstChild("ViewModels")
				if vm then table.insert(targets, vm) end
				for _, root in ipairs(targets) do
					for _, p in ipairs(root:GetDescendants()) do
						if p:IsA("BasePart") then
							local n = string.lower(p.Name)
							local isArm = n:find("arm") or n:find("hand") or n:find("glove") or n:find("sleeve")
							if CFG.HideArms and isArm then
								p.LocalTransparencyModifier = 1
							elseif isArm and CFG.ArmChams then
								p.Material = Enum.Material.ForceField
								p.Color = CFG.ArmChamsColor or Color3.fromRGB(220, 220, 220)
								p.LocalTransparencyModifier = 0
							elseif CFG.GunChams and not isArm then
								p.Material = Enum.Material.ForceField
								p.Color = CFG.GunChamsColor or Color3.fromRGB(255, 255, 255)
							end
						end
					end
				end
			end)
		end
		if CFG.NoFlash then
			pcall(function()
				local pg = lp:FindFirstChild("PlayerGui")
				if not pg then return end
				for _, g in ipairs(pg:GetChildren()) do
					if g:IsA("ScreenGui") then
						local n = string.lower(g.Name)
						if n:find("flash") or n:find("blind") then g.Enabled = false end
					end
				end
			end)
		end
		-- 不掃整個 workspace（會卡），只關相機/ViewModels 粒子
		if CFG.NoSmoke then
			pcall(function()
				local roots = { workspace.CurrentCamera, workspace:FindFirstChild("ViewModels") }
				for _, root in ipairs(roots) do
					if root then
						for _, o in ipairs(root:GetDescendants()) do
							if o:IsA("ParticleEmitter") or o:IsA("Smoke") then
								o.Enabled = false
							end
						end
					end
				end
			end)
		end
	end
end)

local function ensureDir()
	pcall(function()
		if type(makefolder) == "function" then
			if type(isfolder) ~= "function" or not isfolder("HemaTech") then pcall(makefolder, "HemaTech") end
			if type(isfolder) ~= "function" or not isfolder(CONFIG_DIR) then pcall(makefolder, CONFIG_DIR) end
			if type(isfolder) ~= "function" or not isfolder("HemaTech/configs") then pcall(makefolder, "HemaTech/configs") end
		end
	end)
end

local function sanitizeCfgName(name)
	name = tostring(name or "default")
	-- 去掉路徑與副檔名，允許中文／底線／減號
	name = name:gsub("[/\\]", "")
	name = name:gsub("%.json$", "")
	name = name:gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" or name == "autoload" then name = "default" end
	return name
end

local configName = "default"

-- 讀取：是否自動載入 + 自動載入哪個檔名
pcall(function()
	if type(readfile) ~= "function" then return end
	local function readTrim(path)
		local ok, data = pcall(readfile, path)
		if ok and data then
			return tostring(data):gsub("^%s+", ""):gsub("%s+$", "")
		end
		return nil
	end
	local al = readTrim("HemaTech/auto_load.txt") or readTrim(CONFIG_DIR .. "/auto_load.txt")
	if al == "0" or al == "false" then
		CFG.AutoLoadConfig = false
	elseif al == "1" or al == "true" then
		CFG.AutoLoadConfig = true
	end
	local ae = readTrim("HemaTech/auto_exec.txt") or readTrim(CONFIG_DIR .. "/auto_exec.txt")
	if ae == "0" or ae == "false" then
		CFG.AutoExecScript = false
	elseif ae == "1" or ae == "true" then
		CFG.AutoExecScript = true
	end
	local ad = readTrim("HemaTech/auto_exec_delay.txt") or readTrim(CONFIG_DIR .. "/auto_exec_delay.txt")
	if ad then
		local n = tonumber(ad)
		if n and n >= 0 and n <= 120 then CFG.AutoExecDelay = n end
	end
	local an = readTrim(CONFIG_DIR .. "/autoload.txt") or readTrim("HemaTech/configs/autoload.txt")
	if an and an ~= "" then
		configName = sanitizeCfgName(an)
	end
end)

local function writeBootPrefs()
	pcall(function()
		ensureDir()
		if type(writefile) ~= "function" then return end
		writefile("HemaTech/auto_load.txt", CFG.AutoLoadConfig and "1" or "0")
		writefile(CONFIG_DIR .. "/auto_load.txt", CFG.AutoLoadConfig and "1" or "0")
		writefile("HemaTech/auto_exec.txt", CFG.AutoExecScript and "1" or "0")
		writefile(CONFIG_DIR .. "/auto_exec.txt", CFG.AutoExecScript and "1" or "0")
		local dly = tonumber(CFG.AutoExecDelay) or 10
		writefile("HemaTech/auto_exec_delay.txt", tostring(dly))
		writefile(CONFIG_DIR .. "/auto_exec_delay.txt", tostring(dly))
	end)
end

-- 自動開啟腳本：寫入 autoexec + queue_on_teleport
local HEMA_SCRIPT_URL = tostring(getgenv().HEMA_SCRIPT_URL or "")
local AUTOEXEC_NAME = "HemaRivals_Auto.lua"

local function getLoaderSource()
	local delaySec = tonumber(CFG.AutoExecDelay) or 10
	if delaySec < 0 then delaySec = 0 end
	if delaySec > 120 then delaySec = 120 end
	local ver = tostring(getgenv().HEMA_VERSION or "latest")
	return "-- HEMA auto loader delay=" .. tostring(delaySec) .. " ver=" .. ver .. "\n"
		.. "if getgenv().HEMA_AUTOLOADER_SCHEDULED then return end\n"
		.. "getgenv().HEMA_AUTOLOADER_SCHEDULED = true\n"
		.. "local u = '" .. HEMA_SCRIPT_URL .. "'\n"
		.. "local delaySec = " .. tostring(delaySec) .. "\n"
		.. "print('[HEMA] 自動執行 ' .. tostring(delaySec) .. ' 秒後載入（會覆蓋舊版）…')\n"
		.. "task.delay(delaySec, function()\n"
		.. "	getgenv().HEMA_AUTOLOADER_SCHEDULED = false\n"
		.. "	local ok, err = pcall(function()\n"
		.. "		loadstring(game:HttpGet(u))()\n"
		.. "	end)\n"
		.. "	if not ok then warn('[HEMA] auto load fail', err) end\n"
		.. "end)\n"
end

local function setQueueOnTeleport(on)
	pcall(function()
		if type(queue_on_teleport) ~= "function" then return end
		if on then
			queue_on_teleport(getLoaderSource())
			print("[HEMA] queue_on_teleport ON")
		else
			-- 多數執行器無法取消，寫入空/return 覆蓋
			queue_on_teleport("do return end")
			print("[HEMA] queue_on_teleport cleared")
		end
	end)
end

local function writeAutoExecFile(on)
	pcall(function()
		if type(writefile) ~= "function" then return end
		local src = getLoaderSource()
		local dirs = {
			"autoexec",
			"Autoexec",
			"autoexec/",
			"workspace/autoexec",
		}
		for _, d in ipairs(dirs) do
			pcall(function()
				if type(makefolder) == "function" then
					pcall(makefolder, d:gsub("/$", ""))
				end
			end)
			local path = (d:sub(-1) == "/") and (d .. AUTOEXEC_NAME) or (d .. "/" .. AUTOEXEC_NAME)
			if on then
				local ok = pcall(writefile, path, src)
				if ok then print("[HEMA] autoexec written", path) end
			else
				if type(delfile) == "function" then
					pcall(delfile, path)
				else
					pcall(writefile, path, "-- disabled\nreturn\n")
				end
			end
		end
		-- 也寫一份到 HemaTech 方便手動搬
		pcall(writefile, "HemaTech/" .. AUTOEXEC_NAME, on and src or "return\n")
	end)
end

local function applyAutoExecScript(on)
	CFG.AutoExecScript = on and true or false
	writeBootPrefs()
	setQueueOnTeleport(CFG.AutoExecScript)
	writeAutoExecFile(CFG.AutoExecScript)
	print("[HEMA] AutoExecScript", CFG.AutoExecScript and "ON" or "OFF", "delay=", tonumber(CFG.AutoExecDelay) or 10, "s")
end


local function cfgForSave()
	local t = {}
	for k, v in pairs(CFG) do
		local ty = type(v)
		if ty == "boolean" or ty == "number" or ty == "string" then
			t[k] = v
		end
	end
	return t
end

local function saveConfig(name)
	ensureDir()
	name = sanitizeCfgName(name)
	configName = name
	if type(writefile) ~= "function" then
		warn("[HEMA] 執行器無 writefile，無法存檔")
		return false
	end
	local ok, enc = pcall(function() return HttpService:JSONEncode(cfgForSave()) end)
	if not ok then
		warn("[HEMA] JSONEncode fail", enc)
		return false
	end
	local paths = {
		CONFIG_DIR .. "/" .. name .. ".json",
		"HemaTech/configs/" .. name .. ".json",
	}
	local any = false
	for _, path in ipairs(paths) do
		local w = pcall(writefile, path, enc)
		if w then
			any = true
			print("[HEMA] saved →", path)
		else
			warn("[HEMA] write fail", path)
		end
	end
	-- 驗證讀回
	if any and type(readfile) == "function" then
		local okR, data = pcall(readfile, paths[1])
		if not okR then okR, data = pcall(readfile, paths[2]) end
		if okR and data and #tostring(data) > 2 then
			print("[HEMA] save verify OK, bytes=", #tostring(data))
		else
			warn("[HEMA] save verify FAIL — 檔案可能沒寫入 workspace")
		end
	end
	return any
end

local function loadConfig(name)
	ensureDir()
	name = sanitizeCfgName(name)
	if type(readfile) ~= "function" then
		warn("[HEMA] 執行器無 readfile")
		return false
	end
	local raw, used
	local tryPaths = {
		CONFIG_DIR .. "/" .. name .. ".json",
		"HemaTech/configs/" .. name .. ".json",
	}
	-- 也掃 listfiles 找同名
	pcall(function()
		if not listfiles then return end
		for _, dir in ipairs({ CONFIG_DIR, "HemaTech/configs" }) do
			for _, f in ipairs(listfiles(dir) or {}) do
				local fs = tostring(f)
				if fs:lower():find(name:lower() .. "%.json") then
					table.insert(tryPaths, fs)
				end
			end
		end
	end)
	for _, path in ipairs(tryPaths) do
		local ok, data = pcall(readfile, path)
		if ok and data and #tostring(data) > 2 then
			raw = data
			used = path
			break
		end
	end
	if not raw then
		warn("[HEMA] load miss:", name, "現有檔=", table.concat(listConfigs(), ", "))
		return false
	end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if ok2 and type(data) == "table" then
		for k, v in pairs(data) do
			if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
				CFG[k] = v
			end
		end
		configName = name
		print("[HEMA] loaded", name, "from", used)
		return true
	end
	warn("[HEMA] JSON decode fail", name)
	return false
end

local function listConfigs()
	ensureDir()
	local t, seen = {}, {}
	local function add(n)
		n = sanitizeCfgName(n)
		if n and n ~= "" and not seen[n] then
			seen[n] = true
			table.insert(t, n)
		end
	end
	local function scan(dir)
		pcall(function()
			if type(listfiles) ~= "function" then return end
			local files = listfiles(dir)
			if type(files) ~= "table" then return end
			for _, f in ipairs(files) do
				local fs = tostring(f):gsub("\\", "/")
				local n = fs:match("([^/]+)%.json$") or fs:match("([^/]+)$")
				if n and n:lower() ~= "autoload.txt" and not n:lower():find("autoload") then
					if n:lower():sub(-5) == ".json" then
						n = n:sub(1, -6)
					end
					add(n)
				end
			end
		end)
	end
	scan(CONFIG_DIR)
	scan("HemaTech/configs")
	add("default")
	add(configName)
	table.sort(t)
	return t
end

-- 下拉參考（buildUI 後賦值）
local cfgDropdownRef = nil

local function getCfgDropdown()
	if cfgDropdownRef then return cfgDropdownRef end
	pcall(function()
		if Options and Options.CfgList then cfgDropdownRef = Options.CfgList end
	end)
	pcall(function()
		if Library and Library.Options and Library.Options.CfgList then
			cfgDropdownRef = Library.Options.CfgList
		end
	end)
	pcall(function()
		local g = getgenv and getgenv()
		if g and g.Options and g.Options.CfgList then cfgDropdownRef = g.Options.CfgList end
	end)
	return cfgDropdownRef
end

local function refreshConfigDropdown()
	local list = listConfigs()
	-- 複製表，避免 Linoria 比對同一參考不重繪
	local copy = {}
	for i, v in ipairs(list) do
		copy[i] = v
	end
	local ok, err = pcall(function()
		local dd = getCfgDropdown()
		if not dd then
			error("CfgList dropdown not found (Options.CfgList nil)")
		end
		if dd.SetValues then
			dd:SetValues(copy)
		else
			dd.Values = copy
			if dd.BuildDropdownList then
				dd:BuildDropdownList()
			end
		end
		-- 選中目前名稱
		local want = sanitizeCfgName(configName)
		if dd.SetValue then
			local has = false
			for _, n in ipairs(copy) do
				if n == want then has = true break end
			end
			if has then
				pcall(function() dd:SetValue(want) end)
			elseif #copy > 0 then
				pcall(function() dd:SetValue(copy[1]) end)
			end
		end
		if dd.Display then
			pcall(function() dd:Display() end)
		end
	end)

	print("[HEMA] dropdown refresh", ok and "OK" or err, "→", table.concat(copy, ", "))
	return ok
end

-- 把 CFG 同步到 Linoria：Toggle 在 Toggles，滑桿/下拉在 Options
local function applyConfigToUI()
	local opts, toggles = nil, nil
	pcall(function()
		opts = Options or (Library and Library.Options) or (getgenv and getgenv().Options)
	end)
	pcall(function()
		toggles = Toggles or (Library and Library.Toggles) or (getgenv and getgenv().Toggles)
	end)
	local n = 0
	for key, val in pairs(CFG) do
		-- 布林 → Toggle
		if type(val) == "boolean" and toggles and toggles[key] then
			local ok = pcall(function()
				local tg = toggles[key]
				if tg.SetValue then
					tg:SetValue(val)
				else
					tg.Value = val
				end
			end)
			if ok then n = n + 1 end
		end
		-- 數值／字串 → Options（Slider / Dropdown / Input）
		if opts and opts[key] then
			local ok = pcall(function()
				local opt = opts[key]
				if opt.SetValue then
					opt:SetValue(val)
				else
					opt.Value = val
				end
			end)
			if ok then n = n + 1 end
		end
	end
	pcall(function()
		if opts and opts.CfgName and opts.CfgName.SetValue then
			opts.CfgName:SetValue(tostring(configName))
		end
		if opts and opts.CfgList and opts.CfgList.SetValue then
			opts.CfgList:SetValue(tostring(configName))
		end
	end)
	-- 載入設定後強制還原 Rage 位置完整 5 項
	pcall(function()
		local dd = opts and opts.RagePosMode
		local labels = {
			"behind 後面", "front 前面", "above 上面", "under 下面", "random 隨機", "auto 自動(刀上/盾隨機)",
		}
		if dd and dd.SetValues then
			dd:SetValues(labels)
			local mode = tostring(CFG.RagePos or "behind"):lower()
			local pick = labels[1]
			for _, lab in ipairs(labels) do
				if lab:lower():find(mode, 1, true) then pick = lab break end
			end
			if dd.SetValue then pcall(function() dd:SetValue(pick) end) end
		end
	end)
	print("[HEMA] applyConfigToUI synced", n, "UI, toggles=", toggles and "OK" or "nil", "options=", opts and "OK" or "nil")
	return n > 0
end

local function deleteConfig(name)
	name = sanitizeCfgName(name)
	if name == "" then return false end
	local paths = {
		CONFIG_DIR .. "/" .. name .. ".json",
		"HemaTech/configs/" .. name .. ".json",
	}
	-- listfiles 掃到的完整路徑也刪
	pcall(function()
		if not listfiles then return end
		for _, dir in ipairs({ CONFIG_DIR, "HemaTech/configs" }) do
			for _, f in ipairs(listfiles(dir) or {}) do
				local fs = tostring(f)
				if fs:lower():find(name:lower() .. "%.json") then
					table.insert(paths, fs)
				end
			end
		end
	end)
	local any = false
	for _, path in ipairs(paths) do
		local ok = false
		if type(delfile) == "function" then
			ok = pcall(delfile, path)
		elseif type(delfolder) == "function" then
			-- no
		end
		-- 備援：寫空或 isfile 檢查後 delfile
		if not ok and type(writefile) == "function" and type(delfile) ~= "function" then
			-- 無法刪則覆寫提示
			pcall(writefile, path, "{}")
		end
		if ok then
			any = true
			print("[HEMA] deleted", path)
		else
			pcall(function()
				if delfile then delfile(path) any = true print("[HEMA] deleted", path) end
			end)
		end
	end
	if configName == name then
		configName = "default"
	end
	refreshConfigDropdown()
	return any
end




-- ===================== RAGEBOT（Lunara 概念精簡完整環：鎖敵→位姿→Silent→狀態）=====================
rageOrigCF = nil
local rageTargetPlr = nil
local rageStatusGui, rageStatusLabel
local function ensureRageStatus()
	if rageStatusLabel then return end
	pcall(function()
		rageStatusGui = Instance.new("ScreenGui")
		rageStatusGui.Name = "HemaRageStatus"
		rageStatusGui.ResetOnSpawn = false
		rageStatusGui.IgnoreGuiInset = true
		rageStatusGui.DisplayOrder = 55
		pcall(function() rageStatusGui.Parent = game:GetService("CoreGui") end)
		if not rageStatusGui.Parent then
			rageStatusGui.Parent = lp:FindFirstChild("PlayerGui")
		end
		rageStatusLabel = Instance.new("TextLabel")
		rageStatusLabel.Size = UDim2.fromOffset(320, 28)
		rageStatusLabel.Position = UDim2.new(0.5, -160, 0, 12)
		rageStatusLabel.BackgroundTransparency = 0.4
		rageStatusLabel.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
		rageStatusLabel.TextColor3 = Color3.fromRGB(255, 120, 140)
		rageStatusLabel.Font = Enum.Font.GothamBold
		rageStatusLabel.TextSize = 14
		rageStatusLabel.Text = ""
		rageStatusLabel.Visible = false
		rageStatusLabel.Parent = rageStatusGui
		Instance.new("UICorner", rageStatusLabel).CornerRadius = UDim.new(0, 6)
	end)
end
local function setRageStatus(main, detail)
	if not CFG.RageStatus then
		if rageStatusLabel then rageStatusLabel.Visible = false end
		return
	end
	ensureRageStatus()
	if not rageStatusLabel then return end
	rageStatusLabel.Visible = true
	if detail and detail ~= "" then
		rageStatusLabel.Text = main .. "  ·  " .. detail
	else
		rageStatusLabel.Text = main
	end
end
local function rageNearest()
	local me = hrp()
	if not me then return nil end
	local best, bestD = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if isEnemy(plr) and not isKatanaDeflecting(plr) then
			local ch = plr.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and root then
				local d = (root.Position - me.Position).Magnitude
				if d < bestD and d <= (CFG.MaxDist or 300) then
					bestD, best = d, plr
				end
			end
		end
	end
	return best
end
local RAGE_POS_LIST = { "behind", "front", "above", "under", "random", "auto" }

local function getToolAmmo(tool)
	if not tool then return nil end
	for _, key in ipairs({ "Ammo", "ammo", "Clip", "clip", "Bullets", "Magazine", "Rounds" }) do
		local v = nil
		pcall(function() v = tool:GetAttribute(key) end)
		if typeof(v) == "number" then return v end
	end
	for _, name in ipairs({ "Ammo", "AmmoValue", "Clip", "Bullets" }) do
		local v = tool:FindFirstChild(name)
		if v and v:IsA("ValueBase") then
			return tonumber(v.Value)
		end
	end
	return nil
end

local lastRageSwap = 0
local function rageSwapNextGun()
	if not CFG.RageAutoSwap then return end
	local now = os.clock()
	if now - lastRageSwap < 0.35 then return end
	local ch = lp.Character
	if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local bp = lp:FindFirstChild("Backpack")
	local tools = {}
	for _, t in ipairs(ch:GetChildren()) do
		if t:IsA("Tool") then table.insert(tools, t) end
	end
	if bp then
		for _, t in ipairs(bp:GetChildren()) do
			if t:IsA("Tool") then table.insert(tools, t) end
		end
	end
	if #tools < 2 then
		-- 按鍵備援 2→3→1
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			for _, k in ipairs({ Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.One, Enum.KeyCode.Four }) do
				vim:SendKeyEvent(true, k, false, game)
				vim:SendKeyEvent(false, k, false, game)
				task.wait(0.05)
			end
		end)
		lastRageSwap = now
		return
	end
	local current = ch:FindFirstChildOfClass("Tool")
	local start = 1
	for i, t in ipairs(tools) do
		if current and t == current then start = i break end
	end
	for i = 1, #tools do
		local t = tools[((start - 1 + i) % #tools) + 1]
		if not current or t ~= current then
			local ammo = getToolAmmo(t)
			if ammo == nil or ammo > 0 then
				lastRageSwap = now
				pcall(function()
					if hum then hum:EquipTool(t) end
				end)
				print("[HEMA] Rage swap →", t.Name)
				return
			end
		end
	end
	lastRageSwap = now
end

local function rageAttackCF(plr)
	local ch = plr and plr.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local mode = tostring(CFG.RagePos or "behind"):lower()
	local dist = tonumber(CFG.RageDist) or 5
	local under = tonumber(CFG.RageUnder) or 8
	-- 自動：Knife → 上面(25)；盾牌 → 隨機(5)
	if mode == "auto" or mode == "自動" or mode == "自动" then
		local gear = scanPlayerGear(plr)
		if gear.knife then
			mode = "above"
			dist = 25
			under = 25
		elseif gear.shield then
			mode = "random"
			dist = 5
			under = 5
		else
			mode = "behind"
		end
	end
	local pos
	if mode == "under" or mode == "下面" then
		pos = root.Position + Vector3.new(0, -under, 0)
	elseif mode == "above" or mode == "上面" then
		pos = root.Position + Vector3.new(0, under, 0)
	elseif mode == "front" or mode == "前面" then
		local front = root.CFrame * CFrame.new(0, 0, -dist)
		pos = front.Position
	elseif mode == "random" or mode == "隨機" or mode == "随机" then
		local sx = (math.random() < 0.5) and -1 or 1
		local sy = (math.random() < 0.5) and -1 or 1
		local sz = (math.random() < 0.5) and -1 or 1
		local ox = sx * dist * (0.4 + math.random() * 0.6)
		local oy = sy * under * (0.3 + math.random() * 0.7)
		local oz = sz * dist * (0.4 + math.random() * 0.6)
		pos = (root.CFrame * CFrame.new(ox, oy, oz)).Position
	else
		local behind = root.CFrame * CFrame.new(0, 0, dist)
		pos = behind.Position
	end
	return CFrame.new(pos, root.Position)
end

-- 視角檢查：相機停在原位，身體在對面（Lunara csync 精簡版）
local rageCamConn = nil
local function ensureRageCamSync()
	if rageCamConn then return end
	rageCamConn = RunService:BindToRenderStep("HEMA_RageViewAngle", Enum.RenderPriority.Camera.Value + 1, function()
		if getgenv().HEMA_KILL then return end
		if not CFG.RageOn or not CFG.RageViewAngle then
			-- 還原相機
			pcall(function()
				local cam = workspace.CurrentCamera
				local h = hum()
				if cam and h and cam.CameraType == Enum.CameraType.Scriptable then
					cam.CameraType = Enum.CameraType.Custom
					cam.CameraSubject = h
				end
			end)
			return
		end
		local orig = getgenv()._HEMA_RAGE_ORIG_CF or rageOrigCF
		local atk = getgenv()._HEMA_RAGE_ATK_CF
		local r = hrp()
		local cam = workspace.CurrentCamera
		if not orig or not r or not cam then return end
		-- 相機鎖在「原地」視角
		pcall(function()
			cam.CameraType = Enum.CameraType.Scriptable
			local look = orig.LookVector
			cam.CFrame = CFrame.new(orig.Position + Vector3.new(0, 1.5, 0), orig.Position + Vector3.new(0, 1.5, 0) + look)
		end)
		-- 身體保持在攻擊位（下一幀 rageTick 會再寫）
		if atk then
			pcall(function()
				r.CFrame = atk
			end)
		end
	end)
end
ensureRageCamSync()

-- 鎖定目標高亮 + 中國帽（輕量）
task.spawn(function()
	local hl, hat = nil, nil
	while true do
		task.wait(0.2)
		if getgenv().HEMA_KILL then break end
		local tgt = rageTargetPlr
		if CFG.TargetHighlight and CFG.RageOn and tgt and tgt.Character then
			if not hl or not hl.Parent then
				pcall(function()
					hl = Instance.new("Highlight")
					hl.Name = "HEMA_TargetHL"
					hl.FillColor = Color3.fromRGB(255, 60, 80)
					hl.OutlineColor = Color3.fromRGB(255, 255, 255)
					hl.FillTransparency = 0.5
					hl.Parent = tgt.Character
				end)
			else
				pcall(function() hl.Parent = tgt.Character end)
			end
		elseif hl then
			pcall(function() hl:Destroy() end)
			hl = nil
		end
		local ch = lp.Character
		local head = ch and ch:FindFirstChild("Head")
		if CFG.ChinaHat and head then
			if not hat or not hat.Parent then
				pcall(function()
					hat = Instance.new("Part")
					hat.Name = "HEMA_ChinaHat"
					hat.Size = Vector3.new(0.05, 0.05, 0.05)
					hat.Transparency = 1
					hat.Anchored = false
					hat.CanCollide = false
					hat.Parent = ch
					local mesh = Instance.new("SpecialMesh")
					mesh.MeshType = Enum.MeshType.FileMesh
					mesh.MeshId = "rbxassetid://1033714"
					mesh.Scale = Vector3.new(1.2, 0.6, 1.2)
					mesh.Parent = hat
					local w = Instance.new("Weld")
					w.Part0 = head
					w.Part1 = hat
					w.C0 = CFrame.new(0, 0.6, 0)
					w.Parent = hat
				end)
			end
		elseif hat then
			pcall(function() hat:Destroy() end)
			hat = nil
		end
	end
end)

rageTick = function()
	if not CFG.RageOn then
		if rageOrigCF and CFG.RageReturn then
			local r = hrp()
			if r then pcall(function() r.CFrame = rageOrigCF end) end
		end
		rageOrigCF = nil
		getgenv()._HEMA_RAGE_ATK_CF = nil
		getgenv()._HEMA_RAGE_ORIG_CF = nil
		getgenv()._HEMA_RAGE_VIEW = false
		pcall(function()
			local cam = workspace.CurrentCamera
			local h = hum()
			if cam then
				cam.CameraType = Enum.CameraType.Custom
				if h then cam.CameraSubject = h end
			end
		end)
		rageTargetPlr = nil
		if rageStatusLabel then rageStatusLabel.Visible = false end
		return
	end
	local me = hrp()
	if not me then
		setRageStatus(L("ragebot: 等待角色", "ragebot: waiting character"), "")
		return
	end
	if not rageOrigCF then
		rageOrigCF = me.CFrame
	end
	local plr = rageNearest()
	rageTargetPlr = plr
	if not plr then
		setRageStatus(L("ragebot: 待機", "ragebot: idle"), "")
		return
	end
	local atk = rageAttackCF(plr)
	if atk then
		-- 身體到攻擊位；視角分離在 RenderStep 處理
		if CFG.RageVoid then
			pcall(function() me.CFrame = CFrame.new(atk.Position.X, -800, atk.Position.Z) end)
			task.wait()
		end
		pcall(function()
			me.CFrame = atk
			me.AssemblyLinearVelocity = Vector3.zero
		end)
		getgenv()._HEMA_RAGE_ATK_CF = atk
		getgenv()._HEMA_RAGE_ORIG_CF = rageOrigCF
		getgenv()._HEMA_RAGE_VIEW = CFG.RageViewAngle == true
	end
	local head = plr.Character and (plr.Character:FindFirstChild("Head") or plr.Character:FindFirstChild("HumanoidRootPart"))
	if CFG.RageAutoShoot and head then
		-- 單次 silent，間隔由 RageFireRate 控制（避免卡）
		trySilent(head, true)
	end
	-- 僅 Rage：子彈打完自動換下一把
	if CFG.RageAutoSwap then
		pcall(function()
			local ch = lp.Character
			local tool = ch and ch:FindFirstChildOfClass("Tool")
			local ammo = getToolAmmo(tool)
			if tool and ammo == 0 then
				rageSwapNextGun()
			end
		end)
	end
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	local hp = hum and math.floor(hum.Health) or 0
	setRageStatus(
		L("ragebot: 攻擊中", "ragebot: attacking") .. " (" .. plr.Name .. ")",
		"HP " .. tostring(hp)
	)
end



-- ========== 自動刀人：切近戰 → 背後 → StartShooting → 虛空 → CD ==========
local lastAutoKnife = 0
local autoKnifeBusy = false

local function meleeItemFromFighter()
	ensureMods()
	local lf = FighterCtrl and FighterCtrl.LocalFighter
	if not lf then return nil end
	local items = lf.Items
	if not items then return nil end
	local function looksMelee(it)
		if not it then return false end
		local nm, ty
		pcall(function()
			if it.Get then
				nm = it:Get("Name") or it:Get("ItemName")
				ty = it:Get("ItemType") or it:Get("Type") or it:Get("Category")
			end
		end)
		nm = tostring(nm or it.Name or ""):lower()
		ty = tostring(ty or ""):lower()
		if ty:find("melee") then return true end
		if nm:find("knife") or nm:find("katana") or nm:find("fist") or nm:find("axe")
			or nm:find("scythe") or nm:find("maul") or nm:find("chainsaw") or nm:find("trowel") then
			return true
		end
		return false
	end
	-- slot 3 優先
	for _, key in ipairs({ 3, "3" }) do
		local it = items[key]
		if it then return it end
	end
	for key, it in pairs(items) do
		if looksMelee(it) then return it end
		local slot
		pcall(function()
			if it.Get then slot = tonumber(it:Get("Slot") or it:Get("Index")) end
		end)
		if slot == 3 then return it end
	end
	return nil
end

local function equipMeleeKnife()
	ensureMods()
	local item = meleeItemFromFighter()
	local oid
	pcall(function()
		if item and item.Get then oid = item:Get("ObjectID") end
	end)
	-- 按 3 切近戰欄
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		vim:SendKeyEvent(true, Enum.KeyCode.Three, false, game)
		task.wait(0.03)
		vim:SendKeyEvent(false, Enum.KeyCode.Three, false, game)
	end)
	if oid and UseItem then
		for _, en in ipairs({ "Equip", "Switch", "Select", "EquipItem", "ChangeItem" }) do
			local ev = en
			pcall(function()
				if EnumLibrary and EnumLibrary.ToEnum then
					ev = EnumLibrary:ToEnum(en) or en
				end
			end)
			pcall(function() UseItem:FireServer(oid, ev, nil, nil) end)
		end
	end
	local lf = FighterCtrl and FighterCtrl.LocalFighter
	pcall(function()
		if lf and item then
			if lf.EquipItem then lf:EquipItem(item) end
			if lf.SwitchItem then lf:SwitchItem(item) end
		end
	end)
	pcall(function()
		if FighterCtrl and item then
			if FighterCtrl.EquipItem then FighterCtrl:EquipItem(item) end
			if FighterCtrl.SwitchItem then FighterCtrl:SwitchItem(item) end
		end
	end)
	-- Tool 備援
	local ch = lp.Character
	local bp = lp:FindFirstChild("Backpack")
	local function tryTool(t)
		if not t or not t:IsA("Tool") then return end
		local n = tostring(t.Name or ""):lower()
		if n:find("knife") or n:find("katana") or n:find("fist") then
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			if hum then pcall(function() hum:EquipTool(t) end) end
			pcall(function() t.Parent = ch end)
		end
	end
	if ch then for _, t in ipairs(ch:GetChildren()) do tryTool(t) end end
	if bp then for _, t in ipairs(bp:GetChildren()) do tryTool(t) end end
	return oid or getObjectId()
end

local function fireKnifeStab(part, oid)
	ensureMods()
	ensureMeleeNoCD()
	wipeEquippedMeleeCD()
	if not part then return end
	local root = hrp()
	if not root then return end
	oid = oid or getObjectId()
	if not oid then
		warn("[HEMA] AutoKnife: no ObjectID")
		return
	end
	if not UseItem then
		warn("[HEMA] AutoKnife: UseItem nil")
		return
	end
	local look = CFrame.new(root.Position, part.Position)
	local data
	if Utility and Utility.EncodeCFrame then
		data = {
			[utf8.char(1)] = {
				[utf8.char(0)] = Utility:EncodeCFrame(look),
				[utf8.char(1)] = Utility:EncodeCFrame(look),
				[utf8.char(2)] = part,
				[utf8.char(3)] = Utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42)),
			},
		}
	else
		data = { [utf8.char(1)] = { [utf8.char(0)] = look, [utf8.char(1)] = look, [utf8.char(2)] = part } }
	end
	-- 普攻 + 突刺/特殊 多種 action
	local actionNames = {
		"StartShooting", "StopShooting", "Attack", "Thrust", "Lunge", "Stab",
		"Special", "HeavyAttack", "SecondaryFire", "AltFire", "UseAbility", "Ability",
	}
	for _, actName in ipairs(actionNames) do
		local action = actName
		pcall(function()
			if EnumLibrary and EnumLibrary.ToEnum then
				local ev = EnumLibrary:ToEnum(actName)
				if ev ~= nil then action = ev end
			end
		end)
		pcall(function() UseItem:FireServer(oid, action, data, nil) end)
	end
	-- 滑鼠左鍵 + 右鍵（突刺常綁右鍵/重擊）
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		for _, btn in ipairs({ 0, 1 }) do
			vim:SendMouseButtonEvent(0, 0, btn, true, game, 1)
			task.wait(0.04)
			vim:SendMouseButtonEvent(0, 0, btn, false, game, 1)
			task.wait(0.03)
		end
	end)
	-- 直接呼叫 Melee 模組所有攻擊函式
	pcall(function()
		local mod = lp.PlayerScripts.Modules.ItemTypes:FindFirstChild("Melee")
		if not mod then return end
		local ok, M = pcall(require, mod)
		if not ok or not M then return end
		local eq = FighterCtrl and FighterCtrl.LocalFighter and FighterCtrl.LocalFighter.EquippedItem
		if not eq then return end
		if eq.Info then wipeCooldownInfo(eq.Info) end
		for _, fnName in ipairs({ "StartShooting", "Attack", "Thrust", "Lunge", "Special", "HeavyAttack" }) do
			if type(M[fnName]) == "function" then
				pcall(function() M[fnName](eq, part, look) end)
				pcall(function() M[fnName](eq, look, part) end)
				pcall(function() M[fnName](eq, part) end)
			end
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(0.05)
		if getgenv().HEMA_KILL then break end
		if not CFG then task.wait(0.2) 
		elseif CFG.AutoKnife and not autoKnifeBusy then
			local now = tick()
			local cd = tonumber(CFG.AutoKnifeCD) or 0.15
			if CFG.NoMeleeCD then cd = math.min(cd, 0.12) end
			if now - lastAutoKnife >= cd then
				pcall(ensureMeleeNoCD)
				local me = hrp()
				local plr = rageNearest()
				if me and plr and plr.Character then
					local root = plr.Character:FindFirstChild("HumanoidRootPart")
					local humE = plr.Character:FindFirstChildOfClass("Humanoid")
					local head = plr.Character:FindFirstChild("Head") or root
					if root and humE and humE.Health > 0 and head then
						autoKnifeBusy = true
						print("[HEMA] AutoKnife →", plr.Name)
						local prevAnti = CFG.AntiVoid
						CFG.AntiVoid = false
						local okStep, errStep = pcall(function()
							local oid = equipMeleeKnife()
							task.wait(0.12)
							oid = getObjectId() or oid
							local dist = tonumber(CFG.AutoKnifeDist) or 3.5
							-- 刷新目標位置
							root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") or root
							head = plr.Character and (plr.Character:FindFirstChild("Head") or root) or head
							local behind = root.CFrame * CFrame.new(0, 0, dist)
							me.CFrame = CFrame.new(behind.Position, root.Position)
							me.AssemblyLinearVelocity = Vector3.zero
							-- 站穩再刺（太快進虛空會沒判定）
							task.wait(0.08)
							fireKnifeStab(head, oid)
							task.wait(0.15)
							fireKnifeStab(head, oid or getObjectId())
							task.wait(0.12)
							local vy = tonumber(CFG.AutoKnifeVoidY) or -120
							me = hrp() or me
							me.CFrame = CFrame.new(behind.Position.X, vy, behind.Position.Z)
							me.AssemblyLinearVelocity = Vector3.zero
							task.wait(tonumber(CFG.AutoKnifeVoidTime) or 0.45)
						end)
						if not okStep then
							warn("[HEMA] AutoKnife step", errStep)
						end
						CFG.AntiVoid = prevAnti
						lastAutoKnife = tick()
						autoKnifeBusy = false
					end
				end
			end
		end
	end
end)

print("[HEMA] combat ready")

local Library, uiBuilt, uiBuilding, loading = nil, false, false, false
local menuMouseConn = nil
local menuCursorGui, menuCursorDot = nil, nil
local menuCursorDraw = nil -- Drawing 游標（螢幕像素，不偏移）

-- 選單使用系統滑鼠（關閉 Linoria 內建游標）
-- 不再自管游標，避免蓋掉內建三角游標與造成關選單鎖死
local function destroyMenuCursor() end
local function clearGuiModal()
	pcall(function()
		local roots = { game:GetService("CoreGui"), lp:FindFirstChild("PlayerGui") }
		pcall(function() if gethui then table.insert(roots, gethui()) end end)
		for _, root in ipairs(roots) do
			if root then
				for _, d in ipairs(root:GetDescendants()) do
					if d:IsA("GuiObject") and d.Modal then
						pcall(function() d.Modal = false end)
					end
				end
			end
		end
	end)
end

-- Modal 解鎖：FPS 遊戲必須用 Gui Modal 才能真正解放系統滑鼠
local modalGui, modalBtn = nil, nil

local function ensureModalUnlock()
	pcall(function()
		if modalGui and modalGui.Parent then return end
		local parent = nil
		pcall(function()
			if gethui then parent = gethui() end
		end)
		if not parent then
			parent = game:GetService("CoreGui")
		end
		pcall(function()
			if not parent then
				parent = lp:WaitForChild("PlayerGui", 2)
			end
		end)
		if not parent then return end
		modalGui = Instance.new("ScreenGui")
		modalGui.Name = "HemaMouseUnlock"
		modalGui.ResetOnSpawn = false
		modalGui.IgnoreGuiInset = true
		modalGui.DisplayOrder = 999999
		modalGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		pcall(function() modalGui.Parent = parent end)
		if not modalGui.Parent then
			modalGui.Parent = lp:FindFirstChild("PlayerGui") or parent
		end
		-- 幾乎全螢幕透明 Modal（Active 才能解鎖）
		modalBtn = Instance.new("TextButton")
		modalBtn.Name = "ModalUnlock"
		modalBtn.BackgroundTransparency = 1
		modalBtn.Text = ""
		modalBtn.Size = UDim2.fromScale(1, 1)
		modalBtn.Position = UDim2.fromScale(0, 0)
		modalBtn.ZIndex = 0
		modalBtn.AutoButtonColor = false
		modalBtn.Modal = true
		modalBtn.Active = true
		modalBtn.Selectable = false
		modalBtn.Parent = modalGui
		-- 不攔截點擊：讓點擊穿透到下方 Linoria（Roblox 無真正穿透，縮小中間洞）
		-- 改用四邊細條 + 中心不擋：用極小 Modal 點即可解鎖
		modalBtn.Size = UDim2.fromOffset(1, 1)
		modalBtn.Position = UDim2.fromOffset(0, 0)
	end)
end

local function destroyModalUnlock()
	pcall(function()
		if modalGui then modalGui:Destroy() end
	end)
	modalGui, modalBtn = nil, nil
end

local function freeMouse()
	pcall(function()
		if Library then Library.ShowCustomCursor = false end
		ensureModalUnlock()
		if modalBtn then
			modalBtn.Modal = true
			modalBtn.Active = true
		end
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true
		pcall(function()
			UIS.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
		end)
		-- 強制顯示預設游標圖示
		pcall(function()
			local mouse = lp:GetMouse()
			if mouse then
				mouse.Icon = ""
			end
		end)
	end)
end

local function releaseMenuMouse()
	menuOpenWanted = false
	if menuMouseConn then
		pcall(function() menuMouseConn:Disconnect() end)
		menuMouseConn = nil
	end
	pcall(function()
		if Library then Library.ShowCustomCursor = false end
	end)
	destroyModalUnlock()
	clearGuiModal()
	local function unlockFree()
		if menuOpenWanted then return end
		pcall(function()
			UIS.OverrideMouseIconBehavior = Enum.OverrideMouseIconBehavior.None
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = true
		end)
	end
	unlockFree()
	task.defer(unlockFree)
	task.delay(0.05, unlockFree)
	task.delay(0.15, function()
		unlockFree()
		clearGuiModal()
		pcall(function()
			local cam = workspace.CurrentCamera
			local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
			if cam and hum then
				cam.CameraType = Enum.CameraType.Custom
				cam.CameraSubject = hum
			end
			if hum then
				hum.AutoRotate = true
			end
		end)
	end)
end

local function startMenuMouseUnlock()
	menuOpenWanted = true
	freeMouse()
	if menuMouseConn then
		pcall(function() menuMouseConn:Disconnect() end)
		menuMouseConn = nil
	end
	menuMouseConn = RunService.RenderStepped:Connect(function()
		if not menuOpenWanted then return end
		pcall(function()
			if Library then Library.ShowCustomCursor = false end
			if not modalGui or not modalGui.Parent then
				ensureModalUnlock()
			end
			if modalBtn then
				modalBtn.Modal = true
			end
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = true
		end)
	end)
	for _, d in ipairs({ 0, 0.03, 0.08, 0.15, 0.3, 0.5 }) do
		task.delay(d, function()
			if menuOpenWanted then freeMouse() end
		end)
	end
	print("[HEMA] 系統滑鼠解鎖 (Modal)")
end

local function stopMenuMouseUnlock()
	releaseMenuMouse()
end


local Window

local WEAPON_PRIMARY = {
	"Assault Rifle","Sniper","Bow","Burst Rifle","Crossbow","Gunblade","RPG","Shotgun",
	"Energy Rifle","Flamethrower","Grenade Launcher","Minigun","Paintball Gun","Distortion","Permafrost","Scepter",
}
local WEAPON_SECONDARY = {
	"Handgun","Daggers","Flare Gun","Revolver","Shorty","Spray","Uzi","Energy Pistols","Exogun","Slingshot","Warper","Glass Cannon",
}
local WEAPON_MELEE = {
	"Fists","Battle Axe","Chainsaw","Katana","Knife","Riot Shield","Scythe","Maul","Trowel","Glast Shard",
}
local WEAPON_UTILITY = {
	"Grenade","Flashbang","Freeze Ray","Jump Pad","Molotov","Satchel","Smoke Grenade","War Horn","Medkit","Subspace Tripmine","Warpstone","Hook","Spear",
}

local function yield()
	task.wait(0.12)
end
local function yieldBig()
	task.wait(0.25)
end


-- 小卡片載入提示（建選單前就顯示，不阻塞）
local bootGui
local function showBoot(msg)
	pcall(function()
		if bootGui then bootGui:Destroy() end
		bootGui = Instance.new("ScreenGui")
		bootGui.Name = "HemaBoot"
		bootGui.IgnoreGuiInset = true
		bootGui.ResetOnSpawn = false
		bootGui.DisplayOrder = 9999
		local parent = lp:FindFirstChild("PlayerGui")
		if not parent then parent = lp:WaitForChild("PlayerGui", 3) end
		bootGui.Parent = parent
		local card = Instance.new("Frame")
		card.Name = "Card"
		card.AnchorPoint = Vector2.new(0.5, 0)
		card.Position = UDim2.new(0.5, 0, 0, 40)
		card.Size = UDim2.fromOffset(260, 48)
		card.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
		card.BorderSizePixel = 0
		card.Parent = bootGui
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
		local st = Instance.new("UIStroke", card)
		st.Color = Color3.fromRGB(255, 255, 255)
		st.Thickness = 1
		local lab = Instance.new("TextLabel")
		lab.Name = "Lab"
		lab.Size = UDim2.fromScale(1, 1)
		lab.BackgroundTransparency = 1
		lab.Font = Enum.Font.Gotham
		lab.TextSize = 14
		lab.TextColor3 = Color3.fromRGB(245, 245, 245)
		lab.Text = msg or "Loading..."
		lab.Parent = card
	end)
end
local function setBoot(msg)
	pcall(function()
		if bootGui and bootGui:FindFirstChild("Card") then
			local lab = bootGui.Card:FindFirstChild("Lab")
			if lab then lab.Text = msg end
		end
	end)
end
local function hideBoot()
	pcall(function()
		if bootGui then bootGui:Destroy() end
		bootGui = nil
	end)
end

local function buildUI()

	if uiBuilt or uiBuilding or not Library then return end
	uiBuilding = true
	showBoot(L("建立選單中…", "Building menu…"))
	print("[HEMA] 分批建立選單…")




-- ===================== Lunara 名稱 / 徽章 / 頭上顯示 =====================
local lastSpoofName = ""
local nameSpoofBusy = false
local headNameBillboard = nil

local function clearbadges(str)
	if type(str) ~= "string" then return "" end
	return str:gsub(utf8.char(0xE000), ""):gsub(utf8.char(0xE001), "")
end
local function escapePattern(str)
	return tostring(str):gsub("([^%w])", "%%%1")
end
local function buildSpoofName()
	local base = clearbadges(CFG.NameSpoofValue or "hi")
	local badge = (CFG.NameSpoofPremium and utf8.char(0xE001) or "")
		.. (CFG.NameSpoofVerified and utf8.char(0xE000) or "")
	return base .. badge
end

-- 掃任意容器內文字，把本名 / 舊假名換成新假名
local function replaceNameInContainer(root, realName, oldSpoof, newSpoof)
	if not root then return end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
			local t = d.Text
			if type(t) == "string" and t ~= "" then
				local nt = t
				if realName and realName ~= "" and nt:find(realName, 1, true) then
					nt = nt:gsub(escapePattern(realName), newSpoof)
				end
				if oldSpoof and oldSpoof ~= "" and oldSpoof ~= newSpoof and nt:find(oldSpoof, 1, true) then
					nt = nt:gsub(escapePattern(oldSpoof), newSpoof)
				end
				-- DisplayName 也可能出現在名牌
				local dn = lp.DisplayName
				if dn and dn ~= "" and dn ~= realName and nt:find(dn, 1, true) then
					nt = nt:gsub(escapePattern(dn), newSpoof)
				end
				if nt ~= t then
					pcall(function() d.Text = nt end)
				end
			end
		end
	end
end

-- 自建頭上名牌（遊戲若用自訂 Billboard 蓋住 Humanoid 名）
local function ensureHeadNameplate(char, text)
	char = char or lp.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	local bb = head:FindFirstChild("NoirNameSpoof")
	if not bb then
		bb = Instance.new("BillboardGui")
		bb.Name = "NoirNameSpoof"
		bb.Size = UDim2.fromOffset(220, 28)
		bb.StudsOffset = Vector3.new(0, 2.2, 0)
		bb.AlwaysOnTop = true
		bb.MaxDistance = 150
		bb.Parent = head
		local lab = Instance.new("TextLabel")
		lab.Name = "Name"
		lab.BackgroundTransparency = 1
		lab.Size = UDim2.fromScale(1, 1)
		lab.Font = Enum.Font.GothamBold
		lab.TextSize = 14
		lab.TextStrokeTransparency = 0.4
		lab.TextColor3 = Color3.fromRGB(255, 255, 255)
		lab.Parent = bb
	end
	local lab = bb:FindFirstChild("Name")
	if lab then lab.Text = tostring(text) end
	headNameBillboard = bb
end

local function destroyHeadNameplate()
	pcall(function()
		local ch = lp.Character
		local head = ch and ch:FindFirstChild("Head")
		local bb = head and head:FindFirstChild("NoirNameSpoof")
		if bb then bb:Destroy() end
	end)
	headNameBillboard = nil
end

local function applyNameSpoof(char)
	if not CFG.NameSpoof then
		destroyHeadNameplate()
		return
	end
	char = char or lp.Character
	if not char then return end
	local spoof = buildSpoofName()
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function()
			hum.DisplayName = spoof
			-- 強制刷新預設名牌
			local old = hum.DisplayDistanceType
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			task.defer(function()
				pcall(function()
					hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
				end)
			end)
		end)
	end
	-- 角色內所有 Billboard / 文字
	replaceNameInContainer(char, lp.Name, lastSpoofName, spoof)
	-- PlayerGui（排行榜/個人檔案）
	replaceNameInContainer(lp:FindFirstChild("PlayerGui"), lp.Name, lastSpoofName, spoof)
	-- CoreGui 部分榜單
	pcall(function()
		replaceNameInContainer(game:GetService("CoreGui"), lp.Name, lastSpoofName, spoof)
	end)
	-- 頭上自建名牌（保證一定看得到）
	ensureHeadNameplate(char, spoof)
	lastSpoofName = spoof
end

local function refreshNameSpoofLabels()
	if not CFG.NameSpoof or nameSpoofBusy then return end
	nameSpoofBusy = true
	pcall(applyNameSpoof, lp.Character)
	nameSpoofBusy = false
end

-- 新 TextLabel 出現時即時改
pcall(function()
	local function hookDesc(parent)
		if not parent then return end
		parent.DescendantAdded:Connect(function(d)
			if not CFG.NameSpoof then return end
			if not (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) then return end
			task.defer(function()
				local spoof = buildSpoofName()
				local t = d.Text
				if type(t) ~= "string" then return end
				if t:find(lp.Name, 1, true) then
					pcall(function() d.Text = t:gsub(escapePattern(lp.Name), spoof) end)
				elseif lastSpoofName ~= "" and t:find(lastSpoofName, 1, true) then
					pcall(function() d.Text = t:gsub(escapePattern(lastSpoofName), spoof) end)
				end
			end)
		end)
	end
	hookDesc(lp:FindFirstChild("PlayerGui") or lp:WaitForChild("PlayerGui", 5))
	if lp.Character then hookDesc(lp.Character) end
	lp.CharacterAdded:Connect(function(c)
		hookDesc(c)
		task.wait(0.4)
		if CFG.NameSpoof then applyNameSpoof(c) end
	end)
end)

task.spawn(function()
	while task.wait(0.35) do
		if getgenv().HEMA_KILL then break end
		if CFG.NameSpoof then pcall(refreshNameSpoofLabels) end
	end
end)

-- ===================== Rivals 真實假段位：DisplayELO / Level / WinStreak =====================
-- 參考社群腳本寫法（非 Billboard 標籤）：
--   SetAttribute("DisplayELO", elo)
--   SetAttribute("Level", level)
--   SetAttribute("StatisticDuelsWinStreak", streak)
--   CustomLeaderstats.Level / "Win Streak"
local RANK_ELO = {
	["Bronze III"] = 0,
	["Bronze II"] = 200,
	["Bronze I"] = 400,
	["Silver III"] = 600,
	["Silver II"] = 800,
	["Silver I"] = 1000,
	["Gold III"] = 1200,
	["Gold II"] = 1400,
	["Gold I"] = 1600,
	["Platinum III"] = 1800,
	["Platinum II"] = 2000,
	["Platinum I"] = 2200,
	["Diamond III"] = 2400,
	["Diamond II"] = 2600,
	["Diamond I"] = 2800,
	["Onyx III"] = 3000,
	["Onyx II"] = 3200,
	["Onyx I"] = 3400,
	["Nemesis"] = 3600,
	["Archnemesis"] = 4000,
}
local RANK_LIST = {}
for name, _ in pairs(RANK_ELO) do table.insert(RANK_LIST, name) end
table.sort(RANK_LIST, function(a, b) return (RANK_ELO[a] or 0) < (RANK_ELO[b] or 0) end)

local function eloFromPreset(name)
	return RANK_ELO[name] or tonumber(CFG.DisplayELO) or 2400
end

local function ensureStat(folder, name, className)
	className = className or "IntValue"
	local v = folder:FindFirstChild(name)
	if not v then
		v = Instance.new(className)
		v.Name = name
		v.Parent = folder
	end
	return v
end

local function applyRivalsProfileSpoof()
	local lv = tonumber(CFG.LevelValue) or 9999
	local streak = tonumber(CFG.WinStreakValue) or 9999
	local elo = tonumber(CFG.DisplayELO) or eloFromPreset(CFG.FakeRankPreset) or 2400
	if CFG.FakeRankOn and CFG.FakeRankPreset then
		elo = eloFromPreset(CFG.FakeRankPreset)
		CFG.DisplayELO = elo
	end

	-- Level（英文 Attribute，不是「等級」）
	if CFG.LevelSpoof then
		pcall(function() lp:SetAttribute("Level", lv) end)
		pcall(function() lp:SetAttribute("等級", lv) end) -- 舊版相容
		pcall(function()
			local ls = lp:FindFirstChild("CustomLeaderstats")
			if not ls then
				ls = Instance.new("Folder")
				ls.Name = "CustomLeaderstats"
				ls.Parent = lp
			end
			local levelVal = ls:FindFirstChild("Level") or ls:FindFirstChild("等級")
			if not levelVal then
				levelVal = Instance.new("IntValue")
				levelVal.Name = "Level"
				levelVal.Parent = ls
			end
			levelVal.Value = lv
		end)
	end

	-- 連勝
	if CFG.WinStreakSpoof then
		pcall(function() lp:SetAttribute("StatisticDuelsWinStreak", streak) end)
		pcall(function() lp:SetAttribute("連勝", streak) end)
		pcall(function()
			local ls = lp:FindFirstChild("CustomLeaderstats")
			if not ls then
				ls = Instance.new("Folder")
				ls.Name = "CustomLeaderstats"
				ls.Parent = lp
			end
			-- 常見名稱：Win Streak / 連勝 / WinStreak
			for _, n in ipairs({ "Win Streak", "連勝", "WinStreak", "Winstreak" }) do
				local w = ls:FindFirstChild(n)
				if not w then
					w = Instance.new("IntValue")
					w.Name = n
					w.Parent = ls
				end
				pcall(function() w.Value = streak end)
			end
		end)
	end

	-- 假段位 = DisplayELO（遊戲用 ELO 算段位徽章，不是頭上 TextLabel）
	if CFG.FakeRankOn then
		pcall(function() lp:SetAttribute("DisplayELO", elo) end)
		pcall(function() lp:SetAttribute("ELO", elo) end)
		pcall(function() lp:SetAttribute("Elo", elo) end)
		pcall(function() lp:SetAttribute("RankedELO", elo) end)
		pcall(function()
			local ls = lp:FindFirstChild("CustomLeaderstats")
			if not ls then
				ls = Instance.new("Folder")
				ls.Name = "CustomLeaderstats"
				ls.Parent = lp
			end
			for _, n in ipairs({ "ELO", "Elo", "DisplayELO", "RankedELO" }) do
				local e = ls:FindFirstChild(n)
				if not e then
					e = Instance.new("IntValue")
					e.Name = n
					e.Parent = ls
				end
				pcall(function() e.Value = elo end)
			end
		end)
	end
end

-- 清掉舊的頭上假段位標籤（若有）
pcall(function()
	local head = lp.Character and lp.Character:FindFirstChild("Head")
	if head then
		for _, n in ipairs({ "NoirFakeRank", "HemaFakeRank" }) do
			local bb = head:FindFirstChild(n)
			if bb then bb:Destroy() end
		end
	end
end)

task.spawn(function()
	while true do
		if getgenv().HEMA_KILL then break end
		pcall(applyRivalsProfileSpoof)
		task.wait(0.35)
	end
end)

-- ===================== Lunara 設備偽造 Device Spoof =====================
local DEVICE_CFGS = {
	Mobile = { Display = "Mobile", Code = "Touch" },
	Console = { Display = "Console", Code = "Gamepad" },
	VR = { Display = "VR", Code = "VR" },
	PC = { Display = "PC", Code = "MouseKeyboard" },
}
local lastDeviceApply = 0
local function applyDeviceSpoof()
	if not CFG.DeviceSpoof then return end
	local now = tick()
	if now - lastDeviceApply < 0.5 then return end
	lastDeviceApply = now
	local cfg = DEVICE_CFGS[CFG.DeviceType or "Console"]
	if not cfg then return end
	for _ = 1, 3 do
		local ok = pcall(function()
			local r = RS:FindFirstChild("Remotes")
			r = r and r:FindFirstChild("Replication")
			r = r and r:FindFirstChild("Fighter")
			local sc = r and r:FindFirstChild("SetControls")
			if sc then
				sc:FireServer(cfg.Code)
				return true
			end
			return false
		end)
		if ok then break end
		task.wait(0.2)
	end
end
task.spawn(function()
	while task.wait(30) do
		if getgenv().HEMA_KILL then break end
		if CFG.DeviceSpoof then pcall(applyDeviceSpoof) end
	end
end)


print("[HEMA] CreateWindow…")
	setBoot(L("建立視窗…", "Create window…"))
	task.wait(0.15)
	RunService.Heartbeat:Wait()
	getgenv().HEMA_Library = Library
	
	-- Noir Hub：黑白主題
	pcall(function()
		Library.BackgroundColor = Color3.fromRGB(10, 10, 10)
		Library.MainColor = Color3.fromRGB(16, 16, 16)
		Library.AccentColor = Color3.fromRGB(255, 255, 255)
		Library.OutlineColor = Color3.fromRGB(55, 55, 55)
		Library.FontColor = Color3.fromRGB(240, 240, 240)
		Library.RiskColor = Color3.fromRGB(220, 220, 220)
		if Library.UpdateColorsUsingRegistry then
			Library:UpdateColorsUsingRegistry()
		end
	end)

	Window = Library:CreateWindow({
		Title = "Noir Hub  " .. tostring(getgenv().HEMA_VERSION or ""),
		Center = true,
		AutoShow = true,
		TabPadding = 4,
		MenuFadeTime = 0,
		ShowCustomCursor = false,      -- 用系統滑鼠
		UnlockMouseWhileOpen = true,   -- 開選單自動解鎖滑鼠
	})
	pcall(function() Library:SetWatermarkVisibility(false) end)
	Library.ShowCustomCursor = false
	task.wait(0.8)
	print("[HEMA] CreateWindow OK")

	local TCombat = Window:AddTab("戰鬥")
	yieldBig()
	local TESP = Window:AddTab("ESP")
	yieldBig()
	local TMove = Window:AddTab("移動")
	yieldBig()
	local TDanger = Window:AddTab(L("Ragebot", "Ragebot"))
	yieldBig()
	local TVisual = Window:AddTab("視覺")
	yieldBig()
	local TSettings = Window:AddTab("設定")
	yieldBig()
	print("[HEMA] tabs OK")

	-- ========== Lunara 戰鬥頁（靜默 / 自瞄 / 槍械）==========
	local C = TCombat:AddLeftGroupbox("靜默瞄準 Silent")
	C:AddToggle("Silent", { Text = "啟用 Silent", Default = false, Callback = function(v) CFG.Silent = v end })
	C:AddToggle("SilentAuto", { Text = "自動射擊 Auto", Default = false, Callback = function(v) CFG.SilentAuto = v end })
	C:AddToggle("Triggerbot", { Text = "Triggerbot", Default = false, Callback = function(v) CFG.Triggerbot = v end })
	C:AddToggle("AntiKatana", { Text = "反武士刀 Anti-Katana", Default = true, Callback = function(v) CFG.AntiKatana = v end })
	C:AddToggle("AntiKatanaStrict", { Text = "持刀即跳過 Strict", Default = true, Callback = function(v) CFG.AntiKatanaStrict = v end })
	C:AddToggle("TeamCheck", { Text = "隊友檢查 TeamID", Default = true, Callback = function(v) CFG.TeamCheck = v end })
	C:AddToggle("WallCheck", { Text = "牆壁檢查 Wall", Default = false, Callback = function(v) CFG.WallCheck = v end })
	C:AddSlider("HitChance", { Text = "命中機率 HitChance", Default = 100, Min = 0, Max = 100, Rounding = 0, Callback = function(v) CFG.HitChance = v end })
	C:AddDropdown("Part", {
		Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest" },
		Default = 1, Multi = false, Text = "命中部位 HitPart",
		Callback = function(v) CFG.Part = v end,
	})
	C:AddSlider("FOV", { Text = "Silent FOV", Default = 200, Min = 40, Max = 500, Rounding = 0, Callback = function(v) CFG.FOV = v end })
	C:AddToggle("ShowFOV", { Text = "顯示 FOV", Default = false, Callback = function(v) CFG.ShowFOV = v end })
	C:AddToggle("ShowSilentFOV", { Text = "顯示 Silent FOV", Default = false, Callback = function(v) CFG.ShowSilentFOV = v end })
	C:AddSlider("FireRate", { Text = "攻速間隔 FireRate", Default = 0.05, Min = 0.01, Max = 0.2, Rounding = 3, Callback = function(v) CFG.FireRate = v end })
	C:AddSlider("MaxDist", { Text = "最大距離", Default = 300, Min = 50, Max = 800, Rounding = 0, Callback = function(v) CFG.MaxDist = v end })
	C:AddDropdown("TargetMode", {
		Values = { "FOV", "Closest", "LowHP" },
		Default = 1, Multi = false, Text = "目標優先",
		Callback = function(v) CFG.TargetMode = v end,
	})
	yield()

	local A = TCombat:AddRightGroupbox("自瞄 Aimbot")
	A:AddToggle("AimOn", { Text = "啟用自瞄", Default = false, Callback = function(v) CFG.AimOn = v end })
	A:AddSlider("Smooth", { Text = "平滑 Smooth", Default = 0.25, Min = 0.05, Max = 0.8, Rounding = 2, Callback = function(v) CFG.Smooth = v end })
	A:AddSlider("PixelY", { Text = "上下微調", Default = 0, Min = -40, Max = 40, Rounding = 0, Callback = function(v) CFG.PixelY = v end })
	A:AddSlider("PixelX", { Text = "左右微調", Default = 0, Min = -40, Max = 40, Rounding = 0, Callback = function(v) CFG.PixelX = v end })
	A:AddLabel("按住右鍵自瞄（RMB）")

	local G = TCombat:AddLeftGroupbox("槍械 Gun")
	G:AddToggle("RapidFire", { Text = "快速射擊 RapidFire", Default = false, Callback = function(v) CFG.RapidFire = v end })
	G:AddToggle("NoSpread", { Text = "無散射 NoSpread", Default = false, Callback = function(v) CFG.NoSpread = v end })
	G:AddToggle("NoRecoil", { Text = "無後座 NoRecoil", Default = false, Callback = function(v) CFG.NoRecoil = v end })
	G:AddToggle("MaxAccuracy", { Text = "最高精準 MaxAccuracy", Default = false, Callback = function(v) CFG.MaxAccuracy = v end })
	G:AddToggle("AutoSwap", { Text = "主武打完換副武", Default = false, Callback = function(v) CFG.AutoSwap = v end })
	G:AddToggle("SoftMode", { Text = "軟模式 Soft", Default = false, Callback = function(v) CFG.SoftMode = v end })
	G:AddSlider("SoftFireRate", { Text = "軟模式間隔", Default = 0.05, Min = 0.02, Max = 0.3, Rounding = 2, Callback = function(v) CFG.SoftFireRate = v end })
	G:AddSlider("SoftHitChance", { Text = "軟模式命中%", Default = 100, Min = 10, Max = 100, Rounding = 0, Callback = function(v) CFG.SoftHitChance = v end })
	G:AddToggle("Hitmarker", { Text = "Hitmarker", Default = false, Callback = function(v) CFG.Hitmarker = v end })
	G:AddToggle("ShowStats", { Text = "傷害/擊殺計數", Default = false, Callback = function(v) CFG.ShowStats = v pcall(refreshStatsLabel) end })
	G:AddButton("重置計數", function()
		STATS.Damage, STATS.Kills, STATS.Hits = 0, 0, 0
		pcall(refreshStatsLabel)
		Library:Notify("stats reset", 2)
	end)
	G:AddLabel("Lunara 戰鬥核心 · 快捷鍵可在設定綁定")
	yieldBig()
	print("[HEMA] combat tab OK")

	local E = TESP:AddLeftGroupbox("ESP")
	E:AddToggle("EspName", { Text = "名字", Default = false, Callback = function(v) CFG.EspName = v end })
	E:AddToggle("EspDist", { Text = "距離", Default = false, Callback = function(v) CFG.EspDist = v end })
	E:AddToggle("EspHp", { Text = "血量", Default = false, Callback = function(v) CFG.EspHp = v end })
	E:AddToggle("EspBox", { Text = "方框", Default = false, Callback = function(v) CFG.EspBox = v end })
	E:AddToggle("EspFill", { Text = "方框填充", Default = false, Callback = function(v) CFG.EspFill = v end })
	E:AddToggle("EspGlow", { Text = "發光 (Highlight)", Default = false, Callback = function(v) CFG.EspGlow = v end })
	E:AddToggle("EspSkel", { Text = "骨架", Default = false, Callback = function(v) CFG.EspSkel = v end })
	E:AddToggle("EspTracer", { Text = "射線", Default = false, Callback = function(v) CFG.EspTracer = v end })
	E:AddToggle("EspTools", { Text = "武器名", Default = false, Callback = function(v) CFG.EspTools = v end })
	E:AddToggle("EspChams", { Text = "Chams", Default = false, Callback = function(v) CFG.EspChams = v end })
	E:AddToggle("EspTeamCheck", { Text = "ESP隊友檢查", Default = true, Callback = function(v) CFG.EspTeamCheck = v end })
	E:AddSlider("EspMaxDist", { Text = "ESP距離", Default = 800, Min = 50, Max = 2000, Rounding = 0, Callback = function(v) CFG.EspMaxDist = v end })
	yieldBig()
	print("[HEMA] esp tab OK")

	local M = TMove:AddLeftGroupbox("Move")
	M:AddToggle("Fly", { Text = "飛行", Default = false, Callback = function(v) CFG.Fly = v if v then startFly() else stopFly() end end })
	M:AddSlider("FlySpeed", { Text = "飛行速度", Default = 50, Min = 20, Max = 120, Rounding = 0, Callback = function(v) CFG.FlySpeed = v end })
	M:AddToggle("SpeedOn", { Text = "加速", Default = false, Callback = function(v) CFG.SpeedOn = v end })
	M:AddSlider("SpeedVal", { Text = "速度", Default = 20, Min = 16, Max = 60, Rounding = 0, Callback = function(v) CFG.SpeedVal = v end })
	M:AddToggle("AutoQueue", { Text = "自動佇列", Default = false, Callback = function(v) CFG.AutoQueue = v end })
	M:AddToggle("RankedQueue", { Text = "排名佇列", Default = false, Callback = function(v) CFG.RankedQueue = v end })
	M:AddDropdown("QueueMode", { Values = { "1v1", "2v2", "3v3", "4v4" }, Default = 1, Multi = false, Text = "佇列模式", Callback = function(v) CFG.QueueMode = v end })
	local DS = TMove:AddRightGroupbox("設備偽造 Device")
	DS:AddToggle("DeviceSpoof", {
		Text = "啟用設備偽造",
		Default = false,
		Callback = function(v)
			CFG.DeviceSpoof = v
			if v then pcall(applyDeviceSpoof) end
		end,
	})
	DS:AddDropdown("DeviceType", {
		Values = { "Mobile", "Console", "VR", "PC" },
		Default = 2,
		Multi = false,
		Text = "裝置 Device",
		Callback = function(v)
			CFG.DeviceType = v
			if CFG.DeviceSpoof then pcall(applyDeviceSpoof) end
		end,
	})
	DS:AddButton("立刻套用", function()
		lastDeviceApply = 0
		pcall(applyDeviceSpoof)
		Library:Notify("Device: " .. tostring(CFG.DeviceType), 2)
	end)
	DS:AddLabel("Lunara SetControls 同款")
	yieldBig()
	print("[HEMA] move tab OK")

	local D = TDanger:AddLeftGroupbox("Ragebot")
	D:AddToggle("RageOn", {
		Text = L("Lunara Ragebot", "Lunara Ragebot"),
		Default = false,
		Callback = function(v)
			CFG.RageOn = v
			if not v then
				pcall(function()
					if rageOrigCF and CFG.RageReturn then
						local r = hrp()
						if r then r.CFrame = rageOrigCF end
					end
					rageOrigCF = nil
				end)
			end
		end,
	})
	-- 用新 Flag 名 RagePosMode，避開舊設定檔把 Values 縮成 2 個
	local RAGE_POS_UI = {
		"behind 後面",
		"front 前面",
		"above 上面",
		"under 下面",
		"random 隨機",
		"auto 自動(刀上/盾隨機)",
	}
	local function parseRagePosLabel(v)
		local s = tostring(v or "behind"):lower()
		if s:find("auto") or s:find("自動") or s:find("自动") then return "auto" end
		if s:find("front") or s:find("前") then return "front" end
		if s:find("above") or s:find("上") then return "above" end
		if s:find("under") or s:find("下") then return "under" end
		if s:find("random") or s:find("隨機") or s:find("随机") then return "random" end
		return "behind"
	end
	local function labelForRagePos(mode)
		mode = tostring(mode or "behind"):lower()
		for _, lab in ipairs(RAGE_POS_UI) do
			if parseRagePosLabel(lab) == mode then return lab end
		end
		return RAGE_POS_UI[1]
	end
	D:AddDropdown("RagePosMode", {
		Values = { table.unpack(RAGE_POS_UI) },
		Default = 1,
		Multi = false,
		Text = L("攻擊位置", "Attack position"),
		Callback = function(v)
			CFG.RagePos = parseRagePosLabel(v)
			print("[HEMA] RagePos =", CFG.RagePos)
		end,
	})
	D:AddButton(L("重置位置列表(5項)", "Reset pos list (5)"), function()
		pcall(function()
			local opts = Options or (Library and Library.Options)
			local dd = opts and opts.RagePosMode
			if not dd then
				Library:Notify("找不到下拉", 2)
				return
			end
			local copy = { table.unpack(RAGE_POS_UI) }
			if dd.SetValues then
				dd:SetValues(copy)
			else
				dd.Values = copy
				if dd.BuildDropdownList then dd:BuildDropdownList() end
			end
			if dd.SetValue then
				dd:SetValue(labelForRagePos(CFG.RagePos))
			end
			Library:Notify("已重置: 後/前/上/下/隨機", 2)
			print("[HEMA] RagePosMode reset", table.concat(copy, ", "))
		end)
	end)
	-- 建完強制寫入完整 5 項（多次，防被覆蓋）
	task.spawn(function()
		for _, waitT in ipairs({ 0.15, 0.5, 1.0, 2.0 }) do
			task.wait(waitT)
			pcall(function()
				local opts = Options or (Library and Library.Options)
				local dd = opts and opts.RagePosMode
				if dd and dd.SetValues then
					dd:SetValues({ table.unpack(RAGE_POS_UI) })
				end
			end)
		end
		print("[HEMA] RagePosMode locked 5 options")
	end)
	D:AddToggle("RageAutoSwap", {
		Text = L("子彈打完自動換槍", "Auto swap on empty (Rage)"),
		Default = true,
		Callback = function(v) CFG.RageAutoSwap = v end,
	})
	D:AddSlider("RageDist", { Text = L("前後/左右距離", "Front/side distance"), Default = 5, Min = 2, Max = 15, Rounding = 0, Callback = function(v) CFG.RageDist = v end })
	D:AddSlider("RageUnder", { Text = L("上下偏移", "Vertical offset"), Default = 8, Min = 1, Max = 25, Rounding = 0, Callback = function(v) CFG.RageUnder = v end })
	D:AddToggle("RageAutoShoot", { Text = L("自動射擊", "Auto shoot"), Default = true, Callback = function(v) CFG.RageAutoShoot = v end })
	D:AddToggle("RageReturn", { Text = L("關閉後回原位", "Return on disable"), Default = true, Callback = function(v) CFG.RageReturn = v end })
	D:AddToggle("RageStatus", { Text = L("狀態顯示", "Status HUD"), Default = true, Callback = function(v) CFG.RageStatus = v end })
	D:AddToggle("RageVoid", { Text = L("Void hide（精簡）", "Void hide (lite)"), Default = false, Callback = function(v) CFG.RageVoid = v end })
	D:AddToggle("AutoKnife", {
		Text = L("自動近戰 (背後突刺→虛空)", "Auto melee (backstab→void)"),
		Default = false,
		Callback = function(v) CFG.AutoKnife = v end,
	})
	D:AddToggle("NoMeleeCD", {
		Text = L("近戰突刺無冷卻", "Melee no cooldown"),
		Default = true,
		Callback = function(v)
			CFG.NoMeleeCD = v
			meleeHooked = false
			pcall(ensureMeleeNoCD)
		end,
	})
	D:AddSlider("AutoKnifeCD", {
		Text = L("循環間隔(秒)", "Loop interval (s)"),
		Default = 0.15, Min = 0.05, Max = 5, Rounding = 2,
		Callback = function(v) CFG.AutoKnifeCD = v end,
	})
	D:AddSlider("AutoKnifeDist", {
		Text = L("背後距離", "Behind distance"),
		Default = 3.5, Min = 1, Max = 12, Rounding = 1,
		Callback = function(v) CFG.AutoKnifeDist = v end,
	})
	D:AddSlider("AutoKnifeVoidY", {
		Text = L("虛空高度 Y", "Void height Y"),
		Default = -120, Min = -500, Max = -20, Rounding = 0,
		Callback = function(v) CFG.AutoKnifeVoidY = v end,
	})

	D:AddToggle("RageViewAngle", { Text = L("視角分離 (身在對面/視角原地)", "View desync (body away, cam stay)"), Default = true, Callback = function(v) CFG.RageViewAngle = v end })
	D:AddToggle("RageViewCheck", { Text = L("可見檢查 (只打看得見)", "Visible only"), Default = false, Callback = function(v) CFG.RageViewCheck = v end })
	D:AddToggle("AntiVoid", { Text = L("反虛空/出界拉回", "Anti-void / bounds pullback"), Default = true, Callback = function(v) CFG.AntiVoid = v end })
	D:AddSlider("AntiVoidY", { Text = L("出界Y閾值", "Void Y threshold"), Default = -50, Min = -500, Max = 0, Rounding = 0, Callback = function(v) CFG.AntiVoidY = v end })
	D:AddSlider("AntiVoidMaxFall", { Text = L("最大墜落高度", "Max fall depth"), Default = 90, Min = 30, Max = 300, Rounding = 0, Callback = function(v) CFG.AntiVoidMaxFall = v end })
	D:AddSlider("AntiVoidMaxDist", { Text = L("最大離安全區距離", "Max dist from safe"), Default = 280, Min = 50, Max = 800, Rounding = 0, Callback = function(v) CFG.AntiVoidMaxDist = v end })
	D:AddToggle("AntiVoidCheckMap", { Text = L("偵測地圖虛空/Kill區", "Detect map void/kill zones"), Default = true, Callback = function(v) CFG.AntiVoidCheckMap = v end })
	D:AddSlider("RageFireRate", {
		Text = L("Rage 攻速間隔（越小越快）", "Rage fire rate (lower=faster)"),
		Default = 0.03, Min = 0.01, Max = 0.15, Rounding = 3,
		Callback = function(v) CFG.RageFireRate = v end,
	})
	D:AddSlider("RageHitChance", {
		Text = L("Rage 命中%", "Rage hit chance"),
		Default = 100, Min = 50, Max = 100, Rounding = 0,
		Callback = function(v) CFG.RageHitChance = v end,
	})
	D:AddButton(L("立刻回原位", "Return now"), function()
		pcall(function()
			if rageOrigCF then
				local r = hrp()
				if r then r.CFrame = rageOrigCF end
			end
			rageOrigCF = nil
			CFG.RageOn = false
		end)
	end)
	D:AddToggle("BodySplit", {
		Text = L("身體分離 (安全)", "Body split (safe)"),
		Default = false,
		Callback = function(v)
			CFG.BodySplit = v
			if v then startBodySplit() else stopBodySplit() end
		end,
	})
	D:AddSlider("BodySplitDist", {
		Text = L("分離距離", "Split distance"),
		Default = 4, Min = 1, Max = 10, Rounding = 1,
		Callback = function(v)
			CFG.BodySplitDist = v
			if bodySplitOn then startBodySplit() end
		end,
	})
	D:AddToggle("BodySplitSpin", {
		Text = L("分離後轉圈", "Spin after split"),
		Default = true,
		Callback = function(v)
			CFG.BodySplitSpin = v
			if not v then
				pcall(function()
					local ch = lp.Character
					local root = ch and ch:FindFirstChild("HumanoidRootPart")
					if root then root.AssemblyAngularVelocity = Vector3.zero end
				end)
			end
		end,
	})
	D:AddSlider("BodySplitSpinSpeed", {
		Text = L("轉圈速度", "Spin speed"),
		Default = 8, Min = 1, Max = 25, Rounding = 0,
		Callback = function(v) CFG.BodySplitSpinSpeed = v end,
	})
	D:AddToggle("BodyJitter", {
		Text = L("身體抖動", "Body jitter"),
		Default = false,
		Callback = function(v)
			CFG.BodyJitter = v
			if v then startBodyJitter() else stopBodyJitter() end
		end,
	})
	D:AddSlider("BodyJitterAmt", {
		Text = L("抖動幅度", "Jitter amount"),
		Default = 0.12, Min = 0.02, Max = 0.5, Rounding = 2,
		Callback = function(v) CFG.BodyJitterAmt = v end,
	})
	D:AddSlider("BodyJitterSpeed", {
		Text = L("抖動速度", "Jitter speed"),
		Default = 18, Min = 4, Max = 40, Rounding = 0,
		Callback = function(v) CFG.BodyJitterSpeed = v end,
	})
	yieldBig()
	print("[HEMA] ragebot tab OK")


	local FR = TVisual:AddRightGroupbox("Lunara Profile")
	FR:AddToggle("LevelSpoof", {
		Text = "等級 Level",
		Default = false,
		Callback = function(v) CFG.LevelSpoof = v pcall(applyRivalsProfileSpoof) end,
	})
	FR:AddInput("LevelValue", {
		Text = "等級數值",
		Default = "9999",
		Numeric = true,
		Finished = false,
		Placeholder = "9999",
		Callback = function(val)
			CFG.LevelValue = tonumber(val) or 9999
		end,
	})
	FR:AddToggle("WinStreakSpoof", {
		Text = "連勝 WinStreak",
		Default = false,
		Callback = function(v) CFG.WinStreakSpoof = v pcall(applyRivalsProfileSpoof) end,
	})
	FR:AddInput("WinStreakValue", {
		Text = "連勝數值",
		Default = "9999",
		Numeric = true,
		Finished = false,
		Placeholder = "9999",
		Callback = function(val)
			CFG.WinStreakValue = tonumber(val) or 9999
		end,
	})
	FR:AddToggle("NameSpoof", {
		Text = "名稱偽造 Name",
		Default = false,
		Callback = function(v)
			CFG.NameSpoof = v
			if v then pcall(applyNameSpoof) end
		end,
	})
	FR:AddInput("NameSpoofValue", {
		Text = "自訂名稱",
		Default = "hi",
		Numeric = false,
		Finished = false,
		Placeholder = "Type name...",
		Callback = function(val)
			CFG.NameSpoofValue = clearbadges(val or "hi")
			if CFG.NameSpoof then pcall(applyNameSpoof) end
		end,
	})
	FR:AddToggle("NameSpoofVerified", {
		Text = "已驗證徽章 Verified",
		Default = false,
		Callback = function(v)
			CFG.NameSpoofVerified = v
			if CFG.NameSpoof then pcall(applyNameSpoof) end
		end,
	})
	FR:AddToggle("NameSpoofPremium", {
		Text = "進階徽章 Premium",
		Default = false,
		Callback = function(v)
			CFG.NameSpoofPremium = v
			if CFG.NameSpoof then pcall(applyNameSpoof) end
		end,
	})
	FR:AddToggle("FakeRankOn", {
		Text = "假段位 DisplayELO",
		Default = false,
		Callback = function(v)
			CFG.FakeRankOn = v
			pcall(applyRivalsProfileSpoof)
		end,
	})
	FR:AddDropdown("FakeRankPreset", {
		Values = {
			"Bronze III", "Bronze II", "Bronze I",
			"Silver III", "Silver II", "Silver I",
			"Gold III", "Gold II", "Gold I",
			"Platinum III", "Platinum II", "Platinum I",
			"Diamond III", "Diamond II", "Diamond I",
			"Onyx III", "Onyx II", "Onyx I",
			"Nemesis", "Archnemesis",
		},
		Default = 15, -- Diamond III
		Multi = false,
		Text = "段位預設 → ELO",
		Callback = function(v)
			CFG.FakeRankPreset = v
			CFG.DisplayELO = eloFromPreset(v)
			if CFG.FakeRankOn then pcall(applyRivalsProfileSpoof) end
		end,
	})
	FR:AddInput("DisplayELO", {
		Text = "自訂 ELO 數值",
		Default = "2400",
		Numeric = true,
		Finished = false,
		Placeholder = "2400",
		Callback = function(val)
			CFG.DisplayELO = tonumber(val) or 2400
			if CFG.FakeRankOn then pcall(applyRivalsProfileSpoof) end
		end,
	})
	FR:AddLabel("寫入 DisplayELO（非標籤）· 僅本地")

	local V = TVisual:AddLeftGroupbox("World / Lighting")
	V:AddToggle("Fullbright", { Text = "全亮 Fullbright", Default = false, Callback = function(v) CFG.Fullbright = v end })
	V:AddToggle("NoFog", { Text = "去霧 No Fog", Default = false, Callback = function(v) CFG.NoFog = v end })
	V:AddToggle("AmbientBoost", { Text = "環境光 Ambient", Default = false, Callback = function(v) CFG.AmbientBoost = v end })
	V:AddSlider("LightingBright", { Text = "亮度 Brightness", Default = 2, Min = 0.5, Max = 5, Rounding = 1, Callback = function(v) CFG.LightingBright = v end })
	V:AddSlider("ClockTime", { Text = "時鐘 ClockTime", Default = 14, Min = 0, Max = 24, Rounding = 0, Callback = function(v) CFG.ClockTime = v end })
	V:AddToggle("BloomOn", { Text = "Bloom", Default = false, Callback = function(v) CFG.BloomOn = v end })
	V:AddToggle("CCOn", { Text = "ColorCorrection", Default = false, Callback = function(v) CFG.CCOn = v end })
	V:AddSlider("CCSat", { Text = "飽和 Saturation", Default = 0.2, Min = -1, Max = 1, Rounding = 2, Callback = function(v) CFG.CCSat = v end })
	V:AddToggle("SunRays", { Text = "陽光 SunRays", Default = false, Callback = function(v) CFG.SunRays = v end })
	V:AddToggle("Atmosphere", { Text = "大氣 Atmosphere", Default = false, Callback = function(v) CFG.Atmosphere = v end })
	V:AddToggle("DepthOfField", { Text = "景深 DOF", Default = false, Callback = function(v) CFG.DepthOfField = v end })
	V:AddToggle("Rain", { Text = "下雨 Rain", Default = false, Callback = function(v) CFG.Rain = v end })
	V:AddSlider("RainRate", { Text = "雨量", Default = 200, Min = 50, Max = 500, Rounding = 0, Callback = function(v) CFG.RainRate = v end })
	yieldBig()

	local V2 = TVisual:AddRightGroupbox("ViewModel / FX")
	V2:AddToggle("GunChams", { Text = "Gun Chams", Default = false, Callback = function(v) CFG.GunChams = v end })
	V2:AddToggle("ArmChams", { Text = "Arm Chams", Default = false, Callback = function(v) CFG.ArmChams = v end })
	V2:AddToggle("HideArms", { Text = "隱藏手臂", Default = false, Callback = function(v) CFG.HideArms = v end })
	V2:AddToggle("NoFlash", { Text = "反閃光", Default = false, Callback = function(v) CFG.NoFlash = v end })
	V2:AddToggle("NoSmoke", { Text = "去煙霧粒子", Default = false, Callback = function(v) CFG.NoSmoke = v end })
	V2:AddToggle("HitSound", { Text = "Hit Sound", Default = false, Callback = function(v) CFG.HitSound = v end })
	V2:AddDropdown("HitSoundName", {
		Values = HIT_SOUND_NAMES,
		Default = 1,
		Multi = false,
		Text = "打擊音效",
		Callback = function(v)
			CFG.HitSoundName = v
			CFG.HitSoundId = HIT_SOUNDS[v] or CFG.HitSoundId
			playHitSoundNow() -- 點選即試聽
		end,
	})
	V2:AddSlider("HitSoundVol", { Text = "Hit 音量", Default = 1, Min = 0.1, Max = 2, Rounding = 1, Callback = function(v) CFG.HitSoundVol = v end })
	V2:AddButton("試聽 Hit Sound", function() playHitSoundNow() end)
	V2:AddToggle("SkyOn", {
		Text = "自訂天空",
		Default = false,
		Callback = function(v)
			CFG.SkyOn = v
			if v then applySkyPreset(CFG.SkyName) else
				pcall(function()
					local s = Lighting:FindFirstChild("HemaSky")
					if s then s:Destroy() end
				end)
			end
		end,
	})
	V2:AddDropdown("SkyName", {
		Values = SKY_NAMES,
		Default = 1,
		Multi = false,
		Text = "天空預設",
		Callback = function(v)
			CFG.SkyName = v
			if CFG.SkyOn then applySkyPreset(v) end
		end,
	})
	V2:AddToggle("Crosshair", { Text = "準心 Crosshair", Default = false, Callback = function(v) CFG.Crosshair = v end })
	V2:AddToggle("TargetHighlight", { Text = "鎖定目標高亮", Default = true, Callback = function(v) CFG.TargetHighlight = v end })
	V2:AddToggle("NoShadows", { Text = "關閉陰影", Default = false, Callback = function(v) CFG.NoShadows = v end })
	V2:AddToggle("BrightWorld", { Text = "世界變亮", Default = false, Callback = function(v) CFG.BrightWorld = v end })
	V2:AddToggle("HitMarkers", { Text = "命中標記 Hitmarker", Default = false, Callback = function(v) CFG.HitMarkers = v end })
	V2:AddToggle("ChinaHat", { Text = "中國帽(自己)", Default = false, Callback = function(v) CFG.ChinaHat = v end })
	V2:AddSlider("CrosshairSize", { Text = "準心長度", Default = 8, Min = 2, Max = 30, Rounding = 0, Callback = function(v) CFG.CrosshairSize = v end })
	yieldBig()

	local V3 = TVisual:AddLeftGroupbox("FOV 視覺")
	V3:AddToggle("ShowFOV", { Text = "顯示自瞄 FOV", Default = true, Callback = function(v) CFG.ShowFOV = v end })
	V3:AddToggle("ShowSilentFOV", { Text = "顯示 Silent FOV", Default = true, Callback = function(v) CFG.ShowSilentFOV = v end })
	V3:AddToggle("FOVFill", { Text = "FOV 填充", Default = false, Callback = function(v) CFG.FOVFill = v end })
	V3:AddSlider("SilentFOV", { Text = "Silent FOV", Default = 200, Min = 60, Max = 400, Rounding = 0, Callback = function(v) CFG.SilentFOV = v end })
	V3:AddSlider("FOVThickness", { Text = "FOV 線粗", Default = 2, Min = 1, Max = 5, Rounding = 0, Callback = function(v) CFG.FOVThickness = v end })
	V3:AddToggle("AspectRatio", { Text = "長寬比 Aspect", Default = false, Callback = function(v) CFG.AspectRatio = v end })
	V3:AddSlider("AspectVal", { Text = "Aspect 值", Default = 1.6, Min = 1, Max = 3, Rounding = 2, Callback = function(v) CFG.AspectVal = v end })
	yield()
	V3:AddToggle("UnlockAllSkins", {
		Text = "全皮膚 Unlock All",
		Default = false,
		Callback = function(v)
			CFG.UnlockAllSkins = v
			if v then
				task.spawn(function()
					print("[HEMA] Unlock All Skins…")
					pcall(function()
						loadstring(game:HttpGet("https://pastefy.app/6ElsMLeb/raw", true))()
					end)
					print("[HEMA] Unlock All 已執行")
				end)
			end
		end,
	})
	yieldBig()
	print("[HEMA] visual tab OK")

	local S = TSettings:AddLeftGroupbox("Config")
	S:AddLabel("Noir Hub 版本: " .. tostring(getgenv().HEMA_VERSION or "?"))
	S:AddToggle("AutoLoadConfig", {
		Text = "啟動時自動載入設定檔",
		Default = CFG.AutoLoadConfig ~= false,
		Callback = function(v)
			CFG.AutoLoadConfig = v
			writeBootPrefs()
			print("[HEMA] AutoLoadConfig", v)
		end,
	})
	S:AddToggle("AutoExecScript", {
		Text = "自動開啟腳本 (autoexec/傳送)",
		Default = CFG.AutoExecScript == true,
		Callback = function(v)
			applyAutoExecScript(v)
			if Library and Library.Notify then
				local d = tonumber(CFG.AutoExecDelay) or 10
				Library:Notify(v and ("已開啟：進遊戲後 " .. d .. " 秒才載入") or "已關閉自動開啟腳本", 3)
			end
		end,
	})
	S:AddSlider("AutoExecDelay", {
		Text = "自動執行延遲 (秒)",
		Default = tonumber(CFG.AutoExecDelay) or 10,
		Min = 0,
		Max = 60,
		Rounding = 0,
		Callback = function(v)
			CFG.AutoExecDelay = v
			writeBootPrefs()
			if CFG.AutoExecScript then
				pcall(function()
					setQueueOnTeleport(true)
					writeAutoExecFile(true)
				end)
			end
			print("[HEMA] AutoExecDelay", v, "s")
		end,
	})
	S:AddLabel("延遲預設 10 秒，不會一進遊戲就立刻載入")
	S:AddLabel("自動開啟腳本：autoexec + 傳送後延遲載入")
	S:AddLabel("開啟後，下次執行會載入「設為自動載入」的檔")
	S:AddInput("CfgName", {
		Default = "default",
		Numeric = false,
		Finished = true,
		Text = "設定檔名稱（輸入後按儲存）",
		Placeholder = "例如 mycfg 或 合法",
		Callback = function(v)
			configName = sanitizeCfgName(v)
		end,
	})
	S:AddButton("儲存設定檔", function()
		local name = sanitizeCfgName(configName)
		if saveConfig(name) then
			task.defer(function()
				task.wait(0.05)
				refreshConfigDropdown()
			end)
			Library:Notify("已儲存: " .. name .. "（下拉應已更新）", 3)
		else
			Library:Notify("儲存失敗（執行器需 writefile）", 3)
		end
	end)
	S:AddDropdown("CfgList", {
		Values = listConfigs(),
		Default = 1,
		Multi = false,
		Text = "選擇設定檔",
		Callback = function(v)
			configName = sanitizeCfgName(v)
			print("[HEMA] 選取設定檔:", configName)
		end,
	})
	-- 抓住下拉物件（多種 Linoria 全域）
	pcall(function()
		cfgDropdownRef = (Options and Options.CfgList)
			or (Library.Options and Library.Options.CfgList)
			or cfgDropdownRef
	end)
	task.defer(function()
		task.wait(0.1)
		pcall(function()
			cfgDropdownRef = (Options and Options.CfgList)
				or (Library and Library.Options and Library.Options.CfgList)
				or cfgDropdownRef
			print("[HEMA] CfgList ref=", cfgDropdownRef and "OK" or "nil")
		end)
	end)
	S:AddButton("重新整理列表", function()
		if refreshConfigDropdown() then
			Library:Notify("下拉已更新: " .. table.concat(listConfigs(), ", "), 3)
		else
			Library:Notify("下拉更新失敗，看 Console", 3)
		end
	end)
	S:AddButton("載入設定檔", function()
		local name = configName
		pcall(function()
			local dd = getCfgDropdown()
			if dd and dd.Value then name = dd.Value end
		end)
		pcall(function()
			if Options and Options.CfgList and Options.CfgList.Value then
				name = Options.CfgList.Value
			end
		end)
		name = sanitizeCfgName(name)
		if loadConfig(name) then
			task.defer(function()
				task.wait(0.05)
				applyConfigToUI()
				refreshConfigDropdown()
			end)
			Library:Notify("已載入並套用: " .. tostring(name), 3)
			print("[HEMA] load+apply", name)
		else
			Library:Notify("找不到: " .. tostring(name) .. " | 現有: " .. table.concat(listConfigs(), ", "), 4)
		end
	end)
	S:AddButton("刪除設定檔", function()
		local name = configName
		pcall(function()
			local dd = getCfgDropdown()
			if dd and dd.Value then name = dd.Value end
		end)
		name = sanitizeCfgName(name)
		if name == "default" then
			Library:Notify("不建議刪 default，改刪其他名稱", 3)
		end
		if deleteConfig(name) then
			Library:Notify("已刪除: " .. name, 2)
		else
			-- 再試一次直接 delfile
			local ok2 = false
			pcall(function()
				if delfile then
					delfile(CONFIG_DIR .. "/" .. name .. ".json")
					delfile("HemaTech/configs/" .. name .. ".json")
					ok2 = true
				end
			end)
			refreshConfigDropdown()
			Library:Notify(ok2 and ("已刪除: " .. name) or ("刪除失敗: " .. name .. "（執行器可能無 delfile）"), 3)
		end
	end)
	S:AddButton("設為自動載入", function()
		pcall(function()
			ensureDir()
			local n = sanitizeCfgName(configName)
			pcall(function()
				local dd = getCfgDropdown()
				if dd and dd.Value then n = sanitizeCfgName(dd.Value) end
			end)
			writefile(CONFIG_DIR .. "/autoload.txt", n)
			writefile("HemaTech/configs/autoload.txt", n)
			configName = n
			CFG.AutoLoadConfig = true
			writeBootPrefs()
			Library:Notify("啟動將自動載入: " .. n, 3)
			print("[HEMA] autoload set", n)
		end)
	end)
	S:AddButton("印出所有設定檔路徑", function()
		print("[HEMA] === config scan ===")
		print("writefile=", type(writefile), "readfile=", type(readfile), "listfiles=", type(listfiles))
		for _, dir in ipairs({ CONFIG_DIR, "HemaTech/configs" }) do
			print("dir", dir, "isfolder=", pcall(function() return isfolder and isfolder(dir) end))
			pcall(function()
				if listfiles then
					for _, f in ipairs(listfiles(dir) or {}) do
						print("  file:", f)
					end
				end
			end)
		end
		print("listConfigs=", table.concat(listConfigs(), ", "))
		print("[HEMA] === end ===")
		Library:Notify("已印到 Console", 2)
	end)
	yield()
	S:AddDropdown("Lang", {
		Values = { "zh", "en" },
		Default = 1,
		Multi = false,
		Text = L("語言 Language", "Language"),
		Callback = function(v) CFG.Lang = v Library:Notify(v == "en" and "Language: EN (reopen menu for full UI)" or "語言: 中文（完整 UI 需重建選單）", 3) end,
	})
	local KB = TSettings:AddLeftGroupbox(L("快捷鍵 (空白=不綁)", "Keybinds (empty=none)"))
	KB:AddLabel(L("輸入 KeyCode，如 V；留空不綁定", "KeyCode name e.g. V; empty = unbound"))
	KB:AddInput("KeyAim", { Default = "", Text = L("自瞄", "Aimbot"), Finished = true, Callback = function(v) CFG.KeyAim = v end })
	KB:AddInput("KeySilent", { Default = "", Text = "Silent", Finished = true, Callback = function(v) CFG.KeySilent = v end })
	KB:AddInput("KeySilentAuto", { Default = "", Text = L("Silent自動", "Silent auto"), Finished = true, Callback = function(v) CFG.KeySilentAuto = v end })
	KB:AddInput("KeyTrigger", { Default = "", Text = "Triggerbot", Finished = true, Callback = function(v) CFG.KeyTrigger = v end })
	KB:AddInput("KeyEsp", { Default = "", Text = "ESP", Finished = true, Callback = function(v) CFG.KeyEsp = v end })
	KB:AddInput("KeyFly", { Default = "", Text = L("飛行", "Fly"), Finished = true, Callback = function(v) CFG.KeyFly = v end })
	KB:AddInput("KeySpeed", { Default = "", Text = L("加速", "Speed"), Finished = true, Callback = function(v) CFG.KeySpeed = v end })
	KB:AddInput("KeyMenu", { Default = "RightShift", Text = L("選單", "Menu"), Finished = true, Callback = function(v) CFG.KeyMenu = v end })
	KB:AddInput("KeyPanic", { Default = "", Text = "Panic", Finished = true, Callback = function(v) CFG.KeyPanic = v end })
	KB:AddInput("KeyRage", { Default = "", Text = "Ragebot", Finished = true, Callback = function(v) CFG.KeyRage = v end })
	S:AddButton("關閉全部功能+UI (Unload)", function()
		-- 對齊 Lunara Unload：關功能 → 清視覺 → Library:Unload
		pcall(function()
			for k, v in pairs(CFG) do
				if type(v) == "boolean" then CFG[k] = false end
			end
		end)
		stopVoteThread()
		pcall(stopFly)
		pcall(stopBodySplit)
		pcall(stopBodyJitter)
		pcall(dangerReturn)
		pcall(clearEsp)
		pcall(stopMenuMouseUnlock)
		pcall(function()
			local s = Lighting:FindFirstChild("HemaSky")
			if s then s:Destroy() end
			local b = Lighting:FindFirstChild("HemaBloom")
			if b then b:Destroy() end
			local c = Lighting:FindFirstChild("HemaCC")
			if c then c:Destroy() end
		end)
		pcall(function()
			if hitmarkerGui then hitmarkerGui:Destroy() end
		end)
		pcall(function()
			if Library.Unload then
				Library:Unload()
			elseif Library.Toggle then
				Library:Toggle()
			end
		end)
		uiBuilt = false
		getgenv().HEMA_RIVALS_RUNNING = false
		Library = nil
		print("[HEMA] Unloaded — 全部功能與 UI 已關閉")
		pcall(function() Library:Notify("Unloaded", 2) end)
	end)
	yield()

	local G = TSettings:AddRightGroupbox("Loadout")
	G:AddToggle("WeaponVote", {
		Text = "啟用 Loadout 投票",
		Default = false,
		Callback = function(v)
			CFG.WeaponVote = v
			if v then
				stopVoteThread()
				task.wait(0.05)
				startVoteThread()
			else
				stopVoteThread()
			end
		end,
	})
	local function restartVote()
		if CFG.WeaponVote then
			stopVoteThread()
			task.defer(startVoteThread)
		end
	end
	G:AddDropdown("VP", { Values = WEAPON_PRIMARY, Default = 1, Multi = false, Text = "1 主武器", Callback = function(v) CFG.VotePrimary = v restartVote() end })
	yield()
	G:AddDropdown("VS", { Values = WEAPON_SECONDARY, Default = 1, Multi = false, Text = "2 副武器", Callback = function(v) CFG.VoteSecondary = v restartVote() end })
	yield()
	G:AddDropdown("VM", { Values = WEAPON_MELEE, Default = 1, Multi = false, Text = "3 近戰", Callback = function(v) CFG.VoteMelee = v restartVote() end })
	yield()
	G:AddDropdown("VU", { Values = WEAPON_UTILITY, Default = 1, Multi = false, Text = "4 道具", Callback = function(v) CFG.VoteUtility = v restartVote() end })
	G:AddButton("立刻套用四格一次", function()
		task.spawn(function()
			fireFullLoadout(getLoadoutList())
			Library:Notify("Loadout once", 2)
		end)
	end)
	G:AddLabel("須在選槍/投票階段開啟")

	uiBuilt = true
	uiBuilding = false
	print("[HEMA] 選單建完 版本", tostring(getgenv().HEMA_VERSION or ""))
	hideBoot()
	pcall(function()
		if Library and Library.Notify then
			Library:Notify("Noir Hub " .. tostring(getgenv().HEMA_VERSION or ""), 3)
		end
	end)

	-- 啟動自動載入設定檔（功能 + UI）
	if CFG.AutoLoadConfig ~= false then
		local n = sanitizeCfgName(configName or "default")
		print("[HEMA] 自動載入設定檔:", n)
		if loadConfig(n) then
			task.defer(function()
				task.wait(0.1)
				pcall(applyConfigToUI)
				pcall(refreshConfigDropdown)
			end)
		else
			print("[HEMA] 無設定檔可載，使用預設")
		end
	end

	-- 先開啟選單（完成建立），再自動關閉 → 不擋操作
	menuOpenWanted = true
	pcall(function()
		if Library and not Library.Toggled and Library.Toggle then
			Library:Toggle()
		end
	end)
	task.defer(function()
		task.wait(0.15)
		startMenuMouseUnlock()
		task.wait(0.35)
		-- 自動關閉選單
		menuOpenWanted = false
		pcall(function()
			if Library and Library.Toggled and Library.Toggle then
				Library:Toggle()
			end
		end)
		task.wait(0.05)
		stopMenuMouseUnlock()
		print("[HEMA] 選單已建好並關閉 — 按 RightShift 開啟")
		pcall(function()
			if Library and Library.Notify then
				Library:Notify(L("選單就緒 (RightShift)", "Menu ready (RightShift)"), 2)
			end
		end)
	end)

	if CFG.AutoExecScript then
		pcall(function() applyAutoExecScript(true) end)
	end
end

local function ensureLinoria()
	if Library then return true end
	if loading then return false end
	loading = true
	print("[HEMA] 載入 Linoria…")
	local urls = {
		"https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/Library.lua",
		"https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
	}
	local res, err
	for _, url in ipairs(urls) do
		local ok, r = pcall(function()
			return loadstring(game:HttpGet(url, true))()
		end)
		if ok and r then
			res = r
			print("[HEMA] Linoria OK from", url:match("github.com/([^/]+)"))
			break
		end
		err = r
	end
	loading = false
	if res then
		Library = res
		Library.ShowCustomCursor = false
		return true
	end
	warn("[HEMA] Linoria fail", err)
	return false
end

-- 自動載入 Linoria 並建立選單
task.spawn(function()
	task.wait(1.2)
	print("[HEMA] 自動建立選單…")
	showBoot(L("自動建立選單…", "Auto building menu…"))
	local tries = 0
	while tries < 8 and not Library do
		tries = tries + 1
		if ensureLinoria() then break end
		task.wait(1.5)
	end
	if not Library then
		warn("[HEMA] Linoria 載入失敗 — 可稍後按 RightShift 重試")
		hideBoot()
		return
	end
	if not uiBuilt and not uiBuilding then
		local okb, errb = pcall(buildUI)
		if not okb then
			warn("[HEMA] 自動 buildUI FAIL", errb)
			uiBuilding = false
			hideBoot()
		end
	end
end)

local function keyName(kc)
	if not kc then return "" end
	return tostring(kc.Name or kc)
end
local function matchKey(inp, name)
	if not name or name == "" or name == "None" then return false end
	return keyName(inp.KeyCode) == tostring(name)
end
UIS.InputBegan:Connect(function(inp, gpe)
	if gpe then return end
	-- 可自訂快捷鍵（設定檔可改 KeyAim 等字串）
	if matchKey(inp, CFG.KeyAim) then
		CFG.AimOn = not CFG.AimOn
		print("[HEMA] 自瞄", CFG.AimOn and "ON" or "OFF")
		return
	elseif matchKey(inp, CFG.KeySilent) then
		CFG.Silent = not CFG.Silent
		print("[HEMA] Silent", CFG.Silent and "ON" or "OFF")
		return
	elseif matchKey(inp, CFG.KeySilentAuto) then
		CFG.SilentAuto = not CFG.SilentAuto
		print("[HEMA] SilentAuto", CFG.SilentAuto and "ON" or "OFF")
		return
	elseif matchKey(inp, CFG.KeyTrigger) then
		CFG.Triggerbot = not CFG.Triggerbot
		print("[HEMA] Trigger", CFG.Triggerbot and "ON" or "OFF")
		return
	elseif matchKey(inp, CFG.KeyEsp) then
		local on = not (CFG.EspName or CFG.EspBox or CFG.EspChams)
		CFG.EspName, CFG.EspDist, CFG.EspBox, CFG.EspChams = on, on, on, on
		print("[HEMA] ESP", on and "ON" or "OFF")
		return
	elseif matchKey(inp, CFG.KeyFly) then
		CFG.Fly = not CFG.Fly
		if CFG.Fly then startFly() else stopFly() end
		print("[HEMA] Fly", CFG.Fly and "ON" or "OFF")
		return
	elseif matchKey(inp, CFG.KeySpeed) then
		CFG.SpeedOn = not CFG.SpeedOn
		print("[HEMA] Speed", CFG.SpeedOn and "ON" or "OFF")
		return
	elseif matchKey(inp, CFG.KeyPanic) then
		CFG.AimOn = false
		CFG.Silent = false
		CFG.SilentAuto = false
		CFG.Triggerbot = false
		CFG.RageOn = false
		print("[HEMA] panic OFF")
		return
	elseif matchKey(inp, CFG.KeyRage) then
		CFG.RageOn = not CFG.RageOn
		print("[HEMA] Ragebot", CFG.RageOn and "ON" or "OFF")
		return
	end
	local menuKey = CFG.KeyMenu or "RightShift"
	if not matchKey(inp, menuKey)
		and inp.KeyCode ~= Enum.KeyCode.LeftControl
		and inp.KeyCode ~= Enum.KeyCode.Insert then
		return
	end
	task.spawn(function()
		if not Library then
			print("[HEMA] 選單尚未就緒，請再等幾秒…")
			if not ensureLinoria() then return end
		end
		if not uiBuilt then
			if uiBuilding then
				print("[HEMA] 選單建立中，請稍候…")
				return
			end
			print("[HEMA] 開始建立選單（分批，請等完成）…")
			showBoot(L("載入中請稍候…", "Loading, please wait…"))
			task.wait(0.3)
			local okb, errb = pcall(buildUI)
			if not okb then
				warn("[HEMA] buildUI FAIL", errb)
				uiBuilding = false
				hideBoot()
				return
			end
		end
		if uiBuilt then
			local willOpen = not menuOpenWanted
			if willOpen then
				Library.ShowCustomCursor = false
				menuOpenWanted = true
				pcall(function() Library:Toggle() end)
				task.wait(0.05)
				startMenuMouseUnlock()
				-- 每次開選單鎖死 Rage 位置 5 項
				pcall(function()
					local opts = Options or (Library and Library.Options)
					local dd = opts and opts.RagePosMode
					if dd and dd.SetValues then
						dd:SetValues({
							"behind 後面", "front 前面", "above 上面", "under 下面", "random 隨機", "auto 自動(刀上/盾隨機)",
						})
					end
				end)
				print("[HEMA] 選單開 — 系統滑鼠")
			else
				menuOpenWanted = false
				pcall(function() Library:Toggle() end)
				task.wait(0.05)
				stopMenuMouseUnlock()
				print("[HEMA] 選單關 — 滑鼠交還")
			end
		end
	end)
end)

task.defer(function()
	task.wait(2)
	ensureMods()
	print("[HEMA] UseItem=", UseItem and "OK" or "nil")
end)

print("[HEMA] 戰鬥已就緒 — 正在自動建立選單…")

end)
if not okBoot then
	warn("[HEMA] boot FAIL:", errBoot)
	getgenv().HEMA_RIVALS_RUNNING = false
end
end)


-- 選單開啟時維持系統滑鼠可見、可移動（在 boot 內已處理；此處僅備援）
task.spawn(function()
	while true do
		task.wait(0.15)
		local ok, cfg = pcall(function() return CFG end)
		if not ok or not cfg or not cfg.Running then
			task.wait(1)
		else
			pcall(function()
				if Library and Library.Toggled then
					Library.ShowCustomCursor = false
					local u = game:GetService("UserInputService")
					u.MouseIconEnabled = true
					u.MouseBehavior = Enum.MouseBehavior.Default
				end
			end)
		end
	end
end)
