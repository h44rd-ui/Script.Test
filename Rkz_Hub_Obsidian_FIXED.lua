local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()
local function Notify(data)
    pcall(function()
        Library:Notify({
            Title = data.Title or "Rkz Hub",
            Description = data.Content or "",
            Time = data.Duration or 3,
        })
    end)
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local BLOCKED_CFRAMES = {
	{ Pos = Vector3.new(241.24, -30.65, -89.46), Radius = 15 },
	{ Pos = Vector3.new(310.00, -29.15, -89.50), Radius = 15 },
}
local function IsBlockedPosition(pos)
	for _, entry in ipairs(BLOCKED_CFRAMES) do
		if (pos - entry.Pos).Magnitude < entry.Radius then
			return true, entry.Pos
		end
	end
	return false, nil
end
task.spawn(function()
	while true do
		task.wait(0.1)
		if RootPart and RootPart.Parent then
			local blocked = IsBlockedPosition(RootPart.Position)
			if blocked then
				local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
				if spawn then
					RootPart.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 5, 0))
				else
					RootPart.CFrame = CFrame.new(RootPart.Position + Vector3.new(0, 50, 0))
				end
			end
		end
	end
end)
local AutoFollowEnabled = false
local ReachEnabled = false
local ReachDistance = 10
local AutoCatchEnabled = false
local AutoCatchRange = 8
local AutoCatchDelay = 1
local AutoCatchLast = 0
local AC_Hitbox = false
local AC_HitboxPart = nil
local AutoCatchIntelEnabled = false
local AutoCatchIntelConn = nil
local AutoCatchIntelRange = 16
local AutoCatchIntelCooldown = 0.35
local AutoCatchIntelLast = 0
local AutoCatchIntelHeight = 3.5
local AutoCatchIntelAutoDive = true
local AutoCatchIntelComboDelay = 0.15
local AutoDiveBloquearSeIntelAtivo = true
local AimbotBlueEnabled = false
local AimbotGreenEnabled = false
local FlingBallForce = 300
local PowerShootEnabled = false
local PowerShootForce = 250
local PowerShootRange = 8
local ControlBallEnabled = false
local ControlBallConn = nil
local ControlBallSpeed = 80
local OriginalCameraSubject = nil
local OriginalCameraType = nil
local CurveBallMode = "Desativar"
local CurveBallForce = 30
local CurveBallConn = nil
local CurveBallOnKick = true
local CurveBallKickDuration = 0.5
local CurveBallKickEnd = 0
local CurveBallAlwaysActive = false
local LoopBallEnabled = false
local LoopBallConn = nil
local LoopBallDistance = 2.5
local LoopBallMinSpeed = 5
local ImaBallEnabled = false
local ImaBallConn = nil
local ImaBallForce = 60
local ImaBallRange = 40
local AutoGolBlueEnabled = false
local AutoGolGreenEnabled = false
local AutoGolCooldown = 0.4
local AutoGolLast = 0
local AutoGolForce = 180
local AutoGolArcY = 25
local AUTO_GOL_BLUE_CFRAMES = {
	Vector3.new(-32.18, -28.94, -203.58),
}
local AUTO_GOL_GREEN_CFRAMES = {
	Vector3.new(-34.06, -28.94, 383.88),
	Vector3.new(-3.92, -28.94, 388.81),
}
local SpeedEnabled = false
local SpeedValue = 24
local SpeedConn = nil
local AutoDiveEnabled = false
local AutoDiveCooldown = 0.8
local AutoDiveLastTime = 0
local AutoDiveRange = 15
local AutoDiveConn = nil
local AutoDiveMode = "Auto"
local GK_BUTTON_TEXTS = {
	["Esquerda Alto"] = "High Dive Left",
	["Direita Alto"]  = "High Dive Right",
	["Esquerda Baixo"] = "Dive Left",
	["Direita Baixo"] = "Dive Right",
	["Agarrar Alto"]  = "High Catch",
	["Agarrar Baixo"] = "Low Catch",
	["Reflexo"]       = "Reflex",
	["Frente"]        = "Front Dive",
	["Enfrentar"]     = "Rush",
}
local GKBotoes = {}
local CachedBall = nil
local corAtualBola = nil
local texturasBackup = {}
local rainbowConn = nil
local isRainbow = false
local function UpdateCharacter(newChar)
	Character = newChar
	Humanoid = newChar:WaitForChild("Humanoid")
	RootPart = newChar:WaitForChild("HumanoidRootPart")
end
LocalPlayer.CharacterAdded:Connect(UpdateCharacter)
local function EhBolaDeVerdade(obj)
	if not obj or not obj.Parent then return false end
	if Character and obj:IsDescendantOf(Character) then return false end
	local nomeLower = obj.Name:lower()
	if nomeLower == "head" or nomeLower == "torso" then return false end
	if nomeLower:find("stadium") or nomeLower:find("map") or nomeLower:find("goal")
		or nomeLower:find("net") or nomeLower:find("grass") or nomeLower:find("field") then
		return false
	end
	local parentModel = obj:FindFirstAncestorOfClass("Model")
	if parentModel and parentModel:FindFirstChildOfClass("Humanoid") then return false end
	if nomeLower == "tps" or nomeLower == "ball" or nomeLower == "bola"
		or nomeLower:find("soccerball") or nomeLower:find("football") or nomeLower:find("sphere") then
		return true
	end
	local temMesh = obj:FindFirstChildOfClass("SpecialMesh") ~= nil
	if temMesh and not obj.Anchored then
		local size = obj.Size
		if size.X >= 0.5 and size.X <= 8 then return true end
	end
	return false
end
local function GetValidBall()
	if not RootPart or not RootPart.Parent then return nil end
	local bolaMaisProxima = nil
	local menorDistancia = math.huge
	for _, obj in ipairs(workspace:GetDescendants()) do
		if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and not (Character and obj:IsDescendantOf(Character)) then
			local n = obj.Name:lower()
			if n == "tps" or n == "ball" or n == "bola" then
				local parentModel = obj:FindFirstAncestorOfClass("Model")
				if not (parentModel and parentModel:FindFirstChildOfClass("Humanoid")) then
					local size = obj.Size
					if size.X >= 0.5 and size.X <= 8 then
						local distancia = (obj.Position - RootPart.Position).Magnitude
						if distancia < menorDistancia then
							menorDistancia = distancia
							bolaMaisProxima = obj
						end
					end
				end
			end
		end
	end
	CachedBall = bolaMaisProxima
	return bolaMaisProxima
end
local function PegarTodasBolas()
	local bolas = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if (obj:IsA("BasePart") or obj:IsA("MeshPart")) then
			local n = obj.Name:lower()
			if n == "tps" or n == "ball" or n == "bola" then
				if EhBolaDeVerdade(obj) then
					local size = obj.Size
					if size.X >= 0.5 and size.X <= 8 then
						table.insert(bolas, obj)
					end
				end
			end
		end
	end
	return bolas
