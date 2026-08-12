print("[HEMA] loading")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer
if not lp then
	lp = Players.PlayerAdded:Wait()
end

local CFG = {
	Silent = false,
	SilentAuto = false,
	Aimbot = false,
	Rage = false,
	FOV = 150,
	Smooth = 0.3,
	HitChance = 100,
	FireRate = 0.06,
	NoSpread = false,
	NoRecoil = false,
	TeamCheck = true,
	AntiKatana = false,
	AntiShield = false,
	WallCheck = false,
	Wallbang = true,
	-- ESP (對齊原腳本功能)
	ESP_Box = false,
	ESP_Name = false,
	ESP_Distance = false,
	ESP_Tracer = false,
	ESP_Chams = false,
	ESP_Health = false,
	ESP_Team = true, -- 隱藏隊友
	AutoSwap = false,
	DangerRage = false,
	DangerTP = true,
	DangerSpeed = true,
	DangerTPDist = 4,
	RapidFire = false,
	PerfMode = false,      -- 效能模式
	Triggerbot = false,    -- 準星碰到才打
	BodyDesync = false,    -- 身體分離／躲避
	DesyncAmount = 6,      -- 分離幅度（更快更大）
	DesyncSpeed = 28,      -- 分離速度
	AntiVoid = true,       -- 防出界
	AttackSpeed = true,    -- 槍攻速
	AttackRate = 0.02,     -- 射速間隔
	AntiAim = false,       -- Anti Aim
	AAMode = "spin",       -- spin / jitter
	AASpeed = 360,         -- 轉速
	SSHitbox = false,      -- Server-side 風格 hitbox 放大
	SSHitboxSize = 5,      -- 放大倍率相關
	AutoQueue = false,
	QueueMode = "1v1", -- 1v1..5v5
	QueueRanked = false,
	UnlockAll = false,
}

-- 手機 / 電腦偵測
local IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled
local IS_PC = (UIS.KeyboardEnabled or UIS.MouseEnabled) and not IS_MOBILE
if UIS.KeyboardEnabled and UIS.TouchEnabled then
	-- 平板／模擬器：有鍵盤當電腦
	IS_PC = true
	IS_MOBILE = false
end
print("[HEMA] platform PC=", IS_PC, "Mobile=", IS_MOBILE)

-- 按鍵綁定（僅電腦使用）KeyCode.Name -> CFG key
local Keybinds = {
	-- 預設綁定，可在 UI 點擊後改
	Silent = Enum.KeyCode.Q,
	SilentAuto = nil,
	Triggerbot = Enum.KeyCode.T,
	Aimbot = Enum.KeyCode.E,
	Rage = Enum.KeyCode.R,
	DangerRage = Enum.KeyCode.F,
	NoSpread = nil,
	NoRecoil = nil,
	AttackSpeed = nil,
	ESP_Box = Enum.KeyCode.B,
	ESP_Name = nil,
	ESP_Chams = Enum.KeyCode.C,
	PerfMode = nil,
	BodyDesync = Enum.KeyCode.X,
	AntiAim = Enum.KeyCode.Z,
	SSHitbox = nil,
	AntiVoid = nil,
	Wallbang = nil,
	AntiKatana = nil,
	AntiShield = nil,
	WallCheck = nil,
	TeamCheck = nil,
	AutoSwap = nil,
}

local waitingBindFor = nil -- CFG key waiting for next key press

local function keyName(kc)
	if not kc then return "None" end
	return tostring(kc.Name)
end

-- 武士刀格擋中的玩家（對齊原腳本 katanausers）
local katanausers = {}
local shieldusers = {}

local function getParent()
	local p
	pcall(function()
		p = game:GetService("CoreGui")
	end)
	if not p then
		p = lp:WaitForChild("PlayerGui", 10)
	end
	return p
end

local function toScreen(pos)
	local cam = workspace.CurrentCamera
	if not cam then
		return nil, false
	end
	local v, on = cam:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), on and v.Z > 0
end

local function cursor()
	local cam = workspace.CurrentCamera
	if UIS.TouchEnabled and not UIS.KeyboardEnabled then
		return cam and Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2) or Vector2.zero
	end
	return UIS:GetMouseLocation()
end

local function enemy(plr)
	if plr == lp then
		return false
	end
	if CFG.TeamCheck and lp.Team and plr.Team and lp.Team == plr.Team then
		return false
	end
	return true
end

local function alive(plr)
	local c = plr.Character
	if not c then
		return false
	end
	local h = c:FindFirstChildOfClass("Humanoid")
	local r = c:FindFirstChild("HumanoidRootPart")
	return h and r and h.Health > 0 and not c:FindFirstChildOfClass("ForceField")
end

local function hitPart(char)
	return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso")
end

local function nameHas(str, list)
	local s = string.lower(tostring(str or ""))
	for _, n in ipairs(list) do
		if s:find(string.lower(n), 1, true) then
			return true
		end
	end
	return false
end

-- 角色是否拿著刀/盾（裝備中）
local function equippedName(plr)
	local c = plr.Character
	if not c then
		return nil
	end
	for _, ch in ipairs(c:GetChildren()) do
		if ch:IsA("Tool") then
			return ch.Name
		end
	end
	-- 部分遊戲用 Model 當武器
	for _, ch in ipairs(c:GetChildren()) do
		if ch:IsA("Model") and (nameHas(ch.Name, { "katana", "shield", "riot" })) then
			return ch.Name
		end
	end
	return nil
end

local function isKatanaBlocked(plr)
	-- 正在格擋（模組 hook）
	if katanausers[plr] then
		return true
	end
	-- 備援：拿著武士刀就跳過（模組沒掛到時仍可用）
	local n = equippedName(plr)
	if n and nameHas(n, { "katana", "武士刀", "카타나", "katan" }) then
		return true
	end
	local c = plr.Character
	if c then
		for _, d in ipairs(c:GetDescendants()) do
			local dn = string.lower(d.Name)
			if dn:find("katana", 1, true) then
				-- 若有格擋相關特效/值
				if d:IsA("BoolValue") and d.Name:lower():find("deflect") and d.Value then
					return true
				end
				if d:IsA("Tool") or d:IsA("Model") then
					return true
				end
			end
		end
	end
	return false
end

local function isShieldBlocked(plr)
	if shieldusers[plr] then
		return true
	end
	local n = equippedName(plr)
	if n and nameHas(n, { "shield", "riot", "盾", "방패" }) then
		return true
	end
	local c = plr.Character
	if c then
		for _, d in ipairs(c:GetDescendants()) do
			if d:IsA("BasePart") or d:IsA("Model") or d:IsA("Tool") then
				if nameHas(d.Name, { "riotshield", "riot_shield", "shield" }) then
					return true
				end
			end
		end
	end
	return false
end

-- 牆壁可視

-- ===================== 對局／開局判斷（對齊原腳本 liveMatch）=====================
local MATCH_ID_ATTRS = { "MatchId", "DuelId", "RoundId", "GameId", "MatchUUID", "ArenaId", "InstanceId" }
local DUEL_STATE_ATTRS = { "InDuel", "InMatch", "InRound", "InGame", "InFight", "IsInMatch", "IsInDuel", "MatchActive", "Fighting" }
local SPAWN_SAFE_ATTRS = { "InSpawn", "InLobby", "IsSpectating", "InSafeZone", "InIntermission", "IsRespawning" }

local function attrTrue(inst, key)
	if not inst then return false end
	local v = inst:GetAttribute(key)
	return v == true or v == 1 or v == "true"
end

local function inLive(targetPlr)
	if not targetPlr then return false end
	local live = workspace:FindFirstChild("Live")
	if not live then return false end
	if live:FindFirstChild(targetPlr.Name) or live:FindFirstChild(tostring(targetPlr.UserId)) then
		return true
	end
	local char = targetPlr.Character
	if char and (char.Parent == live or char:IsDescendantOf(live)) then
		return true
	end
	return false
end

