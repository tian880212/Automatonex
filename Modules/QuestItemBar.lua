assert(Automaton, "Automaton not found!")

------------------------------
--      Localization      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_QuestItemBar")

L:RegisterTranslations("enUS", function() return {
    ["QuestItemBar"] = "Quest Item Bar",
    ["Shows usable quest items in a quick bar; click to use them."] = "Shows usable quest items in a quick bar; click to use them.",
    ["Button Size"] = "Button Size",
    ["Size of the quest item buttons"] = "Size of the quest item buttons",
    ["Buttons Per Row"] = "Buttons Per Row",
    ["Maximum number of buttons in each row; extra items wrap to new rows"] = "Maximum number of buttons in each row; extra items wrap to new rows",
    ["Lock Position"] = "Lock Position",
    ["Prevent the bar from being dragged"] = "Prevent the bar from being dragged",
    ["Reset Position"] = "Reset Position",
    ["Reset the bar to its default position"] = "Reset the bar to its default position",
    ["Position reset to default."] = "Position reset to default.",
    ["Drag the bar to move it; click an item to use it."] = "Drag the bar to move it; click an item to use it.",
    ["Show Quest Items"] = "Show Quest Items",
    ["Show automatically detected usable quest items in the bar"] = "Show automatically detected usable quest items in the bar",
    ["Show Monitored Items"] = "Show Monitored Items",
    ["Show items from the monitored list in the bar"] = "Show items from the monitored list in the bar",
    ["Item Monitoring"] = "Item Monitoring",
    ["Add Monitored Item"] = "Add Monitored Item",
    ["Add an item ID or paste an item link, then press Enter to monitor it"] = "Add an item ID or paste an item link, then press Enter to monitor it",
    ["Remove Monitored Item"] = "Remove Monitored Item",
    ["Type an item ID and press Enter to stop monitoring it"] = "Type an item ID and press Enter to stop monitoring it",
    ["List Monitored Items"] = "List Monitored Items",
    ["Clear Monitored Items"] = "Clear Monitored Items",
    ["Monitored items cleared."] = "Monitored items cleared.",
} end)