end
task.spawn(function()
	while true do
		task.wait(0.15)
		for _, ball in ipairs(PegarTodasBolas()) do
			if ball and ball.Parent then
				local blocked = IsBlockedPosition(ball.Position)
				if blocked then
					local dir = (ball.Position - BLOCKED_CFRAMES[1].Pos)
					if dir.Magnitude < 0.1 then
						dir = Vector3.new(0, 1, 0)
					end
					ball.CFrame = CFrame.new(ball.Position + dir.Unit * 30)
					ball.AssemblyLinearVelocity = Vector3.zero
					ball.AssemblyAngularVelocity = Vector3.zero
				end
			end
		end
	end
end)
local function salvarTexturas()
	local bolas = PegarTodasBolas()
	for _, part in pairs(bolas) do
		if texturasBackup[part] then continue end
		local data = {}
		pcall(function()
			if part:IsA("MeshPart") and part.TextureID ~= "" then
				data.TextureID = part.TextureID
			end
		end)
		local mesh = part:FindFirstChildWhichIsA("SpecialMesh")
		if mesh then
			pcall(function()
				if mesh.TextureId ~= "" then
					data.MeshTexId = mesh.TextureId
					data.Mesh = mesh
				end
			end)
		end
		data.Decals = {}
		for _, child in pairs(part:GetChildren()) do
			if child:IsA("Texture") or child:IsA("Decal") then
				table.insert(data.Decals, { Obj = child, Trans = child.Transparency })
			end
		end
		pcall(function()
			data.CorOriginal = part.Color
			data.MaterialOriginal = part.Material
		end)
		texturasBackup[part] = data
	end
end
local function removerTexturasDeUma(part)
	pcall(function()
		if part:IsA("MeshPart") then part.TextureID = "" end
	end)
	pcall(function()
		local mesh = part:FindFirstChildWhichIsA("SpecialMesh")
		if mesh then mesh.TextureId = "" end
	end)
	for _, child in pairs(part:GetChildren()) do
		pcall(function()
			if child:IsA("Texture") or child:IsA("Decal") then
				child.Transparency = 1
			end
		end)
	end
end
local function restaurarTexturas()
	for part, data in pairs(texturasBackup) do
		if not part or not part.Parent then continue end
		pcall(function()
			if data.TextureID then part.TextureID = data.TextureID end
		end)
		pcall(function()
			if data.MeshTexId and data.Mesh then data.Mesh.TextureId = data.MeshTexId end
		end)
		for _, d in pairs(data.Decals) do
			pcall(function()
				if d.Obj and d.Obj.Parent then d.Obj.Transparency = d.Trans end
			end)
		end
		pcall(function()
			if data.CorOriginal then part.Color = data.CorOriginal end
			if data.MaterialOriginal then part.Material = data.MaterialOriginal end
		end)
	end
end
local function pararRainbow()
	if rainbowConn then
		rainbowConn:Disconnect()
		rainbowConn = nil
	end
	isRainbow = false
end
local function AplicarCorEmTodas(cor, material)
	pararRainbow()
	corAtualBola = cor
	salvarTexturas()
	for _, part in ipairs(PegarTodasBolas()) do
		pcall(function()
			if Character and part:IsDescendantOf(Character) then return end
			removerTexturasDeUma(part)
			part.Color = cor
			if material then part.Material = material end
		end)
	end
end
local function iniciarRainbow()
	pararRainbow()
	salvarTexturas()
	for _, part in ipairs(PegarTodasBolas()) do
		removerTexturasDeUma(part)
	end
	isRainbow = true
	corAtualBola = "rainbow"
	local hue = 0
	rainbowConn = RunService.Heartbeat:Connect(function(dt)
		hue = (hue + dt * 0.5) % 1
		local c = Color3.fromHSV(hue, 0.85, 1)
		for _, part in pairs(PegarTodasBolas()) do
			pcall(function()
				if part and part.Parent then part.Color = c end
			end)
		end
	end)
end
local function RestaurarBola()
	pararRainbow()
	restaurarTexturas()
	corAtualBola = nil
end
workspace.DescendantAdded:Connect(function(obj)
	task.wait(0.3)
	if (obj:IsA("BasePart") or obj:IsA("MeshPart")) and corAtualBola then
		if EhBolaDeVerdade(obj) then
			if corAtualBola == "rainbow" then
				pcall(function() removerTexturasDeUma(obj) end)
			else
				pcall(function()
					removerTexturasDeUma(obj)
					obj.Color = corAtualBola
				end)
			end
		end
	end
end)
task.spawn(function()
	while true do
		task.wait(0.5)
		if corAtualBola and corAtualBola ~= "rainbow" then
			for _, ball in ipairs(PegarTodasBolas()) do
				pcall(function()
					if ball and ball.Parent and ball.Color ~= corAtualBola then
						removerTexturasDeUma(ball)
						ball.Color = corAtualBola
					end
				end)
			end
		end
	end
end)
local CatchRemote = nil
pcall(function()
	CatchRemote = ReplicatedStorage:FindFirstChild("CatchBall", true)
end)
local function TryCatch(ball)
	if not ball or not ball.Parent then return end
	if CatchRemote then
		pcall(function()
			if CatchRemote:IsA("RemoteEvent") then
				CatchRemote:FireServer(ball)
			elseif CatchRemote:IsA("RemoteFunction") then
				CatchRemote:InvokeServer(ball)
			end
		end)
	end
	AutoCatchLast = tick()
end
local function ScanGoalPosition(teamName)
	local mapa = workspace:FindFirstChild("WorkspaceStadiumMap1")
	if mapa then
		local teamNames = {}
		if teamName == "Blue" then
			teamNames = {"Team1", "TeamBlue", "BlueGoal", "Goal1", "GoalBlue"}
		else
			teamNames = {"Team2", "TeamGreen", "GreenGoal", "Goal2", "GoalGreen"}
		end
		for _, tn in ipairs(teamNames) do
			local team = mapa:FindFirstChild(tn, true)
			if team then
				if team:IsA("BasePart") then
					return team.Position
				end
				local union = team:FindFirstChild("Union2") or team:FindFirstChild("Union") or team:FindFirstChildWhichIsA("BasePart", true)
				if union and union:IsA("BasePart") then
					return union.Position
				end
			end
		end
	end
	local golKeywords
	if teamName == "Blue" then
		golKeywords = {"goalblue", "goal1", "bluegoal", "team1", "teamblue", "goalpost1", "blue_goal"}
	else
		golKeywords = {"goalgreen", "goal2", "greengoal", "team2", "teamgreen", "goalpost2", "green_goal"}
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Anchored then
			local n = obj.Name:lower()
			for _, keyword in ipairs(golKeywords) do
				if n:find(keyword) then
					return obj.Position
				end
			end
		end
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local n = obj.Name:lower()
			local isTarget = false
			if teamName == "Blue" and (n:find("team1") or n:find("blue") or n:find("goal1")) then
				isTarget = true
			elseif teamName == "Green" and (n:find("team2") or n:find("green") or n:find("goal2")) then
				isTarget = true
			end
			if isTarget then
				for _, child in ipairs(obj:GetDescendants()) do
					if child:IsA("BasePart") then
						return child.Position
					end
				end
			end
		end
	end
	local minZ, maxZ = math.huge, -math.huge
	local minZPart, maxZPart = nil, nil
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Anchored and obj.Size.X > 5 then
			local n = obj.Name:lower()
			if n:find("goal") or n:find("post") or n:find("net") or n:find("union") then
				if obj.Position.Z < minZ then
					minZ = obj.Position.Z
					minZPart = obj
				end
				if obj.Position.Z > maxZ then
					maxZ = obj.Position.Z
					maxZPart = obj
				end
			end
		end
	end
	if teamName == "Blue" and minZPart then
		return minZPart.Position
	elseif teamName == "Green" and maxZPart then
		return maxZPart.Position
	end
	return nil
