local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local itemCounts = {}

local function createItemsList()
	local itemsListGui = Instance.new("ScreenGui")
	itemsListGui.Name = "ItemsListGui"
	itemsListGui.ResetOnSpawn = false
	itemsListGui.Parent = player.PlayerGui

	local itemsFrame = Instance.new("Frame")
	itemsFrame.Size = UDim2.new(0.25, 0, 0.5, 0)
	itemsFrame.Position = UDim2.new(0.75, 0, 0.25, 0)
	itemsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	itemsFrame.BackgroundTransparency = 0.8
	itemsFrame.BorderSizePixel = 0
	itemsFrame.Active = true
	itemsFrame.Draggable = true
	itemsFrame.Visible = true
	itemsFrame.Parent = itemsListGui

	local itemsTitleLabel = Instance.new("TextLabel")
	itemsTitleLabel.Size = UDim2.new(1, 0, 0.1, 0)
	itemsTitleLabel.Position = UDim2.new(0, 0, 0, 0)
	itemsTitleLabel.BackgroundTransparency = 1
	itemsTitleLabel.Text = "Item List"
	itemsTitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	itemsTitleLabel.TextSize = 24
	itemsTitleLabel.Font = Enum.Font.GothamSemibold
	itemsTitleLabel.Parent = itemsFrame

	local itemListFrame = Instance.new("ScrollingFrame")
	itemListFrame.Size = UDim2.new(1, 0, 0.8, 0)
	itemListFrame.Position = UDim2.new(0, 0, 0.2, 0)
	itemListFrame.BackgroundTransparency = 1
	itemListFrame.ScrollBarThickness = 8
	itemListFrame.Parent = itemsFrame

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Parent = itemListFrame
	UIListLayout.Padding = UDim.new(0, 5)
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

	local function showNotification(message)
		local existingNotification = itemsListGui:FindFirstChild("Notification")
		if existingNotification then
			existingNotification:Destroy()
		end

		local notification = Instance.new("TextLabel")
		notification.Name = "Notification"
		notification.Size = UDim2.new(0.2, 0, 0, 25)
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
		TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{TextTransparency = 0, BackgroundTransparency = 0.9}
		)

		local fadeOutTween = game:GetService("TweenService"):Create(
		notification,
		TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{TextTransparency = 1, BackgroundTransparency = 0.9}
		)

		fadeInTween:Play()

		wait(1)

		wait(5)

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

        warn("Initial parts count:", #blocksFolder:GetChildren())
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

                    warn("Placement detected for tool:", heldToolName, "Placement Number:", placementCount)

                    local amount = tool:FindFirstChild("Amount")
                    if amount and amount.Value > 0 then
                        amount.Value -= 1
                        warn("Updated tool amount:", amount.Value)
                        if amount.Value <= 0 then
                            tool:Destroy()
                            warn(tool.Name .. " has been depleted and removed.")
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

local function populateItemList()
    local toolsFolder = ReplicatedStorage:FindFirstChild("Tools")
    if toolsFolder then
        for _, tool in ipairs(toolsFolder:GetChildren()) do
            local itemName = tool:FindFirstChild("DisplayName") and tool.DisplayName.Value or tool.Name

            local itemButton = Instance.new("TextButton")
            itemButton.Size = UDim2.new(0.9, 0, 0, 40)
            itemButton.AnchorPoint = Vector2.new(0.5, 0)
            itemButton.Position = UDim2.new(0.5, 0, 0, 0)
            itemButton.BackgroundTransparency = 0.5
            itemButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            itemButton.Text = itemName
            itemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            itemButton.TextSize = 18
            itemButton.Font = Enum.Font.GothamSemibold
            itemButton.Parent = itemListFrame

            local itemButtonCorner = Instance.new("UICorner")
            itemButtonCorner.CornerRadius = UDim.new(0, 8)
            itemButtonCorner.Parent = itemButton

            itemButton.MouseButton1Click:Connect(function()
                local existingPopup = itemsListGui:FindFirstChild("ItemPopup")
                if existingPopup then
                    existingPopup:Destroy()
                end

                local popupFrame = Instance.new("Frame")
                popupFrame.Name = "ItemPopup"
                popupFrame.Size = UDim2.new(0.2, 0, 0.3, 0)
                popupFrame.Position = UDim2.new(0.35, 0, 0.35, 0)
                popupFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                popupFrame.BackgroundTransparency = 0.8
                popupFrame.BorderSizePixel = 0
                popupFrame.Active = true
                popupFrame.Draggable = true
                popupFrame.Parent = itemsListGui

                local amountLabel = Instance.new("TextLabel")
                amountLabel.Size = UDim2.new(1, 0, 0.2, 0)
                amountLabel.Position = UDim2.new(0, 0, 0.1, 0)
                amountLabel.BackgroundTransparency = 1
                amountLabel.Text = "Item amount:"
                amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                amountLabel.TextSize = 18
                amountLabel.Font = Enum.Font.GothamSemibold
                amountLabel.Parent = popupFrame

                local amountTextBox = Instance.new("TextBox")
                amountTextBox.Size = UDim2.new(0.8, 0, 0.2, 0)
                amountTextBox.Position = UDim2.new(0.1, 0, 0.4, 0)
                amountTextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                amountTextBox.BackgroundTransparency = 0.5
                amountTextBox.BorderSizePixel = 0
                amountTextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                amountTextBox.PlaceholderText = "Enter amount..."
                amountTextBox.Font = Enum.Font.Gotham
                amountTextBox.TextSize = 16
                amountTextBox.Parent = popupFrame

                local amountTextBoxCorner = Instance.new("UICorner")
                amountTextBoxCorner.CornerRadius = UDim.new(0, 8)
                amountTextBoxCorner.Parent = amountTextBox

                local confirmButton = Instance.new("TextButton")
                confirmButton.Size = UDim2.new(0.6, 0, 0.2, 0)
                confirmButton.Position = UDim2.new(0.2, 0, 0.7, 0)
                confirmButton.BackgroundColor3 = Color3.fromRGB(50, 122, 183)
                confirmButton.BackgroundTransparency = 0.5
                confirmButton.BorderSizePixel = 0
                confirmButton.Text = "OK"
                confirmButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                confirmButton.TextSize = 18
                confirmButton.Font = Enum.Font.GothamSemibold
                confirmButton.Parent = popupFrame

                local confirmButtonCorner = Instance.new("UICorner")
                confirmButtonCorner.CornerRadius = UDim.new(0, 8)
                confirmButtonCorner.Parent = confirmButton

                confirmButton.MouseButton1Click:Connect(function()
                    local amount = tonumber(amountTextBox.Text)
                    if amount then
                        local existingItem = nil
                        for _, item in ipairs(player.Backpack:GetChildren()) do
                            if item:IsA("Tool") and item:FindFirstChild("DisplayName") and item.DisplayName.Value == tool.DisplayName.Value then
                                existingItem = item
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

                        if itemCounts[itemName] then
                            itemCounts[itemName] = itemCounts[itemName] + amount
                        else
                            itemCounts[itemName] = amount
                        end
                        showNotification("+ " .. itemCounts[itemName] .. " " .. itemName .. "s")

                        popupFrame:Destroy()
                    else
                        warn("Invalid amount entered.")
                    end
                end)
            end)
        end
    else
        warn("Tools folder not found in ReplicatedStorage.")
    end
end

	populateItemList()

	local function updateCanvasSize()
		local layoutHeight = UIListLayout.AbsoluteContentSize.Y
		itemListFrame.CanvasSize = UDim2.new(0, 0, 0, layoutHeight)
	end

	UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
	updateCanvasSize()

	local searchBar = Instance.new("TextBox")
	searchBar.Size = UDim2.new(0.9, 0, 0, 30)
	searchBar.Position = UDim2.new(0.05, 0, 0.12, 0)
	searchBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	searchBar.BackgroundTransparency = 0.5
	searchBar.BorderSizePixel = 0
	searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
	searchBar.PlaceholderText = "Search items..."
	searchBar.Font = Enum.Font.Gotham
	searchBar.TextSize = 16
	searchBar.Parent = itemsFrame

	local searchBarCorner = Instance.new("UICorner")
	searchBarCorner.CornerRadius = UDim.new(0, 8)
	searchBarCorner.Parent = searchBar

	searchBar:GetPropertyChangedSignal("Text"):Connect(function()
		local searchText = string.lower(searchBar.Text)
		for _, itemButton in ipairs(itemListFrame:GetChildren()) do
			if itemButton:IsA("TextButton") then
				local itemName = itemButton.Text:lower()
				if searchText == "" or itemName:find(searchText, 1, true) then
					itemButton.Visible = true
				else
					itemButton.Visible = false
				end
			end
		end
	end)

	return itemsListGui
end

local function deleteExistingItemsListGui()
	local existingGui = player.PlayerGui:FindFirstChild("ItemsListGui")
	if existingGui then
		existingGui:Destroy()
	end
end

deleteExistingItemsListGui()

createItemsList()
wait("0.01")
local clientBlock = game.ReplicatedStorage:WaitForChild("rbxts_include"):WaitForChild("node_modules"):WaitForChild("@rbxts"):WaitForChild("net"):WaitForChild("out"):WaitForChild("_NetManaged"):FindFirstChild("CLIENT_BLOCK_PLACE_REQUEST")

if clientBlock then
    clientBlock:Destroy()
else
    warn("CLIENT_BLOCK_PLACE_REQUEST not found")
end
