local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local UIS = game:GetService("UserInputService")
local mouse = player:GetMouse()

local uiItemDisplays = {}

local function parseAmountString(amountString)
    amountString = string.lower(string.gsub(amountString, "%s", ""))
    local numberPart = tonumber(string.match(amountString, "^(%d+%.?%d*)"))
    local suffixPart = string.match(amountString, "[kmbtqa]$")

    if not numberPart then
        return nil
    end

    if suffixPart then
        if suffixPart == "k" then
            numberPart = numberPart * 1000
        elseif suffixPart == "m" then
            numberPart = numberPart * 1000000
        elseif suffixPart == "b" then
            numberPart = numberPart * 1000000000
        elseif suffixPart == "t" then
            numberPart = numberPart * 1000000000000
        elseif suffixPart == "qa" then
            numberPart = numberPart * 1000000000000000
        else
            return nil
        end
    end

    return math.floor(numberPart)
end

local function showNotification(message)
    local itemsListGui = player.PlayerGui:FindFirstChild("ItemsListGui")
    if not itemsListGui then return end

    local existingNotification = itemsListGui:FindFirstChild("Notification")
    if existingNotification then
        existingNotification:Destroy()
    end

    local notification = Instance.new("TextLabel")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0.2, 0, 0, 30)
    notification.Position = UDim2.new(0.76, 0, 0.925, 0)
    notification.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    notification.BackgroundTransparency = 0.9
    notification.Text = message
    notification.TextColor3 = Color3.fromRGB(153, 255, 175)
    notification.TextSize = 25
    notification.Font = Enum.Font.FredokaOne
    notification.TextStrokeTransparency = 0.5
    notification.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    notification.TextXAlignment = Enum.TextXAlignment.Left

    local padding = Instance.new("UIPadding")
    padding.Parent = notification
    padding.PaddingLeft = UDim.new(0, 10)

    notification.Parent = itemsListGui

    local fadeInTween = game:GetService("TweenService"):Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0, BackgroundTransparency = 0.7}
    )

    local fadeOutTween = game:GetService("TweenService"):Create(
        notification,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 1, BackgroundTransparency = 0.9}
    )

    fadeInTween:Play()

    task.wait(2)

    fadeOutTween:Play()

    fadeOutTween.Completed:Connect(function()
        notification:Destroy()
    end)
end

local function findBlocksFolder()
    local islandsFolder = Workspace:FindFirstChild("Islands")
    if not islandsFolder then
        warn("Islands folder not found in Workspace.")
        return nil
    end

    for _, island in ipairs(islandsFolder:GetChildren()) do
        if string.match(island.Name, "%-island$") then
            local blocksFolder = island:FindFirstChild("Blocks")
            if blocksFolder then
                return blocksFolder
            end
        end
    end
    warn("Blocks folder not found in any island.")
    return nil
end

local function trackItemPlacement(tool)
    local blocksFolder = findBlocksFolder()
    if not blocksFolder then
        warn("Blocks folder not found. Cannot track item placement.")
        return
    end

    local heldToolName = tool.Name
    local placementCount = 0

    tool.Activated:Connect(function()
        local initialParts = {}
        for _, part in ipairs(blocksFolder:GetChildren()) do
            if not part:GetAttribute("PlacedByTool") then
                part:SetAttribute("PlacedByTool", false)
            end
            initialParts[part] = true
        end

        task.wait(0.5)

        local newParts = {}
        for _, part in ipairs(blocksFolder:GetChildren()) do
            if not initialParts[part] and not part:GetAttribute("PlacedByTool") then
                part:SetAttribute("PlacedByTool", true)
                table.insert(newParts, part)
            end
        end

        if #newParts > 0 then
            for _, newPart in ipairs(newParts) do
                if newPart.Name == heldToolName then
                    placementCount += 1
                    local placementValue = Instance.new("IntValue")
                    placementValue.Name = "PlacementNumber"
                    placementValue.Value = placementCount
                    placementValue.Parent = newPart

                    local amount = tool:FindFirstChild("Amount")
                    if amount and amount.Value > 0 then
                        amount.Value -= 1
                        if amount.Value <= 0 then
                            tool:Destroy()
                        end
                    end
                else
                    warn("Detected new part but name mismatch:", newPart.Name, "vs", heldToolName)
                end
            end
        else
            warn("Tool was activated but no new placement was detected.")
        end
    end)