end
local function doAimbot(direcaoGol)
	local ball = GetValidBall()
	if not ball or not ball.Parent then return end
	if not RootPart or not RootPart.Parent then return end
	local vel = ball.AssemblyLinearVelocity
	if vel.Magnitude < 15 then return end
	local golPos = ScanGoalPosition(direcaoGol)
	if not golPos then return end
	local dirGol = (Vector3.new(golPos.X - ball.Position.X, 0, golPos.Z - ball.Position.Z)).Unit
	local velH = Vector3.new(vel.X, 0, vel.Z)
	if velH.Magnitude < 0.1 then return end
	local velAlvo = velH.Unit:Lerp(dirGol, 0.25)
	ball.AssemblyLinearVelocity = Vector3.new(velAlvo.X * velH.Magnitude, vel.Y, velAlvo.Z * velH.Magnitude)
	ball.AssemblyAngularVelocity = Vector3.zero
end
local function TeleportToBall()
	local ball = GetValidBall()
	if not ball or not ball.Parent then
		Notify({ Title = "TP Ball", Content = "Nenhuma bola encontrada.", Duration = 2 })
		return
	end
	if not RootPart or not RootPart.Parent then return end
	local direcao = (ball.Position - RootPart.Position).Unit
	local posFinal = ball.Position - (direcao * 2.5) + Vector3.new(0, 2, 0)
	RootPart.CFrame = CFrame.new(posFinal)
	Notify({ Title = "TP Ball", Content = "Teleportado para a bola.", Duration = 1.5 })
end
local function StartLoopBall()
	if LoopBallConn then return end
	LoopBallConn = RunService.Heartbeat:Connect(function()
		if not LoopBallEnabled then return end
		if not RootPart or not RootPart.Parent then return end
		local ball = GetValidBall()
		if not ball or not ball.Parent then return end
		local vel = ball.AssemblyLinearVelocity
		if vel.Magnitude < LoopBallMinSpeed then
			return
		end
		local dir = (ball.Position - RootPart.Position)
		local dirH = Vector3.new(dir.X, 0, dir.Z)
		if dirH.Magnitude < 0.1 then
			RootPart.CFrame = CFrame.new(ball.Position + Vector3.new(0, 1.5, 0))
		else
			local dirUnit = dirH.Unit
			local posFinal = ball.Position - (dirUnit * LoopBallDistance) + Vector3.new(0, 1.5, 0)
			RootPart.CFrame = CFrame.new(posFinal)
		end
		pcall(function()
			firetouchinterest(RootPart, ball, 0)
			firetouchinterest(RootPart, ball, 1)
		end)
	end)
end
local function StopLoopBall()
	if LoopBallConn then
		LoopBallConn:Disconnect()
		LoopBallConn = nil
	end
end
local function StartImaBall()
	if ImaBallConn then return end
	ImaBallConn = RunService.Heartbeat:Connect(function(dt)
		if not ImaBallEnabled then return end
		if not RootPart or not RootPart.Parent then return end
		local ball = GetValidBall()
		if not ball or not ball.Parent then return end
		local dir = RootPart.Position - ball.Position
		local dist = dir.Magnitude
		if dist > ImaBallRange or dist < 0.5 then return end
		local dirUnit = dir.Unit
		local forceMultiplier = math.clamp(1 - (dist / ImaBallRange), 0.3, 1)
		local pull = dirUnit * ImaBallForce * forceMultiplier
		local vel = ball.AssemblyLinearVelocity
		local newVel = vel:Lerp(pull, dt * 8)
		ball.AssemblyLinearVelocity = newVel
	end)
end
local function StopImaBall()
	if ImaBallConn then
		ImaBallConn:Disconnect()
		ImaBallConn = nil
	end
