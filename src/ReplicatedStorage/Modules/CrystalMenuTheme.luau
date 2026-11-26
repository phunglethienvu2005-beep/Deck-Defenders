local TweenService = game:GetService("TweenService")

local Theme = {
    ice = Color3.fromRGB(124, 191, 255),
    blue = Color3.fromRGB(52, 120, 191),
    gold = Color3.fromRGB(255, 200, 61),
    green = Color3.fromRGB(101, 218, 53),
    red = Color3.fromRGB(240, 68, 68),
    purple = Color3.fromRGB(168, 85, 247),
    slate = Color3.fromRGB(95, 111, 139),
    black = Color3.fromRGB(6, 8, 16),
}

local function edge(parent, name, color, thickness, transparency)
    local stroke = parent:FindFirstChild(name) or Instance.new("UIStroke")
    stroke.Name = name
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color, stroke.Thickness, stroke.Transparency = color, thickness, transparency
    stroke.Parent = parent
    return stroke
end

function Theme.surface(gui, tint, bright)
    local corner = gui:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = gui
    gui.BorderSizePixel = 0
    gui.BackgroundColor3 = Color3.new(1, 1, 1)
    local gradient = gui:FindFirstChild("CrystalGradient") or Instance.new("UIGradient")
    gradient.Name = "CrystalGradient"
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, tint:Lerp(Theme.black, if bright then 0.08 else 0.55)),
        ColorSequenceKeypoint.new(0.16, tint:Lerp(Theme.black, if bright then 0.18 else 0.70)),
        ColorSequenceKeypoint.new(0.86, tint:Lerp(Theme.black, if bright then 0.56 else 0.90)),
        ColorSequenceKeypoint.new(1, Theme.black),
    })
    gradient.Rotation = 90
    gradient.Parent = gui
    for _, child in ipairs(gui:GetChildren()) do
        if child:IsA("UIStroke") and child.Name ~= "CrystalRim" then child.Enabled = false end
    end
    local rim = edge(gui, "CrystalRim", tint:Lerp(Color3.new(1, 1, 1), 0.23), 1, if bright then 0.12 else 0.44)
    return rim
end

function Theme.label(gui)
    gui.Font = Enum.Font.FredokaOne
    gui.TextColor3 = Color3.new(1, 1, 1)
    gui.TextStrokeColor3 = Theme.black
    gui.TextStrokeTransparency = 0.55
end

function Theme.hover(gui)
    local rim = gui:FindFirstChild("CrystalRim")
    if not rim then return end
    local idle
    local tween
    local function glow(transparency)
        if tween then tween:Cancel() end
        tween = TweenService:Create(rim, TweenInfo.new(0.16), {Transparency = transparency})
        tween:Play()
    end
    gui.MouseEnter:Connect(function()
        idle = rim.Transparency
        glow(math.max(0, idle - 0.35))
    end)
    gui.MouseLeave:Connect(function() if idle then glow(idle) end end)
end

function Theme.rewardIcon(parent, tint, glyph, position, size)
    local emblem = Instance.new("Frame")
    emblem.Name = "RewardEmblem"
    emblem.Position = position
    emblem.Size = UDim2.fromOffset(size, size)
    Theme.surface(emblem, tint, true)
    emblem.Parent = parent
    local symbol = Instance.new("TextLabel")
    symbol.Size = UDim2.fromScale(1, 1)
    symbol.BackgroundTransparency = 1
    symbol.TextSize = math.floor(size * 0.69)
    symbol.Text = glyph
    Theme.label(symbol)
    symbol.TextColor3 = tint:Lerp(Color3.new(1, 1, 1), 0.55)
    symbol.Parent = emblem
    return emblem
end

