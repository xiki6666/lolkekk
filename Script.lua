-- Создаем объекты
local screenGui = Instance.new("ScreenGui")
local frame = Instance.new("Frame")
local toggleButton = Instance.new("TextButton")
local flyButton = Instance.new("TextButton")
local speedInput = Instance.new("TextBox")
local speedhackInput = Instance.new("TextBox")
local speedhackButton = Instance.new("TextButton")
local keybindButton = Instance.new("TextButton")
local flyKeybindButton = Instance.new("TextButton")
local teleportButton = Instance.new("TextButton")
local teleportKeybindButton = Instance.new("TextButton")
local proximityPromptButton = Instance.new("TextButton")
local proximityKeybindButton = Instance.new("TextButton")

-- Переменные для управления полетом, Speedhack
local flying = false
local speed = 50
local speedhackSpeed = 33
local speedhackEnabled = false
local flyConnection
local bodyVelocity
local bodyGyro
local menuVisible = true
local speedhackKey = Enum.KeyCode.R
local flyKey = Enum.KeyCode.G
local teleportKey = Enum.KeyCode.T
local proximityKey = Enum.KeyCode.J
local keybindListening = false
local flyKeybindListening = false
local teleportKeybindListening = false
local proximityKeybindListening = false
local teleportToggle = false

-- Переменные для ProximityPrompt
local proximityPromptEnabled = false
local originalDurations = {}

-- Обновление меню после смерти
local function restoreMenuOnDeath()
    local player = game.Players.LocalPlayer
    player.CharacterAdded:Connect(function(character)
        wait(1)
        screenGui.Parent = player:WaitForChild("PlayerGui")
        frame.Visible = menuVisible

        if speedhackEnabled then
            character:WaitForChild("Humanoid").WalkSpeed = speedhackSpeed
        end
        
        -- Восстанавливаем состояние ProximityPrompt после смерти
        if proximityPromptEnabled then
            updateAllPrompts()
        end
    end)
end