L:RegisterTranslations("zhCN", function() return {
    ["QuestItemBar"] = "任务物品快捷栏",
    ["Shows usable quest items in a quick bar; click to use them."] = "在快捷栏中显示可用的任务物品，点击即可使用。",
    ["Button Size"] = "按钮大小",
    ["Size of the quest item buttons"] = "任务物品按钮的尺寸",
    ["Buttons Per Row"] = "每排按钮数",
    ["Maximum number of buttons in each row; extra items wrap to new rows"] = "每排最多显示的按钮数量，超出的自动换到下一排",
    ["Lock Position"] = "锁定位置",
    ["Prevent the bar from being dragged"] = "禁止拖动快捷栏",
    ["Reset Position"] = "重置位置",
    ["Reset the bar to its default position"] = "将快捷栏恢复到默认位置",
    ["Position reset to default."] = "位置已重置到默认。",
    ["Drag the bar to move it; click an item to use it."] = "拖动栏可移动位置；点击物品即可使用。",
    ["Show Quest Items"] = "显示任务物品",
    ["Show automatically detected usable quest items in the bar"] = "在快捷栏中显示自动检测到的可用任务物品",
    ["Show Monitored Items"] = "显示监控物品",
    ["Show items from the monitored list in the bar"] = "在快捷栏中显示监控列表里的物品",
    ["Item Monitoring"] = "物品监控",
    ["Add Monitored Item"] = "添加监控物品",
    ["Add an item ID or paste an item link, then press Enter to monitor it"] = "输入物品ID或粘贴物品链接后按回车，加入任务物品快捷栏监控",
    ["Remove Monitored Item"] = "移除监控物品",
    ["Type an item ID and press Enter to stop monitoring it"] = "输入物品ID后按回车，从监控中移除",
    ["List Monitored Items"] = "列出监控物品",
    ["Clear Monitored Items"] = "清空监控物品",
    ["Monitored items cleared."] = "已清空所有监控物品。",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_QuestItemBar = Automaton:NewModule("QuestItemBar")
Automaton_QuestItemBar.modulename = L["QuestItemBar"]
Automaton_QuestItemBar.moduledesc = L["Shows usable quest items in a quick bar; click to use them."]

Automaton_QuestItemBar.options = {
    buttonSize = {
        type = "range",
        name = L["Button Size"],
        desc = L["Size of the quest item buttons"],
        min = 24, max = 48, step = 2,
        order = 2,
        get = function() return Automaton_QuestItemBar.db.profile.buttonSize end,
        set = function(v)
            Automaton_QuestItemBar.db.profile.buttonSize = v
            Automaton_QuestItemBar:Update()
        end,
    },
    perRow = {
        type = "range",
        name = L["Buttons Per Row"],
        desc = L["Maximum number of buttons in each row; extra items wrap to new rows"],
        min = 1, max = 20, step = 1,
        order = 3,
        get = function() return Automaton_QuestItemBar.db.profile.perRow end,
        set = function(v)
            Automaton_QuestItemBar.db.profile.perRow = v
            Automaton_QuestItemBar:Update()
        end,
    },
    lockPosition = {
        type = "toggle",
        name = L["Lock Position"],
        desc = L["Prevent the bar from being dragged"],
        order = 4,
        get = function() return Automaton_QuestItemBar.db.profile.lockPosition end,
        set = function(v)
            Automaton_QuestItemBar.db.profile.lockPosition = v
            Automaton_QuestItemBar:ApplyBackdrop()
        end,
    },
    resetPosition = {
        type = "execute",
        name = L["Reset Position"],
        desc = L["Reset the bar to its default position"],
        order = 5,
        func = function() Automaton_QuestItemBar:ResetPosition() end,
    },
    showQuestItems = {
        type = "toggle",
        name = L["Show Quest Items"],
        desc = L["Show automatically detected usable quest items in the bar"],
        order = 5.5,
        get = function() return Automaton_QuestItemBar.db.profile.showQuestItems ~= false end,
        set = function(v)
            Automaton_QuestItemBar.db.profile.showQuestItems = v
            Automaton_QuestItemBar:Update()
        end,
    },
    monitoredHeader = {
        type = "header",
        name = L["Item Monitoring"],
        order = 10,
    },
    monitoredAdd = {
        type = "text",
        name = L["Add Monitored Item"],
        desc = L["Add an item ID or paste an item link, then press Enter to monitor it"],
        order = 11,
        get = false,
        set = function(v)
            v = string.gsub(v or "", "^%s*(.-)%s*$", "%1")
            if v ~= "" then
                Automaton_QuestItemBar:HandleCommand("add " .. v)
            end
        end,
        usage = L["Add an item ID or paste an item link, then press Enter to monitor it"],
    },
    monitoredRemove = {
        type = "text",
        name = L["Remove Monitored Item"],
        desc = L["Type an item ID and press Enter to stop monitoring it"],
        order = 12,
        get = false,
        set = function(v)
            v = string.gsub(v or "", "^%s*(.-)%s*$", "%1")
            if v ~= "" then
                Automaton_QuestItemBar:HandleCommand("del " .. v)
            end
        end,
        usage = L["Type an item ID and press Enter to stop monitoring it"],
    },
    showMonitoredItems = {
        type = "toggle",
        name = L["Show Monitored Items"],
        desc = L["Show items from the monitored list in the bar"],
        order = 12.5,
        get = function() return Automaton_QuestItemBar.db.profile.showMonitoredItems ~= false end,
        set = function(v)
            Automaton_QuestItemBar.db.profile.showMonitoredItems = v
            Automaton_QuestItemBar:Update()
        end,
    },
    monitoredList = {
        type = "execute",
        name = L["List Monitored Items"],
        desc = "在聊天框列出当前监控的物品ID",
        order = 13,
        func = function() Automaton_QuestItemBar:HandleCommand("list") end,
    },
    monitoredClear = {
        type = "execute",
        name = L["Clear Monitored Items"],
        desc = "清空当前角色的所有监控物品",
        order = 14,
        func = function() Automaton_QuestItemBar:HandleCommand("clear") end,
    },
}

----------------------------------
--      Local Constants      --
----------------------------------

-- 任务物品类型（GetItemInfo 返回的物品类别），兼容中英文客户端
local QUEST_TYPE_EN = "Quest"
local QUEST_TYPE_ZH = "任务物品"

----------------------------------
--      Initialization      --
----------------------------------

function Automaton_QuestItemBar:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("QuestItemBar")
    Automaton:RegisterDefaults("QuestItemBar", "profile", {
        disabled = false,
        buttonSize = 36,
        perRow = 6,
        lockPosition = false,
        showQuestItems = true,
        showMonitoredItems = true,
        position = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 250,
            y = 0,
        },
    })
    -- 监控物品按角色保存：不同角色监控的物品不一样
    Automaton:RegisterDefaults("QuestItemBar", "char", {
        monitoredItems = {},
    })
    -- 一次性迁移：旧版本监控列表存在 profile（账号共享）里 → 搬到 char（按角色）
    if self.db.profile.monitoredItems and next(self.db.profile.monitoredItems) then
        if not next(self.db.char.monitoredItems) then
            for id in pairs(self.db.profile.monitoredItems) do
                self.db.char.monitoredItems[id] = true
            end
        end
        self.db.profile.monitoredItems = nil
    end
    Automaton:SetDisabledAsDefault(self, "QuestItemBar")
    self:RegisterOptions(self.options)

    self.buttons = {}
    self.questCache = {}

    -- 扫描用隐藏 tooltip（参考 shiqu.lua 的实现方式）
    self.scanTooltip = CreateFrame("GameTooltip", "Automaton_QIB_ScanTooltip", UIParent, "GameTooltipTemplate")
    self.scanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    self.tooltipName = "Automaton_QIB_ScanTooltip"

    -- 默认位置（重置用）：屏幕中间、偏右
    self.defaultPosition = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 250,
        y = 0,
    }

    -- 防抖计时器：背包更新频繁，合并后再刷新一次
    self._updateTimer = CreateFrame("Frame")
    self._updateTimer:Hide()
    self._updateTimer:SetScript("OnUpdate", function()
        local elapsed = arg1 or 0
        this._acc = (this._acc or 0) + elapsed
        if this._acc >= 0.15 then
            this:Hide()
            this._acc = 0
            Automaton_QuestItemBar:Update()
        end
    end)