function Theme.battleRewardCards(parent)
    local WaveData = require(script.Parent:WaitForChild("WaveData"))
    local minimum, maximum = math.huge, 0
    for _, enemy in pairs(WaveData.EnemyStats) do
        local amount = enemy.reward or 15
        minimum, maximum = math.min(minimum, amount), math.max(maximum, amount)
    end
    local rewards = {
        {name = "ENEMY BOUNTY", value = string.format("%d–%d ¥", minimum, maximum), glyph = "¥", tint = Theme.gold},
        {name = "WAVE CLEAR", value = "Varies by wave", glyph = "✦", tint = Theme.ice},
    }
    for index, reward in ipairs(rewards) do
        local tile = Instance.new("Frame")
        tile.Size = UDim2.new(0.5, -12, 1, -8)
        tile.Position = UDim2.new((index - 1) * 0.5, 7, 0, 4)
        Theme.surface(tile, reward.tint, false)
        tile.Parent = parent
        Theme.rewardIcon(tile, reward.tint, reward.glyph, UDim2.fromOffset(8, 7), 34)
        Theme.hover(tile)
        for row, value in ipairs({reward.name, reward.value}) do
            local label = Instance.new("TextLabel")
            label.BackgroundTransparency = 1
            label.Position = UDim2.fromOffset(52, 6 + (row - 1) * 17)
            label.Size = UDim2.new(1, -58, 0, 16)
            Theme.label(label)
            label.Text = value
            label.TextSize = if row == 1 then 11 else 16
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextColor3 = if row == 1 then reward.tint else Color3.new(1, 1, 1)
            label.Parent = tile
        end
    end
end

function Theme.button(gui, tint, enabled)
    local rim = Theme.surface(gui, tint, enabled)
    Theme.label(gui)
    gui.AutoButtonColor = false
    gui.Active = enabled
    gui.Selectable = enabled
    local title = Instance.new("TextLabel")
    title.Name = "CrystalTitle"
    title.Size = UDim2.fromScale(1, 1)
    title.BackgroundTransparency = 1
    title.ZIndex = gui.ZIndex + 2
    Theme.label(title)
    local function syncTitle()
        title.Text = gui.Text
        title.TextSize = gui.TextSize
        title.TextScaled = gui.TextScaled
        title.TextWrapped = gui.TextWrapped
        title.TextXAlignment = gui.TextXAlignment
        title.TextYAlignment = gui.TextYAlignment
        title.TextTransparency = if enabled then 0 else 0.3
    end
    for _, property in ipairs({"Text", "TextSize", "TextScaled", "TextWrapped", "TextXAlignment", "TextYAlignment"}) do
        gui:GetPropertyChangedSignal(property):Connect(syncTitle)
    end
    gui.TextTransparency = 1
    syncTitle()
    title.Parent = gui
    if not enabled then return end
    local scale = Instance.new("UIScale")
    scale.Parent = gui
    local activeTween
    local function animate(size, glow)
        if activeTween then activeTween:Cancel() end
        activeTween = TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {Scale = size})
        activeTween:Play()
        rim.Transparency = glow
    end
    gui.MouseEnter:Connect(function() animate(1.02, 0) end)
    gui.MouseLeave:Connect(function() animate(1, 0.08) end)
    gui.MouseButton1Down:Connect(function() animate(0.97, 0) end)
    gui.MouseButton1Up:Connect(function() animate(1, 0.08) end)
end

function Theme.heroPortrait(parent, template)
    if not template or not template:IsA("Model") or not template.Archivable then return end
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "HeroPortrait"
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.BackgroundTransparency = 1
    local copy = template:Clone()
    for _, child in ipairs(copy:GetDescendants()) do
        if child:IsA("LuaSourceContainer") then child:Destroy() end
    end
    copy.Parent = viewport
    local target, size = copy:GetBoundingBox()
    local center = target.Position + Vector3.new(0, size.Y * 0.18, 0)
    local camera = Instance.new("Camera")
    camera.FieldOfView = 40
    camera.CFrame = CFrame.lookAt(center + target.LookVector * math.max(4, size.Y), center)
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    viewport.Parent = parent
end