local function plrMatchId(targetPlr)
	if not targetPlr then return nil end
	for _, key in ipairs(MATCH_ID_ATTRS) do
		local v = targetPlr:GetAttribute(key)
		if v ~= nil and v ~= "" and v ~= 0 and v ~= false then
			return tostring(v)
		end
	end
	local char = targetPlr.Character
	if char then
		for _, key in ipairs(MATCH_ID_ATTRS) do
			local v = char:GetAttribute(key)
			if v ~= nil and v ~= "" and v ~= 0 and v ~= false then
				return tostring(v)
			end
		end
	end
	return nil
end

local function liveMatch()
	-- 大廳／等待／觀戰 → 否
	for _, key in ipairs(SPAWN_SAFE_ATTRS) do
		if attrTrue(lp, key) then return false end
	end
	local char = lp.Character
	if not char then return false end
	for _, key in ipairs(SPAWN_SAFE_ATTRS) do
		if attrTrue(char, key) then return false end
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not root then return false end

	-- 明確對局屬性
	for _, key in ipairs(DUEL_STATE_ATTRS) do
		if attrTrue(lp, key) or attrTrue(char, key) then
			return true
		end
	end

	-- 在 Live 資料夾（對局實體）
	if inLive(lp) then
		return true
	end

	-- 與他人同 MatchId
	local myId = plrMatchId(lp)
	if myId then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp and plrMatchId(plr) == myId then
				return true
			end
		end
	end

	return false
end

-- 暫時關閉對局限制（過嚴會完全打不到）
local function canCombat()
	return true
end

local function validTarget(plr)
	return enemy(plr) and alive(plr)
end


local function isVisible(part)
	local cam = workspace.CurrentCamera
	local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	local origin = (cam and cam.CFrame.Position) or (myRoot and myRoot.Position)
	if not origin then
		return true
	end
	local target = part.Position
	local dir = target - origin
	local dist = dir.Magnitude
	if dist < 0.5 then
		return true
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {}
	if lp.Character then
		table.insert(filter, lp.Character)
	end
	if part.Parent then
		table.insert(filter, part.Parent)
	end
	params.FilterDescendantsInstances = filter
	params.IgnoreWater = true
	local res = workspace:Raycast(origin, dir.Unit * (dist + 1), params)
	if not res then
		return true
	end
	if part.Parent and res.Instance:IsDescendantOf(part.Parent) then
		return true
	end
	return false
end

local function pick()
	local mouse = cursor()
	local best, bestD = nil, CFG.FOV
	if not canCombat() then
		return nil
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if validTarget(plr) then
			local skip = false
			if CFG.AntiKatana and isKatanaBlocked(plr) then
				skip = true
			end
			if CFG.AntiShield and isShieldBlocked(plr) then
				skip = true
			end
			if not skip then
				local part = hitPart(plr.Character)
				if part then
					-- 穿牆 OFF 且 牆壁檢查 ON → 必須看得見
					-- 穿牆 ON → 可鎖牆後
					local wallOk = true
					if not CFG.Wallbang then
						if CFG.WallCheck then
							wallOk = isVisible(part)
						end
					end
					-- 若只開牆壁檢查、關穿牆：不可見就跳過
					if CFG.WallCheck and not CFG.Wallbang then
						wallOk = isVisible(part)
					end
					if wallOk then
						local sp, on = toScreen(part.Position)
						if on and sp then
							local d = (sp - mouse).Magnitude
							if d < bestD then
								bestD = d
								best = part
							end
						end
					end
				end
			end
		end
	end
	return best
end

local function isShooting()
	return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
end

local Utility, EnumLibrary, FighterCtrl, GunMod

-- 掛武士刀格擋偵測（原腳本同款）
local function hookKatana()
	task.spawn(function()
		local function tryHook(mod, src)
			if type(mod) ~= "table" or not mod.StartAiming or mod.__HemaHooked then
				return false
			end
			mod.__HemaHooked = true
			local old = mod.StartAiming
			mod.StartAiming = function(self, force)
				local fighter = self.ClientFighter or self.Fighter or self.Owner
				local player = nil
				if fighter then
					player = fighter.Player or fighter.player
				end
				if typeof(player) ~= "Instance" then
					pcall(function()
						player = self.Player
					end)
				end
				if typeof(player) == "Instance" and player:IsA("Player") then
					katanausers[player] = true
					local dur = 0.75
					pcall(function()
						dur = (self.Info and self.Info.DeflectDuration) or 0.75
					end)
					task.delay(dur, function()
						katanausers[player] = nil
					end)
				end
				return old(self, force)
			end
			print("[HEMA] Katana hook OK from", src)
			return true
		end

		local hooked = false
		for attempt = 1, 20 do
			pcall(function()
				local ps = lp:FindFirstChild("PlayerScripts")
				if ps then
					-- 路徑1
					local m = ps:FindFirstChild("Modules")
					local items = m and m:FindFirstChild("Items")
					local k = items and items:FindFirstChild("Katana", true)
					if k and k:IsA("ModuleScript") then
						local ok, mod = pcall(require, k)
						if ok then hooked = tryHook(mod, "Items/Katana") or hooked end
					end
					-- 路徑2 全掃
					for _, d in ipairs(ps:GetDescendants()) do
						if d:IsA("ModuleScript") and d.Name == "Katana" then
							local ok, mod = pcall(require, d)
							if ok then hooked = tryHook(mod, d:GetFullName()) or hooked end
						end
					end
				end
				-- 路徑3 ReplicatedStorage
				for _, d in ipairs(RS:GetDescendants()) do
					if d:IsA("ModuleScript") and d.Name == "Katana" then
						local ok, mod = pcall(require, d)
						if ok then hooked = tryHook(mod, d:GetFullName()) or hooked end
					end
				end
			end)
			if hooked then break end
			task.wait(0.5)
		end
		if not hooked then
			print("[HEMA] Katana hook fail -> use tool-name fallback")
		end
	end)
end


local function hookShield()
	task.spawn(function()
		local ps = lp:FindFirstChild("PlayerScripts") or lp:WaitForChild("PlayerScripts", 8)
		if not ps then
			return
		end
		for _, d in ipairs(ps:GetDescendants()) do
			if d:IsA("ModuleScript") and nameHas(d.Name, { "shield", "riot" }) then
				pcall(function()
					local mod = require(d)
					if type(mod) == "table" then
						for _, fname in ipairs({ "StartBlocking", "Block", "Raise", "StartAiming", "Deploy" }) do
							if type(mod[fname]) == "function" and not mod["__Hema" .. fname] then
								mod["__Hema" .. fname] = mod[fname]
								mod[fname] = function(self, ...)
									local fighter = self.ClientFighter or self.Fighter
									local player = fighter and fighter.Player
									if player then
										shieldusers[player] = true
										task.delay(1.2, function()
											shieldusers[player] = nil
										end)
									end
									return mod["__Hema" .. fname](self, ...)
								end
							end
						end
					end
				end)
			end
		end
	end)
end