end
local function EscolherCFrameAleatorio(lista)
	return lista[math.random(1, #lista)]
end
local function CheckAutoGol()
	if not AutoGolBlueEnabled and not AutoGolGreenEnabled then return end
	if not RootPart or not RootPart.Parent then return end
	if tick() - AutoGolLast < AutoGolCooldown then return end
	local ball = GetValidBall()
	if not ball or not ball.Parent then return end
	local dist = (ball.Position - RootPart.Position).Magnitude
	if dist > 6 then return end
	local target
	if AutoGolBlueEnabled and AutoGolGreenEnabled then
		if math.random() < 0.5 then
			target = EscolherCFrameAleatorio(AUTO_GOL_BLUE_CFRAMES)
		else
			target = EscolherCFrameAleatorio(AUTO_GOL_GREEN_CFRAMES)
		end
	elseif AutoGolBlueEnabled then
		target = EscolherCFrameAleatorio(AUTO_GOL_BLUE_CFRAMES)
	elseif AutoGolGreenEnabled then
		target = EscolherCFrameAleatorio(AUTO_GOL_GREEN_CFRAMES)
	end
	if not target then return end
	AutoGolLast = tick()
	local dir = (target - ball.Position)
	local dirH = Vector3.new(dir.X, 0, dir.Z)
	if dirH.Magnitude < 0.1 then return end
	local dirUnit = dirH.Unit
	local shootVec = (dirUnit * AutoGolForce) + Vector3.new(0, AutoGolArcY, 0)
	local currentVel = ball.AssemblyLinearVelocity
	ball.AssemblyLinearVelocity = currentVel:Lerp(shootVec, 0.85)
	ball.AssemblyAngularVelocity = Vector3.new(
		math.random(-15, 15),
		math.random(-15, 15),
		math.random(-15, 15)
	)
	pcall(function()
		firetouchinterest(RootPart, ball, 0)
		firetouchinterest(RootPart, ball, 1)
	end)
end
local function AplicarSpeed(velocidade, dt)
	if not Humanoid or not RootPart or not RootPart.Parent then return end
	if not Character or not Character.Parent then return end
	if Humanoid.Health <= 0 then return end
	if Humanoid.Sit or Humanoid.SeatPart then return end
	local moveDir = Humanoid.MoveDirection
	if moveDir.Magnitude < 0.05 then return end
	local targetVel = moveDir.Unit * velocidade
	local currentVel = RootPart.AssemblyLinearVelocity
	local horizontal = Vector3.new(currentVel.X, 0, currentVel.Z)
	if (horizontal - targetVel).Magnitude < 0.5 then return end
	local state = Humanoid:GetState()
	if state == Enum.HumanoidStateType.Freefall 
		or state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Swimming then
		return
	end
	local jitter = math.random(-30, 30) / 100
	local finalVel = moveDir.Unit * (velocidade + jitter)
	local newVel = horizontal:Lerp(finalVel, math.clamp(dt * 15, 0, 1))
	RootPart.AssemblyLinearVelocity = Vector3.new(newVel.X, currentVel.Y, newVel.Z)
end
local function StartSpeed()
	if SpeedConn then return end
	SpeedConn = RunService.Heartbeat:Connect(function(dt)
		if not SpeedEnabled then return end
		AplicarSpeed(SpeedValue, dt)
	end)
end
local function StopSpeed()
	if SpeedConn then
		SpeedConn:Disconnect()
		SpeedConn = nil
	end
end
local function EscanearBotoesGK()
	GKBotoes = {}
	pcall(function()
		for _, v in ipairs(PlayerGui:GetDescendants()) do
			if v:IsA("TextButton") or v:IsA("ImageButton") then
				local nome = v.Name
				local texto = ""
				pcall(function() texto = v.Text end)
				if nome:find("GK") or nome:find("C2") 
					or texto:find("Dive") or texto:find("Catch") 
					or texto:find("High") or texto:find("Low")
					or texto:find("Reflex") or texto:find("Forward")
					or texto:find("Front") or texto:find("Rush") then
					table.insert(GKBotoes, {
						Button = v,
						Nome = nome,
						Texto = texto,
					})
				end
			end
		end
	end)
	print("[Auto Dive] Botões GK encontrados:", #GKBotoes)
	for _, b in ipairs(GKBotoes) do
		print("  ->", b.Nome, "| Texto:", b.Texto)
	end
end
EscanearBotoesGK()
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(2)
	EscanearBotoesGK()
end)
local function EncontrarBotaoPorTexto(texto)
	for _, info in ipairs(GKBotoes) do
		if info.Texto and info.Texto:lower() == texto:lower() then
			return info.Button
		end
	end
	for _, info in ipairs(GKBotoes) do
		if info.Texto and info.Texto:lower():find(texto:lower(), 1, true) then
			return info.Button
		end
	end
	return nil
end
local function ClicarBotao(botao)
	if not botao then return end
	pcall(function() firesignal(botao.Activated) end)
	pcall(function() firesignal(botao.MouseButton1Click) end)
	pcall(function() firesignal(botao.MouseButton1Down) end)
	pcall(function() firesignal(botao.MouseButton1Up) end)
	pcall(function() firesignal(botao.TouchTap) end)
end
local function Pular()
	pcall(function()
		Humanoid.Jump = true
	end)
	pcall(function()
		Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end)
end
local function DelaySeguro(t)
	if t > 0 then
		task.wait(t)
	end
end
local function AnalisarBola()
	local ball = GetValidBall()
	if not ball or not RootPart then return nil end
	local vel = ball.AssemblyLinearVelocity
	local dist = (ball.Position - RootPart.Position).Magnitude
	local tempo = 0
	if vel.Magnitude > 3 then
		tempo = dist / vel.Magnitude
		tempo = math.clamp(tempo, 0, 0.6)
	end
	local posFutura = ball.Position + (vel * tempo)
	local camLook = Camera.CFrame.LookVector
	local camRight = Camera.CFrame.RightVector
	local frenteH = Vector3.new(camLook.X, 0, camLook.Z)
	if frenteH.Magnitude < 0.1 then frenteH = Vector3.new(0, 0, -1) end
	frenteH = frenteH.Unit
	local direitaH = Vector3.new(camRight.X, 0, camRight.Z)
	if direitaH.Magnitude < 0.1 then direitaH = Vector3.new(1, 0, 0) end
	direitaH = direitaH.Unit
	local delta = posFutura - RootPart.Position
	local deltaH = Vector3.new(delta.X, 0, delta.Z)
	local ladoX = deltaH:Dot(direitaH)
	local ladoY = posFutura.Y - RootPart.Position.Y
	local frenteDist = deltaH:Dot(frenteH)
	return {
		ball = ball,
		vel = vel,
		dist = dist,
		posFutura = posFutura,
		lado = ladoX,
		altura = ladoY,
		frente = frenteDist,
	}
end
local function ExecutarAutoCatchIntel()
	local info = AnalisarBola()
	if not info then return end
	local lado = info.lado
	local altura = info.altura
	local ladoAbs = math.abs(lado)
	local bolaAlta = altura > AutoCatchIntelHeight
	local bolaLateral = ladoAbs >= 2.5
	if bolaLateral then
		if bolaAlta then
			local textoDive = lado < 0 and "High Dive Left" or "High Dive Right"
			local botaoDive = EncontrarBotaoPorTexto(textoDive)
			if botaoDive then
				ClicarBotao(botaoDive)
				print(string.format("[Auto Catch Intel] %s | lado=%.1f altura=%.1f",
					textoDive, lado, altura))
			end
		else
			local botao = EncontrarBotaoPorTexto("Low Catch")
			if botao then
				ClicarBotao(botao)
				print(string.format("[Auto Catch Intel] Low Catch | lado=%.1f altura=%.1f",
					lado, altura))
			end
		end
	else
		if bolaAlta then
			task.spawn(Pular)
			DelaySeguro(0.05)
			local botao = EncontrarBotaoPorTexto("High Catch")
			if botao then
				ClicarBotao(botao)
				print(string.format("[Auto Catch Intel] Pulo + High Catch | altura=%.1f", altura))
			end
		else
			local botao = EncontrarBotaoPorTexto("Low Catch")
			if botao then
				ClicarBotao(botao)
				print(string.format("[Auto Catch Intel] Low Catch | altura=%.1f", altura))
			end
		end
	end
end
local function StartAutoCatchIntel()
	if AutoCatchIntelConn then return end
	if #GKBotoes == 0 then
		EscanearBotoesGK()
	end
	AutoCatchIntelConn = RunService.Heartbeat:Connect(function()
		if not AutoCatchIntelEnabled then return end
		if not RootPart or not RootPart.Parent then return end
		if tick() - AutoCatchIntelLast < AutoCatchIntelCooldown then return end
		local info = AnalisarBola()
		if not info then return end
		if info.dist > AutoCatchIntelRange then return end
		if info.vel.Magnitude < 4 then return end
		local dirParaPlayer = (RootPart.Position - info.ball.Position)
		local dirH = Vector3.new(dirParaPlayer.X, 0, dirParaPlayer.Z)
		if dirH.Magnitude < 0.1 then return end
		local velH = Vector3.new(info.vel.X, 0, info.vel.Z)
		if velH.Magnitude < 0.1 then return end
		local dot = velH.Unit:Dot(dirH.Unit)
		if dot > 0.15 then
			AutoCatchIntelLast = tick()
			task.spawn(ExecutarAutoCatchIntel)
		end
	end)
end
local function StopAutoCatchIntel()
	if AutoCatchIntelConn then
		AutoCatchIntelConn:Disconnect()
		AutoCatchIntelConn = nil
	end
end
local function ExecutarDive()
	local ball = GetValidBall()
	if not ball or not RootPart then return end
	local ballVel = ball.AssemblyLinearVelocity
	local distBola = (ball.Position - RootPart.Position).Magnitude
	local tempoChegada = 0
	if ballVel.Magnitude > 5 then
		tempoChegada = math.clamp(distBola / ballVel.Magnitude, 0, 0.7)
	end
	local posFutura = ball.Position + (ballVel * tempoChegada)
	local camLook = Camera.CFrame.LookVector
	local camRight = Camera.CFrame.RightVector
	local direitaH = Vector3.new(camRight.X, 0, camRight.Z)
	if direitaH.Magnitude < 0.1 then direitaH = Vector3.new(1, 0, 0) end
	direitaH = direitaH.Unit
	local delta = posFutura - RootPart.Position
	local lado = (Vector3.new(delta.X, 0, delta.Z)):Dot(direitaH)
	local altura = delta.Y
	local textoAlvo
	if AutoDiveMode ~= "Auto" then
		textoAlvo = GK_BUTTON_TEXTS[AutoDiveMode]
	else
		if altura > AutoCatchIntelHeight then
			textoAlvo = lado > 0 and "High Dive Right" or "High Dive Left"
		else
			textoAlvo = lado > 0 and "Dive Right" or "Dive Left"
		end
	end
	if not textoAlvo then return end
	local botaoEncontrado = nil
	for _, info in ipairs(GKBotoes) do
		if info.Texto and info.Texto:lower() == textoAlvo:lower() then
			botaoEncontrado = info.Button
			break
		end
	end
	if not botaoEncontrado then
		for _, info in ipairs(GKBotoes) do
			if info.Texto and info.Texto:lower():find(textoAlvo:lower(), 1, true) then
				botaoEncontrado = info.Button
				break
			end
		end
	end
	if botaoEncontrado then
		pcall(function() firesignal(botaoEncontrado.Activated) end)
		pcall(function() firesignal(botaoEncontrado.MouseButton1Click) end)
		pcall(function() firesignal(botaoEncontrado.MouseButton1Down) end)
		pcall(function() firesignal(botaoEncontrado.MouseButton1Up) end)
		pcall(function() firesignal(botaoEncontrado.TouchTap) end)
		print(string.format("[Auto Dive] %s | Lado: %.1f | Altura: %.1f",
			textoAlvo, lado, altura))
	else
		print("[Auto Dive] Botão não encontrado:", textoAlvo)
	end
end
local function StartAutoDive()
	if AutoDiveConn then return end
	if #GKBotoes == 0 then
		EscanearBotoesGK()
	end
	AutoDiveConn = RunService.Heartbeat:Connect(function()
		if not AutoDiveEnabled then return end
		if AutoDiveBloquearSeIntelAtivo and AutoCatchIntelEnabled then return end
		if not RootPart or not RootPart.Parent then return end
		if tick() - AutoDiveLastTime < AutoDiveCooldown then return end
		local ball = GetValidBall()
		if not ball or not ball.Parent then return end
		local dist = (ball.Position - RootPart.Position).Magnitude
		if dist > AutoDiveRange then return end
		local ballVel = ball.AssemblyLinearVelocity
		if ballVel.Magnitude < 5 then return end
		local dirParaPlayer = (RootPart.Position - ball.Position)
		local dirH = Vector3.new(dirParaPlayer.X, 0, dirParaPlayer.Z)
		if dirH.Magnitude < 0.1 then return end
		local ballVelH = Vector3.new(ballVel.X, 0, ballVel.Z)
		if ballVelH.Magnitude < 0.1 then return end
		local dot = ballVelH.Unit:Dot(dirH.Unit)
		if dot > 0.15 then
			AutoDiveLastTime = tick()
			task.spawn(ExecutarDive)
		end
	end)
end
local function StopAutoDive()
	if AutoDiveConn then
		AutoDiveConn:Disconnect()
		AutoDiveConn = nil
	end
end
local function FlingBall()
	local ball = GetValidBall()
	if not ball or not ball.Parent then
		Notify({ Title = "Fling Ball", Content = "Nenhuma bola encontrada.", Duration = 2 })
		return
	end
	if not RootPart or not RootPart.Parent then return end
	local direcao = (ball.Position - RootPart.Position).Unit
	local posFinal = ball.Position - (direcao * 1.5) + Vector3.new(0, 1, 0)
	RootPart.CFrame = CFrame.new(posFinal)
	task.wait(0.1)
	if ball and ball.Parent then
		local randomDir = Vector3.new(
			math.random(-100, 100) / 100,
			1,
			math.random(-100, 100) / 100
		).Unit
		ball.AssemblyLinearVelocity = randomDir * FlingBallForce + Vector3.new(0, FlingBallForce * 0.6, 0)
		ball.AssemblyAngularVelocity = Vector3.new(
			math.random(-50, 50),
			math.random(-50, 50),
			math.random(-50, 50)
		)
		pcall(function()
			firetouchinterest(RootPart, ball, 0)
			firetouchinterest(RootPart, ball, 1)
		end)
		Notify({ Title = "Fling Ball", Content = "Bola flingada.", Duration = 1.5 })
	end
end
local function CheckPowerShoot()
	if not PowerShootEnabled then return end
	if not RootPart or not RootPart.Parent then return end
	local ball = GetValidBall()
	if not ball or not ball.Parent then return end
	local dist = (ball.Position - RootPart.Position).Magnitude
	if dist > PowerShootRange then return end
	local dir = (ball.Position - RootPart.Position).Unit
	local lookDir = RootPart.CFrame.LookVector
	local shootDir = (lookDir + dir).Unit
	ball.AssemblyLinearVelocity = shootDir * PowerShootForce + Vector3.new(0, PowerShootForce * 0.3, 0)
	ball.AssemblyAngularVelocity = Vector3.new(
		math.random(-30, 30),
		math.random(-30, 30),
		math.random(-30, 30)
	)
	pcall(function()
		firetouchinterest(RootPart, ball, 0)
		firetouchinterest(RootPart, ball, 1)
	end)
end
local function StartControlBall()
	if ControlBallConn then return end
	local ball = GetValidBall()
	if not ball or not ball.Parent then
		Notify({ Title = "Control Ball", Content = "Nenhuma bola encontrada.", Duration = 2 })
		ControlBallEnabled = false
		return
	end
	OriginalCameraType = Camera.CameraType
	OriginalCameraSubject = Camera.CameraSubject
	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = ball
	Notify({ Title = "Control Ball", Content = "Camera na bola! Gire a camera para mover.", Duration = 3 })
	ControlBallConn = RunService.Heartbeat:Connect(function(dt)
		if not ControlBallEnabled then return end
		ball = GetValidBall()
		if not ball or not ball.Parent then return end
		local blocked = IsBlockedPosition(ball.Position)
		if blocked then
			local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
			if spawn then
				ball.CFrame = CFrame.new(spawn.Position + Vector3.new(0, 10, 0))
			else
				ball.CFrame = CFrame.new(ball.Position + Vector3.new(0, 40, 0))
			end
			ball.AssemblyLinearVelocity = Vector3.zero
			return
		end
		if Camera.CameraSubject ~= ball then
			Camera.CameraSubject = ball
			Camera.CameraType = Enum.CameraType.Custom
		end
		local camLook = Camera.CFrame.LookVector
		local targetVel = camLook * ControlBallSpeed
		local currentVel = ball.AssemblyLinearVelocity
		local newVel = Vector3.new(targetVel.X, targetVel.Y, targetVel.Z)
		ball.AssemblyLinearVelocity = currentVel:Lerp(newVel, dt * 10)
		ball.AssemblyAngularVelocity = Vector3.zero
	end)
end
local function StopControlBall()
	if ControlBallConn then
		ControlBallConn:Disconnect()
		ControlBallConn = nil
	end
	pcall(function()
		if OriginalCameraSubject then
			Camera.CameraSubject = OriginalCameraSubject
		elseif Humanoid then
			Camera.CameraSubject = Humanoid
		end
		Camera.CameraType = OriginalCameraType or Enum.CameraType.Custom
	end)
	OriginalCameraType = nil
	OriginalCameraSubject = nil
end
local function AplicarCurva(ball, dt)
	if not ball or not ball.Parent then return end
	local vel = ball.AssemblyLinearVelocity
	local velH = Vector3.new(vel.X, 0, vel.Z)
	if velH.Magnitude < 5 then return end
	local forward = velH.Unit
	local force = Vector3.zero
	if CurveBallMode == "Direita" then
		force = Vector3.new(forward.Z, 0, -forward.X)
	elseif CurveBallMode == "Esquerda" then
		force = Vector3.new(-forward.Z, 0, forward.X)
	elseif CurveBallMode == "Cima" then
		force = Vector3.new(0, 1, 0)
	else
		return
	end
	local curveForce = force * CurveBallForce * dt * 60
	local finalVel = vel + curveForce
	local velHFinal = Vector3.new(finalVel.X, 0, finalVel.Z)
	local forwardDot = velHFinal.Unit:Dot(forward)
	if forwardDot < 0.5 then
		local correctedH = (forward * velH.Magnitude * 0.9) + Vector3.new(curveForce.X, 0, curveForce.Z)
		finalVel = Vector3.new(correctedH.X, finalVel.Y, correctedH.Z)
	end
	ball.AssemblyLinearVelocity = finalVel
end
local function StartCurveBall()
	if CurveBallConn then return end
	CurveBallConn = RunService.Heartbeat:Connect(function(dt)
		if CurveBallMode == "Desativar" then return end
		if CurveBallOnKick and not CurveBallAlwaysActive then
			if tick() > CurveBallKickEnd then return end
		end
		for _, ball in ipairs(PegarTodasBolas()) do
			AplicarCurva(ball, dt)
		end
	end)
end
local function StopCurveBall()
	if CurveBallConn then
		CurveBallConn:Disconnect()
		CurveBallConn = nil
	end
end
local function UpdateCurveBall()
	if CurveBallMode == "Desativar" then
		StopCurveBall()
	else
		if not CurveBallConn then
			StartCurveBall()
		end
	end
end
local function DetectarChute()
	local function marcarChute()
		CurveBallKickEnd = tick() + CurveBallKickDuration
	end
	local function hookTool(tool)
		if not tool:IsA("Tool") then return end
		local nome = tool.Name:lower()
		if nome:find("chutar") or nome:find("chute") or nome:find("kick")
			or nome:find("shoot") or nome:find("bater") or nome:find("toque") then
			tool.Activated:Connect(marcarChute)
			tool.Unequipped:Connect(marcarChute)
		end
	end
	local function hookAllTools(container)
		if not container then return end
		for _, obj in ipairs(container:GetChildren()) do
			hookTool(obj)
		end
		container.ChildAdded:Connect(function(child)
			task.wait(0.1)
			hookTool(child)
		end)
	end
	hookAllTools(LocalPlayer:FindFirstChild("Backpack"))
	hookAllTools(Character)
	LocalPlayer.CharacterAdded:Connect(function(newChar)
		task.wait(1)
		hookAllTools(LocalPlayer:FindFirstChild("Backpack"))
		hookAllTools(newChar)
	end)
	pcall(function()
		local function hookRemote(v)
			if v:IsA("RemoteEvent") then
				local n = v.Name:lower()
				if n:find("chutar") or n:find("chute") or n:find("kick")
					or n:find("shoot") or n:find("bater") then
					v.OnClientEvent:Connect(marcarChute)
				end
			end
		end
		for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
			hookRemote(v)
		end
		ReplicatedStorage.DescendantAdded:Connect(function(v)
			task.wait(0.1)
			hookRemote(v)
		end)
	end)
end
task.spawn(DetectarChute)
local function TouchBall(ball)
	if not ball or not ball.Parent then return end
	if not RootPart or not RootPart.Parent then return end
	pcall(function()
		firetouchinterest(RootPart, ball, 0)
		firetouchinterest(RootPart, ball, 1)
	end)
	local lf = Character:FindFirstChild("Left Foot") or Character:FindFirstChild("Left Leg")
	local rf = Character:FindFirstChild("Right Foot") or Character:FindFirstChild("Right Leg")
	if lf then
		pcall(function()
			firetouchinterest(lf, ball, 0)
			firetouchinterest(lf, ball, 1)
		end)
	end
	if rf then
		pcall(function()
			firetouchinterest(rf, ball, 0)
			firetouchinterest(rf, ball, 1)
		end)
	end
end
local function SendCharCommand(name)
	local success = pcall(function()
		local Channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
		if Channel then
			Channel:SendAsync(":char " .. name)
		else
			error("Canal nao encontrado")
		end
	end)
	if not success then
		pcall(function()
			ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents")
				:WaitForChild("SayMessageRequest")
				:FireServer(":char " .. name, "All")
		end)
	end
end
local function HabilidadeAtiva()
	if not Humanoid then return true end
	if Humanoid.Sit or Humanoid.SeatPart then return true end
	local estado = Humanoid:GetState()
	if estado ~= Enum.HumanoidStateType.Running
		and estado ~= Enum.HumanoidStateType.RunningNoPhysics
		and estado ~= Enum.HumanoidStateType.Jumping
		and estado ~= Enum.HumanoidStateType.Landed
		and estado ~= Enum.HumanoidStateType.Freefall then
		return true
	end
	return false
end
local function IsManualInputActive()
	if ControlBallEnabled then return true end
	return UserInputService:IsKeyDown(Enum.KeyCode.W)
		or UserInputService:IsKeyDown(Enum.KeyCode.A)
		or UserInputService:IsKeyDown(Enum.KeyCode.S)
		or UserInputService:IsKeyDown(Enum.KeyCode.D)
end
RunService.PreRender:Connect(function()
	if not RootPart or not RootPart.Parent or not Humanoid then return end
	local ball = GetValidBall()
	local habilidade = HabilidadeAtiva()
	if AutoFollowEnabled and not ControlBallEnabled and not LoopBallEnabled and not IsManualInputActive() and ball and not habilidade then
		local delta = ball.Position - RootPart.Position
		local moveDirection = Vector3.new(delta.X, 0, delta.Z)
		if moveDirection.Magnitude > 0.5 then
			Humanoid:Move(moveDirection.Unit, false)
		end
	end
	if ReachEnabled and ball and not habilidade then
		local distance = (ball.Position - RootPart.Position).Magnitude
		if distance <= ReachDistance then
			TouchBall(ball)
		end
	end
	if AutoCatchEnabled and tick() - AutoCatchLast >= AutoCatchDelay then
		local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
		if ball and hrp and (ball.Position - hrp.Position).Magnitude <= AutoCatchRange then
			TryCatch(ball)
		end
	end
	if AC_Hitbox and RootPart and RootPart.Parent then
		local d = AutoCatchRange * 2
		if not AC_HitboxPart or not AC_HitboxPart.Parent then
			AC_HitboxPart = Instance.new("Part")
			AC_HitboxPart.Name = "Newton_AC_Hitbox"
			AC_HitboxPart.Shape = Enum.PartType.Ball
			AC_HitboxPart.Material = Enum.Material.ForceField
			AC_HitboxPart.Color = Color3.fromRGB(0, 200, 255)
			AC_HitboxPart.Transparency = 0.65
			AC_HitboxPart.CanCollide = false
			AC_HitboxPart.CanQuery = false
			AC_HitboxPart.CanTouch = false
			AC_HitboxPart.Anchored = true
			AC_HitboxPart.Parent = workspace
		end
		AC_HitboxPart.Size = Vector3.new(d, d, d)
		AC_HitboxPart.Position = RootPart.Position
	elseif AC_HitboxPart and AC_HitboxPart.Parent then
		AC_HitboxPart:Destroy()
		AC_HitboxPart = nil
	end
	if AimbotBlueEnabled then doAimbot("Blue") end
	if AimbotGreenEnabled then doAimbot("Green") end
	CheckPowerShoot()
	CheckAutoGol()
end)

local Window = Library:CreateWindow({
    Title = "Rkz Hub",
    Footer = "Rkz Hub",
    Center = true,
    AutoShow = true,
    Resizable = true,
    MobileButtonsSide = "Left",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Goalkeeper = Window:AddTab("Goalkeeper", "shield"),
    Ball = Window:AddTab("Ball", "circle"),
    Troll = Window:AddTab("Troll", "zap"),
    AutoFarm = Window:AddTab("Auto Farm", "repeat"),
    Char = Window:AddTab("Char", "user"),
    Reach = Window:AddTab("Reach", "ruler"),
    Player = Window:AddTab("Player", "user"),
    Credits = Window:AddTab("Credits", "heart"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local function slider(box, id, text, default, min, max, rounding, callback)
    box:AddSlider(id, {Text=text, Default=default, Min=min, Max=max, Rounding=rounding or 0, Callback=callback})
end

local gk = Tabs.Goalkeeper:AddLeftGroupbox("Auto Catch")
gk:AddToggle("AutoCatchEnabled",{Text="Ativar Auto Catch",Default=false,Callback=function(v) AutoCatchEnabled=v end})
slider(gk,"AutoCatchRange","Distancia de Captura",8,3,30,1,function(v) AutoCatchRange=v end)
slider(gk,"AutoCatchDelay","Cooldown",1,0.2,3,1,function(v) AutoCatchDelay=v end)
gk:AddToggle("AC_Hitbox",{Text="Mostrar Hitbox do Auto Catch",Default=false,Callback=function(v) AC_Hitbox=v end})

local intel = Tabs.Goalkeeper:AddRightGroupbox("Auto Catch Inteligente")
intel:AddToggle("AutoCatchIntelEnabled",{Text="Ativar Auto Catch Inteligente",Default=false,Callback=function(v)
    AutoCatchIntelEnabled=v
    if v then StartAutoCatchIntel() else StopAutoCatchIntel() end
end})
slider(intel,"AutoCatchIntelRange","Alcance",16,5,35,1,function(v) AutoCatchIntelRange=v end)
slider(intel,"AutoCatchIntelHeight","Altura mínima",3.5,1,10,1,function(v) AutoCatchIntelHeight=v end)
slider(intel,"AutoCatchIntelCooldown","Cooldown",0.35,0.1,2,2,function(v) AutoCatchIntelCooldown=v end)

local dive = Tabs.Goalkeeper:AddLeftGroupbox("Auto Dive")
dive:AddToggle("AutoDiveEnabled",{Text="Ativar Auto Dive",Default=false,Callback=function(v)
    AutoDiveEnabled=v
    if v then StartAutoDive() else StopAutoDive() end
end})
dive:AddDropdown("AutoDiveMode",{Text="Modo do Dive",Values={"Auto","Esquerda Alto","Direita Alto","Esquerda Baixo","Direita Baixo","Agarrar Alto","Agarrar Baixo","Reflexo","Frente"},Default="Auto",Callback=function(v) AutoDiveMode=v end})
slider(dive,"AutoDiveRange","Alcance do Dive",15,5,30,1,function(v) AutoDiveRange=v end)
slider(dive,"AutoDiveCooldown","Cooldown do Dive",0.8,0.3,5,1,function(v) AutoDiveCooldown=v end)
dive:AddToggle("AutoDiveBlockIntel",{Text="Dive pausa quando Intel ON",Default=true,Callback=function(v) AutoDiveBloquearSeIntelAtivo=v end})

local ball = Tabs.Ball:AddLeftGroupbox("Ball")
ball:AddToggle("AutoFollowEnabled",{Text="Seguir Bola",Default=false,Callback=function(v)
    AutoFollowEnabled=v
    if not v and Humanoid then Humanoid:Move(Vector3.zero,false) end
end})
ball:AddButton({Text="Teleportar para a Bola",Func=TeleportToBall})
ball:AddToggle("AimbotBlueEnabled",{Text="Aimbot Blue",Default=false,Callback=function(v) AimbotBlueEnabled=v end})
ball:AddToggle("AimbotGreenEnabled",{Text="Aimbot Green",Default=false,Callback=function(v) AimbotGreenEnabled=v end})
ball:AddDropdown("CurveBallMode",{Text="Direção da Curva",Values={"Desativar","Direita","Esquerda","Cima"},Default="Desativar",Callback=function(v) CurveBallMode=v;UpdateCurveBall() end})
slider(ball,"CurveBallForce","Força da Curva",30,5,100,1,function(v) CurveBallForce=v end)
ball:AddToggle("CurveBallOnKick",{Text="Curvar Apenas no Chute",Default=true,Callback=function(v) CurveBallOnKick=v end})
slider(ball,"CurveBallKickDuration","Duração pós-chute",0.5,0.1,3,1,function(v) CurveBallKickDuration=v end)
ball:AddToggle("CurveBallAlwaysActive",{Text="Curva Sempre Ativa",Default=false,Callback=function(v) CurveBallAlwaysActive=v end})

local colors = Tabs.Ball:AddRightGroupbox("Cor da Bola")
colors:AddLabel("Escolher Cor"):AddColorPicker("BallColorPicker",{Default=Color3.fromRGB(89,247,255),Title="Cor da Bola",Callback=function(c) AplicarCorEmTodas(c,Enum.Material.Neon) end})
local CORES_BALL={{N="Azul",C=Color3.fromRGB(40,130,255)},{N="Verde",C=Color3.fromRGB(45,225,95)},{N="Roxo",C=Color3.fromRGB(155,55,255)},{N="Amarelo",C=Color3.fromRGB(255,220,30)},{N="Branco",C=Color3.fromRGB(255,255,255)},{N="Vermelho",C=Color3.fromRGB(255,45,45)},{N="Rosa",C=Color3.fromRGB(255,85,185)},{N="Laranja",C=Color3.fromRGB(255,150,30)},{N="Ciano",C=Color3.fromRGB(35,220,245)},{N="Dourado",C=Color3.fromRGB(255,195,50)},{N="Lima",C=Color3.fromRGB(140,255,50)},{N="Preto",C=Color3.fromRGB(20,20,20)}}
for _,c in ipairs(CORES_BALL) do colors:AddButton({Text=c.N,Func=function() AplicarCorEmTodas(c.C,Enum.Material.Neon) end}) end
colors:AddButton({Text="Arco-Iris",Func=iniciarRainbow})
colors:AddButton({Text="Restaurar Bola Original",Func=function() RestaurarBola();Notify({Title="Bola",Content="Bola restaurada!",Duration=2}) end})

local troll = Tabs.Troll:AddLeftGroupbox("Loop / Ímã")
troll:AddToggle("LoopBallEnabled",{Text="Ativar Loop Ball",Default=false,Callback=function(v) LoopBallEnabled=v;if v then StartLoopBall() else StopLoopBall() end end})
slider(troll,"LoopBallMinSpeed","Velocidade mínima da Bola",5,1,30,1,function(v) LoopBallMinSpeed=v end)
slider(troll,"LoopBallDistance","Distância da Bola",2.5,1,8,1,function(v) LoopBallDistance=v end)
troll:AddToggle("ImaBallEnabled",{Text="Ativar Ímã Ball",Default=false,Callback=function(v) ImaBallEnabled=v;if v then StartImaBall() else StopImaBall() end end})
slider(troll,"ImaBallForce","Força do Ímã",60,10,200,1,function(v) ImaBallForce=v end)
slider(troll,"ImaBallRange","Alcance do Ímã",40,5,100,1,function(v) ImaBallRange=v end)

local troll2 = Tabs.Troll:AddRightGroupbox("Control / Power")
troll2:AddToggle("ControlBallEnabled",{Text="Ativar Control Ball",Default=false,Callback=function(v) ControlBallEnabled=v;if v then StartControlBall() else StopControlBall() end end})
slider(troll2,"ControlBallSpeed","Velocidade da Bola",80,20,300,1,function(v) ControlBallSpeed=v end)
troll2:AddButton({Text="Fling Ball",Func=FlingBall})
slider(troll2,"FlingBallForce","Força do Fling",300,100,800,1,function(v) FlingBallForce=v end)
troll2:AddToggle("PowerShootEnabled",{Text="Ativar Power Shoot",Default=false,Callback=function(v) PowerShootEnabled=v end})
slider(troll2,"PowerShootForce","Força do Power Shoot",250,100,800,1,function(v) PowerShootForce=v end)
slider(troll2,"PowerShootRange","Alcance do Power Shoot",8,3,20,1,function(v) PowerShootRange=v end)

local farm = Tabs.AutoFarm:AddLeftGroupbox("Auto Gol")
farm:AddToggle("AutoGolBlueEnabled",{Text="Auto Gol Blue",Default=false,Callback=function(v) AutoGolBlueEnabled=v end})
farm:AddToggle("AutoGolGreenEnabled",{Text="Auto Gol Green",Default=false,Callback=function(v) AutoGolGreenEnabled=v end})
slider(farm,"AutoGolForce","Força do Arremesso",180,50,500,1,function(v) AutoGolForce=v end)
slider(farm,"AutoGolArcY","Arco (altura)",25,0,100,1,function(v) AutoGolArcY=v end)
slider(farm,"AutoGolCooldown","Cooldown",0.4,0.1,3,1,function(v) AutoGolCooldown=v end)

local charBox = Tabs.Char:AddLeftGroupbox("Chars Disponíveis")
local CharList={"Feliipeef","pret_oncio","jessnaldo","lucasbr8181","PositiveVapor","kvbberdad","kvbber","ongoal","leolity","pauloneto05","candyxzzz0","BRENOTAKEDA2011","monoball_jhh","zvbFaeTVXTq","defantastico","emaofj","5zB4y","ByGui08","levi_furacao","o_lfk","feliou23","3qu","thunder65q","MiguelcalebeGamer202","legendinho","THIXGOOOOOO","talenttt","vnpthu","oxlade","Dismalbeni","megutrap","brvnofalcon","Rhuanbla","SenAstrozx","I_Ruanblox","Rvnezzy","heheboi202000","Nescauzin_skills","lilililililili_305","heitor756666","nexzaard","mitoashpikachu2","rosa_skillsz","zico_alt123","b_2020f","ry_dinno","cachorrao_fla","barard28","Miguelcalebegame202","yurinho_0011","deyvztcs","euperdro14","Alex151kk"}
for _,name in ipairs(CharList) do charBox:AddButton({Text=name,Func=function() SendCharCommand(name);Notify({Title="Char",Content="Aplicando: "..name,Duration=2}) end}) end

local reach = Tabs.Reach:AddLeftGroupbox("Reach")
reach:AddToggle("ReachEnabled",{Text="Ativar Reach",Default=false,Callback=function(v) ReachEnabled=v end})
slider(reach,"ReachDistance","Distância do Reach",10,1,50,1,function(v) ReachDistance=v end)

local player = Tabs.Player:AddLeftGroupbox("Speed")
player:AddToggle("SpeedEnabled",{Text="Ativar Speed",Default=false,Callback=function(v) SpeedEnabled=v;if v then StartSpeed() else StopSpeed() end end})
slider(player,"SpeedValue","Velocidade",24,16,150,1,function(v) SpeedValue=v end)

local credits = Tabs.Credits:AddLeftGroupbox("Rkz Hub")
credits:AddLabel("Rkz Hub")
credits:AddLabel("Obsidian UI")
credits:AddLabel("Versão: 3.4")
credits:AddButton({Text="Copiar Discord",Func=function()
    pcall(function() if setclipboard then setclipboard("https://discord.gg/seu-link-aqui") end end)
    Notify({Title="Discord",Content="Link copiado!",Duration=2})
end})

local settings = Tabs["UI Settings"]:AddLeftGroupbox("Interface")
settings:AddToggle("KeybindMenuOpen",{Text="Mostrar Keybinds",Default=Library.KeybindFrame and Library.KeybindFrame.Visible or false,Callback=function(v) if Library.KeybindFrame then Library.KeybindFrame.Visible=v end end})
settings:AddToggle("AlwaysOnTop",{Text="Sempre no topo",Default=Window.AlwaysOnTop,Callback=function(v) Window:SetAlwaysOnTop(v) end})
settings:AddLabel("Os botões de abrir/fechar e travar ficam no lado esquerdo.")

local menu = Tabs["UI Settings"]:AddRightGroupbox("Menu")
menu:AddLabel("Tecla do menu"):AddKeyPicker("MenuKeybind",{Default="RightControl",NoUI=true,Text="Abrir/Fechar interface"})
Library.ToggleKeybind = Library.Options.MenuKeybind

Notify({Title="Rkz Hub",Content="Interface carregada.",Duration=4})
