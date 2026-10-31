-- TysUI Library (Purple Edition) -- extracted from Tys Client V8.2
return (function()
    local UIS = game:GetService("UserInputService")
    local TS  = game:GetService("TweenService")
    local CG  = game:GetService("CoreGui")
    local PL  = game:GetService("Players")

    local UI = {}
    local COL_BG_TOP   = Color3.fromRGB(38, 14, 62)
    local COL_BG_BOT   = Color3.fromRGB(20, 8, 34)
    local COL_ACCENT   = Color3.fromRGB(168, 96, 255)
    local COL_ACCENT_D = Color3.fromRGB(70, 22, 130)
    local COL_STROKE   = Color3.fromRGB(190, 130, 255)
    local COL_TEXT     = Color3.fromRGB(240, 228, 255)
    local COL_DIM      = Color3.fromRGB(205, 188, 232)
    local COL_OFF      = Color3.fromRGB(58, 34, 92)

    local function getGuiParent()
        local ok, ui = pcall(function() return gethui and gethui() end)
        if ok and ui then return ui end
        local ok2 = pcall(function() return CG.Name end)
        if ok2 then return CG end
        return PL.LocalPlayer:WaitForChild("PlayerGui")
    end
    local function new(c, p, par)
        local i = Instance.new(c)
        for k, v in pairs(p or {}) do i[k] = v end
        if par then i.Parent = par end
        return i
    end
    local function round(p, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, p) end
    local function outline(p, col, th, tr) return new("UIStroke", { Color = col, Thickness = th, Transparency = tr }, p) end
    local function tween(o, t, props, st, d)
        TS:Create(o, TweenInfo.new(t, st or Enum.EasingStyle.Quad, d or Enum.EasingDirection.Out), props):Play()
    end
    local function safe(cb, ...)
        if type(cb) ~= "function" then return end
        task.spawn(function(...)
            local ok, err = pcall(cb, ...)
            if not ok then warn("[TysUI] " .. tostring(err)) end
        end, ...)
    end
    local function spaced(s)
        local words = {}
        for w in tostring(s):gmatch("%S+") do
            local sp = w:upper():gsub(".", "%0 "); sp = sp:gsub(" $", "")
            words[#words + 1] = sp
        end
        return table.concat(words, "   ")
    end

    function UI:AddTheme() end

    local notifyGui, notifyHolder
    local function ensureNotify()
        if notifyGui and notifyGui.Parent then return end
        notifyGui = new("ScreenGui", {
            Name = "TysClientNotify", ResetOnSpawn = false, IgnoreGuiInset = true,
            DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        }, getGuiParent())
        notifyHolder = new("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
            Size = UDim2.new(0, 270, 1, -32), BackgroundTransparency = 1,
        }, notifyGui)
        new("UIListLayout", {
            Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
        }, notifyHolder)
    end

    function UI:Notify(cfg)
        cfg = cfg or {}
        ensureNotify()
        local toast = new("CanvasGroup", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = Color3.fromRGB(32, 12, 54), BackgroundTransparency = 0.12,
            BorderSizePixel = 0, GroupTransparency = 1,
        }, notifyHolder)
        round(toast, 10)
        outline(toast, COL_STROKE, 1, 0.65)
        new("UIPadding", {
            PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 10),
            PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
        }, toast)
        new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, toast)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
            Text = tostring(cfg.Title or ""), TextColor3 = COL_ACCENT, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1,
        }, toast)
        new("TextLabel", {
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1, Font = Enum.Font.Gotham,
            Text = tostring(cfg.Content or ""), TextColor3 = COL_TEXT, TextSize = 12,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2,
        }, toast)
        tween(toast, 0.25, { GroupTransparency = 0 })
        task.delay(cfg.Duration or 4, function()
            if not toast.Parent then return end
            local tw = TS:Create(toast, TweenInfo.new(0.3), { GroupTransparency = 1 })
            tw:Play(); tw.Completed:Wait(); toast:Destroy()
        end)
    end

        function UI:CreateWindow(cfg)
        cfg = cfg or {}
        local parent = getGuiParent()
        for _, root in ipairs({ parent, CG, PL.LocalPlayer:FindFirstChild("PlayerGui") }) do
            if root then
                for _, n in ipairs({ "TysClientUI", "TysClientToggle" }) do
                    local old = root:FindFirstChild(n)
                    if old then pcall(function() old:Destroy() end) end
                end
            end
        end

        local cam  = workspace.CurrentCamera
        local view = cam and cam.ViewportSize or Vector2.new(1280, 720)
        local reqW = cfg.Size and cfg.Size.X.Offset or 620
        local reqH = cfg.Size and cfg.Size.Y.Offset or 480
        local MIN_W, MIN_H = 380, 260
        local BTN_SIZE, BTN_OFFSET = 40, 30
        local frameSize = Vector2.new(
            math.max(MIN_W, math.min(reqW, view.X * 0.9)),
            math.max(MIN_H, math.min(reqH, view.Y * 0.85))
        )
        local center = Vector2.new(view.X / 2, view.Y / 2)

        local Window = {}
        local openCbs, closeCbs = {}, {}

        local gui = new("ScreenGui", {
            Name = "TysClientUI", ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
        }, parent)
        pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)

        local main = new("CanvasGroup", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(center.X, center.Y),
            Size = UDim2.fromOffset(0, 0), BackgroundColor3 = COL_BG_TOP,
            BackgroundTransparency = 0, BorderSizePixel = 0, GroupTransparency = 1,
            Visible = false, ZIndex = 2,
        }, gui)
        round(main, 14)
        local mainStroke = outline(main, COL_STROKE, 1, 0.62)

        local bg = new("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(24, 10, 42),
            BackgroundTransparency = 0.28, BorderSizePixel = 0, ZIndex = 1,
        }, main)
        round(bg, 14)

        local bgMotion = new("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            ClipsDescendants = true, ZIndex = 2,
        }, main)
        round(bgMotion, 14)

        local function makeBlob(size, pos, transparency)
            local b = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size),
                Position = pos, BackgroundColor3 = Color3.fromRGB(125, 60, 200),
                BackgroundTransparency = transparency, BorderSizePixel = 0, ZIndex = 2,
            }, bgMotion)
            round(b, size); return b
        end
        local blob1 = makeBlob(260, UDim2.new(0.12, 0, 0.18, 0), 0.91)
        local blob2 = makeBlob(330, UDim2.new(0.86, 0, 0.76, 0), 0.93)
        for _, item in ipairs({
            {blob1, UDim2.new(0.24, 0, 0.28, 0), 8.0},
            {blob2, UDim2.new(0.72, 0, 0.66, 0), 10.0},
        }) do
            TS:Create(item[1], TweenInfo.new(item[3], Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {Position = item[2]}):Play()
        end

        local header = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "",
            AutoButtonColor = false, ZIndex = 5,
        }, main)
        new("TextLabel", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 0),
            Size = UDim2.new(0.6, -18, 1, 0), Font = Enum.Font.GothamBold,
            Text = spaced(cfg.Title or "TYS UI"), TextColor3 = COL_TEXT, TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, header)
        new("TextLabel", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 0), Size = UDim2.new(0.4, -16, 1, 0),
            Font = Enum.Font.Gotham, Text = tostring(cfg.Author or ""), TextColor3 = COL_DIM,
            TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right,
            TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 6,
        }, header)
        new("Frame", {
            Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, 38),
            BackgroundColor3 = COL_ACCENT, BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 4,
        }, main)

        local sidebar = new("ScrollingFrame", {
            Position = UDim2.new(0, 10, 0, 46), Size = UDim2.new(0, 134, 1, -58),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
            ScrollBarImageColor3 = COL_ACCENT, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 5,
        }, main)
        new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
        new("UIPadding", { PaddingRight = UDim.new(0, 4) }, sidebar)

        local contentHolder = new("Frame", {
            Position = UDim2.new(0, 154, 0, 46), Size = UDim2.new(1, -164, 1, -58),
            BackgroundTransparency = 1, ZIndex = 5,
        }, main)

        local toggle = new("TextButton", {
            Name = "Toggle", AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE), BackgroundColor3 = COL_ACCENT_D,
            BackgroundTransparency = 0.05, Text = "", AutoButtonColor = false,
            BorderSizePixel = 0, ZIndex = 40,
        }, gui)
        round(toggle, 100)
        outline(toggle, COL_STROKE, 1, 0.65)
        local halo = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.new(1, 12, 1, 12), BackgroundTransparency = 1, ZIndex = 39,
        }, toggle)
        round(halo, 100)
        outline(halo, COL_ACCENT, 1, 0.92)
        local diamond = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(13, 13), BackgroundColor3 = Color3.fromRGB(248, 240, 255),
            BackgroundTransparency = 0.05, BorderSizePixel = 0, Rotation = 45, ZIndex = 41,
        }, toggle)
        round(diamond, 3)
        toggle.MouseEnter:Connect(function() tween(toggle, 0.2, { Size = UDim2.fromOffset(BTN_SIZE + 6, BTN_SIZE + 6) }) end)
        toggle.MouseLeave:Connect(function() tween(toggle, 0.2, { Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE) }) end)

        local function updateButtonPosition()
            local x = math.max(BTN_SIZE / 2 + 6, center.X - frameSize.X / 2 - BTN_OFFSET)
            toggle.Position = UDim2.fromOffset(x, center.Y)
        end
        updateButtonPosition()

        local isOpen, animating = false, false
        function Window:IsOpen() return isOpen end

        local function setOpen(open)
            if animating or isOpen == open then return end
            animating = true
            isOpen = open
            tween(diamond, 0.45, { Rotation = open and 135 or 45 }, Enum.EasingStyle.Quart)
            if open then
                main.Visible = true
                main.Size = UDim2.fromOffset(0, 0)
                main.GroupTransparency = 1
                mainStroke.Transparency = 1
                local sTw = TS:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                    { Size = UDim2.fromOffset(frameSize.X, frameSize.Y) })
                sTw:Play()
                TS:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { GroupTransparency = 0 }):Play()
                tween(mainStroke, 0.4, { Transparency = 0.25 })
                sTw.Completed:Connect(function()
                    main.GroupTransparency = 0; animating = false; updateButtonPosition()
                end)
                task.delay(1, function()
                    if main and main.Parent and isOpen then
                        main.GroupTransparency = 0; animating = false
                    end
                end)
                for _, cb in ipairs(openCbs) do safe(cb) end
            else
                local tw = TS:Create(main, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    { Size = UDim2.fromOffset(0, 0), GroupTransparency = 1 })
                tw:Play()
                tween(mainStroke, 0.3, { Transparency = 1 })
                tw.Completed:Connect(function() main.Visible = false; animating = false end)
                for _, cb in ipairs(closeCbs) do safe(cb) end
            end
        end

        function Window:Open() setOpen(true) end
        function Window:Close() setOpen(false) end
        function Window:Toggle() setOpen(not isOpen) end
        function Window:OnOpen(cb) table.insert(openCbs, cb) end
        function Window:OnClose(cb) table.insert(closeCbs, cb) end
        function Window:Destroy() gui:Destroy() end

        UIS.InputBegan:Connect(function(input, processed)
            if not processed and input.KeyCode == Enum.KeyCode.RightControl then
                setOpen(not isOpen)
            end
        end)

        do
            local dragging, startInput, startCenter
            header.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    startInput = Vector2.new(input.Position.X, input.Position.Y)
                    startCenter = center
                end
            end)
            UIS.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                center = startCenter + (Vector2.new(input.Position.X, input.Position.Y) - startInput)
                main.Position = UDim2.fromOffset(center.X, center.Y)
                updateButtonPosition()
            end)
            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
        end

        do
            local pressing, moved, startInput, startCenter = false, false, nil, nil
            toggle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    pressing, moved = true, false
                    startInput = Vector2.new(input.Position.X, input.Position.Y)
                    startCenter = center
                end
            end)
            UIS.InputChanged:Connect(function(input)
                if not pressing then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                local d = Vector2.new(input.Position.X, input.Position.Y) - startInput
                if d.Magnitude > 6 then moved = true end
                if moved then
                    center = startCenter + d
                    main.Position = UDim2.fromOffset(center.X, center.Y)
                    updateButtonPosition()
                end
            end)
            UIS.InputEnded:Connect(function(input)
                if pressing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                    pressing = false
                    if not moved then setOpen(not isOpen) end
                end
            end)
        end

        local function createHandle(mode)
            local handle = new("TextButton", {
                Size = UDim2.fromOffset(20, 20), BackgroundColor3 = COL_ACCENT,
                BackgroundTransparency = 0.45, Text = "", AutoButtonColor = false,
                BorderSizePixel = 0, ZIndex = 30,
            }, main)
            round(handle, 7)
            outline(handle, COL_STROKE, 1, 0.65)
            local dot = new("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.fromRGB(250, 245, 255),
                BorderSizePixel = 0, Rotation = 45, ZIndex = 31,
            }, handle)
            round(dot, 2)
            if mode == "TopRight" then
                handle.AnchorPoint = Vector2.new(1, 0)
                handle.Position = UDim2.new(1, -2, 0, 2)
            else
                handle.AnchorPoint = Vector2.new(0, 1)
                handle.Position = UDim2.new(0, 2, 1, -2)
            end
            return handle
        end

        local function setupResize(handle, mode)
            local dragging, startInput, sL, sT, sR, sB
            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    startInput = Vector2.new(input.Position.X, input.Position.Y)
                    sL, sT = center.X - frameSize.X / 2, center.Y - frameSize.Y / 2
                    sR, sB = center.X + frameSize.X / 2, center.Y + frameSize.Y / 2
                end
            end)
            UIS.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType ~= Enum.UserInputType.MouseMovement
                and input.UserInputType ~= Enum.UserInputType.Touch then return end
                local d = Vector2.new(input.Position.X, input.Position.Y) - startInput
                local L, T, R, B = sL, sT, sR, sB
                if mode == "TopRight" then
                    local nR, nT = R + d.X, T + d.Y
                    if nR - L < MIN_W then nR = L + MIN_W end
                    if B - nT < MIN_H then nT = B - MIN_H end
                    R, T = nR, nT
                else
                    local nL, nB = L + d.X, B + d.Y
                    if R - nL < MIN_W then nL = R - MIN_W end
                    if nB - T < MIN_H then nB = T + MIN_H end
                    L, B = nL, nB
                end
                local w, h = R - L, B - T
                frameSize = Vector2.new(w, h)
                center = Vector2.new(L + w / 2, T + h / 2)
                main.Size = UDim2.fromOffset(w, h)
                main.Position = UDim2.fromOffset(center.X, center.Y)
                updateButtonPosition()
            end)
            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
        end
        setupResize(createHandle("TopRight"), "TopRight")
        setupResize(createHandle("BottomLeft"), "BottomLeft")

        local tabs, tabCount = {}, 0
        local function selectTab(t)
            for _, data in pairs(tabs) do
                local on = (data == t)
                data.page.Visible = on
                data.indicator.Visible = on
                tween(data.button, 0.18, {
                    BackgroundColor3 = on and COL_ACCENT_D or COL_BG_BOT,
                    TextColor3 = on and COL_TEXT or COL_DIM,
                })
                tween(data.btnStroke, 0.18, { Transparency = on and 0.15 or 0.7 })
            end
        end

                function Window:Tab(tcfg)
            tcfg = tcfg or {}
            tabCount = tabCount + 1
            local btn = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = COL_BG_BOT,
                BackgroundTransparency = 0.4, Text = "  " .. tostring(tcfg.Title or "Tab"),
                Font = Enum.Font.GothamMedium, TextColor3 = COL_DIM, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false, BorderSizePixel = 0, LayoutOrder = tabCount, ZIndex = 6,
            }, sidebar)
            round(btn, 8)
            local btnStroke = outline(btn, COL_STROKE, 1, 0.85)
            local indicator = new("Frame", {
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
                Size = UDim2.new(0, 3, 0.5, 0), BackgroundColor3 = COL_ACCENT,
                BorderSizePixel = 0, ZIndex = 7, Visible = false,
            }, btn)
            round(indicator, 100)

            local page = new("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
                ScrollBarThickness = 4, ScrollBarImageColor3 = COL_ACCENT,
                CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Visible = false, ZIndex = 6,
            }, contentHolder)
            new("UIPadding", {
                PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 26),
                PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 8),
            }, page)
            new("UIListLayout", {
                Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Center,
            }, page)

            local data = { button = btn, page = page, indicator = indicator, btnStroke = btnStroke }
            tabs[tabCount] = data
            btn.MouseButton1Click:Connect(function() selectTab(data) end)
            if tabCount == 1 then selectTab(data) end

            local Tab = {}
            Tab.Page = page
            Tab.Colors = {
                Accent = COL_ACCENT, AccentDark = COL_ACCENT_D, Stroke = COL_STROKE,
                Text = COL_TEXT, Dim = COL_DIM, BgTop = COL_BG_TOP, BgBot = COL_BG_BOT, Off = COL_OFF,
            }
            local order = 0
            local function nextOrder() order = order + 1; return order end

            local function makeRow(class, c, rightPad)
                local row = new(class, {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = Color3.fromRGB(34, 14, 58), BackgroundTransparency = 0.18,
                    BorderSizePixel = 0, LayoutOrder = nextOrder(), ZIndex = 7,
                }, page)
                if class == "TextButton" then row.Text = ""; row.AutoButtonColor = false end
                round(row, 8)
                outline(row, COL_STROKE, 1, 0.82)
                new("UIPadding", {
                    PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
                    PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
                }, row)
                new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)
                local head = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1, LayoutOrder = 1,
                }, row)
                local textBox = new("Frame", {
                    Size = UDim2.new(1, -(rightPad or 0), 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1,
                }, head)
                new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, textBox)
                local titleLbl = new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
                    Text = tostring(c.Title or ""), TextColor3 = COL_TEXT, TextSize = 13,
                    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 1,
                }, textBox)
                local desc = c.Desc or c.Description
                local descLbl = new("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundTransparency = 1, Font = Enum.Font.Gotham,
                    Text = tostring(desc or ""), TextColor3 = COL_DIM, TextSize = 11,
                    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top, LayoutOrder = 2,
                    Visible = (desc ~= nil and tostring(desc) ~= ""),
                }, textBox)
                return row, head, titleLbl, descLbl
            end

            local function textApi(obj, titleLbl, descLbl)
                function obj:SetTitle(t) titleLbl.Text = tostring(t) end
                function obj:SetDesc(t)
                    descLbl.Text = tostring(t)
                    descLbl.Visible = tostring(t) ~= ""
                end
                obj.SetDescription = obj.SetDesc
                function obj:Destroy() titleLbl.Parent.Parent.Parent:Destroy() end
            end

            function Tab:Section(c)
                c = c or {}
                local f = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = nextOrder(),
                }, page)
                local bar = new("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 2),
                    Size = UDim2.fromOffset(3, 14), BackgroundColor3 = COL_ACCENT, BorderSizePixel = 0,
                }, f)
                round(bar, 100)
                new("TextLabel", {
                    Position = UDim2.fromOffset(12, 2), Size = UDim2.new(1, -12, 1, 0),
                    BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
                    Text = tostring(c.Title or ""), TextColor3 = COL_ACCENT, TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                }, f)
                return {}
            end

            function Tab:Paragraph(c)
                c = c or {}
                local _, _, t, d = makeRow("Frame", c, 0)
                local obj = {}
                textApi(obj, t, d)
                return obj
            end

            function Tab:Button(c)
                c = c or {}
                local row, head, t, d = makeRow("TextButton", c, 24)
                new("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold, Text = ">", TextColor3 = COL_ACCENT, TextSize = 16,
                }, head)
                -- Keep the row's original appearance after a one-shot click.
                -- The old code restored COL_BG_BOT, which made action rows look
                -- almost black instead of returning to their normal purple.
                local normalButtonColor = row.BackgroundColor3
                local normalButtonTransparency = row.BackgroundTransparency
                row.MouseEnter:Connect(function()
                    tween(row, 0.15, { BackgroundTransparency = 0 })
                end)
                row.MouseLeave:Connect(function()
                    tween(row, 0.15, { BackgroundTransparency = normalButtonTransparency })
                end)
                row.MouseButton1Click:Connect(function()
                    row.BackgroundColor3 = COL_ACCENT_D
                    tween(row, 0.22, {
                        BackgroundColor3 = normalButtonColor,
                        BackgroundTransparency = normalButtonTransparency,
                    })

                    safe(c.Callback)
                end)
                local obj = {}
                textApi(obj, t, d)
                return obj
            end

            function Tab:Toggle(c)
                c = c or {}
                local row, head, t, d = makeRow("TextButton", c, 52)
                local sw = new("Frame", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(38, 20), BackgroundColor3 = COL_OFF, BorderSizePixel = 0,
                }, head)
                round(sw, 100)
                outline(sw, COL_STROKE, 1, 0.82)
                local knob = new("Frame", {
                    Position = UDim2.fromOffset(2, 2), Size = UDim2.fromOffset(16, 16),
                    BackgroundColor3 = Color3.fromRGB(235, 225, 250), BorderSizePixel = 0,
                }, sw)
                round(knob, 100)
                local obj = { Value = false }
                local function render(v)
                    tween(sw, 0.18, { BackgroundColor3 = v and COL_ACCENT or COL_OFF })
                    tween(knob, 0.18, { Position = v and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2) })
                end
                function obj:Set(v, silent)
                    v = v and true or false
                    self.Value = v; render(v)
                    if not silent then safe(c.Callback, v) end
                end
                function obj:GetValue() return self.Value end
                obj.GetState = obj.GetValue
                textApi(obj, t, d)
                if c.Default or c.Value then obj:Set(true, true) end
                row.MouseEnter:Connect(function() tween(row, 0.15, { BackgroundTransparency = 0 }) end)
                row.MouseLeave:Connect(function() tween(row, 0.15, { BackgroundTransparency = 0.15 }) end)
                row.MouseButton1Click:Connect(function() obj:Set(not obj.Value) end)
                return obj
            end

            function Tab:Slider(c)
                c = c or {}
                local vt = type(c.Value) == "table" and c.Value or {}
                local min  = c.Min or vt.Min or 0
                local max  = c.Max or vt.Max or 100
                local def  = c.Default or vt.Default or (type(c.Value) == "number" and c.Value) or min
                local step = c.Step or 1
                local dec = 0
                local dstr = string.format("%g", step):match("%.(%d+)")
                if dstr then dec = #dstr end
                local function snap(v)
                    v = min + math.floor((v - min) / step + 0.5) * step
                    v = math.clamp(v, min, max)
                    return tonumber(string.format("%." .. dec .. "f", v))
                end
                local row, head, t, d = makeRow("Frame", c, 60)
                local valLbl = new("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
                    Size = UDim2.fromOffset(56, 16), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold, Text = "", TextColor3 = COL_ACCENT, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                }, head)
                local holder = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = 2,
                }, row)
                local bar = new("Frame", {
                    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = COL_OFF, BorderSizePixel = 0,
                }, holder)
                round(bar, 100)
                local fill = new("Frame", {
                    Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = COL_ACCENT, BorderSizePixel = 0,
                }, bar)
                round(fill, 100)
                local knob = new("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.fromRGB(248, 240, 255),
                    BorderSizePixel = 0,
                }, fill)
                round(knob, 100)
                local hit = new("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
                    AutoButtonColor = false,
                }, holder)
                local obj = { Value = snap(def) }
                local function render()
                    local a = (max == min) and 0 or (obj.Value - min) / (max - min)
                    fill.Size = UDim2.new(a, 0, 1, 0)
                    valLbl.Text = tostring(obj.Value)
                end
                function obj:Set(v, silent)
                    v = snap(tonumber(v) or min)
                    local changed = v ~= self.Value
                    self.Value = v; render()
                    if changed and not silent then safe(c.Callback, v) end
                end
                textApi(obj, t, d); render()
                local dragging = false
                local function fromInput(input)
                    local w = bar.AbsoluteSize.X
                    if w <= 0 then return end
                    local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / w, 0, 1)
                    obj:Set(min + rel * (max - min))
                end
                hit.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; page.ScrollingEnabled = false; fromInput(input)
                    end
                end)
                UIS.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        fromInput(input)
                    end
                end)
                UIS.InputEnded:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                        dragging = false; page.ScrollingEnabled = true
                    end
                end)
                return obj
            end

            function Tab:Input(c)
                c = c or {}
                local row, head, t, d = makeRow("Frame", c, 142)
                local box = new("TextBox", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(134, 26), BackgroundColor3 = COL_BG_TOP,
                    BackgroundTransparency = 0.2, BorderSizePixel = 0, Font = Enum.Font.Gotham,
                    Text = tostring(c.Value or c.Default or ""), PlaceholderText = tostring(c.Placeholder or ""),
                    PlaceholderColor3 = COL_DIM, TextColor3 = COL_TEXT, TextSize = 12,
                    ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd,
                }, head)
                round(box, 6)
                local bs = outline(box, COL_STROKE, 1, 0.65)
                box.Focused:Connect(function() tween(bs, 0.15, { Transparency = 0.1 }) end)
                box.FocusLost:Connect(function()
                    tween(bs, 0.15, { Transparency = 0.65 })
                    safe(c.Callback, box.Text)
                end)
                local obj = {}
                function obj:Set(v) box.Text = tostring(v) end
                function obj:GetValue() return box.Text end
                textApi(obj, t, d)
                return obj
            end

            function Tab:Dropdown(c)
                c = c or {}
                local row, head, t, d = makeRow("TextButton", c, 140)
                local arrow = new("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 16), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamBold, Text = "v", TextColor3 = COL_ACCENT, TextSize = 12,
                }, head)
                local valLbl = new("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0),
                    Size = UDim2.fromOffset(110, 16), BackgroundTransparency = 1,
                    Font = Enum.Font.GothamMedium, Text = "", TextColor3 = COL_ACCENT, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd,
                }, head)
                local list = new("ScrollingFrame", {
                    Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = COL_BG_TOP,
                    BackgroundTransparency = 0.3, BorderSizePixel = 0, ScrollBarThickness = 3,
                    ScrollBarImageColor3 = COL_ACCENT, CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, LayoutOrder = 2,
                }, row)
                round(list, 6)
                new("UIPadding", {
                    PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
                    PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
                }, list)
                new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

                local obj = { Value = nil, Values = {} }
                local opened = false
                local function label(v)
                    if type(v) == "table" then return tostring(v.Title or v.Name or v[1] or "") end
                    return tostring(v)
                end
                local function setOpened(o)
                    opened = o
                    arrow.Text = o and "^" or "v"
                    if o then
                        local n = #obj.Values
                        list.Size = UDim2.new(1, 0, 0, math.min(n * 30 + 8, 168))
                    end
                    list.Visible = o
                end
                local function choose(v, silent)
                    obj.Value = v; valLbl.Text = label(v)
                    if not silent then safe(c.Callback, v) end
                end
                local function build(values)
                    for _, ch in ipairs(list:GetChildren()) do
                        if ch:IsA("TextButton") then ch:Destroy() end
                    end
                    obj.Values = values or {}
                    for i, v in ipairs(obj.Values) do
                        local item = new("TextButton", {
                            Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = COL_BG_BOT,
                            BackgroundTransparency = 0.4, BorderSizePixel = 0, AutoButtonColor = false,
                            Font = Enum.Font.Gotham, Text = "  " .. label(v), TextColor3 = COL_TEXT,
                            TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = i,
                        }, list)
                        round(item, 6)
                        item.MouseEnter:Connect(function() tween(item, 0.1, { BackgroundColor3 = COL_ACCENT_D }) end)
                        item.MouseLeave:Connect(function() tween(item, 0.1, { BackgroundColor3 = COL_BG_BOT }) end)
                        item.MouseButton1Click:Connect(function() choose(v); setOpened(false) end)
                    end
                    if opened then setOpened(true) end
                end
                function obj:Refresh(values) build(values) end
                function obj:Select(v) choose(v) end
                obj.Set = obj.Select
                function obj:GetValue() return self.Value end
                textApi(obj, t, d)
                build(c.Values)
                if c.Value ~= nil and c.Value ~= "" then choose(c.Value, true) end
                row.MouseButton1Click:Connect(function() setOpened(not opened) end)
                return obj
            end

            return Tab
        end

        function Window:Dialog(dcfg)
            dcfg = dcfg or {}
            local overlay = new("TextButton", {
                Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
                BackgroundTransparency = 0.85, Text = "", AutoButtonColor = false, ZIndex = 100,
            }, gui)
            local box = new("CanvasGroup", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(0, 300, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromRGB(32, 12, 54), BorderSizePixel = 0, ZIndex = 101, GroupTransparency = 1,
            }, overlay)
            round(box, 12)
            outline(box, COL_STROKE, 1.5, 0.25)
            new("UIPadding", {
                PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 14),
                PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16),
            }, box)
            new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, box)
            new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
                Text = tostring(dcfg.Title or ""), TextColor3 = COL_ACCENT, TextSize = 15,
                TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1,
            }, box)
            new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1, Font = Enum.Font.Gotham,
                Text = tostring(dcfg.Content or ""), TextColor3 = COL_TEXT, TextSize = 13,
                TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2,
            }, box)
            local btnRow = new("Frame", {
                Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = 3,
            }, box)
            new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, btnRow)
            tween(box, 0.25, { GroupTransparency = 0 })
            local function close()
                tween(overlay, 0.2, { BackgroundTransparency = 1 })
                local tw = TS:Create(box, TweenInfo.new(0.2), { GroupTransparency = 1 })
                tw:Play(); tw.Completed:Connect(function() overlay:Destroy() end)
            end
            local buttons = dcfg.Buttons or { { Title = "OK", Variant = "Primary" } }
            local n = #buttons
            for i, b in ipairs(buttons) do
                local primary = (b.Variant == "Primary")
                local bt = new("TextButton", {
                    Size = UDim2.new(1 / n, -(8 * (n - 1)) / n, 1, 0),
                    BackgroundColor3 = primary and COL_ACCENT_D or COL_BG_BOT,
                    BackgroundTransparency = primary and 0.05 or 0.3, BorderSizePixel = 0,
                    AutoButtonColor = false, Font = Enum.Font.GothamMedium, Text = tostring(b.Title or "OK"),
                    TextColor3 = COL_TEXT, TextSize = 13, LayoutOrder = i,
                }, btnRow)
                round(bt, 8)
                outline(bt, COL_STROKE, 1, primary and 0.2 or 0.7)
                bt.MouseButton1Click:Connect(function() close(); safe(b.Callback) end)
            end
        end

        setOpen(true)
        return Window
    end
    return UI
end)()