end

function Automaton_QuestItemBar:OnEnable()
    if not self.bar then
        self:CreateBar()
    end
    self:LoadPosition()
    -- 按当前锁定状态决定底框显隐（登录/重载时同步一次）
    self:ApplyBackdrop()
    self:RegisterEvent("BAG_UPDATE")
    self:RegisterEvent("BAG_UPDATE_COOLDOWN")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.bar:Show()
    self:Update()
end

function Automaton_QuestItemBar:OnDisable()
    self:UnregisterAllEvents()
    if self.bar then
        self.bar:Hide()
    end
end

----------------------------------
--      UI Creation      --
----------------------------------

function Automaton_QuestItemBar:CreateBar()
    local frame = CreateFrame("Frame", "Automaton_QuestItemBar", UIParent)
    frame:SetFrameStrata("HIGH")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        tile = true, tileSize = 16,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.5)

    -- 拖动栏体移动位置（锁定后禁止）
    frame:SetScript("OnDragStart", function()
        if Automaton_QuestItemBar.db.profile.lockPosition then return end
        this:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local point, _, rel, x, y = this:GetPoint()
        if point then
            Automaton_QuestItemBar.db.profile.position = {
                point = point,
                relativePoint = rel,
                x = x,
                y = y,
            }
        end
    end)

    self.bar = frame
end

