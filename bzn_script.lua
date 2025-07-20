-- bzn_script.lua
-- BZN Scripts - Loader com sistema de key + hub completo para Blade Ball

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

-- URL dos arquivos no GitHub
local urlKeys = "https://raw.githubusercontent.com/bielz89760/BZN-BladeBall-Scripts/main/valid_keys.txt"

-- Carrega keys válidas
local function fetchKeys()
    local success, data = pcall(function()
        return game:HttpGet(urlKeys)
    end)
    local tbl = {}
    if success and data then
        for line in data:gmatch("[^\r\n]+") do
            tbl[line] = true
        end
    end
    return tbl
end

local validKeys = fetchKeys()
local enteredKey = ""

-- Tela de login/key
local winLogin = OrionLib:MakeWindow({
    Name = "BZN Scripts - Login",
    IntroText = "Insira a sua key",
    HidePremium = true,
})
local tabLogin = winLogin:MakeTab({
    Name = "Login",
    Icon = "rbxassetid://4483345998",
})
tabLogin:AddTextbox({
    Name = "Digite a key",
    Default = "",
    TextDisappear = true,
    Callback = function(v) enteredKey = v end
})
tabLogin:AddButton({
    Name = "Verificar Key",
    Callback = function()
        if validKeys[enteredKey] then
            OrionLib:MakeNotification({
                Name = "✔️ Sucesso",
                Content = "Key aceita! Carregando script...",
                Time = 3
            })
            winLogin:Close()
            wait(0.5)
            loadScript()
        else
            OrionLib:MakeNotification({
                Name = "❌ Erro",
                Content = "Key inválida!",
                Time = 3
            })
        end
    end
})
OrionLib:Init()