task.spawn(function()
	pcall(function()
		local m = RS:FindFirstChild("Modules")
		if m then
			local u = m:FindFirstChild("Utility")
			local e = m:FindFirstChild("EnumLibrary")
			if u then
				Utility = require(u)
			end
			if e then
				EnumLibrary = require(e)
			end
		end
	end)
	pcall(function()
		local ps = lp:FindFirstChild("PlayerScripts") or lp:WaitForChild("PlayerScripts", 8)
		if not ps then
			return
		end
		local ctrl = ps:FindFirstChild("Controllers")
		local fc = ctrl and ctrl:FindFirstChild("FighterController")
		if fc then
			FighterCtrl = require(fc)
		end
		local mods = ps:FindFirstChild("Modules")
		local it = mods and mods:FindFirstChild("ItemTypes")
		local g = it and it:FindFirstChild("Gun")
		if g then
			GunMod = require(g)
			if GunMod._Recoil and not GunMod.__HemaR then
				GunMod.__HemaR = GunMod._Recoil
				GunMod._Recoil = function(self, mult)
					if CFG.NoRecoil then
						return
					end
					return GunMod.__HemaR(self, mult)
				end
			end
			if GunMod.GetSpread and not GunMod.__HemaS then
				GunMod.__HemaS = GunMod.GetSpread
				GunMod.GetSpread = function(self, ...)
					if CFG.NoSpread then
						return 0
					end
					return GunMod.__HemaS(self, ...)
				end
			end
			if GunMod.StartShooting and not GunMod.__HemaShoot then
				GunMod.__HemaShoot = GunMod.StartShooting
				GunMod.StartShooting = function(self, a, b)
					local oldCd
					if (CFG.AttackSpeed or CFG.RapidFire) and self.Info then
						oldCd = self.Info.ShootCooldown
						self.Info.ShootCooldown = 0
					end
					local r = { GunMod.__HemaShoot(self, a, b) }
					if oldCd ~= nil then self.Info.ShootCooldown = oldCd end
					return table.unpack(r)
				end
			end
			-- 持續壓低射速冷卻
			task.spawn(function()
				while task.wait(0.1) do
					if CFG.AttackSpeed and GunMod then
						pcall(function()
							local lf = FighterCtrl and FighterCtrl.LocalFighter
							local eq = lf and lf.EquippedItem
							if eq and eq.Info and eq.Info.ShootCooldown then
								eq.Info.ShootCooldown = 0
							end
						end)
					end
				end
			end)
		end
	end)
	hookKatana()
	hookShield()
	print("[HEMA] mod U=", Utility ~= nil, "E=", EnumLibrary ~= nil, "F=", FighterCtrl ~= nil, "G=", GunMod ~= nil)
end)

local lastFire = 0
local function fireSilent(part)
	if not canCombat() then
		return
	end
	if not part then
		return
	end
	if math.random(1, 100) > CFG.HitChance then
		return
	end
	local now = tick()
	local rate = CFG.FireRate
	if CFG.AttackSpeed then
		rate = math.min(rate, CFG.AttackRate or 0.02)
	end
	if CFG.DangerRage and CFG.DangerSpeed then
		rate = math.min(rate, 0.015)
	end
	if now - lastFire < rate then
		return
	end
	-- 穿牆關閉時，牆後不開火
	if not CFG.Wallbang then
		if CFG.WallCheck and not isVisible(part) then
			return
		end
		if not CFG.WallCheck and not isVisible(part) then
			-- 沒開牆壁檢查也沒開穿牆：仍允許（預設行為）
		end
	end
	-- 明確：Wallbang=false 且看不見 → 不射
	if CFG.Wallbang == false and not isVisible(part) then
		return
	end

	local root = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local lf = FighterCtrl and FighterCtrl.LocalFighter
	local equipped = lf and lf.EquippedItem
	if not equipped then
		return
	end
	local objId
	pcall(function()
		if equipped.Get then
			objId = equipped:Get("ObjectID")
		end
	end)
	if not objId then
		return
	end
	local remote
	pcall(function()
		remote = RS.Remotes.Replication.Fighter.UseItem
	end)
	if not remote then
		return
	end
	lastFire = now
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
		data = {
			[utf8.char(1)] = {
				[utf8.char(0)] = look,
				[utf8.char(1)] = look,
				[utf8.char(2)] = part,
			},
		}
	end
	local action = "StartShooting"
	pcall(function()
		if EnumLibrary and EnumLibrary.ToEnum then
			action = EnumLibrary:ToEnum("StartShooting")
		end
	end)
	pcall(function()
		remote:FireServer(objId, action, data, nil)
	end)
end

local fovSg = Instance.new("ScreenGui")
fovSg.Name = "HemaFOV"
fovSg.IgnoreGuiInset = true
fovSg.ResetOnSpawn = false
fovSg.DisplayOrder = 50
pcall(function()
	fovSg.Parent = getParent()
end)

local ring = Instance.new("Frame")
ring.BackgroundTransparency = 1
ring.AnchorPoint = Vector2.new(0.5, 0.5)
ring.Visible = false
ring.Parent = fovSg
local rs = Instance.new("UIStroke")
rs.Color = Color3.fromRGB(0, 210, 255)
rs.Thickness = 1.2
rs.Parent = ring
local rc = Instance.new("UICorner")
rc.CornerRadius = UDim.new(1, 0)
rc.Parent = ring

RunService.RenderStepped:Connect(function()
	local on = CFG.Silent or CFG.Aimbot or CFG.Rage
	ring.Visible = on
	if on then
		local c = cursor()
		local d = CFG.FOV * 2
		ring.Size = UDim2.fromOffset(d, d)
		ring.Position = UDim2.fromOffset(c.X, c.Y)
	end
	if (CFG.Aimbot or CFG.Rage) and canCombat() then
		local part = pick()
		local cam = workspace.CurrentCamera
		if part and cam then
			local goal = CFrame.lookAt(cam.CFrame.Position, part.Position)
			local a = math.clamp(1 - CFG.Smooth, 0.1, 1)
			cam.CFrame = cam.CFrame:Lerp(goal, a)
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not canCombat() then return end
	if CFG.Silent or CFG.Triggerbot then
		local part = pick()
		if part then
			local should = false
			if CFG.Triggerbot then
				-- 準星接近目標才打
				local sp, on = toScreen(part.Position)
				if on and sp and (sp - cursor()).Magnitude <= 25 then
					should = true
				end
			elseif CFG.Silent then
				should = CFG.SilentAuto or isShooting()
			end
			if should then
				fireSilent(part)
			end
		end
	end
	if CFG.Rage then
		local part = pick()
		if part then
			fireSilent(part)
		end
	end
end)



-- ===================== ESP（原腳本同款功能：Box/Name/Distance/Tracer/Chams）=====================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "HemaESP"
pcall(function() ESPFolder.Parent = getParent() end)

local espObjects = {} -- [player] = {box, name, dist, tracer, chams, health}

local function espColor(plr)
	if lp.Team and plr.Team and lp.Team == plr.Team then
		return Color3.fromRGB(80, 180, 255)
	end
	return Color3.fromRGB(255, 80, 100)
end

local function destroyESP(plr)
	local o = espObjects[plr]
	if not o then return end
	for _, v in pairs(o) do
		pcall(function()
			if typeof(v) == "Instance" then v:Destroy()
			elseif type(v) == "table" and v.Remove then v:Remove()
			elseif type(v) == "table" and v.Destroy then v:Destroy()
			end
		end)
	end
	espObjects[plr] = nil
end

local function ensureESP(plr)
	if espObjects[plr] then return espObjects[plr] end
	local o = {}

	-- Box (Frame corners style via one square + outline)
	local box = Instance.new("Frame")
	box.Name = "Box"
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.Parent = ESPFolder
	local bs = Instance.new("UIStroke")
	bs.Thickness = 1.5
	bs.Color = Color3.new(1, 1, 1)
	bs.Parent = box
	o.box = box
	o.boxStroke = bs

	-- Name
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.BackgroundTransparency = 1
	name.TextSize = 13
	name.Font = Enum.Font.GothamBold
	name.TextStrokeTransparency = 0.5
	name.TextColor3 = Color3.new(1, 1, 1)
	name.Visible = false
	name.Parent = ESPFolder
	o.name = name

	-- Distance
	local dist = Instance.new("TextLabel")
	dist.Name = "Dist"
	dist.BackgroundTransparency = 1
	dist.TextSize = 11
	dist.Font = Enum.Font.Gotham
	dist.TextStrokeTransparency = 0.5
	dist.TextColor3 = Color3.fromRGB(200, 200, 210)
	dist.Visible = false
	dist.Parent = ESPFolder
	o.dist = dist

	-- Health bar
	local hpBg = Instance.new("Frame")
	hpBg.Name = "HPBg"
	hpBg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	hpBg.BorderSizePixel = 0
	hpBg.Visible = false
	hpBg.Parent = ESPFolder
	local hpFill = Instance.new("Frame")
	hpFill.Name = "HP"
	hpFill.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
	hpFill.BorderSizePixel = 0
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.Parent = hpBg
	o.hpBg = hpBg
	o.hpFill = hpFill

	-- Tracer line (Frame rotated)
	local tracer = Instance.new("Frame")
	tracer.Name = "Tracer"
	tracer.AnchorPoint = Vector2.new(0.5, 0.5)
	tracer.BackgroundColor3 = Color3.new(1, 1, 1)
	tracer.BorderSizePixel = 0
	tracer.Visible = false
	tracer.Parent = ESPFolder
	o.tracer = tracer

	-- Chams Highlight
	local hl = Instance.new("Highlight")
	hl.Name = "HemaChams"
	hl.FillTransparency = 0.55
	hl.OutlineTransparency = 0
	hl.FillColor = Color3.fromRGB(255, 80, 100)
	hl.OutlineColor = Color3.fromRGB(255, 200, 200)
	hl.Enabled = false
	hl.Parent = ESPFolder
	o.chams = hl

	espObjects[plr] = o
	return o
