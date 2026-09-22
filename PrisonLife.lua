--[[
	Prison Life - Rayfield UI
	Aimbot + ESP with team checks (Criminals / Guards / Inmates)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local settings = {
	Aimbot = false,
	TeamCheck = { Criminals = false, Guards = false, Inmates = false },
	Target = { Torso = false, Head = true },
	ESP = false,
	ESPTeamCheck = { Criminals = true, Guards = true, Inmates = true }
}

local AllowedGuns = {
	["AK-47"] = true, ["FAL"] = true, ["M4A1"] = true,
	["M9"] = true, ["MP5"] = true, ["Remington 870"] = true,
	["Taser"] = true
}

local function holdingValidGun()
	local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
	return tool and AllowedGuns[tool.Name] or false
end

local ESP_Folder = Instance.new("Folder")
ESP_Folder.Name = "PL_ESP_Storage"
pcall(function()
	local old = CoreGui:FindFirstChild("PL_ESP_Storage")
	if old then old:Destroy() end
end)
ESP_Folder.Parent = CoreGui

local function validTeam(plr)
	if not settings.TeamCheck.Criminals and plr.Team and plr.Team.Name == "Criminals" then return false end
	if not settings.TeamCheck.Guards and plr.Team and plr.Team.Name == "Guards" then return false end
	if not settings.TeamCheck.Inmates and plr.Team and plr.Team.Name == "Inmates" then return false end
	return true
end

local function getTargetPart(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return nil end
	if settings.Target.Head and char:FindFirstChild("Head") then return char.Head end
	if settings.Target.Torso then
		return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
	end
	return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
end

local function getClosestScreenTarget()
	local best, bestDist = nil, math.huge
	local mousePos = UIS:GetMouseLocation()

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and validTeam(plr) then
			local part = getTargetPart(plr.Character)
			if part then
				local pos, visible = Camera:WorldToViewportPoint(part.Position)
				if visible and pos.Z > 0 then
					local diff = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
					local rpc = RaycastParams.new()
					rpc.FilterType = Enum.RaycastFilterType.Exclude
					rpc.FilterDescendantsInstances = { LocalPlayer.Character }

					local ray = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rpc)
					if not ray or (ray.Instance and ray.Instance:IsDescendantOf(plr.Character)) then
						if diff < bestDist then
							bestDist = diff
							best = plr.Character
						end
					end
				end
			end
		end
	end
	return best
end

RunService.RenderStepped:Connect(function()
	if settings.Aimbot and holdingValidGun() then
		local target = getClosestScreenTarget()
		if target then
			local part = getTargetPart(target)
			if part then
				Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
			end
		end
	end
end)

local function teamAllowed(plr)
	if not plr.Team then return false end
	if plr.Team.Name == "Criminals" and settings.ESPTeamCheck.Criminals then return true end
	if plr.Team.Name == "Guards" and settings.ESPTeamCheck.Guards then return true end
	if plr.Team.Name == "Inmates" and settings.ESPTeamCheck.Inmates then return true end
	return false
end

local function teamColor(plr)
	if not plr.Team then return Color3.new(1, 1, 1) end
	if plr.Team.Name == "Criminals" then return Color3.fromRGB(255, 0, 0) end
	if plr.Team.Name == "Guards" then return Color3.fromRGB(0, 120, 255) end
	if plr.Team.Name == "Inmates" then return Color3.fromRGB(255, 140, 0) end
	return Color3.new(1, 1, 1)
end

local function getHighlight(plr)
	local h = ESP_Folder:FindFirstChild(plr.Name)
	if h then return h end
	local Highlight = Instance.new("Highlight")
	Highlight.Name = plr.Name
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.Parent = ESP_Folder
	return Highlight
end

local function removeHighlight(plr)
	local h = ESP_Folder:FindFirstChild(plr.Name)
	if h then h:Destroy() end
end

Players.PlayerRemoving:Connect(removeHighlight)

RunService.RenderStepped:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if not hrp or not hum or hum.Health <= 0 then
				removeHighlight(plr)
				continue
			end
			if not settings.ESP then
				removeHighlight(plr)
				continue
			end
			if not teamAllowed(plr) then
				removeHighlight(plr)
				continue
			end

			local h = getHighlight(plr)
			h.Adornee = plr.Character
			local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
			h.OutlineColor = dist <= 25 and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
			h.FillColor = teamColor(plr)
			h.FillTransparency = 0.5
			h.OutlineTransparency = 0
		else
			removeHighlight(plr)
		end
	end
end)

-- ===================== RAYFIELD UI =====================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Prison Life | Rayfield",
	LoadingTitle = "Prison Life Script",
	LoadingSubtitle = "Aimbot + ESP",
	ConfigurationSaving = {
		Enabled = true,
		FolderName = "PrisonLifeRF",
		FileName = "Config"
	},
	Discord = { Enabled = false },
	KeySystem = false
})