end

local function updateItemDisplay(itemName, amount)
    if uiItemDisplays[itemName] and uiItemDisplays[itemName].label then
        uiItemDisplays[itemName].label.Text = itemName
    end
end

local function setupBackpackListeners()
    for _, toolInBackpack in ipairs(player.Backpack:GetChildren()) do
        if toolInBackpack:IsA("Tool") then
            local itemName = toolInBackpack:FindFirstChild("DisplayName") and toolInBackpack.DisplayName.Value or toolInBackpack.Name
            local amount = toolInBackpack:FindFirstChild("Amount") and toolInBackpack.Amount.Value or 1
            updateItemDisplay(itemName, amount)

            local amountValue = toolInBackpack:FindFirstChild("Amount")
            if amountValue then
                amountValue.Changed:Connect(function(newAmount)
                    updateItemDisplay(itemName, newAmount)
                end)
            end
        end
    end

    player.Backpack.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            local itemName = child:FindFirstChild("DisplayName") and child.DisplayName.Value or child.Name
            local amount = child:FindFirstChild("Amount") and child.Amount.Value or 1
            updateItemDisplay(itemName, amount)

            local amountValue = child:FindFirstChild("Amount")
            if amountValue then
                amountValue.Changed:Connect(function(newAmount)
                    updateItemDisplay(itemName, newAmount)
                end)
            else
                updateItemDisplay(itemName, 1)
            end
        end
    end)

    player.Backpack.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") then
            local itemName = child:FindFirstChild("DisplayName") and child.DisplayName.Value or child.Name
            updateItemDisplay(itemName, 0)
        end
    end)
end

local function populateItemList(itemsListGui)
    local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
    if toolsFolder then
        local itemListFrame = itemsListGui:FindFirstChild("ItemsFrame"):FindFirstChild("ItemListFrame")
        if not itemListFrame then return end

        for _, tool in ipairs(toolsFolder:GetChildren()) do
            local itemName = tool:FindFirstChild("DisplayName") and tool.DisplayName.Value or tool.Name

            local itemContainer = Instance.new("Frame")
            itemContainer.Size = UDim2.new(1, 0, 1, 0)
            itemContainer.BackgroundTransparency = 0.8
            itemContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            itemContainer.Parent = itemListFrame

            local itemContainerCorner = Instance.new("UICorner")
            itemContainerCorner.CornerRadius = UDim.new(0, 8)
            itemContainerCorner.Parent = itemContainer

            local itemContainerGradient = Instance.new("UIGradient")
            itemContainerGradient.Color = ColorSequence.new(Color3.fromRGB(40, 40, 40), Color3.fromRGB(25, 25, 25))
            itemContainerGradient.Rotation = 90
            itemContainerGradient.Parent = itemContainer

            local itemNameLabel = Instance.new("TextLabel")
            itemNameLabel.Size = UDim2.new(0.5, 0, 1, 0)
            itemNameLabel.Position = UDim2.new(0, 0, 0, 0)
            itemNameLabel.BackgroundTransparency = 1
            itemNameLabel.Text = itemName
            itemNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemNameLabel.TextSize = 16
            itemNameLabel.Font = Enum.Font.GothamSemibold
            itemNameLabel.TextXAlignment = Enum.TextXAlignment.Left
            itemNameLabel.TextScaled = true
            itemNameLabel.Parent = itemContainer

            local padding = Instance.new("UIPadding")
            padding.Parent = itemNameLabel
            padding.PaddingLeft = UDim.new(0, 10)

            local amountTextBox = Instance.new("TextBox")
            amountTextBox.Size = UDim2.new(0.2, 0, 0.8, 0)
            amountTextBox.Position = UDim2.new(0.52, 0, 0.5, 0)
            amountTextBox.AnchorPoint = Vector2.new(0, 0.5)
            amountTextBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            amountTextBox.BackgroundTransparency = 0.2
            amountTextBox.BorderSizePixel = 0
            amountTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            amountTextBox.PlaceholderText = "Amt"
            amountTextBox.Text = "1"
            amountTextBox.Font = Enum.Font.Gotham
            amountTextBox.TextSize = 14
            amountTextBox.Parent = itemContainer

            local amountTextBoxCorner = Instance.new("UICorner")
            amountTextBoxCorner.CornerRadius = UDim.new(0, 6)
            amountTextBoxCorner.Parent = amountTextBox

            local okButton = Instance.new("TextButton")
            okButton.Size = UDim2.new(0.18, 0, 0.8, 0)
            okButton.Position = UDim2.new(0.75, 0, 0.5, 0)
            okButton.AnchorPoint = Vector2.new(0, 0.5)
            okButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
            okButton.BackgroundTransparency = 0.1
            okButton.BorderSizePixel = 0
            okButton.Text = "OK"
            okButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            okButton.TextSize = 14
            okButton.Font = Enum.Font.GothamSemibold
            okButton.Parent = itemContainer

            local okButtonCorner = Instance.new("UICorner")
            okButtonCorner.CornerRadius = UDim.new(0, 6)
            okButtonCorner.Parent = okButton

            local okButtonGradient = Instance.new("UIGradient")
            okButtonGradient.Color = ColorSequence.new(Color3.fromRGB(85, 85, 85), Color3.fromRGB(70, 70, 70))
            okButtonGradient.Rotation = 90
            okButtonGradient.Parent = okButton

            okButton.MouseButton1Click:Connect(function()
                local amount = parseAmountString(amountTextBox.Text)
                if amount and amount > 0 then
                    local existingItem = nil
                    for _, itemInBackpack in ipairs(player.Backpack:GetChildren()) do
                        if itemInBackpack:IsA("Tool") and itemInBackpack:FindFirstChild("DisplayName") and itemInBackpack.DisplayName.Value == tool.DisplayName.Value then
                            existingItem = itemInBackpack
                            break
                        end
                    end

                    if existingItem then
                        if existingItem:FindFirstChild("Amount") then
                            existingItem.Amount.Value = existingItem.Amount.Value + amount
                        else
                            local amountValue = Instance.new("IntValue")
                            amountValue.Name = "Amount"
                            amountValue.Value = amount
                            amountValue.Parent = existingItem
                        end
                    else
                        local newItem = tool:Clone()
                        newItem.Parent = player.Backpack

                        if newItem:FindFirstChild("Amount") then
                            newItem.Amount.Value = amount
                        else
                            local amountValue = Instance.new("IntValue")
                            amountValue.Name = "Amount"
                            amountValue.Value = amount
                            amountValue.Parent = newItem
                        end
                        trackItemPlacement(newItem)
                    end

                    showNotification("+ " .. amount .. " " .. itemName)
                else
                    showNotification("Invalid amount entered.")
                end
            end)

            uiItemDisplays[itemName] = {
                label = itemNameLabel,
                originalTool = tool
            }
        end
    else
        warn("Tools folder not found in ReplicatedStorage.")
    end