function Theme.crystal(parent, position, size, tint)
    local gem = Instance.new("Frame")
    gem.Name = "CrystalFacet"
    gem.AnchorPoint = Vector2.new(0.5, 0.5)
    gem.Position = position
    gem.Size = UDim2.fromOffset(size, size)
    gem.Rotation = 45
    gem.ZIndex = parent.ZIndex + 1
    Theme.surface(gem, tint, true)
    gem.Parent = parent
    return gem
end

function Theme.mapPreview(parent)
    local map = workspace:FindFirstChild("The Void")
    if not map then return end
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "VoidPreview"
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.BackgroundColor3 = Color3.fromRGB(56, 77, 111)
    viewport.BorderSizePixel = 0
    local lighting = game:GetService("Lighting")
    viewport.Ambient = lighting.OutdoorAmbient:Lerp(Color3.fromRGB(164, 184, 218), 0.65)
    viewport.LightColor = Color3.fromRGB(244, 226, 196)
    viewport.LightDirection = -lighting:GetSunDirection()
    viewport.ZIndex = parent.ZIndex + 1
    viewport.Parent = parent
    local scene = Instance.new("WorldModel")
    scene.Parent = viewport
    local geometry = Instance.new("Model")
    geometry.Parent = scene
    local shade = Instance.new("Frame")
    shade.Name = "PreviewShade"
    shade.Size = UDim2.fromScale(1, 1)
    shade.BackgroundColor3 = Theme.black
    shade.BorderSizePixel = 0
    shade.ZIndex = viewport.ZIndex + 1
    local fade = Instance.new("UIGradient")
    fade.Rotation = 90
    fade.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.51, 0.97),
        NumberSequenceKeypoint.new(1, 0.14),
    })
    fade.Parent = shade
    shade.Parent = parent
    viewport.ImageTransparency = 1
    task.defer(function()
        local count = 0
        for _, part in ipairs(map:GetDescendants()) do
            if not viewport.Parent then return end
            if part:IsA("BasePart") and part.Archivable and part.Transparency < 1 then
                local copy = part:Clone()
                for _, child in ipairs(copy:GetChildren()) do
                    if not (child:IsA("Decal") or child:IsA("SurfaceAppearance") or child:IsA("DataModelMesh")) then
                        child:Destroy()
                    end
                end
                copy.Anchored = true
                copy.CanCollide = false
                copy.Parent = geometry
                count += 1
                if count % 45 == 0 then task.wait() end
            end
        end
        if not viewport.Parent then return end
        if count == 0 then viewport:Destroy(); shade:Destroy(); return end
        local bounds, extent = geometry:GetBoundingBox()
        local camera = Instance.new("Camera")
        camera.FieldOfView = 36
        camera.Parent = viewport
        viewport.CurrentCamera = camera
        local center = bounds.Position
        local angle = Vector3.new(0.74, 0.62, 1).Unit
        local orientation = CFrame.lookAt(center + angle, center)
        local function fit()
            local size = viewport.AbsoluteSize
            local aspect = if size.Y > 0 then math.max(0.1, size.X / size.Y) else 2
            local vertical = math.tan(math.rad(camera.FieldOfView / 2))
            local distance = 1
            for _, x in ipairs({-0.5, 0.5}) do
                for _, y in ipairs({-0.5, 0.5}) do
                    for _, z in ipairs({-0.5, 0.5}) do
                        local corner = bounds:PointToWorldSpace(extent * Vector3.new(x, y, z))
                        local offset = orientation:VectorToObjectSpace(corner - center)
                        distance = math.max(distance, offset.Z + 1.04 * math.max(
                            math.abs(offset.Y) / vertical, math.abs(offset.X) / (vertical * aspect)))
                    end
                end
            end
            camera.CFrame = CFrame.lookAt(center + angle * distance, center)
        end
        viewport:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
        fit()
        TweenService:Create(viewport, TweenInfo.new(0.24), {ImageTransparency = 0}):Play()
    end)
    return viewport
end

return Theme
