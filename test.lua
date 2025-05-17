--// Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--// Estados
local aimbotEnabled = false
local espEnabled = false
local guiVisible = true
local antiLagEnabled = false
local showFPS = false

--// Configurações
local aimbotSettings = {
    fov = 150,
    smoothness = 0.2
}

--// GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "AimbotESP_Hub"
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 250, 0, 280)
Frame.Position = UDim2.new(0, 50, 0, 50)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local function createLabel(parent, text, size, pos, fontSize, color)
    local label = Instance.new("TextLabel", parent)
    label.Size = size
    label.Position = pos
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.Font = Enum.Font.SourceSans
    label.TextSize = fontSize
    return label
end

createLabel(Frame, "🎯 Aimbot + ESP Hub", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, 0), 20, Color3.fromRGB(255, 0, 0))

local function createButton(name, yPos, callback)
    local button = Instance.new("TextButton", Frame)
    button.Size = UDim2.new(1, -20, 0, 30)
    button.Position = UDim2.new(0, 10, 0, yPos)
    button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.SourceSans
    button.TextSize = 16
    button.Text = name
    button.MouseButton1Click:Connect(callback)
end

local statusLabel = createLabel(Frame, "", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 250), 14)
local fpsLabel = createLabel(Frame, "FPS: N/A", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 0, 230), 14, Color3.fromRGB(0, 255, 0))
fpsLabel.Visible = false

local function updateStatus()
    statusLabel.Text = string.format("Status: Aimbot %s | ESP %s | Anti-Lag %s",
        aimbotEnabled and "On" or "Off",
        espEnabled and "On" or "Off",
        antiLagEnabled and "On" or "Off")
end

local function applyAntiLag()
    if antiLagEnabled then
        aimbotSettings.smoothness = 0.05
        espEnabled = false
    else
        aimbotSettings.smoothness = 0.2
    end
end

--// Botões
createButton("Ativar/Desativar Aimbot", 40, function()
    aimbotEnabled = not aimbotEnabled
    updateStatus()
end)

createButton("Ativar/Desativar ESP", 80, function()
    espEnabled = not espEnabled
    if antiLagEnabled then espEnabled = false end
    updateStatus()
end)

createButton("Fechar/Abrir Hub", 120, function()
    guiVisible = not guiVisible
    ScreenGui.Enabled = guiVisible
end)

createButton("Ativar/Desativar Anti-Lag", 160, function()
    antiLagEnabled = not antiLagEnabled
    applyAntiLag()
    updateStatus()
end)

createButton("Mostrar/Ocultar FPS", 200, function()
    showFPS = not showFPS
    fpsLabel.Visible = showFPS
end)

--// Inimigos
local function getEnemies()
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if player.Team and LocalPlayer.Team and player.Team ~= LocalPlayer.Team then
                table.insert(enemies, player)
            elseif player.TeamColor and LocalPlayer.TeamColor and player.TeamColor ~= LocalPlayer.TeamColor then
                table.insert(enemies, player)
            end
        end
    end
    return enemies
end

--// Aimbot
local function getClosestTarget()
    local closest
    local shortestDistance = aimbotSettings.fov
    local mouse = UserInputService:GetMouseLocation()

    for _, enemy in ipairs(getEnemies()) do
        local part = enemy.Character and (enemy.Character:FindFirstChild("Head") or enemy.Character:FindFirstChild("HumanoidRootPart"))
        if part then
            local screenPos, visible = Camera:WorldToViewportPoint(part.Position)
            if visible then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouse).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closest = part
                end
            end
        end
    end
    return closest
end

--// ESP com BoxHandleAdornment
local espBoxes = {}

local function createBox(player)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    if not espBoxes[player] then
        local box = Instance.new("BoxHandleAdornment")
        box.Size = Vector3.new(4, 6, 2)
        box.Color3 = Color3.fromRGB(255, 0, 0)
        box.Transparency = 0.5
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Adornee = char.HumanoidRootPart
        box.Name = "ESPBox"
        box.Parent = CoreGui
        espBoxes[player] = box
    end
end

local function removeBox(player)
    if espBoxes[player] then
        espBoxes[player]:Destroy()
        espBoxes[player] = nil
    end
end

Players.PlayerRemoving:Connect(removeBox)

--// FPS
local lastTime = tick()
local frames = 0

--// Loop principal
RunService.RenderStepped:Connect(function()
    -- FPS
    frames += 1
    local now = tick()
    if now - lastTime >= 1 then
        if showFPS then
            fpsLabel.Text = "FPS: " .. frames
        end
        frames = 0
        lastTime = now
    end

    -- Aimbot
    if aimbotEnabled then
        local target = getClosestTarget()
        if target then
            local newCF = CFrame.lookAt(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, aimbotSettings.smoothness)
        end
    end

    -- ESP
    local activeEnemies = {}
    for _, player in ipairs(getEnemies()) do
        activeEnemies[player] = true
        createBox(player)

        local box = espBoxes[player]
        if box then
            box.Visible = espEnabled
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                box.Adornee = player.Character.HumanoidRootPart
            end
        end
    end

    -- Remover caixas antigas
    for player, box in pairs(espBoxes) do
        if not activeEnemies[player] then
            removeBox(player)
        end
    end
end)

-- Inicializar
updateStatus()