-- 底框显示控制（2026-09-30 用户要求）：
-- 锁定位置后隐藏黑色半透明底框（只留图标悬浮）；
-- 解锁时恢复底框，提示「此时可拖动」。
function Automaton_QuestItemBar:ApplyBackdrop()
    if not self.bar then return end
    local locked = self.db.profile.lockPosition
    self.bar:SetBackdropColor(0, 0, 0, locked and 0 or 0.5)
end

function Automaton_QuestItemBar:SetupButtonScripts(btn)
    btn:RegisterForDrag("LeftButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- 从栏中把物品拖出（放到动作栏 / 交易等）
    btn:SetScript("OnDragStart", function()
        if this.bagID and this.slotID then
            PickupContainerItem(this.bagID, this.slotID)
        end
    end)
    btn:SetScript("OnReceiveDrag", function()
        if this.bagID and this.slotID then
            PickupContainerItem(this.bagID, this.slotID)
        end
    end)
    -- 点击使用（左键或右键均可使用）；
    -- Shift+点击 保留聊天框链接的默认行为
    btn:SetScript("OnClick", function()
        if IsShiftKeyDown() and this.bagID and this.slotID then
            local link = GetContainerItemLink(this.bagID, this.slotID)
            if link and ChatFrameEditBox and ChatFrameEditBox:IsVisible() then
                ChatFrameEditBox:Insert(link)
                return
            end
        end
        if this.bagID and this.slotID then
            UseContainerItem(this.bagID, this.slotID)
        end
    end)
    -- 悬停显示物品提示
    -- 关键坑（已验证）：本客户端 GameTooltip:SetBagItem 实际按“按钮 parent/自身的 ID”
    -- 定位，而非传入参数。parent(bar) 与按钮自身的 ID 默认都是 0，
    -- 不处理就会定位到 (0,0)=背包本身。故先把正确的背包/槽位 ID 设到
    -- parent(bar) 与按钮自身，再调用 SetBagItem，即可显示真实物品。
    btn:SetScript("OnEnter", function()
        local bid = this.bagID
        local sid = this.slotID
        if not (bid and sid) then return end
        this:GetParent():SetID(bid)
        this:SetID(sid)
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetBagItem(bid, sid)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- 让按钮内部的子纹理（图标 / 边框 / 冷却圈）跟随按钮尺寸变化。
-- ContainerFrameItemButtonTemplate 的子纹理多为固定像素尺寸
-- （如 NormalTexture 边框图默认 58x58、IconTexture 默认跟随按钮），
-- 仅缩放按钮框架不会自动跟随，必须显式重置尺寸与锚点。
--
-- 全部边框一律去除（2026-09-30 用户要求：截图里槽位框 UI-Quickslot2
-- 是 58x58 固定尺寸，套在 36px 按钮上互相叠加成连片深色框，非常丑）：
-- - NormalTexture 除了 :Hide()，还调 btn:SetNormalTexture("") 从控件层面
--   解除引用，防止任何时机被重新显示/拉伸成色块；
-- - Border / IconBorder 存在则直接隐藏（1.12 模板本无，防御兼容层添加）；
-- - 图标完全铺满按钮（0px 边距），纯图标无框的扁平外观。
function Automaton_QuestItemBar:ResizeButton(btn, size)
    -- 图标：铺满整个按钮，无边距
    local icon = getglobal(btn:GetName() .. "IconTexture")
    if icon then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        icon:SetWidth(size)
        icon:SetHeight(size)
    end
    -- 槽位背景图（UI-Quickslot2）：隐藏 + 解除按钮控件引用，彻底去除
    local normal = getglobal(btn:GetName() .. "NormalTexture")
    if normal then
        normal:Hide()
    end
    btn:SetNormalTexture("")
    -- 品质边框 / 图标边框：存在则隐藏（1.12 无，防御性）
    local border = getglobal(btn:GetName() .. "Border")
    if border then
        border:Hide()
    end
    local iconBorder = getglobal(btn:GetName() .. "IconBorder")
    if iconBorder then
        iconBorder:Hide()
    end
    -- 冷却圈：覆盖整个按钮
    local cd = getglobal(btn:GetName() .. "Cooldown")
    if cd then
        cd:ClearAllPoints()
        cd:SetAllPoints(btn)
    end
end

----------------------------------
--      Quest Item Detection      --
--      自包含实现，移植自 Guda 的   --
--      ItemDetection / QuestItemBar  --
----------------------------------

-- 判断物品是否为任务物品，以及是否可用 / 起始任务
-- 通过链接缓存检测结果，避免每次背包更新都重复扫描 tooltip
function Automaton_QuestItemBar:CheckQuestItem(bag, slot, link)
    if self.questCache[link] then
        local c = self.questCache[link]
        return c.isQuest, c.isStarter, c.isUsable
    end

    local isQuest = false
    local isStarter = false
    local isUsable = false

    -- 主要判定来源：扫描背包物品的 tooltip。
    -- Guda 已验证：普通背包(0-4) 的 SetBagItem 可靠有效。
    self.scanTooltip:ClearLines()
    self.scanTooltip:SetBagItem(bag, slot)
    local numLines = self.scanTooltip:NumLines() or 0

    for i = 1, numLines do
        local left = getglobal(self.tooltipName .. "TextLeft" .. i)
        local right = getglobal(self.tooltipName .. "TextRight" .. i)
        local ltext = left and left:GetText() or ""
        local rtext = right and right:GetText() or ""
        local ll = string.lower(ltext)
        local rl = string.lower(rtext)

        -- 类别行：精确匹配“任务物品 / Quest”
        if ltext == QUEST_TYPE_ZH or rtext == QUEST_TYPE_ZH
           or ltext == QUEST_TYPE_EN or rtext == QUEST_TYPE_EN then
            isQuest = true
        end
        -- 起始任务（右键开始任务）——起始必为任务物品
        if string.find(ll, "开始") or string.find(rl, "开始")
           or string.find(ll, "begin") or string.find(rl, "begin")
           or string.find(ll, "start") or string.find(rl, "start") then
            isStarter = true
            isQuest = true
        end
        -- 使用效果（任务物品通常带“使用：/ Use:”）
        if string.find(ll, "使用") or string.find(rl, "使用")
           or string.find(ll, "use:") or string.find(rl, "use:") then
            isUsable = true
        end
    end

    -- 兜底：GetItemInfo 类别（扫描全部返回值，绕开本客户端布局错位）。
    -- 用 pcall 防止未缓存时抛错；仅在 tooltip 尚未判定为任务物品时补充。
    if not isQuest then
        local ok, itemInfo = pcall(GetItemInfo, link)
        if ok and itemInfo then
            for _, v in ipairs(itemInfo) do
                if v == QUEST_TYPE_EN or v == QUEST_TYPE_ZH then
                    isQuest = true
                    break
                end
            end
        end
    end

    -- 仅当 tooltip 数据看起来完整（>=2 行）才缓存，
    -- 避免 GetItemInfo / tooltip 未加载时的占位结果被永久缓存（缓存污染）。
    if numLines >= 2 then
        self.questCache[link] = {
            isQuest = isQuest,
            isStarter = isStarter,
            isUsable = isUsable,
        }
    end
    return isQuest, isStarter, isUsable
end

-- 从物品链接中提取物品ID（兼容短链接 item:ID:0:0:0 与完整彩色链接）
function Automaton_QuestItemBar:GetItemID(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    return id and tonumber(id) or nil
end

-- 扫描背包（0-4）收集可显示的物品（受两个开关控制）：
-- 1) 任务物品（可用 或 起始任务）—— showQuestItems
-- 2) 监控列表中的物品（按 itemID 匹配，无论是否任务物品）—— showMonitoredItems
function Automaton_QuestItemBar:ScanBagsForQuestItems()
    local items = {}
    local monitored = self.db.char.monitoredItems
    local showQuest = self.db.profile.showQuestItems ~= false
    local showMonitored = self.db.profile.showMonitoredItems ~= false
    local seen = {}  -- itemID -> 已收录的 items 表项：去重 + 各格数量合计（动作条逻辑）
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local texture, count = GetContainerItemInfo(bag, slot)
            if texture then
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local itemID = (showMonitored or showQuest) and self:GetItemID(link) or nil
                    -- 按 itemID 去重：同一物品多格堆叠时只显示第一格，数量累加合计
                    local existing = itemID and seen[itemID]
                    if existing then
                        existing.count = existing.count + (count or 1)
                    else
                        local isMonitored = showMonitored and itemID and monitored[itemID] or nil
                        local isQuest, isStarter, isUsable
                        if isMonitored then
                            -- 监控物品：直接纳入，无需判定任务类型（也避免多余 tooltip 扫描）
                            isQuest, isStarter, isUsable = false, false, false
                        elseif showQuest then
                            isQuest, isStarter, isUsable = self:CheckQuestItem(bag, slot, link)
                        end
                        -- 显示条件：任务物品(可用/起始) 或 监控物品
                        if (isQuest and (isUsable or isStarter)) or isMonitored then
                            local entry = {
                                bagID = bag,
                                slotID = slot,
                                link = link,
                                texture = texture,
                                count = count or 1,
                                monitored = isMonitored,
                            }
                            table.insert(items, entry)
                            if itemID then
                                seen[itemID] = entry
                            end
                        end
                    end
                end
            end
        end
    end
    return items
end

----------------------------------
--      Bar Update      --
----------------------------------

function Automaton_QuestItemBar:Update()
    if not self.bar then return end
    local frame = self.bar

    local items = self:ScanBagsForQuestItems()
    if table.getn(items) == 0 then
        frame:Hide()
        return
    end
    frame:Show()

    local size = self.db.profile.buttonSize
    local spacing = 2
    local pad = 2
    -- 每排上限由 perRow 控制，总按钮数不再设上限，超出自动换排
    local perRow = self.db.profile.perRow or 6
    local n = table.getn(items)
    local rows = math.ceil(n / perRow)

    for i = 1, n do
        local item = items[i]
        local btn = self.buttons[i]
        if not btn then
            btn = CreateFrame("Button", "Automaton_QIB_Btn" .. i, frame, "ContainerFrameItemButtonTemplate")
            self.buttons[i] = btn
            self:SetupButtonScripts(btn)
        end
        btn.bagID = item.bagID
        btn.slotID = item.slotID
        btn.link = item.link

        SetItemButtonTexture(btn, item.texture)
        SetItemButtonCount(btn, item.count or 1)

        btn:SetWidth(size)
        btn:SetHeight(size)
        self:ResizeButton(btn, size)

        local cd = getglobal(btn:GetName() .. "Cooldown")
        if cd then
            local startT, duration, enable = GetContainerItemCooldown(item.bagID, item.slotID)
            if startT and duration and duration > 0 and enable == 1 then
                CooldownFrame_SetTimer(cd, startT, duration, enable)
            else
                cd:Hide()
            end
        end

        -- 网格布局：第 i 个按钮 → 第 floor((i-1)/perRow) 排、第 mod((i-1),perRow) 列
        -- （Lua 5.0 无 % 运算符，用 math.mod）
        local col = math.mod(i - 1, perRow)
        local row = math.floor((i - 1) / perRow)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT",
            pad + col * (size + spacing),
            -(pad + row * (size + spacing)))
        btn:Show()
    end

    -- 隐藏多余的按钮
    for j = n + 1, table.getn(self.buttons) do
        self.buttons[j]:Hide()
    end

    -- 根据行列数量调整栏尺寸
    local cols = math.min(n, perRow)
    frame:SetWidth(pad * 2 + cols * (size + spacing) - spacing)
    frame:SetHeight(pad * 2 + rows * (size + spacing) - spacing)