end

local function createItemsList()
    local itemsListGui = Instance.new("ScreenGui")
    itemsListGui.Name = "ItemsListGui"
    itemsListGui.ResetOnSpawn = false
    itemsListGui.Parent = player.PlayerGui

    local itemsFrame = Instance.new("Frame")
    itemsFrame.Name = "ItemsFrame"
    itemsFrame.Size = UDim2.new(0.18, 0, 0.40, 0)
    itemsFrame.Position = UDim2.new(-itemsFrame.Size.X.Scale, 0, 0.80, 0)
    itemsFrame.AnchorPoint = Vector2.new(0, 0.5)
    itemsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    itemsFrame.BackgroundTransparency = 0.1
    itemsFrame.BorderSizePixel = 0
    itemsFrame.Active = true
    itemsFrame.Draggable = false
    itemsFrame.Visible = true
    itemsFrame.Parent = itemsListGui

    local uiCornerFrame = Instance.new("UICorner")
    uiCornerFrame.CornerRadius = UDim.new(0, 12)
    uiCornerFrame.Parent = itemsFrame

    local frameGradient = Instance.new("UIGradient")
    frameGradient.Color = ColorSequence.new(Color3.fromRGB(20, 20, 20), Color3.fromRGB(5, 5, 5))
    frameGradient.Rotation = 90
    frameGradient.Parent = itemsFrame

    local searchBar = Instance.new("TextBox")
    searchBar.Size = UDim2.new(0.9, 0, 0, 35)
    searchBar.Position = UDim2.new(0.05, 0, 0.05, 0)
    searchBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    searchBar.BackgroundTransparency = 0.2
    searchBar.BorderSizePixel = 0
    searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBar.PlaceholderText = "Filter items..."
    searchBar.Text = ""
    searchBar.Font = Enum.Font.Gotham
    searchBar.TextSize = 18
    searchBar.Parent = itemsFrame

    local searchBarCorner = Instance.new("UICorner")
    searchBarCorner.CornerRadius = UDim.new(0, 8)
    searchBarCorner.Parent = searchBar

    local itemListFrame = Instance.new("ScrollingFrame")
    itemListFrame.Name = "ItemListFrame"
    itemListFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    itemListFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
    itemListFrame.BackgroundTransparency = 1
    itemListFrame.ScrollBarThickness = 6
    itemListFrame.Parent = itemsFrame

    local scrollBarBackground = Instance.new("Frame")
    scrollBarBackground.Size = UDim2.new(0, 6, 1, 0)
    scrollBarBackground.Position = UDim2.new(1, -6, 0, 0)
    scrollBarBackground.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    scrollBarBackground.BorderSizePixel = 0
    scrollBarBackground.Parent = itemListFrame

    local scrollBarBackgroundCorner = Instance.new("UICorner")
    scrollBarBackgroundCorner.CornerRadius = UDim.new(0, 3)
    scrollBarBackgroundCorner.Parent = scrollBarBackground

    local scrollBarBackgroundGradient = Instance.new("UIGradient")
    scrollBarBackgroundGradient.Color = ColorSequence.new(Color3.fromRGB(15, 15, 15), Color3.fromRGB(5, 5, 5))
    scrollBarBackgroundGradient.Rotation = 90
    scrollBarBackgroundGradient.Parent = scrollBarBackground

    itemListFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)

    local UIGridLayout = Instance.new("UIGridLayout")
    UIGridLayout.Parent = itemListFrame
    UIGridLayout.CellSize = UDim2.new(1, 0, 0, 40)
    UIGridLayout.CellPadding = UDim2.new(0, 0, 0, 5)
    UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIGridLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    populateItemList(itemsListGui)

    local function updateCanvasSize()
        local contentHeight = UIGridLayout.AbsoluteContentSize.Y
        itemListFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
    end

    UIGridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    updateCanvasSize()

    searchBar:GetPropertyChangedSignal("Text"):Connect(function()
        local searchText = string.lower(searchBar.Text)
        for _, itemContainer in ipairs(itemListFrame:GetChildren()) do
            if itemContainer:IsA("Frame") and itemContainer:FindFirstChildOfClass("TextLabel") then
                local itemNameLabel = itemContainer:FindFirstChildOfClass("TextLabel")
                local itemName = itemNameLabel.Text:lower()
                if searchText == "" or itemName:find(searchText, 1, true) then
                    itemContainer.Visible = true
                else
                    itemContainer.Visible = false
                end
            end
        end
    end)

    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = "ToggleButton"
    toggleButton.Size = UDim2.new(0, 40, 0, 80)
    toggleButton.Position = UDim2.new(0, 0, 0.80, 0)
    toggleButton.AnchorPoint = Vector2.new(0, 0.5)
    toggleButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggleButton.BackgroundTransparency = 0.1
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = "→"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 30
    toggleButton.Font = Enum.Font.GothamSemibold
    toggleButton.Parent = itemsListGui

    local toggleButtonCorner = Instance.new("UICorner")
    toggleButtonCorner.CornerRadius = UDim.new(0, 8)
    toggleButtonCorner.Parent = toggleButton

    local toggleButtonGradient = Instance.new("UIGradient")
    toggleButtonGradient.Color = ColorSequence.new(Color3.fromRGB(70, 70, 70), Color3.fromRGB(50, 50, 50))
    toggleButtonGradient.Rotation = 90
    toggleButtonGradient.Parent = toggleButton

    local panelOpen = false

    local function slidePanel(open)
        local targetFramePosition
        local targetButtonPosition
        local buttonText

        if open then
            targetFramePosition = UDim2.new(0, 0, 0.80, 0)
            targetButtonPosition = UDim2.new(itemsFrame.Size.X.Scale, 0, 0.80, 0)
            buttonText = "←"
        else
            targetFramePosition = UDim2.new(-itemsFrame.Size.X.Scale, 0, 0.80, 0)
            targetButtonPosition = UDim2.new(0, 0, 0.80, 0)
            buttonText = "→"
        end

        local frameTween = game:GetService("TweenService"):Create(
            itemsFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = targetFramePosition}
        )
        frameTween:Play()

        local buttonTween = game:GetService("TweenService"):Create(
            toggleButton,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = targetButtonPosition}
        )
        buttonTween:Play()

        toggleButton.Text = buttonText
        panelOpen = open
    end

    toggleButton.MouseButton1Click:Connect(function()
        slidePanel(not panelOpen)
    end)

    slidePanel(false)

    return itemsListGui