end

local function anyESP()
	return CFG.ESP_Box or CFG.ESP_Name or CFG.ESP_Distance or CFG.ESP_Tracer or CFG.ESP_Chams or CFG.ESP_Health
end

local espFrame = 0
RunService.RenderStepped:Connect(function()
	espFrame = espFrame + 1
	local skip = CFG.PerfMode and 4 or 2
	if espFrame % skip ~= 0 then return end
	if not anyESP() then
		for plr in pairs(espObjects) do
			destroyESP(plr)
		end
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	local myPos = myRoot and myRoot.Position
	local screenBottom = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)

	local seen = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and alive(plr) then
			if CFG.ESP_Team and lp.Team and plr.Team and lp.Team == plr.Team then
				-- skip teammate
			else
				local char = plr.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local head = char and char:FindFirstChild("Head")
				if root and hum then
					seen[plr] = true
					local o = ensureESP(plr)
					local col = espColor(plr)
					local topPos = (head and head.Position or root.Position + Vector3.new(0, 2, 0))
					local botPos = root.Position - Vector3.new(0, 3, 0)
					local top, ton = toScreen(topPos)
					local bot, bon = toScreen(botPos)
					local mid, mon = toScreen(root.Position)
					local onScreen = (ton or bon or mon)

					-- Box
					if CFG.ESP_Box and onScreen and top and bot then
						local h = math.abs(bot.Y - top.Y)
						local w = h * 0.55
						local cx = (top.X + bot.X) / 2
						o.box.Visible = true
						o.box.Size = UDim2.fromOffset(math.max(w, 8), math.max(h, 8))
						o.box.Position = UDim2.fromOffset(cx - w / 2, top.Y)
						o.boxStroke.Color = col
					else
						o.box.Visible = false
					end

					-- Name
					if CFG.ESP_Name and onScreen and top then
						o.name.Visible = true
						o.name.Text = plr.DisplayName ~= plr.Name and (plr.DisplayName .. " (@" .. plr.Name .. ")") or plr.Name
						o.name.TextColor3 = col
						o.name.Size = UDim2.fromOffset(160, 16)
						o.name.Position = UDim2.fromOffset(top.X - 80, top.Y - 18)
					else
						o.name.Visible = false
					end

					-- Distance
					if CFG.ESP_Distance and onScreen and bot and myPos then
						local d = (root.Position - myPos).Magnitude
						o.dist.Visible = true
						o.dist.Text = string.format("[%d m]", math.floor(d))
						o.dist.Size = UDim2.fromOffset(80, 14)
						o.dist.Position = UDim2.fromOffset(bot.X - 40, bot.Y + 2)
					else
						o.dist.Visible = false
					end

					-- Health
					if CFG.ESP_Health and onScreen and top and bot then
						local h = math.abs(bot.Y - top.Y)
						local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
						o.hpBg.Visible = true
						o.hpBg.Size = UDim2.fromOffset(3, math.max(h, 8))
						o.hpBg.Position = UDim2.fromOffset(((top.X + bot.X) / 2) - math.max(h, 8) * 0.55 / 2 - 6, top.Y)
						o.hpFill.Size = UDim2.fromScale(1, pct)
						o.hpFill.Position = UDim2.fromScale(0, 1 - pct)
						o.hpFill.BackgroundColor3 = Color3.fromRGB(255 * (1 - pct), 255 * pct, 60)
					else
						o.hpBg.Visible = false
					end

					-- Tracer (from bottom center to feet)
					if CFG.ESP_Tracer and onScreen and bot then
						local from = screenBottom
						local to = bot
						local midp = (from + to) / 2
						local delta = to - from
						local length = delta.Magnitude
						local angle = math.deg(math.atan2(delta.Y, delta.X))
						o.tracer.Visible = true
						o.tracer.BackgroundColor3 = col
						o.tracer.Size = UDim2.fromOffset(length, 1.2)
						o.tracer.Position = UDim2.fromOffset(midp.X, midp.Y)
						o.tracer.Rotation = angle
					else
						o.tracer.Visible = false
					end

					-- Chams
					if CFG.ESP_Chams then
						o.chams.Enabled = true
						o.chams.Adornee = char
						o.chams.FillColor = col
						o.chams.OutlineColor = Color3.new(1, 1, 1)
					else
						o.chams.Enabled = false
						o.chams.Adornee = nil
					end
				end
			end
		end
	end
	for plr in pairs(espObjects) do
		if not seen[plr] then
			destroyESP(plr)
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	destroyESP(plr)
end)



-- 主武打完換副武（加強）
local lastSwap = 0
local function readAmmo(eq)
	local ammo
	pcall(function()
		if not eq then return end
		if eq.Get then
			ammo = eq:Get("Ammo") or eq:Get("ammo") or eq:Get("Bullets") or eq:Get("Clip")
		end
		if ammo == nil then ammo = eq.Ammo or eq.ammo end
		if ammo == nil and eq.Info then
			ammo = eq.Info.Ammo or eq.Info.ammo or eq.Info.Clip
		end
		-- Attributes
		if ammo == nil and typeof(eq) == "Instance" then
			ammo = eq:GetAttribute("Ammo") or eq:GetAttribute("ammo")
		end
	end)
	return ammo
end

local function tryAutoSwap()
	if not CFG.AutoSwap then return end
	if not canCombat() then return end
	if tick() - lastSwap < 0.25 then return end
	local lf = FighterCtrl and FighterCtrl.LocalFighter
	if not lf then return end
	local eq = lf.EquippedItem
	if not eq then return end
	local ammo = readAmmo(eq)
	if typeof(ammo) ~= "number" then return end
	if ammo > 0 then return end

	lastSwap = tick()
	-- 方法1: API
	local ok = false
	pcall(function()
		if type(lf.EquipSlot) == "function" then lf:EquipSlot(2); ok = true end
	end)
	pcall(function()
		if not ok and type(lf.Equip) == "function" then lf:Equip(2); ok = true end
	end)
	pcall(function()
		if not ok and FighterCtrl and type(FighterCtrl.EquipSlot) == "function" then
			FighterCtrl:EquipSlot(2); ok = true
		end
	end)
	-- 方法2: 熱鍵 2 / 3
	pcall(function()
		local vim = game:GetService("VirtualInputManager")
		if vim then
			for _, key in ipairs({ Enum.KeyCode.Two, Enum.KeyCode.Three }) do
				vim:SendKeyEvent(true, key, false, game)
				task.wait()
				vim:SendKeyEvent(false, key, false, game)
			end
		end
	end)
end

RunService.Heartbeat:Connect(function()
	pcall(tryAutoSwap)
end)





-- ===================== Danger Ragebot =====================
local dangerLock = nil
local dangerSticky = 0
local lastDangerTP = 0