-- Настройка ScreenGui
screenGui.Name = "MenuGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Настройка фрейма (меню)
frame.Size = UDim2.new(0, 400, 0, 440)
frame.Position = UDim2.new(0.5, -200, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BackgroundTransparency = 0.2
frame.BorderColor3 = Color3.fromRGB(0, 170, 255)
frame.BorderSizePixel = 2
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Закругляем углы фрейма
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

-- Настройка кнопки сворачивания
toggleButton.Size = UDim2.new(0, 150, 0, 30)
toggleButton.Position = UDim2.new(0.5, -75, 0, -60)
toggleButton.Text = "Toggle Menu"
toggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
toggleButton.BorderColor3 = Color3.fromRGB(0, 170, 255)
toggleButton.BorderSizePixel = 2
toggleButton.Parent = screenGui

-- Функция для стилизации кнопок
local function styleButton(button, text, position)
    button.Size = UDim2.new(0, 380, 0, 30)
    button.Position = position
    button.Text = text
    button.TextScaled = true
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderColor3 = Color3.fromRGB(0, 170, 255)
    button.BorderSizePixel = 2
    button.Parent = frame
end

-- Настройка кнопки полета
styleButton(flyButton, "Enable Fly", UDim2.new(0, 10, 0, 20))

-- Настройка поля ввода скорости полета
speedInput.Size = UDim2.new(0, 380, 0, 30)
speedInput.Position = UDim2.new(0, 10, 0, 60)
speedInput.Text = "Enter Fly Speed"
speedInput.TextScaled = true
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedInput.BorderColor3 = Color3.fromRGB(0, 170, 255)
speedInput.BorderSizePixel = 2
speedInput.Parent = frame

-- Настройка поля ввода скорости Speedhack
speedhackInput.Size = UDim2.new(0, 380, 0, 30)
speedhackInput.Position = UDim2.new(0, 10, 0, 100)
speedhackInput.Text = "Enter Speedhack Speed"
speedhackInput.TextScaled = true
speedhackInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedhackInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedhackInput.BorderColor3 = Color3.fromRGB(0, 170, 255)
speedhackInput.BorderSizePixel = 2
speedhackInput.Parent = frame

-- Настройка кнопки Speedhack
styleButton(speedhackButton, "Enable Speedhack", UDim2.new(0, 10, 0, 140))

-- Настройка кнопки для выбора клавиши Speedhack
styleButton(keybindButton, "Speedhack Key: R", UDim2.new(0, 10, 0, 180))

-- Настройка кнопки для выбора клавиши полета
styleButton(flyKeybindButton, "Fly Key: G", UDim2.new(0, 10, 0, 220))

-- Настройка кнопки телепортации
styleButton(teleportButton, "Teleport to Position 1", UDim2.new(0, 10, 0, 260))

-- Настройка кнопки для выбора клавиши телепортации
styleButton(teleportKeybindButton, "Teleport Key: T", UDim2.new(0, 10, 0, 300))

-- Настройка кнопки ProximityPrompt
styleButton(proximityPromptButton, "Disable ProximityPrompt", UDim2.new(0, 10, 0, 340))

-- Настройка кнопки для выбора клавиши ProximityPrompt
styleButton(proximityKeybindButton, "Proximity Key: J", UDim2.new(0, 10, 0, 380))

-- Функция для применения изменений ко всем промптам
local function updateAllPrompts()
    for _, prompt in ipairs(game:GetService("Workspace"):GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            if proximityPromptEnabled then
                if not originalDurations[prompt] then
                    originalDurations[prompt] = prompt.HoldDuration
                end
                prompt.HoldDuration = 0
            else
                if originalDurations[prompt] then
                    prompt.HoldDuration = originalDurations[prompt]
                end
            end
        end
    end
end

-- Обработчик новых ProximityPrompt
local function onDescendantAdded(descendant)
    if descendant:IsA("ProximityPrompt") then
        if proximityPromptEnabled then
            originalDurations[descendant] = descendant.HoldDuration
            descendant.HoldDuration = 0
        end
    end
end

-- Подписываемся на событие добавления новых объектов
game:GetService("Workspace").DescendantAdded:Connect(onDescendantAdded)

-- Функция переключения ProximityPrompt
local function toggleProximityPrompts()
    proximityPromptEnabled = not proximityPromptEnabled
    
    if proximityPromptEnabled then
        proximityPromptButton.Text = "Enable ProximityPrompt"
        proximityPromptButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        proximityPromptButton.Text = "Disable ProximityPrompt"
        proximityPromptButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    
    updateAllPrompts()
end

-- Функция для настройки клавиши ProximityPrompt
local function setProximityKeybind()
    proximityKeybindListening = true
    proximityKeybindButton.Text = "Press any key..."

    local connection
    connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if proximityKeybindListening and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                proximityKey = input.KeyCode
                proximityKeybindButton.Text = "Proximity Key: " .. tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                proximityKeybindListening = false
                connection:Disconnect()
            end
        end
    end)
end

-- Функция полета
local function fly()
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = humanoidRootPart

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.CFrame = humanoidRootPart.CFrame
    bodyGyro.Parent = humanoidRootPart

    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new(0, 0, 0)

        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + (camera.CFrame.LookVector * speed)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - (camera.CFrame.LookVector * speed)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - (camera.CFrame.RightVector * speed)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + (camera.CFrame.RightVector * speed)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, speed, 0)
        end
        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, speed, 0)
        end

        bodyVelocity.Velocity = moveDirection
        bodyGyro.CFrame = camera.CFrame
    end)
end

-- Функция для включения/выключения полета
local function toggleFly()
    flying = not flying
    flyButton.Text = flying and "Disable Fly" or "Enable Fly"

    if flying then
        fly()
    else
        if flyConnection then flyConnection:Disconnect() end
        if bodyVelocity then bodyVelocity:Destroy() end
        if bodyGyro then bodyGyro:Destroy() end
        local humanoidRootPart = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

-- Функция телепортации
local function toggleTeleport()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    teleportToggle = not teleportToggle

    if teleportToggle then
        humanoidRootPart.CFrame = CFrame.new(Vector3.new(170.43, 3.66, 474.95))
        teleportButton.Text = "Teleport to Position 2"
    else
        humanoidRootPart.CFrame = CFrame.new(Vector3.new(172.26, 47.47, 426.68))
        teleportButton.Text = "Teleport to Position 1"
    end