end

----------------------------------
--      Cooldown Refresh      --
----------------------------------

function Automaton_QuestItemBar:UpdateCooldowns()
    if not self.buttons then return end
    for _, btn in ipairs(self.buttons) do
        if btn:IsShown() and btn.bagID and btn.slotID then
            local cd = getglobal(btn:GetName() .. "Cooldown")
            if cd then
                local startT, duration, enable = GetContainerItemCooldown(btn.bagID, btn.slotID)
                if startT and duration and duration > 0 and enable == 1 then
                    CooldownFrame_SetTimer(cd, startT, duration, enable)
                else
                    cd:Hide()
                end
            end
        end
    end
end

----------------------------------
--      Position Management      --
----------------------------------

function Automaton_QuestItemBar:LoadPosition()
    local pos = self.db.profile.position or self.defaultPosition
    self.bar:ClearAllPoints()
    self.bar:SetPoint(pos.point, UIParent, pos.relativePoint or pos.point, pos.x, pos.y)
end

function Automaton_QuestItemBar:ResetPosition()
    self.db.profile.position = {
        point = self.defaultPosition.point,
        relativePoint = self.defaultPosition.relativePoint,
        x = self.defaultPosition.x,
        y = self.defaultPosition.y,
    }
    self:LoadPosition()
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[任务物品快捷栏]|r " .. L["Position reset to default."])
    end