end

local function getDropsFolder()
    local islandsFolder = Workspace:FindFirstChild("Islands")
    if not islandsFolder then
        warn("Islands folder not found in Workspace.")
        return nil
    end

    for _, island in ipairs(islandsFolder:GetChildren()) do
        if string.match(island.Name, "%-island$") then
            local dropsFolder = island:FindFirstChild("Drops")
            if not dropsFolder then
                dropsFolder = Instance.new("Folder")
                dropsFolder.Name = "Drops"
                dropsFolder.Parent = island
            end
            return dropsFolder
        end
    end
    warn("Drops folder not found or created in any island.")
    return nil
end

local function dropItem(tool)
    if tool and tool:FindFirstChild("Amount") then
        local amount = tool.Amount
        if amount.Value > 0 then
            amount.Value -= 1

            local dropsFolder = getDropsFolder()
            if not dropsFolder then
                warn("Drops folder not found. Cannot drop item.")
                return
            end

            local toolClone = tool:Clone()
            toolClone.Parent = dropsFolder

            if toolClone:FindFirstChild("Handle") then
                toolClone.Handle.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, -2, -2)
                toolClone.Handle.CanCollide = true
            else
                warn("Tool does not have a Handle. Cannot drop properly.")
            end

            local droppedAmount = toolClone:FindFirstChild("Amount")
            if droppedAmount then
                droppedAmount:Destroy()
            end

            task.delay(30, function()
                if toolClone and toolClone.Parent == dropsFolder then
                    toolClone:Destroy()
                    warn("Dropped item " .. toolClone.Name .. " has been destroyed after 30 seconds.")
                end
            end)

            if amount.Value == 0 then
                tool:Destroy()
                warn("Tool removed from backpack as Amount hit 0.")
            end
        else
            warn("No more items left to drop.")
        end
    end
