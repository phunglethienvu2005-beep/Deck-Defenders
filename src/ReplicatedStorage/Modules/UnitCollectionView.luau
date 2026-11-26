local Collection = {}
local HttpService = game:GetService("HttpService")
local Input = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Loadout = require(script.Parent.UnitLoadout)
local Placement = require(script.Parent.PlacementRules)
local Theme = require(script.Parent.CrystalMenuTheme)
local warm = Color3.fromRGB(242, 148, 51)
local fire = Color3.fromRGB(249, 94, 68)
local obsidian = Color3.fromRGB(8, 9, 13)
local white = Color3.new(1, 1, 1)

local function make(class, parent, name, bounds)
    local gui = Instance.new(class)
    gui.Name, gui.Position, gui.Size = name, bounds[1], bounds[2]
    gui.BorderSizePixel = 0
    gui.Parent = parent
    return gui
end

local function box(x, y, width, height)
    return {UDim2.fromScale(x, y), UDim2.fromScale(width, height)}
end

local function gradient(gui, name, top, middle, bottom, angle)
    local layer = gui:FindFirstChild(name) or Instance.new("UIGradient")
    layer.Name = name
    layer.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, top), ColorSequenceKeypoint.new(0.4, middle),
        ColorSequenceKeypoint.new(1, bottom),
    })
    layer.Rotation = angle or 90
    layer.Parent = gui
    gui.BackgroundColor3 = white
    return layer
end

local function outline(gui, name, color, thickness, transparency)
    local stroke = gui:FindFirstChild(name) or Instance.new("UIStroke")
    stroke.Name = name
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color, stroke.Thickness, stroke.Transparency = color, thickness, transparency
    stroke.Parent = gui
    return stroke
end

local function enamel(gui, tint)
    local color = Color3.fromRGB(22, 24, 33)
    gradient(gui, "CrystalGradient", tint:Lerp(white, 0.17), tint:Lerp(color, 0.32), tint:Lerp(obsidian, 0.76))
    outline(gui, "CrystalRim", tint:Lerp(white, 0.35), 1.4, 0.18)
    outline(gui, "BevelShadow", obsidian, 3, 0.2)
end