end

-- Функция для изменения скорости полета
speedInput.FocusLost:Connect(function(enterPressed)
    local newSpeed = tonumber(speedInput.Text)
    if newSpeed then
        speed = newSpeed
        speedInput.Text = "Speed: " .. speed
    else
        speedInput.Text = "Invalid Input"
    end
end)

-- Функция для изменения скорости Speedhack
speedhackInput.FocusLost:Connect(function(enterPressed)
    local newSpeedhackSpeed = tonumber(speedhackInput.Text)
    if newSpeedhackSpeed then
        speedhackSpeed = newSpeedhackSpeed
        if speedhackEnabled then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speedhackSpeed
        end
        speedhackInput.Text = "Speedhack: " .. speedhackSpeed
    else
        speedhackInput.Text = "Invalid Input"
    end
end)

-- Функция включения/выключения Speedhack
local function toggleSpeedhack()
    speedhackEnabled = not speedhackEnabled
    speedhackButton.Text = speedhackEnabled and "Disable Speedhack" or "Enable Speedhack"

    if speedhackEnabled then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = speedhackSpeed
    else
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end

-- Функция для настройки клавиши Speedhack
local function setSpeedhackKeybind()
    keybindListening = true
    keybindButton.Text = "Press any key..."

    local connection
    connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if keybindListening and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                speedhackKey = input.KeyCode
                keybindButton.Text = "Speedhack Key: " .. tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                keybindListening = false
                connection:Disconnect()
            end
        end
    end)
end

-- Функция для настройки клавиши полета
local function setFlyKeybind()
    flyKeybindListening = true
    flyKeybindButton.Text = "Press any key..."

    local connection
    connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if flyKeybindListening and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                flyKey = input.KeyCode
                flyKeybindButton.Text = "Fly Key: " .. tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                flyKeybindListening = false
                connection:Disconnect()
            end
        end
    end)
end

-- Функция для настройки клавиши телепортации
local function setTeleportKeybind()
    teleportKeybindListening = true
    teleportKeybindButton.Text = "Press any key..."

    local connection
    connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if teleportKeybindListening and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                teleportKey = input.KeyCode
                teleportKeybindButton.Text = "Teleport Key: " .. tostring(input.KeyCode):gsub("Enum.KeyCode.", "")
                teleportKeybindListening = false
                connection:Disconnect()
            end
        end
    end)
end

-- Обработчик нажатия клавиш для всех функций
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == speedhackKey then
            toggleSpeedhack()
        elseif input.KeyCode == flyKey then
            toggleFly()
        elseif input.KeyCode == teleportKey then
            toggleTeleport()
        elseif input.KeyCode == proximityKey then
            toggleProximityPrompts()
        end
    end
end)

-- Функция для скрытия/показа меню
local function toggleMenu()
    menuVisible = not menuVisible
    frame.Visible = menuVisible
end

-- Привязка функций к кнопкам
flyButton.MouseButton1Click:Connect(toggleFly)
speedhackButton.MouseButton1Click:Connect(toggleSpeedhack)
keybindButton.MouseButton1Click:Connect(setSpeedhackKeybind)
flyKeybindButton.MouseButton1Click:Connect(setFlyKeybind)
teleportButton.MouseButton1Click:Connect(toggleTeleport)
teleportKeybindButton.MouseButton1Click:Connect(setTeleportKeybind)
proximityPromptButton.MouseButton1Click:Connect(toggleProximityPrompts)
proximityKeybindButton.MouseButton1Click:Connect(setProximityKeybind)

-- Привязка функции к кнопке сворачивания
toggleButton.MouseButton1Click:Connect(toggleMenu)

-- Восстанавливаем меню после смерти
restoreMenuOnDeath()

-- Обработка существующих ProximityPrompt при запуске
updateAllPrompts()

-- Добавляем заголовок
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 380, 0, 50)
titleLabel.Position = UDim2.new(0, 10, 0, -40)
titleLabel.Text = "chalun"
titleLabel.TextScaled = true
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextStrokeTransparency = 0
titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 170, 255)
titleLabel.BackgroundTransparency = 1
titleLabel.BorderSizePixel = 0
titleLabel.Parent = frame