end

local function pickUpItem(tool)
    local existingTool = player.Backpack:FindFirstChild(tool.Name)
    if existingTool and existingTool:FindFirstChild("Amount") then
        existingTool.Amount.Value += 1
    else
        tool.Parent = player.Backpack
        if not tool:FindFirstChild("Amount") then
            local amountValue = Instance.new("IntValue")
            amountValue.Name = "Amount"
            amountValue.Value = 1
            amountValue.Parent = tool
        end
    end
    warn("Picked up tool:", tool.Name, "Amount increased.")
    tool:Destroy()
end

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q then
        local tool = player.Character:FindFirstChildOfClass("Tool") or player.Backpack:FindFirstChildOfClass("Tool")
        if tool then
            dropItem(tool)
        end
    elseif input.KeyCode == Enum.KeyCode.F then
        local target = mouse.Target
        if target then
            local dropsFolder = getDropsFolder()
            if dropsFolder and target:IsDescendantOf(dropsFolder) then
                local toolCandidate = target.Parent
                if toolCandidate and toolCandidate:IsA("Tool") then
                    pickUpItem(toolCandidate)
                elseif target:IsA("BasePart") and target.Parent:IsA("Tool") then
                    pickUpItem(target.Parent)
                else
                    warn("Hovered over invalid tool or non-tool object. Parent:", target.Parent, "Class:", target.Parent and target.Parent.ClassName)
                end
            else
                warn("Hovered target is not part of Drops. Target Parent:", target.Parent)
            end
        else
            warn("No target detected under mouse.")
        end
    end
end)

local function deleteExistingItemsListGui()
    local existingGui = player.PlayerGui:FindFirstChild("ItemsListGui")
    if existingGui then
        existingGui:Destroy()
    end
end

deleteExistingItemsListGui()

local createdGui = createItemsList()
setupBackpackListeners()

local clientBlock = game.ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):FindFirstChild("CLIENT_BLOCK_PLACE_REQUEST")
if clientBlock then
    clientBlock:Destroy()
end

mouse.TargetFilter = Workspace.Islands
