assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Unlock")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
    ["Unlock"] = "自动开锁",
    ["Automatically handle lockpicking for rogues"] = "为盗贼自动处理开锁功能",
    ["Right-Click Unlock"] = "右键开锁",
    ["Right-click locked items in bags to unlock"] = "右键点击背包中的锁定物品进行开锁",
    ["Trade Frame Button"] = "交易界面按钮",
    ["Add a lockpicking button to the trade window"] = "在交易窗口添加开锁按钮",
} end)

L:RegisterTranslations("zhCN", function() return {
    ["Unlock"] = "自动开锁",
    ["Automatically handle lockpicking for rogues"] = "为盗贼自动处理开锁功能",
    ["Right-Click Unlock"] = "右键开锁",
    ["Right-click locked items in bags to unlock"] = "右键点击背包中的锁定物品进行开锁",
    ["Trade Frame Button"] = "交易界面按钮",
    ["Add a lockpicking button to the trade window"] = "在交易窗口添加开锁按钮",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Unlock = Automaton:NewModule("Unlock")
Automaton_Unlock.modulename = L["Unlock"]
Automaton_Unlock.moduledesc = L["Automatically handle lockpicking for rogues"]
Automaton_Unlock.options = {
    rightClick = {
        type = 'toggle',
        name = L["Right-Click Unlock"],
        desc = L["Right-click locked items in bags to unlock"],
        order = 2,
        get = function() return Automaton_Unlock.db.profile.rightClick end,
        set = function(v) Automaton_Unlock.db.profile.rightClick = v end,
    },
    tradeFrameButton = {
        type = 'toggle',
        name = L["Trade Frame Button"],
        desc = L["Add a lockpicking button to the trade window"],
        order = 3,
        get = function() return Automaton_Unlock.db.profile.tradeFrameButton end,
        set = function(v) 
            Automaton_Unlock.db.profile.tradeFrameButton = v 
            if v then
                Automaton_Unlock:CreateTradeFrameButton()
            else
                Automaton_Unlock:HideTradeFrameButton()
            end
        end,
    }
}

------------------------------
--      Initialization      --
------------------------------

-- 开锁技能名（1.12 原生 API 没有可用的 spellID：GetSpellInfo(name) 的第 3 个返回值是
-- 图标纹理而不是 ID，所以这里一律按名字在法术书里匹配，不依赖任何 spellId）
local LOCKPICK_NAMES = { "开锁", "Pick Lock" }

-- 在法术书中查找开锁技能，返回 (法术书槽位, 法术书类型)；未学会返回 nil
local function FindLockpickingSpellSlot()
    for tab = 1, 12 do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        if offset and numSpells and offset >= 0 and numSpells > 0 then
            for i = offset + 1, offset + numSpells do
                local bookName = GetSpellName(i, "spell")
                if bookName then
                    for _, wanted in ipairs(LOCKPICK_NAMES) do
                        if bookName == wanted then
                            return i, "spell"
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

-- 判断 gratuity 当前扫描到的物品是否"已锁"（左右两栏都查，排除"锁甲"这类误判）
local function IsScannedItemLocked()
    local tip = Automaton.gratuity
    if not tip then return false end
    for i = 1, tip:NumLines() do
        local left  = tip:GetLine(i)
        local right = tip:GetLine(i, true)
        if left and string.find(left, "锁") and not string.find(left, "锁甲") then
            return true
        end
        if right and string.find(right, "锁") and not string.find(right, "锁甲") then
            return true
        end
    end
    return false
end

-- 调试命令（手动调用，不影响正常流程）
local function RegisterDebugCommands()
    _G["Automaton_Unlock_DebugCheck"] = function()
        local slot, book = FindLockpickingSpellSlot()
        print("[自动开锁调试] 等级="..tostring(UnitLevel("player")).."，职业="..tostring(UnitClass("player")))
        if slot then
            print("[自动开锁调试] 找到开锁：槽位="..slot.."，类型="..book)
            CastSpell(slot, book)
        else
            print("[自动开锁调试] 法术书里没有开锁技能（盗贼需 16 级在盗贼训练师处学习「开锁」）")
        end
    end
end

-- 创建交易界面开锁按钮
function Automaton_Unlock:CreateTradeFrameButton()
    if self.tradeFrameButton then return end
    
    -- 检查是否为盗贼
    local isRogue = (self.playerClass.en == "ROGUE") or (self.playerClass.locale == "盗贼")
    if not isRogue then return end
    
    -- 创建按钮
    self.tradeFrameButton = CreateFrame("Button", "AutomatonTradeFrameLockpickButton", TradeFrame, "UIPanelButtonTemplate")
    self.tradeFrameButton:SetWidth(80)
    self.tradeFrameButton:SetHeight(25)
    self.tradeFrameButton:SetText(L["Unlock"])
    self.tradeFrameButton:SetPoint("TOP", TradeFrameCancelButton, "BOTTOM", 0, -5)
    
    -- 设置点击事件
    self.tradeFrameButton:SetScript("OnClick", function()
        if not self.lockpickSlot then
            self.lockpickSlot, self.lockpickBook = FindLockpickingSpellSlot()
        end
        if self.lockpickSlot then
            CastSpell(self.lockpickSlot, self.lockpickBook)
        else
            print("[自动开锁] 交易窗口：法术书里没有「开锁」技能（盗贼需 16 级学习）")
        end
    end)
    
    -- 初始显示状态 - 修复：使用 Show() 和 Hide() 而不是 SetShown()
    if self.db.profile.tradeFrameButton then
        self.tradeFrameButton:Show()
    else
        self.tradeFrameButton:Hide()
    end
end

-- 隐藏交易界面按钮
function Automaton_Unlock:HideTradeFrameButton()
    if self.tradeFrameButton then
        self.tradeFrameButton:Hide()
    end
end

function Automaton_Unlock:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("Unlock")
    Automaton:RegisterDefaults("Unlock", "profile", {
        disabled = false,
        rightClick = true,
        tradeFrameButton = true  -- 默认启用交易界面按钮
    })
    Automaton:SetDisabledAsDefault(self, "Unlock")
    self:RegisterOptions(self.options)
    
    -- 缓存开锁技能信息（未学会时为 nil，之后按需重新扫描）
    self.lockpickSlot, self.lockpickBook = FindLockpickingSpellSlot()
    
    -- 获取玩家职业信息
    local classLocale, classEn = UnitClass("player")
    self.playerClass = {
        locale = classLocale,
        en = classEn
    }
    self.isRogue = (classEn == "ROGUE") or (classLocale == "盗贼")
    
    -- 注册调试命令（仅在盗贼职业时）
    if self.isRogue then
        RegisterDebugCommands()
        -- 创建交易界面按钮
        self:CreateTradeFrameButton()
    end
end

function Automaton_Unlock:OnEnable()
    if self.isRogue then
        self:Hook("ContainerFrameItemButton_OnClick", "OnBagItemClick")
        -- 显示交易界面按钮（如果已创建）
        if self.tradeFrameButton and self.db.profile.tradeFrameButton then
            self.tradeFrameButton:Show()
        end
    end
end

function Automaton_Unlock:OnDisable()
    self:UnhookAll()
    if _G["LockpickingFrame"] then
        _G["LockpickingFrame"]:Hide()
    end
    -- 隐藏交易界面按钮
    self:HideTradeFrameButton()
end

------------------------------
--      Helper Functions      --
------------------------------

function Automaton_Unlock:OnBagItemClick(button, ignoreShift)
    if button == "RightButton" and self.db.profile.rightClick and self.isRogue
        and not (BankFrame and BankFrame:IsVisible()) then
        local bag, slot = this:GetParent():GetID(), this:GetID()
        if bag and slot then
            Automaton.gratuity:SetBagItem(bag, slot)

            -- 只有"已锁"的物品才继续：普通物品（装备/使用/开锁盒）直接放行，
            -- 不扫描法术书、不打印任何提示
            if IsScannedItemLocked() then
                if not self.lockpickSlot then
                    -- 可能刚学到开锁，按需重扫一次
                    self.lockpickSlot, self.lockpickBook = FindLockpickingSpellSlot()
                end
                if self.lockpickSlot then
                    CastSpell(self.lockpickSlot, self.lockpickBook)
                    PickupContainerItem(bag, slot)
                    return
                end
                -- 未学会开锁：只提示一次，之后静默
                if not self.warnedNoLockpick then
                    self.warnedNoLockpick = true
                    print("[自动开锁] 这是锁定的物品，但法术书里没有「开锁」技能（盗贼需 16 级在训练师处学习）")
                end
            end
        end
    end

    -- 执行原始点击处理
    self.hooks.ContainerFrameItemButton_OnClick(button, ignoreShift)
end