local WarningTab = Window:CreateTab("Warning", 4483362458)
local AimbotTab = Window:CreateTab("Aimbot", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)

WarningTab:CreateSection("Info")
WarningTab:CreateParagraph({
	Title = "Warning",
	Content = "Aimbot only works when holding a valid weapon:\nAK-47, FAL, M4A1, M9, MP5, Remington 870, Taser"
})

AimbotTab:CreateSection("Main")
AimbotTab:CreateToggle({
	Name = "Aimbot",
	CurrentValue = false,
	Flag = "AimbotMain",
	Callback = function(v)
		settings.Aimbot = v
	end
})

AimbotTab:CreateSection("Team Check (skip these teams)")
AimbotTab:CreateToggle({
	Name = "Skip Criminals",
	CurrentValue = false,
	Flag = "TC_Criminals",
	Callback = function(v)
		settings.TeamCheck.Criminals = v
	end
})
AimbotTab:CreateToggle({
	Name = "Skip Guards",
	CurrentValue = false,
	Flag = "TC_Guards",
	Callback = function(v)
		settings.TeamCheck.Guards = v
	end
})
AimbotTab:CreateToggle({
	Name = "Skip Inmates",
	CurrentValue = false,
	Flag = "TC_Inmates",
	Callback = function(v)
		settings.TeamCheck.Inmates = v
	end
})

AimbotTab:CreateSection("Aim Target")
AimbotTab:CreateToggle({
	Name = "Head",
	CurrentValue = true,
	Flag = "TargetHead",
	Callback = function(v)
		settings.Target.Head = v
	end
})
AimbotTab:CreateToggle({
	Name = "Torso",
	CurrentValue = false,
	Flag = "TargetTorso",
	Callback = function(v)
		settings.Target.Torso = v
	end
})

ESPTab:CreateSection("Main")
ESPTab:CreateToggle({
	Name = "ESP",
	CurrentValue = false,
	Flag = "ESPMain",
	Callback = function(v)
		settings.ESP = v
	end
})

ESPTab:CreateSection("ESP Team Filter (show these)")
ESPTab:CreateToggle({
	Name = "Show Criminals",
	CurrentValue = true,
	Flag = "ESP_Criminals",
	Callback = function(v)
		settings.ESPTeamCheck.Criminals = v
	end
})
ESPTab:CreateToggle({
	Name = "Show Guards",
	CurrentValue = true,
	Flag = "ESP_Guards",
	Callback = function(v)
		settings.ESPTeamCheck.Guards = v
	end
})
ESPTab:CreateToggle({
	Name = "Show Inmates",
	CurrentValue = true,
	Flag = "ESP_Inmates",
	Callback = function(v)
		settings.ESPTeamCheck.Inmates = v
	end
})

Rayfield:LoadConfiguration()

Rayfield:Notify({
	Title = "Prison Life",
	Content = "Loaded successfully!",
	Duration = 4
})
