-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

-- Player Stuff
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local start_position = HumanoidRootPart.CFrame

-- Remote Events
local CoinCollected = ReplicatedStorage.Remotes.Gameplay.CoinCollected
local RoundStart = ReplicatedStorage.Remotes.Gameplay.RoundStart
local RoundEnd = ReplicatedStorage.Remotes.Gameplay.RoundEndFade

-- Variables
local coin_farming = false
local egg_farming = false
local bag_full = false
local anti_afk = false
local TELEPORT_DISTANCE = 150
local SPEED_MULTIPLIER = 25

-- Anti AFK
Player.Idled:Connect(function()
    if anti_afk then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Helper Functions
local function get_nearest(target_type)
    local closest, min_distance = nil, math.huge
    for _, model in ipairs(Workspace:GetDescendants()) do
        if model:IsA("BasePart") and model:GetAttribute("CoinID") == target_type then
            if model:FindFirstChild("TouchInterest") then
                local distance = (HumanoidRootPart.Position - model.Position).Magnitude
                if distance < min_distance then
                    closest = model
                    min_distance = distance
                end
            end
        end
    end
    return closest, min_distance
end

local function move_to(targetCFrame, duration)
    local tween = TweenService:Create(
        HumanoidRootPart,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = targetCFrame}
    )
    tween:Play()
    return tween
end

-- Remote Events Listeners
CoinCollected.OnClientEvent:Connect(function(coin_type, current, max)
    if (coin_type == "Coin" or coin_type == "Egg") and current >= max then
        bag_full = true
        move_to(start_position, 2).Completed:Wait()
        Player.Character.Humanoid.Health = 0
        bag_full = false
    end
end)

RoundStart.OnClientEvent:Connect(function()
    bag_full = false
end)

RoundEnd.OnClientEvent:Connect(function()
    bag_full = true
    move_to(start_position, 2)
end)

-- Farming Loop
task.spawn(function()
    while task.wait() do
        if bag_full or not Character or not HumanoidRootPart then
            Character = Player.Character or Player.CharacterAdded:Wait()
            HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
            continue
        end

        if coin_farming then
            local coin, distance = get_nearest("Coin")
            if coin then
                if distance > TELEPORT_DISTANCE then
                    HumanoidRootPart.CFrame = coin.CFrame
                else
                    local tween = move_to(coin.CFrame, distance / SPEED_MULTIPLIER)
                    repeat task.wait()
                    until not coin.Parent or not coin:FindFirstChild("TouchInterest") or not coin_farming
                    tween:Cancel()
                end
            end
        end

        if egg_farming then
            local egg, distance = get_nearest("Egg")
            if egg then
                if distance > TELEPORT_DISTANCE then
                    HumanoidRootPart.CFrame = egg.CFrame
                else
                    local tween = move_to(egg.CFrame, distance / SPEED_MULTIPLIER)
                    repeat task.wait()
                    until not egg.Parent or not egg:FindFirstChild("TouchInterest") or not egg_farming
                    tween:Cancel()
                end
            end
        end
    end
end)

-- GUI Setup
-- Destroy old GUI
local oldGui = CoreGui:FindFirstChild("FarmGUI")
if oldGui then oldGui:Destroy() end

-- Create GUI
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "FarmGUI"
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 250, 0, 220)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MainFrame.BackgroundTransparency = 0.4
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true

local MainFrameCorner = Instance.new("UICorner", MainFrame)
MainFrameCorner.CornerRadius = UDim.new(0, 10)

local MainFrameStroke = Instance.new("UIStroke", MainFrame)
MainFrameStroke.Color = Color3.fromRGB(0, 255, 255)
MainFrameStroke.Thickness = 2
MainFrameStroke.Transparency = 0.2
MainFrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Title Section
local TitleBox = Instance.new("Frame", MainFrame)
TitleBox.Size = UDim2.new(1, 0, 0, 40)
TitleBox.Position = UDim2.new(0, 0, 0, 0)
TitleBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TitleBox.BackgroundTransparency = 0.7
TitleBox.BorderSizePixel = 0
local TitleBoxCorner = Instance.new("UICorner", TitleBox)
TitleBoxCorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel", TitleBox)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "Coin & Egg AutoFarm"
Title.TextColor3 = Color3.fromRGB(255, 0, 0)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 22
Title.TextStrokeTransparency = 0.3
Title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