end

----------------------------------
--      Events      --
----------------------------------

function Automaton_QuestItemBar:BAG_UPDATE()
    self:ScheduleUpdate()
end

function Automaton_QuestItemBar:BAG_UPDATE_COOLDOWN()
    if self.bar and self.bar:IsShown() then
        self:UpdateCooldowns()
    end
end

function Automaton_QuestItemBar:PLAYER_ENTERING_WORLD()
    -- 切换角色 / 升级后清空检测缓存（物品属性可能因等级/语言变化）
    self.questCache = {}
    -- 延迟刷新：进服瞬间物品数据可能尚未完全加载，等一拍再检测
    self:ScheduleUpdate()
end

function Automaton_QuestItemBar:ScheduleUpdate()
    self._updateTimer._acc = 0
    self._updateTimer:Show()
end

----------------------------------
--      物品监控（GUI 内部解析）      --
----------------------------------

function Automaton_QuestItemBar:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[任务物品快捷栏]|r " .. (msg or ""))
    end
end

-- 设置界面「物品监控」输入框/按钮的内部解析：
-- add <ID或链接> | del/remove <ID> | list | clear
function Automaton_QuestItemBar:HandleCommand(msg)
    msg = msg or ""
    local space = string.find(msg, " ")
    local cmd = space and string.lower(string.sub(msg, 1, space - 1)) or string.lower(msg)
    local rest = space and string.sub(msg, space + 1) or ""
    rest = string.gsub(rest, "^%s*(.-)%s*$", "%1")  -- 去首尾空格

    if cmd == "add" or cmd == "a" then
        local id
        -- 支持直接传物品ID，或从物品链接中提取（如 shift 复制的链接）
        if string.find(rest, "item:%d+") then
            local _, _, n = string.find(rest, "item:(%d+)")
            id = tonumber(n)
        else
            id = tonumber(rest)
        end
        if not id then
            self:Print("请输入有效的物品ID或物品链接")
            return
        end
        self.db.char.monitoredItems[id] = true
        self:Update()
        self:Print("已添加监控物品：" .. id)
    elseif cmd == "del" or cmd == "remove" or cmd == "r" then
        local id = tonumber(rest)
        if not id then
            self:Print("请输入有效的物品ID")
            return
        end
        if self.db.char.monitoredItems[id] then
            self.db.char.monitoredItems[id] = nil
            self:Update()
            self:Print("已移除监控物品：" .. id)
        else
            self:Print("未监控该物品：" .. id)
        end
    elseif cmd == "list" or cmd == "l" then
        local list = {}
        for id in pairs(self.db.char.monitoredItems) do
            table.insert(list, tostring(id))
        end
        if table.getn(list) == 0 then
            self:Print("当前未监控任何物品。")
        else
            table.sort(list, function(a, b) return tonumber(a) < tonumber(b) end)
            self:Print("监控物品ID：" .. table.concat(list, ", "))
        end
    elseif cmd == "clear" or cmd == "c" then
        self.db.char.monitoredItems = {}
        self:Update()
        self:Print(L["Monitored items cleared."])
    end
end