local function captionStroke(label, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
    stroke.Color, stroke.Thickness = obsidian, thickness
    stroke.Parent = label
    label.TextStrokeTransparency = 1
end

local function text(parent, name, value, bounds, size, color)
    local label = make("TextLabel", parent, name, bounds)
    label.BackgroundTransparency = 1
    Theme.label(label)
    label.Text, label.TextSize = value, size
    label.TextColor3 = color or Color3.new(1, 1, 1)
    label.TextWrapped = true
    return label
end

local function button(parent, name, value, bounds, size, tint)
    local item = make("TextButton", parent, name, bounds)
    item.Text, item.TextSize = value, size
    Theme.button(item, tint, true)
    enamel(item, tint)
    captionStroke(item.CrystalTitle, 1.8)
    return item
end

local function colorFor(unit)
    return if unit.element == "Ice" then Theme.ice else fire
end

function Collection.mount(gui, player, partyAction)
    local templates = game:GetService("ReplicatedStorage"):WaitForChild("Towers")
    local overlay = make("CanvasGroup", gui, "UnitCollection", box(0, 0, 1, 1))
    overlay.Visible, overlay.Active, overlay.ZIndex = false, true, 40
    overlay.BackgroundColor3 = obsidian
    overlay.BackgroundTransparency = 0.2
    local window = make("Frame", overlay, "CollectionWindow", box(0.5, 0.5, 0.93, 0.89))
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    Theme.surface(window, warm, false)
    gradient(window, "CrystalGradient", Color3.fromRGB(19, 20, 29), obsidian, Color3.fromRGB(12, 13, 19), 120)
    outline(window, "CrystalRim", warm, 1.2, 0.16)
    for _, position in ipairs({Vector2.new(0.013, 0.015), Vector2.new(0.987, 0.015),
        Vector2.new(0.013, 0.985), Vector2.new(0.987, 0.985)}) do
        local corner = Theme.crystal(window, UDim2.fromScale(position.X, position.Y), 9, warm)
        corner.BackgroundTransparency = 0.42
        corner.CrystalRim.Transparency = 0.67
    end
    local scale = Instance.new("UIScale")
    scale.Parent = window

    local banner = make("Frame", window, "CollectionBanner", box(0.02, 0.025, 0.36, 0.11))
    banner.BackgroundTransparency = 1
    local ribbon = make("Frame", banner, "RibbonFace", box(0, 0.04, 0.89, 0.91))
    gradient(ribbon, "Amber", Color3.fromRGB(255, 223, 82), Color3.fromRGB(252, 137, 32), Color3.fromRGB(192, 39, 15), 14)
    outline(ribbon, "InkEdge", obsidian, 2.5, 0)
    local tip = make("Frame", banner, "RibbonPoint", box(0.83, 0.5, 0, 0))
    tip.AnchorPoint, tip.Rotation = Vector2.new(0.5, 0.5), 45
    local function fitRibbon()
        local diagonal = math.max(6, math.min(banner.AbsoluteSize.Y * 0.64, banner.AbsoluteSize.X * 0.17))
        tip.Size = UDim2.fromOffset(diagonal, diagonal)
    end
    banner:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitRibbon)
    fitRibbon()
    gradient(tip, "Amber", Color3.fromRGB(241, 141, 36), Color3.fromRGB(215, 66, 21), Color3.fromRGB(148, 29, 12), 45)
    for row = 1, 3 do
        for col = 1, 7 do
            local dot = make("Frame", ribbon, "InkDot", {UDim2.fromScale(0.62 + col * 0.044, 0.13 + row * 0.18), UDim2.fromOffset(3, 3)})
            dot.BackgroundColor3, dot.BackgroundTransparency = obsidian, 0.52 + row * 0.09
        end
    end
    local sigil = text(banner, "Sigil", "✦", box(0.72, 0.08, 0.12, 0.81), 20, obsidian)
    sigil.TextStrokeTransparency = 1
    local title = text(banner, "Title", "COLLECTION", box(0.05, 0, 0.66, 1), 33)
    title.TextXAlignment = Enum.TextXAlignment.Left
    captionStroke(title, 2.3)
    local search = make("TextBox", window, "Search", box(0.40, 0.032, 0.23, 0.095))
    search.Text, search.PlaceholderText = "", "Search units…"
    search.ClearTextOnFocus = false
    search.TextSize, search.Font = 16, Enum.Font.GothamMedium
    search.TextColor3 = Color3.new(1, 1, 1)
    Theme.surface(search, warm, false)
    gradient(search, "CrystalGradient", Color3.fromRGB(28, 27, 31), obsidian, obsidian)
    outline(search, "CrystalRim", warm, 1, 0.58)
    local filter = button(window, "Filter", "All units  ▾", box(0.64, 0.032, 0.15, 0.095), 14, Theme.slate)
    local sort = button(window, "Sort", "Name  ↕", box(0.80, 0.032, 0.11, 0.095), 14, Theme.slate)
    local close = button(window, "Close", "×", box(0.93, 0.025, 0.055, 0.11), 28, warm)
    Theme.crystal(close, UDim2.fromScale(0.5, 0.11), 9, Theme.gold)
    local grid = make("ScrollingFrame", window, "OwnedUnits", box(0.02, 0.16, 0.56, 0.69))
    Theme.surface(grid, Theme.slate, false)
    gradient(grid, "CrystalGradient", Color3.fromRGB(21, 23, 31), obsidian, obsidian, 125)
    grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
    grid.CanvasSize = UDim2.new()
    grid.ScrollingDirection = Enum.ScrollingDirection.Y
    grid.ScrollBarThickness = 5
    local layout = Instance.new("UIGridLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.CellPadding = UDim2.fromOffset(9, 10)
    layout.Parent = grid
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft, padding.PaddingTop = UDim.new(0, 9), UDim.new(0, 9)
    padding.Parent = grid
    local function fit()
        local width = grid.AbsoluteSize.X
        local columns = if width >= 620 then 5 elseif width >= 360 then 4 elseif width >= 240 then 3 else 2
        local tile = math.clamp(math.floor((width - 24 - (columns - 1) * 9) / columns), 36, 148)
        layout.CellSize = UDim2.fromOffset(tile, math.floor(tile * 1.07))
    end
    grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    fit()
    local details = make("Frame", window, "UnitDetails", box(0.60, 0.16, 0.38, 0.69))
    Theme.surface(details, Theme.slate, false)
    gradient(details, "CrystalGradient", Color3.fromRGB(21, 23, 31), obsidian, obsidian)
    local nameLabel = text(details, "UnitName", "Select a unit", box(0.045, 0.022, 0.91, 0.11), 31)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    captionStroke(nameLabel, 1.9)
    local meta = text(details, "UnitMetadata", "", box(0.045, 0.131, 0.91, 0.058), 13, Theme.ice)
    meta.TextXAlignment = Enum.TextXAlignment.Left
    local preview = make("Frame", details, "PortraitStage", box(0.025, 0.20, 0.95, 0.62))
    Theme.surface(preview, Theme.blue, false)
    preview.Active = true
    local facets = {
        Theme.crystal(preview, UDim2.fromScale(0.12, 0.71), 15, Theme.ice),
        Theme.crystal(preview, UDim2.fromScale(0.88, 0.28), 21, Theme.ice),
    }
    local tags = {}
    for index, value in ipairs({"GROUND", "", "AoE SKILL"}) do
        local label = text(preview, "Tag" .. index, value, box(0.025 + (index - 1) * 0.24, 0.025, 0.22, 0.09), 12)
        label.ZIndex = preview.ZIndex + 4
        captionStroke(label, 1.5)
        tags[index] = label
    end
    local statRow = make("Frame", details, "StatCards", box(0.025, 0.69, 0.95, 0.145))
    statRow.BackgroundTransparency, statRow.ZIndex = 1, preview.ZIndex + 5
    local metrics = {}
    for index, entry in ipairs({{"⚔", "DAMAGE", fire}, {"◷", "SPA", Theme.ice}, {"◎", "RANGE", Theme.gold}}) do
        local tile = make("Frame", statRow, entry[2], box((index - 1) / 3, 0, 0.316, 1))
        tile.ZIndex = statRow.ZIndex
        Theme.surface(tile, entry[3], false)
        gradient(tile, "CrystalGradient", entry[3]:Lerp(obsidian, 0.72), obsidian, obsidian)
        local heading = text(tile, "StatName", entry[1] .. " " .. entry[2], box(0.04, 0.05, 0.92, 0.32), 12, entry[3])
        heading.ZIndex = tile.ZIndex + 1
        local headingSize = Instance.new("UITextSizeConstraint")
        headingSize.MinTextSize, headingSize.MaxTextSize, headingSize.Parent = 8, 12, heading
        heading.TextScaled = true
        local value = text(tile, "Value", "—", box(0.05, 0.35, 0.90, 0.60), 22)
        value.ZIndex = tile.ZIndex + 1
        metrics[index] = value
    end
    local cost = text(details, "PlacementCost", "", box(0.045, 0.850, 0.46, 0.053), 13, Theme.gold)
    local limit = text(details, "PlacementLimit", "", box(0.53, 0.850, 0.42, 0.053), 13, Theme.ice)
    local skill = text(details, "Skill", "", box(0.045, 0.917, 0.91, 0.065), 15)
    skill.TextXAlignment = Enum.TextXAlignment.Left
    local equip = button(window, "EquipAction", "Equip", box(0.60, 0.875, 0.38, 0.095), 22, Theme.green)
    local clear = button(window, "UnequipAll", "Unequip All", box(0.35, 0.875, 0.23, 0.095), 17, fire)
    local loadoutLabel = text(window, "LoadoutStatus", "", box(0.02, 0.875, 0.31, 0.095), 16, Theme.gold)
    local empty = text(window, "NoMatches", "No units match this filter.", box(0.04, 0.40, 0.52, 0.10), 17)
    for _, label in ipairs({title, nameLabel, cost, limit, skill, meta, loadoutLabel,
        tags[1], tags[2], tags[3], metrics[1], metrics[2], metrics[3]}) do
        local constraint = Instance.new("UITextSizeConstraint")
        constraint.MaxTextSize = label.TextSize
        constraint.MinTextSize = 9
        constraint.Parent = label
        label.TextScaled = true
    end

    local selected, currentPortrait
    local cards = {}
    local lobby, filterIndex, sortIndex = true, 1, 1
    local filters = {"All units", "Equipped", "Not equipped", "Ice", "Fire"}
    local sorts = {"Name", "Price", "Level"}
    local worn = player:GetAttribute("DeckLoadout")
    local owned = {}
    local nextRequest = 0
    local savedOrder
    local opened = false
    local fadeTween, sizeTween

    local function renderDetails()
        local unit = selected and Loadout.units[selected]
        if not unit or not owned[selected] then
            nameLabel.Text, meta.Text = "Select a unit", ""
            cost.Text, limit.Text, skill.Text = "", "", ""
            statRow.Visible = false
            equip.Visible = false
            for _, tag in ipairs(tags) do tag.Visible = false end
            for _, facet in ipairs(facets) do facet.Visible = false end
            if currentPortrait then currentPortrait:Destroy(); currentPortrait = nil end
            return
        end
        local equipped = Loadout.contains(worn, selected)
        equip.Visible = true
        equip.Text = if equipped then "UNEQUIP" else "EQUIP"
        enamel(equip, if equipped then fire else Theme.green)
        nameLabel.Text = unit.name
        meta.Text = string.format("LV. %d   /   %s", owned[selected], if equipped then "EQUIPPED" else "NOT EQUIPPED")
        tags[2].Text = string.upper(unit.element)
        tags[2].TextColor3 = colorFor(unit)
        for _, tag in ipairs(tags) do tag.Visible = true end
        local cap = Placement.heroLimit(selected)
        statRow.Visible = true
        metrics[1].Text, metrics[2].Text, metrics[3].Text = tostring(unit.damage), string.format("%.1fs", unit.attackRate), tostring(unit.range)
        cost.Text = string.format("PLACEMENT    %d ¥", unit.price)
        limit.Text = "LIMIT    " .. tostring(cap)
        skill.Text = "✦   " .. unit.skillName
        if currentPortrait and currentPortrait:GetAttribute("UnitId") == selected then return end
        if currentPortrait then currentPortrait:Destroy() end
        Theme.surface(preview, colorFor(unit), false)
        gradient(preview, "CrystalGradient", colorFor(unit):Lerp(obsidian, 0.62), obsidian, colorFor(unit):Lerp(obsidian, 0.87), 120)
        for _, facet in ipairs(facets) do
            facet.Visible = true
            Theme.surface(facet, colorFor(unit), true)
        end
        Theme.heroPortrait(preview, templates:FindFirstChild(selected))
        currentPortrait = preview:FindFirstChild("HeroPortrait")
        if currentPortrait then
            local model = currentPortrait:FindFirstChildOfClass("Model")
            if model then
                local world = Instance.new("WorldModel")
                world.Parent = currentPortrait
                model.Parent = world
                local bounds, height = model:GetBoundingBox()
                local head = model:FindFirstChild("Head")
                local focal = if head and head:IsA("BasePart") then head.Position - Vector3.new(0, height.Y * 0.18, 0)
                    else bounds.Position + Vector3.new(0, height.Y * 0.15, 0)
                local camera = currentPortrait.CurrentCamera
                if camera then
                    local front = if head and head:IsA("BasePart") then head.CFrame.LookVector else bounds.LookVector
                    camera.FieldOfView = 40
                    camera.Focus = CFrame.new(focal)
                    camera.CFrame = CFrame.lookAt(focal + front * math.max(4, height.Y * 1.05)
                        + bounds.RightVector * height.Y * 0.12 + Vector3.new(0, height.Y * 0.07, 0), focal)
                end
            end
            currentPortrait.Ambient = Color3.fromRGB(158, 166, 187)
            currentPortrait.LightColor = colorFor(unit):Lerp(white, 0.7)
            currentPortrait.LightDirection = Vector3.new(-1, -0.8, -0.45)
            currentPortrait:SetAttribute("UnitId", selected)
            currentPortrait.ImageTransparency = 1
            TweenService:Create(currentPortrait, TweenInfo.new(0.18), {ImageTransparency = 0}):Play()
        end
    end

    local function refresh()
        if not opened then return end
        worn = player:GetAttribute("DeckLoadout")
        local data = player:GetAttribute("DeckOwnedUnits")
        owned = if typeof(data) == "string" then HttpService:JSONDecode(data) else {}
        local query = string.lower(search.Text)
        local visible, equippedCount = 0, 0
        local firstVisible
        local ids = {}
        for id in pairs(owned) do if Loadout.units[id] then table.insert(ids, id) end end
        table.sort(ids, function(a, b)
            if sortIndex == 2 and Loadout.units[a].price ~= Loadout.units[b].price then
                return Loadout.units[a].price < Loadout.units[b].price
            elseif sortIndex == 3 and owned[a] ~= owned[b] then
                return owned[a] > owned[b]
            end
            return Loadout.units[a].name < Loadout.units[b].name
        end)
        for order, id in ipairs(ids) do
            local unit = Loadout.units[id]
            local tint = colorFor(unit)
            local equipped = Loadout.contains(worn, id)
            if equipped then equippedCount += 1 end
            local item = cards[id]
            if not item then
                local card = button(grid, id, "", box(0, 0, 1, 1), 16, tint)
                card.LayoutOrder = order
                card.ClipsDescendants = true
                gradient(card, "CrystalGradient", tint:Lerp(obsidian, 0.65), obsidian, tint:Lerp(obsidian, 0.85), 120)
                local holder = make("Frame", card, "Model", box(0.025, 0.02, 0.95, 0.96))
                holder.BackgroundTransparency = 1
                Theme.heroPortrait(holder, templates:FindFirstChild(id))
                local shade = make("Frame", card, "CaptionShade", box(0, 0.52, 1, 0.48))
                shade.ZIndex = card.ZIndex + 2
                local dark = gradient(shade, "Shade", obsidian, obsidian, obsidian)
                dark.Transparency = NumberSequence.new(1, 0.08)
                local track = make("Frame", card, "InsetEdge", box(0.035, 0.035, 0.93, 0.93))
                track.BackgroundTransparency = 1
                track.ZIndex = card.ZIndex + 3
                outline(track, "ElementLine", tint, 1, 0.42)
                local lv = text(card, "Level", "", box(0.06, 0.035, 0.57, 0.16), 14)
                lv.TextXAlignment = Enum.TextXAlignment.Left
                local mark = text(card, "Equipped", "✓", box(0.064, 0.18, 0.26, 0.23), 24, Theme.green)
                local icon = text(card, "Element", if unit.element == "Ice" then "❄" else "♨", box(0.71, 0.035, 0.23, 0.22), 22, tint)
                local price = text(card, "Price", tostring(unit.price) .. " ¥", box(0.30, 0.67, 0.63, 0.13), 15, Theme.gold)
                price.TextXAlignment = Enum.TextXAlignment.Right
                local label = text(card, "UnitName", unit.name, box(0.06, 0.81, 0.89, 0.15), 16)
                label.TextXAlignment = Enum.TextXAlignment.Left
                for _, caption in ipairs({lv, mark, icon, price, label}) do
                    caption.ZIndex = card.ZIndex + 4
                    captionStroke(caption, 1.7)
                end
                label.TextScaled = true
                local size = Instance.new("UITextSizeConstraint")
                size.MaxTextSize, size.MinTextSize, size.Parent = 15, 9, label
                card.Activated:Connect(function() selected = id; refresh() end)
                item = {button = card, level = lv, mark = mark}
                cards[id] = item
            end
            local shows = string.find(string.lower(id .. " " .. unit.name), query, 1, true) ~= nil
                and (filterIndex == 1 or (filterIndex == 2 and equipped) or (filterIndex == 3 and not equipped)
                    or filters[filterIndex] == unit.element)
            item.button.Visible = shows
            item.button.LayoutOrder = order
            item.level.Text = "Lv. " .. tostring(owned[id])
            if equipped and item.equipped == false then
                item.mark.TextTransparency = 1
                TweenService:Create(item.mark, TweenInfo.new(0.16), {TextTransparency = 0}):Play()
            end
            item.equipped = equipped
            item.mark.Visible = equipped
            if shows then visible += 1; firstVisible = firstVisible or id end
        end
        for id, item in pairs(cards) do
            if not owned[id] then item.button:Destroy(); cards[id] = nil end
        end
        if not selected or not cards[selected] or not cards[selected].button.Visible then selected = firstVisible end
        for id, item in pairs(cards) do
            item.button.CrystalRim.Color = if id == selected then white else colorFor(Loadout.units[id])
            item.button.CrystalRim.Thickness = if id == selected then 2.4 else 1.3
            outline(item.button, "BevelShadow", colorFor(Loadout.units[id]), 4, if id == selected then 0.42 else 0.81)
        end
        empty.Visible = visible == 0
        loadoutLabel.Text = string.format("LOADOUT  %d / %d   •   %d SLOTS LOCKED",
            equippedCount, Loadout.unlockedSlots, Loadout.slotCount - Loadout.unlockedSlots)
        clear.Visible = equippedCount > 0
        renderDetails()
    end

    local function toggle(open)
        open = open and lobby
        if opened == open then return end
        opened = open
        if fadeTween then fadeTween:Cancel() end
        if sizeTween then sizeTween:Cancel() end
        local duration = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
        if open then
            if not overlay.Visible then savedOrder = gui.DisplayOrder end
            gui.DisplayOrder = 45
            if not overlay.Visible then overlay.GroupTransparency, scale.Scale = 1, 0.96 end
            overlay.Visible = true
            refresh()
            fadeTween = TweenService:Create(overlay, duration, {GroupTransparency = 0})
            sizeTween = TweenService:Create(scale, duration, {Scale = 1})
        else
            search:ReleaseFocus()
            local closing = TweenService:Create(overlay, duration, {GroupTransparency = 1})
            fadeTween = closing
            sizeTween = TweenService:Create(scale, duration, {Scale = 0.96})
            closing.Completed:Once(function(state)
                if state ~= Enum.PlaybackState.Completed or opened or fadeTween ~= closing then return end
                overlay.Visible = false
                gui.DisplayOrder = savedOrder
                if currentPortrait then currentPortrait:Destroy(); currentPortrait = nil end
                for id, item in pairs(cards) do item.button:Destroy(); cards[id] = nil end
            end)
        end
        fadeTween:Play()
        sizeTween:Play()
    end

    local function request(action, id)
        local now = os.clock()
        if not lobby or not opened or now < nextRequest then return end
        nextRequest = now + 0.26
        partyAction:FireServer(action, id)
    end
    equip.Activated:Connect(function()
        if selected then request(if Loadout.contains(worn, selected) then "Unequip" else "Equip", selected) end
    end)
    clear.Activated:Connect(function() request("UnequipAll") end)
    close.Activated:Connect(function() toggle(false) end)
    filter.Activated:Connect(function()
        filterIndex = filterIndex % #filters + 1
        filter.Text = filters[filterIndex] .. "  ▾"
        refresh()
    end)
    sort.Activated:Connect(function()
        sortIndex = sortIndex % #sorts + 1
        sort.Text = sorts[sortIndex] .. "  ↕"
        refresh()
    end)
    search:GetPropertyChangedSignal("Text"):Connect(refresh)
    player:GetAttributeChangedSignal("DeckLoadout"):Connect(refresh)
    player:GetAttributeChangedSignal("DeckOwnedUnits"):Connect(refresh)
    Input.InputBegan:Connect(function(input, consumed)
        if not consumed and input.KeyCode == Enum.KeyCode.H and not Input:GetFocusedTextBox() then toggle(not opened) end
    end)
    task.spawn(function()
        local hud = player:WaitForChild("PlayerGui"):WaitForChild("AnimeLobbyHUD", 15)
        local units = hud and hud:FindFirstChild("UnitsButton", true)
        if units and units:IsA("GuiButton") then units.Activated:Connect(function() toggle(not opened) end) end
        local play = hud and hud:FindFirstChild("PlayButton", true)
        if play and play:IsA("GuiButton") then play.Activated:Connect(function() toggle(false) end) end
    end)

    local drag, lastX
    preview.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag, lastX = input, input.Position.X
        end
    end)
    Input.InputEnded:Connect(function(input) if input == drag then drag = nil end end)
    Input.InputChanged:Connect(function(input)
        if not opened or not drag or not currentPortrait then return end
        if input ~= drag and not (drag.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement) then return end
        local camera = currentPortrait.CurrentCamera
        local world = currentPortrait:FindFirstChildOfClass("WorldModel")
        local model = world and world:FindFirstChildOfClass("Model")
        if not camera or not model then return end
        local center = camera.Focus.Position
        local delta = input.Position.X - lastX
        lastX = input.Position.X
        local offset = CFrame.Angles(0, -delta * 0.012, 0):VectorToWorldSpace(camera.CFrame.Position - center)
        camera.CFrame = CFrame.lookAt(center + offset, center)
    end)
    return {setLobby = function(value) lobby = value; if not lobby then toggle(false) end end}
end

return Collection