-- TextBox for Buttons
local TextBoxFrame = Instance.new("Frame", MainFrame)
TextBoxFrame.Size = UDim2.new(1, -20, 0, 90)
TextBoxFrame.Position = UDim2.new(0, 10, 0, 45)
TextBoxFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TextBoxFrame.BackgroundTransparency = 0.5
TextBoxFrame.BorderSizePixel = 0
TextBoxFrame.Active = true
TextBoxFrame.ClipsDescendants = true

local TextBoxFrameCorner = Instance.new("UICorner", TextBoxFrame)
TextBoxFrameCorner.CornerRadius = UDim.new(0, 10)

-- Toggle Button Creator
local function createToggle(text, yPosition, settingName)
    local Label = Instance.new("TextLabel", TextBoxFrame)
    Label.Size = UDim2.new(0, 120, 0, 30)
    Label.Position = UDim2.new(0, 10, 0, yPosition)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.Font = Enum.Font.GothamBlack
    Label.TextSize = 17
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextStrokeTransparency = 0.3
    Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

    local Button = Instance.new("TextButton", TextBoxFrame)
    Button.Size = UDim2.new(0, 40, 0, 30)
    Button.Position = UDim2.new(0, 140, 0, yPosition)
    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Button.BackgroundTransparency = 0.2
    Button.Text = "OFF"
    Button.Font = Enum.Font.GothamBold
    Button.TextSize = 14
    Button.TextColor3 = Color3.fromRGB(255, 80, 80)

    local ButtonCorner = Instance.new("UICorner", Button)
    ButtonCorner.CornerRadius = UDim.new(1, 0)

    -- Local toggle state
    local currentState = false

    Button.MouseButton1Click:Connect(function()
        currentState = not currentState

        if settingName == "CoinFarm" then
            coin_farming = currentState
        elseif settingName == "EggFarm" then
            egg_farming = currentState
        elseif settingName == "AntiAFK" then
            anti_afk = currentState
        end

        local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        local tween = TweenService:Create(Button, tweenInfo, {
            BackgroundColor3 = currentState and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(50, 50, 50)
        })
        tween:Play()

        Button.Text = currentState and "ON" or "OFF"
        Button.TextColor3 = currentState and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(255, 80, 80)
    end)
end

-- Create Buttons
createToggle("Coin Farm", 5, "CoinFarm")
createToggle("Egg Farm", 35, "EggFarm")
createToggle("Anti AFK", 65, "AntiAFK")

-- Info Label
local infoText = Instance.new("TextLabel", MainFrame)
infoText.Size = UDim2.new(0, 230, 0, 30)
infoText.Position = UDim2.new(0.5, -115, 0.85, 0)
infoText.BackgroundTransparency = 1
infoText.Text = "💡 Start Auto Farming By Turning The Buttons - Created By Blox"
infoText.Font = Enum.Font.GothamBlack
infoText.TextSize = 14
infoText.TextColor3 = Color3.fromRGB(255, 255, 0)
infoText.TextStrokeTransparency = 0
infoText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
infoText.TextWrapped = true
infoText.TextScaled = false
infoText.RichText = true
infoText.ZIndex = 10

-- Title Color Tween
task.spawn(function()
    local colors = {
        Color3.fromRGB(255, 0, 0),
        Color3.fromRGB(0, 0, 255)
    }

    local i = 1
    while true do
        local nextColor = colors[i % #colors + 1]
        TweenService:Create(Title, TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
            TextColor3 = nextColor
        }):Play()

        i = i + 1
        task.wait(3)
    end
end)