-- Função central: carrega o hub
function loadScript()
    -- UI principal
    local Window = OrionLib:MakeWindow({
        Name = "BZN Scripts",
        IntroText = "Blade Ball Hub",
        SaveConfig = true,
        ConfigFolder = "BZNBladeBall",
        AccentColor = Color3.fromRGB(255,85,85)
    })
    local Tab = Window:MakeTab({
        Name = "Blade Ball",
        Icon = "rbxassetid://4483345998",
    })

    local clickS = Instance.new("Sound", workspace)
    clickS.SoundId = "rbxassetid://142070127"
    clickS.Volume = 0.5

    local function playClick() pcall(function() clickS:Play() end) end

    -- Variáveis controle
    local autoSwing, autoDash, autoFarm, aimbot, espEnabled = false, false, false, false, false
    local noClip, infiniteStamina, godMode, fullBright = false, false, false, false
    local swingC, dashC, farmC, aimC, staminaC, noClipC
    local espBoxes = {}
    local origBright = Lighting.Brightness

    -- Funções auxiliares
    local function CreateESP(p)
        if espBoxes[p] then return end
        local b = Drawing.new("Square")
        b.Visible = false; b.Color = Color3.new(1,0,0)
        b.Thickness = 2; b.Transparency = 1
        espBoxes[p] = b
    end
    local function UpdateESP()
        for p,b in pairs(espBoxes) do
            local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and espEnabled and p~=LocalPlayer then
                local pos,on = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                if on then
                    b.Position = Vector2.new(pos.X-20,pos.Y-20)
                    b.Size = Vector2.new(40,40); b.Visible=true
                else b.Visible=false end
            else b.Visible=false end
        end
    end
    local function ClearESP()
        for _,b in pairs(espBoxes) do b:Remove() end
        espBoxes = {}
    end
    local function GetClosest()
        local md, targ = math.huge
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (p.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                if d<md then md, targ = d, p end
            end
        end
        return targ
    end

    -- Funções do hub
    Tab:AddToggle({ Name="Auto Swing", Default=false, Tooltip="Ataca automaticamente", Callback=function(v)
        playClick(); autoSwing=v
        if v then swingC = RunService.RenderStepped:Connect(function()
            pcall(function() ReplicatedStorage.Events.Swing:FireServer() end)
        end) else if swingC then swingC:Disconnect() end end
    end})
    Tab:AddSlider({ Name="Walk Speed",Min=16,Max=150,Default=16,Increment=1,ValueName="Speed",Tooltip="Velocidade",Callback=function(v)
        playClick(); if LocalPlayer.Character then LocalPlayer.Character.Humanoid.WalkSpeed=v end
    end})
    Tab:AddSlider({ Name="Jump Power",Min=50,Max=300,Default=50,Increment=1,ValueName="Jump",Tooltip="Altura do pulo",Callback=function(v)
        playClick(); if LocalPlayer.Character then LocalPlayer.Character.Humanoid.JumpPower=v end
    end})
    Tab:AddToggle({ Name="Auto Dash", Default=false, Tooltip="Dash automático", Callback=function(v)
        playClick(); autoDash=v
        if v then dashC = RunService.RenderStepped:Connect(function()
            pcall(function() ReplicatedStorage.Events.Dash:FireServer() end)
        end) else if dashC then dashC:Disconnect() end end
    end})
    Tab:AddToggle({ Name="Auto Farm", Default=false, Tooltip="Ataca inimigos", Callback=function(v)
        playClick(); autoFarm=v
        if v then farmC = RunService.Heartbeat:Connect(function()
            if LocalPlayer.Character then
                for _,e in pairs(workspace:GetChildren()) do
                    if e:IsA("Model") and e:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = e.HumanoidRootPart.CFrame * CFrame.new(0,0,3)
                        pcall(function() ReplicatedStorage.Events.Swing:FireServer() end)
                    end
                end
            end
        end) else if farmC then farmC:Disconnect() end end
    end})
    Tab:AddToggle({ Name="ESP",Default=false,Tooltip="Destaca inimigos",Callback=function(v)
        playClick(); espEnabled=v
        if v then for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then CreateESP(p) end end
            RunService:BindToRenderStep("esp",Enum.RenderPriority.Camera.Value+1,UpdateESP)
        else RunService:UnbindFromRenderStep("esp"); ClearESP() end
    end})
    Tab:AddToggle({ Name="Aimbot",Default=false,Tooltip="Mira inimigo mais próximo",Callback=function(v)
        playClick(); aimbot=v
        if v then aimC = RunService.RenderStepped:Connect(function()
            local t = GetClosest()
            if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
                workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, t.Character.HumanoidRootPart.Position)
            end
        end) else if aimC then aimC:Disconnect() end end
    end})
    Tab:AddButton({ Name="Auto Win", Tooltip="Aciona vitória",Callback=function() playClick(); pcall(function() ReplicatedStorage.Events.Win:FireServer() end) end})
    Tab:AddButton({ Name="Auto Heal", Tooltip="Regen instantânea",Callback=function() playClick(); if LocalPlayer.Character then LocalPlayer.Character.Humanoid.Health=LocalPlayer.Character.Humanoid.MaxHealth end end})
    Tab:AddToggle({ Name="Anti Knockback",Default=false,Tooltip="Remove knockback",Callback=function(v)
        playClick()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not v)
            LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not v)
        end
    end})
    Tab:AddToggle({ Name="No Clip",Default=false,Tooltip="Caminha através paredes",Callback=function(v)
        playClick(); noClip=v
        if v then noClipC = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CanCollide = false
            end
        end) else if noClipC then noClipC:Disconnect() end end
    end})
    Tab:AddToggle({ Name="God Mode", Default=false, Tooltip="Modo Deus (beta)", Callback=function(v)
        playClick(); godMode = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.MaxHealth = v and math.huge or 100
            LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
        end
    end})
    Tab:AddToggle({ Name="Infinite Stamina", Default=false, Tooltip="Endurance infinito", Callback=function(v)
        playClick(); infiniteStamina=v
        if v then staminaC=RunService.Stepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Stamina") then
                LocalPlayer.Character.Stamina.Value = LocalPlayer.Character.Stamina.MaxValue
            end
        end) else if staminaC then staminaC:Disconnect() end end
    end})
    Tab:AddToggle({ Name="Full Bright", Default=false, Tooltip="Iluminação ativa", Callback=function(v)
        playClick()
        if v then Lighting.Brightness = 100 else Lighting.Brightness = origBright end
    end})
    Tab:AddButton({ Name="Teleport Center", Tooltip="Ir ao centro", Callback=function()
        playClick()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0,10,0)
        end
    end})
    Tab:AddButton({ Name="Kill All", Tooltip="Elimina inimigos (beta)", Callback=function()
        playClick()
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") then
                p.Character.Humanoid.Health = 0
            end
        end
    end})
    Tab:AddButton({ Name="Equip Weapon", Tooltip="Equipe sua espada", Callback=function()
        playClick()
        pcall(function()
            ReplicatedStorage.Events.Equip:FireServer()
        end)
    end})
    Tab:AddButton({ Name="Reset Stats", Tooltip="Redefinir atributos", Callback=function()
        playClick()
        -- exemplo hipotético:
        pcall(function() ReplicatedStorage.Events.Reset:FireServer() end)
    end})
    Tab:AddButton({ Name="Auto Respawn", Tooltip="Respawn automático", Callback=function()
        playClick()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health<=0 then
            LocalPlayer:LoadCharacter()
        end
    end})

    -- Reset geral ao sair
    game:BindToClose(function()
        if swingC then swingC:Disconnect() end
        if dashC then dashC:Disconnect() end
        if farmC then farmC:Disconnect() end
        if aimC then aimC:Disconnect() end
        if noClipC then noClipC:Disconnect() end
        if staminaC then staminaC:Disconnect() end
        RunService:UnbindFromRenderStep("esp")
        ClearESP()
        Lighting.Brightness = origBright
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
            LocalPlayer.Character.Humanoid.JumpPower = 50
            LocalPlayer.Character.Humanoid.MaxHealth = 100
        end
    end)

    OrionLib:Init()
end