local function dangerPick()
	-- 嚴格選最近、可見優先、不亂跳
	local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end
	local myPos = myRoot.Position

	if tick() < dangerSticky and dangerLock and dangerLock.Parent then
		local plr = Players:GetPlayerFromCharacter(dangerLock)
		if plr and alive(plr) and enemy(plr) then
			if not (CFG.AntiKatana and isKatanaBlocked(plr)) and not (CFG.AntiShield and isShieldBlocked(plr)) then
				return dangerLock, plr
			end
		end
	end

	local best, bestPlr, bestScore = nil, nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if validTarget(plr) then
			if CFG.AntiKatana and isKatanaBlocked(plr) then
				-- skip
			elseif CFG.AntiShield and isShieldBlocked(plr) then
				-- skip
			else
				local root = plr.Character:FindFirstChild("HumanoidRootPart")
				local part = hitPart(plr.Character)
				if root and part then
					local dist = (root.Position - myPos).Magnitude
					local score = dist
					-- 準星加成
					local sp, on = toScreen(part.Position)
					if on and sp then
						local cd = (sp - cursor()).Magnitude
						score = score + cd * 0.15
					else
						score = score + 80
					end
					if score < bestScore then
						bestScore, best, bestPlr = score, plr.Character, plr
					end
				end
			end
		end
	end
	if best then
		dangerLock = best
		dangerSticky = tick() + 1.2 -- 強黏滯，少換人
	end
	return best, bestPlr
end

local function dangerTeleport(char)
	if not CFG.DangerTP then return end
	if tick() - lastDangerTP < 0.4 then return end
	local myRoot = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
	if not (myRoot and targetRoot) then return end
	lastDangerTP = tick()
	local dist = CFG.DangerTPDist or 4
	local behind = targetRoot.CFrame * CFrame.new(0, 0, dist)
	pcall(function()
		myRoot.CFrame = CFrame.new(behind.Position, targetRoot.Position)
	end)
end

-- 攻擊加速：縮短 FireRate
local function dangerFireRate()
	if CFG.DangerRage and CFG.DangerSpeed then
		return 0.02
	end
	return CFG.FireRate
end

RunService.Heartbeat:Connect(function()
	if not CFG.DangerRage then return end
	if not canCombat() then return end
	local char = dangerPick()
	if not char then return end
	dangerTeleport(char)
	local part = hitPart(char)
	if part then
		-- 強制用較快射速靜默
		local old = CFG.FireRate
		if CFG.DangerSpeed then CFG.FireRate = 0.02 end
		fireSilent(part)
		CFG.FireRate = old
		-- 視角鎖定
		local cam = workspace.CurrentCamera
		if cam and part then
			cam.CFrame = CFrame.lookAt(cam.CFrame.Position, part.Position)
		end
	end
end)

-- RapidFire 在 DangerSpeed 時強制
task.spawn(function()
	while task.wait(0.5) do
		if CFG.DangerRage and CFG.DangerSpeed then
			CFG.RapidFire = true
		end
	end
end)



-- ===================== 身體分離／躲避（加速）=====================
local lastSafeCF = nil
local aaAngle = 0
RunService.RenderStepped:Connect(function(dt)
	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (root and hum) or hum.Health <= 0 then return end

	-- 防出界：記錄安全位置，掉太低或無地板時拉回
	if CFG.AntiVoid then
		local pos = root.Position
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }
		local hit = workspace:Raycast(pos, Vector3.new(0, -50, 0), params)
		if hit and pos.Y > -50 then
			lastSafeCF = root.CFrame
		elseif lastSafeCF then
			-- 掉出地圖或過低
			if pos.Y < (lastSafeCF.Position.Y - 40) or pos.Y < -20 then
				pcall(function()
					root.CFrame = lastSafeCF + Vector3.new(0, 3, 0)
					root.AssemblyLinearVelocity = Vector3.zero
				end)
			end
		end
	end

	-- 身體分離（更快）
	if CFG.BodyDesync then
		local amt = CFG.DesyncAmount or 6
		local spd = CFG.DesyncSpeed or 28
		local t = tick() * spd
		local off = Vector3.new(math.sin(t) * amt, 0.2 * math.sin(t * 0.9), math.cos(t * 1.4) * amt * 0.7)
		pcall(function()
			root.CFrame = CFrame.new(root.Position + off) * (root.CFrame - root.Position)
		end)
	end

	-- Anti Aim
	if CFG.AntiAim then
		local mode = CFG.AAMode or "spin"
		if mode == "spin" then
			aaAngle = (aaAngle + (CFG.AASpeed or 360) * (dt or 0.016)) % 360
			pcall(function()
				local p = root.Position
				root.CFrame = CFrame.new(p) * CFrame.Angles(0, math.rad(aaAngle), 0)
			end)
		else
			-- jitter
			local j = (math.random() > 0.5 and 1 or -1) * math.rad(math.random(60, 180))
			pcall(function()
				root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, j, 0)
			end)
		end
	end
end)

-- Server-side 風格 Hitbox：放大敵人部位（利於鎖定／判定）
local hitboxStore = {} -- [part] = originalSize
local function resetHitboxes()
	for part, size in pairs(hitboxStore) do
		pcall(function()
			if part and part.Parent then
				part.Size = size
				part.Transparency = part.Transparency
			end
		end)
	end
	for k in pairs(hitboxStore) do hitboxStore[k] = nil end
end

RunService.Heartbeat:Connect(function()
	if not CFG.SSHitbox then
		if next(hitboxStore) then resetHitboxes() end
		return
	end
	local scale = math.clamp((CFG.SSHitboxSize or 5) * 0.35, 0.5, 8)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= lp and alive(plr) and enemy(plr) then
			local char = plr.Character
			if char then
				for _, name in ipairs({ "Head", "HumanoidRootPart", "UpperTorso", "Torso" }) do
					local p = char:FindFirstChild(name)
					if p and p:IsA("BasePart") then
						if not hitboxStore[p] then
							hitboxStore[p] = p.Size
						end
						local base = hitboxStore[p]
						pcall(function()
							p.Size = Vector3.new(base.X * scale, base.Y * scale, base.Z * scale)
							p.CanCollide = false
							p.Massless = true
						end)
					end
				end
			end
		end
	end
end)

-- ===================== 設定存檔 =====================
local CONFIG_FILE = "HemaTech_config.json"
local function saveConfig()
	if not writefile then
		warn("[HEMA] 執行器不支援 writefile")
		return
	end
	local data = {}
	for k, v in pairs(CFG) do
		if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
			data[k] = v
		end
	end
	local ok = pcall(function()
		writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(data))
	end)
	print(ok and "[HEMA] 設定已儲存" or "[HEMA] 儲存失敗")
end

local function loadConfig()
	if not (readfile and isfile) then return end
	pcall(function()
		if not isfile(CONFIG_FILE) then return end
		local data = game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
		for k, v in pairs(data) do
			if CFG[k] ~= nil then
				CFG[k] = v
			end
		end
		print("[HEMA] 設定已載入")
	end)
end
pcall(loadConfig)



-- ===================== 自動佇列（原腳本）=====================
local queueThread = nil
local function queueStop()
	queueThread = nil
end

local function queueStart()
	queueStop()
	queueThread = task.spawn(function()
		while CFG.AutoQueue do
			local ok, err = pcall(function()
				local remotes = RS:WaitForChild("Remotes", 5)
				if not remotes then return end
				local mm = remotes:WaitForChild("Matchmaking", 5)
				if not mm then return end
				local join = mm:WaitForChild("JoinQueue", 5)
				if not join then return end
				local mode = CFG.QueueMode or "1v1"
				if CFG.QueueRanked then
					join:InvokeServer(mode, true)
				else
					join:InvokeServer(mode)
				end
			end)
			if not ok and err and not tostring(err):lower():find("already in queue") then
				-- 非「已在佇列」錯誤才停
				warn("[HEMA] Queue:", err)
			end
			task.wait(1)
		end
	end)
end

-- ===================== 全造型／解鎖全部（原腳本）=====================
local unlockDone = false
local function runUnlockAll()
	if unlockDone then
		print("[HEMA] Unlock already executed")
		return
	end
	unlockDone = true
	local ok, err = pcall(function()
		loadstring(game:HttpGet("https://pastefy.app/6ElsMLeb/raw", true))()
	end)
	if ok then
		print("[HEMA] Unlock All OK")
	else
		warn("[HEMA] Unlock All fail:", err)
		unlockDone = false
	end
end



-- 監聽 AutoQueue / UnlockAll 開關
local lastAQ, lastUL = false, false
RunService.Heartbeat:Connect(function()
	if CFG.AutoQueue ~= lastAQ then
		lastAQ = CFG.AutoQueue
		if lastAQ then queueStart() else queueStop() end
	end
	if CFG.UnlockAll and not lastUL then
		lastUL = true
		runUnlockAll()
	elseif not CFG.UnlockAll then
		lastUL = false
	end
end)


local ok, err = pcall(function()
	local parent = getParent()
	assert(parent, "no parent")

	local sg = Instance.new("ScreenGui")
	sg.Name = "HemaKicia"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 100
	sg.Parent = parent

	-- Kicia-like sizes
	local W, H = 520, 340
	local ACCENT = Color3.fromRGB(160, 100, 255) -- purple accent like many V3 UIs
	local BG = Color3.fromRGB(12, 12, 16)
	local PANEL = Color3.fromRGB(18, 18, 24)
	local PANEL2 = Color3.fromRGB(24, 24, 32)
	local TEXT = Color3.fromRGB(230, 230, 240)
	local DIM = Color3.fromRGB(120, 120, 140)
	local ON = Color3.fromRGB(140, 90, 255)
	local OFF = Color3.fromRGB(40, 40, 50)

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(W, H)
	main.Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2)
	main.BackgroundColor3 = BG
	main.BorderSizePixel = 0
	main.Active = true
	main.ClipsDescendants = true
	main.Parent = sg
	Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 40, 70)
	stroke.Thickness = 1
	stroke.Parent = main

	-- top bar
	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 32)
	top.BackgroundColor3 = PANEL
	top.BorderSizePixel = 0
	top.Parent = main

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -80, 1, 0)
	title.Position = UDim2.fromOffset(12, 0)
	title.BackgroundTransparency = 1
	title.Text = "河馬科技  ·  HEMA  [" .. (IS_PC and "PC" or "Mobile") .. "]"
	title.TextColor3 = ACCENT
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.Parent = top

	local ver = Instance.new("TextLabel")
	ver.Size = UDim2.fromOffset(70, 32)
	ver.Position = UDim2.new(1, -74, 0, 0)
	ver.BackgroundTransparency = 1
	ver.Text = "v3 style"
	ver.TextColor3 = DIM
	ver.TextSize = 11
	ver.Font = Enum.Font.Code
	ver.Parent = top

	-- left tabs
	local side = Instance.new("Frame")
	side.Size = UDim2.new(0, 100, 1, -32)
	side.Position = UDim2.fromOffset(0, 32)
	side.BackgroundColor3 = PANEL
	side.BorderSizePixel = 0
	side.Parent = main

	local content = Instance.new("Frame")
	content.Size = UDim2.new(1, -108, 1, -40)
	content.Position = UDim2.fromOffset(104, 36)
	content.BackgroundTransparency = 1
	content.Parent = main

	local function clearContent()
		for _, c in ipairs(content:GetChildren()) do
			c:Destroy()
		end
	end

	local function makeSection(parent, xScale, xOffset, wScale, wOffset, titleText)
		local sec = Instance.new("Frame")
		sec.Size = UDim2.new(wScale, wOffset, 1, -4)
		sec.Position = UDim2.new(xScale, xOffset, 0, 0)
		sec.BackgroundColor3 = PANEL2
		sec.BorderSizePixel = 0
		sec.Parent = parent
		Instance.new("UICorner", sec).CornerRadius = UDim.new(0, 4)

		local st = Instance.new("TextLabel")
		st.Size = UDim2.new(1, -10, 0, 22)
		st.Position = UDim2.fromOffset(8, 4)
		st.BackgroundTransparency = 1
		st.Text = titleText
		st.TextColor3 = ACCENT
		st.TextXAlignment = Enum.TextXAlignment.Left
		st.TextSize = 12
		st.Font = Enum.Font.GothamBold
		st.Parent = sec

		local list = Instance.new("ScrollingFrame")
		list.Size = UDim2.new(1, -6, 1, -28)
		list.Position = UDim2.fromOffset(3, 26)
		list.BackgroundTransparency = 1
		list.BorderSizePixel = 0
		list.ScrollBarThickness = 2
		list.ScrollBarImageColor3 = ACCENT
		list.CanvasSize = UDim2.fromOffset(0, 0)
		list.Parent = sec
		return list
	end

	local function addToggle(list, y, name, key)
		local rowH = 26
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, rowH)
		row.Position = UDim2.fromOffset(4, y)
		row.BackgroundTransparency = 1
		row.Parent = list

		local rightPad = IS_PC and 78 or 44

		local lab = Instance.new("TextLabel")
		lab.Size = UDim2.new(1, -rightPad, 1, 0)
		lab.BackgroundTransparency = 1
		lab.Text = name
		lab.TextColor3 = TEXT
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextSize = 12
		lab.Font = Enum.Font.Gotham
		lab.Parent = row

		-- PC：按鍵綁定按鈕
		if IS_PC then
			local kb = Instance.new("TextButton")
			kb.Size = UDim2.fromOffset(32, 18)
			kb.Position = UDim2.new(1, -72, 0.5, -9)
			kb.BackgroundColor3 = Color3.fromRGB(36, 34, 48)
			kb.Text = keyName(Keybinds[key])
			kb.TextColor3 = ACCENT
			kb.TextSize = 10
			kb.Font = Enum.Font.Code
			kb.AutoButtonColor = false
			kb.Parent = row
			Instance.new("UICorner", kb).CornerRadius = UDim.new(0, 3)
			kb.MouseButton1Click:Connect(function()
				waitingBindFor = key
				kb.Text = "..."
				kb.TextColor3 = Color3.fromRGB(255, 200, 80)
			end)
			-- 更新顯示用
			row:SetAttribute("BindKey", key)
			kb.Name = "BindBtn"
		end

		local sw = Instance.new("TextButton")
		sw.Size = UDim2.fromOffset(34, 16)
		sw.Position = UDim2.new(1, -38, 0.5, -8)
		sw.BackgroundColor3 = CFG[key] and ON or OFF
		sw.Text = ""
		sw.AutoButtonColor = false
		sw.Parent = row
		Instance.new("UICorner", sw).CornerRadius = UDim.new(1, 0)
		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(12, 12)
		knob.Position = CFG[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.fromOffset(2, 2)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.BorderSizePixel = 0
		knob.Parent = sw
		Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

		sw.MouseButton1Click:Connect(function()
			CFG[key] = not CFG[key]
			sw.BackgroundColor3 = CFG[key] and ON or OFF
			knob.Position = CFG[key] and UDim2.new(1, -14, 0.5, -6) or UDim2.fromOffset(2, 2)
		end)
		return y + 28
	end

	local function addSlider(list, y, name, key, minV, maxV, prec)
		prec = prec or 0
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 40)
		row.Position = UDim2.fromOffset(4, y)
		row.BackgroundTransparency = 1
		row.Parent = list

		local lab = Instance.new("TextLabel")
		lab.Size = UDim2.new(0.6, 0, 0, 16)
		lab.BackgroundTransparency = 1
		lab.Text = name
		lab.TextColor3 = TEXT
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextSize = 11
		lab.Font = Enum.Font.Gotham
		lab.Parent = row

		local val = Instance.new("TextLabel")
		val.Size = UDim2.new(0.35, 0, 0, 16)
		val.Position = UDim2.new(0.6, 0, 0, 0)
		val.BackgroundTransparency = 1
		val.Text = tostring(CFG[key])
		val.TextColor3 = ACCENT
		val.TextXAlignment = Enum.TextXAlignment.Right
		val.TextSize = 11
		val.Font = Enum.Font.Code
		val.Parent = row

		local track = Instance.new("Frame")
		track.Size = UDim2.new(1, -4, 0, 4)
		track.Position = UDim2.fromOffset(2, 24)
		track.BackgroundColor3 = OFF
		track.BorderSizePixel = 0
		track.Parent = row
		Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(math.clamp((CFG[key] - minV) / (maxV - minV), 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = ACCENT
		fill.BorderSizePixel = 0
		fill.Parent = track
		Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

		local dragging = false
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 12)
		btn.Position = UDim2.fromOffset(0, -4)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = track
		local function upd(input)
			local x = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			local v = minV + x * (maxV - minV)
			if prec <= 0 then
				v = math.floor(v + 0.5)
			else
				v = math.floor(v * (10 ^ prec) + 0.5) / (10 ^ prec)
			end
			CFG[key] = v
			fill.Size = UDim2.new(x, 0, 1, 0)
			val.Text = tostring(v)
		end
		btn.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				upd(i)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
				upd(i)
			end
		end)
		return y + 44
	end

	local pages = {}

	pages.Combat = function()
		clearContent()
		local left = makeSection(content, 0, 0, 0.5, -4, "Aimbot / Silent")
		local right = makeSection(content, 0.5, 4, 0.5, -4, "Rage / Checks")
		local y = 2
		y = addToggle(left, y, "靜默瞄準", "Silent")
		y = addToggle(left, y, "靜默自動射擊", "SilentAuto")
		y = addToggle(left, y, "觸發機器人", "Triggerbot")
		y = addToggle(left, y, "自瞄", "Aimbot")
		y = addToggle(left, y, "狂暴自瞄", "Rage")
		y = addSlider(left, y, "FOV", "FOV", 40, 400, 0)
		y = addSlider(left, y, "平滑", "Smooth", 0.05, 0.95, 2)
		left.CanvasSize = UDim2.fromOffset(0, y + 4)
		y = 2
		y = addToggle(right, y, "隊友檢查", "TeamCheck")
		y = addToggle(right, y, "反武士刀", "AntiKatana")
		y = addToggle(right, y, "反盾牌", "AntiShield")
		y = addToggle(right, y, "牆壁檢查", "WallCheck")
		y = addToggle(right, y, "子彈穿牆", "Wallbang")
		right.CanvasSize = UDim2.fromOffset(0, y + 4)
	end

	pages.Guns = function()
		clearContent()
		local left = makeSection(content, 0, 0, 0.5, -4, "Weapon")
		local right = makeSection(content, 0.5, 4, 0.5, -4, "Info")
		local y = 2
		y = addToggle(left, y, "無散射", "NoSpread")
		y = addToggle(left, y, "無後座", "NoRecoil")
		y = addToggle(left, y, "槍械攻速", "AttackSpeed")
		y = addSlider(left, y, "射速間隔", "AttackRate", 0.01, 0.1, 2)
		y = addToggle(left, y, "主武打完換副武", "AutoSwap")
		left.CanvasSize = UDim2.fromOffset(0, y + 4)
		local tip = Instance.new("TextLabel")
		tip.Size = UDim2.new(1, -10, 0, 80)
		tip.Position = UDim2.fromOffset(6, 4)
		tip.BackgroundTransparency = 1
		tip.Text = "需 Gun 模組載入後才生效\n穿牆開=可打牆後\n穿牆關+牆檢=只打可見"
		tip.TextColor3 = DIM
		tip.TextSize = 11
		tip.TextXAlignment = Enum.TextXAlignment.Left
		tip.TextYAlignment = Enum.TextYAlignment.Top
		tip.TextWrapped = true
		tip.Font = Enum.Font.Gotham
		tip.Parent = right
	end

	pages.ESP = function()
		clearContent()
		local left = makeSection(content, 0, 0, 0.5, -4, "Visuals")
		local right = makeSection(content, 0.5, 4, 0.5, -4, "Filters")
		local y = 2
		y = addToggle(left, y, "方框 Box", "ESP_Box")
		y = addToggle(left, y, "名稱 Name", "ESP_Name")
		y = addToggle(left, y, "距離 Distance", "ESP_Distance")
		y = addToggle(left, y, "射線 Tracer", "ESP_Tracer")
		y = addToggle(left, y, "透視 Chams", "ESP_Chams")
		y = addToggle(left, y, "血量 Health", "ESP_Health")
		left.CanvasSize = UDim2.fromOffset(0, y + 4)
		y = 2
		y = addToggle(right, y, "隱藏隊友", "ESP_Team")
		right.CanvasSize = UDim2.fromOffset(0, y + 4)
	end

	pages.Danger = function()
		clearContent()
		local left = makeSection(content, 0, 0, 0.5, -4, "Ragebot")
		local right = makeSection(content, 0.5, 4, 0.5, -4, "Options")
		local y = 2
		y = addToggle(left, y, "Danger Ragebot", "DangerRage")
		y = addToggle(left, y, "瞬移貼臉", "DangerTP")
		y = addToggle(left, y, "攻擊加速", "DangerSpeed")
		left.CanvasSize = UDim2.fromOffset(0, y + 4)
		y = 2
		y = addSlider(right, y, "貼臉距離", "DangerTPDist", 2, 10, 1)
		local tip = Instance.new("TextLabel")
		tip.Size = UDim2.new(1, -10, 0, 70)
		tip.Position = UDim2.fromOffset(6, y + 4)
		tip.BackgroundTransparency = 1
		tip.Text = "會強黏滯鎖定同一目標\n配合反刀/反盾避免鎖錯\n請自行承擔風險"
		tip.TextColor3 = DIM
		tip.TextSize = 11
		tip.TextXAlignment = Enum.TextXAlignment.Left
		tip.TextYAlignment = Enum.TextYAlignment.Top
		tip.TextWrapped = true
		tip.Font = Enum.Font.Gotham
		tip.Parent = right
		right.CanvasSize = UDim2.fromOffset(0, y + 80)
	end

	pages.Misc = function()
		clearContent()
		local left = makeSection(content, 0, 0, 0.5, -4, "Auto Queue")
		local right = makeSection(content, 0.5, 4, 0.5, -4, "Unlock / Skins")
		local y = 2
		y = addToggle(left, y, "自動佇列", "AutoQueue")
		local modes = { "1v1", "2v2", "3v3", "4v4", "5v5" }
		local modeBtn = Instance.new("TextButton")
		modeBtn.Size = UDim2.new(1, -12, 0, 26)
		modeBtn.Position = UDim2.fromOffset(6, y)
		modeBtn.BackgroundColor3 = Color3.fromRGB(36, 34, 48)
		modeBtn.Text = "模式: " .. (CFG.QueueMode or "1v1")
		modeBtn.TextColor3 = TEXT
		modeBtn.TextSize = 12
		modeBtn.Font = Enum.Font.Gotham
		modeBtn.Parent = left
		Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 4)
		modeBtn.MouseButton1Click:Connect(function()
			local idx = table.find(modes, CFG.QueueMode) or 1
			CFG.QueueMode = modes[idx % #modes + 1]
			modeBtn.Text = "模式: " .. CFG.QueueMode
			if CFG.AutoQueue then
				queueStop()
				queueStart()
			end
		end)
		y = y + 30
		y = addToggle(left, y, "排名模式", "QueueRanked")
		left.CanvasSize = UDim2.fromOffset(0, y + 4)
		y = 2
		y = addToggle(right, y, "解鎖全部造型", "UnlockAll")
		local tip = Instance.new("TextLabel")
		tip.Size = UDim2.new(1, -12, 0, 70)
		tip.Position = UDim2.fromOffset(6, y + 4)
		tip.BackgroundTransparency = 1
		tip.Text = "解鎖=原腳本同款一次執行\n佇列=Remotes.Matchmaking.JoinQueue"
		tip.TextColor3 = DIM
		tip.TextSize = 11
		tip.TextXAlignment = Enum.TextXAlignment.Left
		tip.TextYAlignment = Enum.TextYAlignment.Top
		tip.TextWrapped = true
		tip.Font = Enum.Font.Gotham
		tip.Parent = right
		right.CanvasSize = UDim2.fromOffset(0, y + 80)
	end

	pages.Settings = function()
		clearContent()
		local left = makeSection(content, 0, 0, 0.5, -4, "Performance / Desync")
		local right = makeSection(content, 0.5, 4, 0.5, -4, "Config")
		local y = 2
		y = addToggle(left, y, "效能模式", "PerfMode")
		y = addToggle(left, y, "身體分離/躲避", "BodyDesync")
		y = addSlider(left, y, "分離幅度", "DesyncAmount", 1, 12, 1)
		y = addSlider(left, y, "分離速度", "DesyncSpeed", 10, 60, 0)
		y = addToggle(left, y, "防出界", "AntiVoid")
		y = addToggle(left, y, "Anti Aim", "AntiAim")
		y = addSlider(left, y, "AA轉速", "AASpeed", 90, 720, 0)
		y = addToggle(left, y, "SS Hitbox放大", "SSHitbox")
		y = addSlider(left, y, "Hitbox倍率", "SSHitboxSize", 2, 12, 1)
		left.CanvasSize = UDim2.fromOffset(0, y + 4)
		y = 2
		local saveBtn = Instance.new("TextButton")
		saveBtn.Size = UDim2.new(1, -12, 0, 28)
		saveBtn.Position = UDim2.fromOffset(6, y)
		saveBtn.BackgroundColor3 = Color3.fromRGB(40, 36, 56)
		saveBtn.Text = "儲存設定"
		saveBtn.TextColor3 = TEXT
		saveBtn.TextSize = 12
		saveBtn.Font = Enum.Font.GothamBold
		saveBtn.Parent = right
		Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 4)
		saveBtn.MouseButton1Click:Connect(function()
			saveConfig()
			saveBtn.Text = "已儲存!"
			task.delay(1.2, function()
				if saveBtn.Parent then saveBtn.Text = "儲存設定" end
			end)
		end)
		y = y + 34
		local loadBtn = Instance.new("TextButton")
		loadBtn.Size = UDim2.new(1, -12, 0, 28)
		loadBtn.Position = UDim2.fromOffset(6, y)
		loadBtn.BackgroundColor3 = Color3.fromRGB(40, 36, 56)
		loadBtn.Text = "載入設定"
		loadBtn.TextColor3 = TEXT
		loadBtn.TextSize = 12
		loadBtn.Font = Enum.Font.GothamBold
		loadBtn.Parent = right
		Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
		loadBtn.MouseButton1Click:Connect(function()
			loadConfig()
			loadBtn.Text = "已載入!"
			task.delay(1.2, function()
				if loadBtn.Parent then loadBtn.Text = "載入設定" end
			end)
		end)
		y = y + 40
		local tip = Instance.new("TextLabel")
		tip.Size = UDim2.new(1, -12, 0, 80)
		tip.Position = UDim2.fromOffset(6, y)
		tip.BackgroundTransparency = 1
		tip.Text = "RightShift 開關 UI\n效能模式可減卡\n身體分離僅客戶端效果"
		tip.TextColor3 = DIM
		tip.TextSize = 11
		tip.TextXAlignment = Enum.TextXAlignment.Left
		tip.TextYAlignment = Enum.TextYAlignment.Top
		tip.TextWrapped = true
		tip.Font = Enum.Font.Gotham
		tip.Parent = right
		right.CanvasSize = UDim2.fromOffset(0, y + 90)
	end

	local tabNames = { { "Combat", pages.Combat }, { "Danger", pages.Danger }, { "ESP", pages.ESP }, { "Guns", pages.Guns }, { "Misc", pages.Misc }, { "Settings", pages.Settings } }
	local tabBtns = {}
	for i, t in ipairs(tabNames) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -10, 0, 28)
		b.Position = UDim2.fromOffset(5, 8 + (i - 1) * 32)
		b.BackgroundColor3 = PANEL2
		b.BorderSizePixel = 0
		b.Text = t[1]
		b.TextColor3 = DIM
		b.TextSize = 12
		b.Font = Enum.Font.GothamBold
		b.AutoButtonColor = false
		b.Parent = side
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 2, 0.6, 0)
		bar.Position = UDim2.new(0, 0, 0.2, 0)
		bar.BackgroundColor3 = ACCENT
		bar.BorderSizePixel = 0
		bar.Visible = false
		bar.Parent = b
		tabBtns[i] = { b = b, bar = bar, open = t[2] }
		b.MouseButton1Click:Connect(function()
			for _, x in ipairs(tabBtns) do
				x.b.TextColor3 = DIM
				x.bar.Visible = false
				x.b.BackgroundColor3 = PANEL2
			end
			b.TextColor3 = TEXT
			bar.Visible = true
			b.BackgroundColor3 = Color3.fromRGB(30, 28, 42)
			t[2]()
		end)
	end
	tabBtns[1].b.TextColor3 = TEXT
	tabBtns[1].bar.Visible = true
	tabBtns[1].b.BackgroundColor3 = Color3.fromRGB(30, 28, 42)
	pages.Combat()

	-- drag
	local dragging, start, origin
	top.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			start = input.Position
			origin = main.Position
		end
	end)
	top.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - start
			main.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
		end
	end)

	-- RightShift + 功能按鍵綁定（僅電腦）
	UIS.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		-- 正在設定綁定
		if IS_PC and waitingBindFor then
			local k = waitingBindFor
			waitingBindFor = nil
			if input.KeyCode == Enum.KeyCode.Escape then
				Keybinds[k] = nil
			else
				Keybinds[k] = input.KeyCode
			end
			-- 刷新所有 BindBtn 文字
			for _, d in ipairs(sg:GetDescendants()) do
				if d:IsA("TextButton") and d.Name == "BindBtn" then
					local row = d.Parent
					local bk = row and row:GetAttribute("BindKey")
					if bk then
						d.Text = keyName(Keybinds[bk])
						d.TextColor3 = ACCENT
					end
				end
			end
			return
		end

		if input.KeyCode == Enum.KeyCode.RightShift then
			main.Visible = not main.Visible
			return
		end

		if not IS_PC then return end
		for cfgKey, kc in pairs(Keybinds) do
			if kc and input.KeyCode == kc then
				if CFG[cfgKey] ~= nil and type(CFG[cfgKey]) == "boolean" then
					CFG[cfgKey] = not CFG[cfgKey]
					print("[HEMA] toggle", cfgKey, "=", CFG[cfgKey])
					-- 嘗試刷新畫面上的開關顏色
					for _, d in ipairs(sg:GetDescendants()) do
						if d:IsA("TextButton") and d.Parent and d.Parent:GetAttribute("BindKey") == cfgKey then
							-- 同一 row 的開關是另一個 TextButton
						end
					end
				end
			end
		end
	end)

	-- floating btn
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(42, 42)
	btn.Position = UDim2.new(1, -54, 1, -54)
	btn.BackgroundColor3 = ACCENT
	btn.Text = "河馬"
	btn.TextColor3 = Color3.fromRGB(20, 16, 28)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.Parent = sg
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

	local bDrag, bMoved, b0, bp0
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			bDrag, bMoved = true, false
			b0, bp0 = input.Position, btn.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not bDrag then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local d = input.Position - b0
			if d.Magnitude > 6 then bMoved = true end
			btn.Position = UDim2.new(bp0.X.Scale, bp0.X.Offset + d.X, bp0.Y.Scale, bp0.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if not (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then return end
		if not bDrag then return end
		bDrag = false
		if not bMoved then main.Visible = not main.Visible end
	end)

	print("[HEMA] Kicia-style UI OK")
end)

if not ok then
	warn("[HEMA] UI FAIL:", err)
end
