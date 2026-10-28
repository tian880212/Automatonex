assert(Automaton, "Automaton not found!")

----------------------------------
--   龙头计时相关常量 / 输出    --
----------------------------------
-- 旧版：固定 18 秒，而且只在「收到别人转播」时才开始倒数。
-- 转播延迟 + 固定值不准 = 炉石读条 10 秒落地时 buff 已经生效。
-- 现在：本地听到喊话立刻起表（省掉转播延迟），秒数优先用实测值，检测到 buff 真生效就结束倒计时。
local DEFAULT_LEAD_TIME   = 18      -- 尚未校准前的兜底值（喊话 -> 生效）
local LEAD_TIME_MIN       = 3       -- 合理下限（太小说明测到别的东西了）
local LEAD_TIME_MAX       = 60      -- 合理上限
local WORLD_BUFF_MIN_LEFT = 6900    -- 剩余时长 >= 此值视为 2 小时世界 buff（龙头/酋长/赞达拉）
local HEARTH_CAST_TIME    = 10      -- 炉石施法时间（秒）

local function PWBPrint(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffff7c0a[世界BUFF]|r " .. text)
end

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_WorldBuffs = Automaton:NewModule("WorldBuffs")
Automaton_WorldBuffs.modulename = "世界BUFF通告"
Automaton_WorldBuffs.moduledesc = "世界BUFF通告倒计时"
Automaton_WorldBuffs.options = {
    sound = {
        type = 'toggle',
        name = "播放提示音",
        desc = "触发时播放提示音",
        order = 2,
        get = function() return Automaton_WorldBuffs.db.profile.sound end,
        set = function(v) Automaton_WorldBuffs.db.profile.sound = v end,
    },
    showbar = {
        type = 'toggle',
        name = "倒计时提醒",
        desc = "屏幕中央闪烁倒计时提醒",
        order = 3,
        get = function() return Automaton_WorldBuffs.db.profile.showbar end,
        set = function(v) Automaton_WorldBuffs.db.profile.showbar = v end,
    },
    guild = {
        type = 'toggle',
        name = "公会通告",
        desc = "触发时在公会通告",
        order = 4,
        get = function() return Automaton_WorldBuffs.db.profile.guild end,
        set = function(v) Automaton_WorldBuffs.db.profile.guild = v end,
    },
    showhotel = {
        type = 'toggle',
        name = "显示炉石按钮",
        desc = "当龙头信息倒计时出现的时候弹出炉石按钮，方便快速回城\n当计时小于10秒后自动隐藏。",
        order = 5,
        get = function() return Automaton_WorldBuffs.db.profile.showhotel end,
        set = function(v) Automaton_WorldBuffs.db.profile.showhotel = v end,
    },
    autoLogout = {
        type = 'toggle',
        name = "自动登出",
        desc = "获得世界BUFF后自动登出游戏",
        order = 6,
        get = function() return Automaton_WorldBuffs.db.profile.autoLogout end,
        set = function(v) Automaton_WorldBuffs.db.profile.autoLogout = v end,
    },
    autoExit = {
        type = 'toggle',
        name = "自动退出游戏",
        desc = "获得世界BUFF后自动退出游戏",
        order = 7,
        get = function() return Automaton_WorldBuffs.db.profile.autoExit end,
        set = function(v) Automaton_WorldBuffs.db.profile.autoExit = v end,
    },
    leadTime = {
        type = 'text',
        name = "龙头生效延迟(秒)",
        desc = "从喊话播报到龙头 buff 真正生效的秒数。\n填 0 = 自动学习实测间隔（推荐）。\n炉石施法 10 秒，所以这个值小于 10 时基本只能提前在城里等。",
        order = 8,
        get = function()
            local v = Automaton_WorldBuffs.db.profile.leadTime
            if v and v >= LEAD_TIME_MIN then return tostring(v) end
            return "0"
        end,
        set = function(v)
            local n = tonumber(v)
            if not n or n < 0 then
                PWBPrint("请输入数字；0 = 自动学习")
                return
            end
            Automaton_WorldBuffs.db.profile.leadTime = n
            if n >= LEAD_TIME_MIN then
                PWBPrint("龙头倒计时已固定为 " .. n .. " 秒")
            else
                Automaton_WorldBuffs.db.profile.learnedLead = nil
                PWBPrint("已切换为自动学习生效间隔（下次数完就记住）")
            end
        end,
    },
}

------------------------------
--      Initialization      --
------------------------------
local config = {}
local pattern = "^MPWB:(.+):(.+)$"
local icon = [[Interface\Icons\INV_Misc_Head_Dragon_01]]
local hotelicon = [[Interface\Icons\INV_Misc_Rune_01]]
local timer
local SOUND_PATH = "Interface\\AddOns\\Automatonex\\Sound\\sound1.ogg"  -- 定义音效路径

-- 自动下线相关变量
Automaton_WorldBuffs.logoutAt = nil
Automaton_WorldBuffs.logoutFrame = nil

if GetLocale() == "zhCN" then
    config = {
        Alliance = {
            Onyxia = { name = "玛丁雷少校", yell = "向我们的英雄们致敬", msg = "【联盟】黑龙" },
            Nefarian = { name = "艾法希比元帅", yell = "黑石之王已经被干掉了", msg = "【联盟】奈法" },
        },
        Horde = {
            Onyxia = { name = "伦萨克", yell = "奥妮克希亚已经被斩杀了", msg = "【部落】黑龙" },
            Nefarian = { name = "萨鲁法尔大王", yell = "奈法利安被杀掉了", msg = "【部落】奈法" },
        }
    }
else
    config = {
        Alliance = {
            Onyxia = { name = "Major Mattingly", yell = "history has been made", msg = "【联盟】黑龙" },
            Nefarian = { name = "Field Marshal Afrasiabi", yell = "the Lord of Blackrock is slain", msg = "【联盟】奈法" },
        },
        Horde = {
            Onyxia = { name = "Overlord Runthak", yell = "Onyxia, has been slain", msg = "【部落】黑龙" },
            Nefarian = { name = "High Overlord Saurfang", yell = "NEFARIAN IS SLAIN", msg = "【部落】奈法" },
        }
    }
end

-- 自定义音效播放函数
local function PlayCustomSound()
    if Automaton_WorldBuffs.db.profile.sound then
        -- 使用WoW标准函数播放自定义音效
        PlaySoundFile(SOUND_PATH, "Master")
    end
end

-- 通过物品ID查找物品
local function FindItemByID(itemID)
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local foundID = tonumber(string.match(itemLink, "item:(%d+):"))
                if foundID and foundID == itemID then
                    return bag, slot
                end
            end
        end
    end
end

function Automaton_WorldBuffs:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("WorldBuffs")
    Automaton:RegisterDefaults("WorldBuffs", "profile", {
        disabled = true,
        showbar = true,
        sound = true,
        guild = false,
        showhotel = true,
        autoLogout = false,
        autoExit = false,
        leadTime = 0,      -- 0 = 自动学习；>=3 = 手动固定秒数
    })
    Automaton:SetDisabledAsDefault(self, "WorldBuffs")
    self:RegisterOptions(self.options)
    
    -- 创建自动下线框架
    self.logoutFrame = CreateFrame("Frame")
    self.logoutFrame:Hide()
    self.logoutFrame:SetScript("OnUpdate", function()
        self:LogoutFrame_OnUpdate()
    end)
end

function Automaton_WorldBuffs:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
    self:RegisterEvent("CHAT_MSG_CHANNEL")
    self.logoutFrame:Show()
end

function Automaton_WorldBuffs:OnDisable()
    self:UnregisterAllEvents()
    self.logoutFrame:Hide()
    self.logoutAt = nil
end

-- 自动下线框架的OnUpdate处理
function Automaton_WorldBuffs:LogoutFrame_OnUpdate()
    if (self.db.profile.autoLogout or self.db.profile.autoExit) and self.logoutAt and GetTime() >= self.logoutAt then
        self.logoutAt = nil
        
        if self.db.profile.autoLogout then
            self:Print("正在登出...")
            Logout()      -- 执行登出
        else
            self:Print("正在退出游戏...")
            Quit()        -- 执行退出游戏
        end
        
        -- 自动禁用功能并提示
        if self.db.profile.autoLogout then
            self.db.profile.autoLogout = false
        end
        
        if self.db.profile.autoExit then
            self.db.profile.autoExit = false  
        end
    end
end

------------------------------
--      Event Handlers      --
------------------------------
-- 只监控自己阵容的NPC喊话
function Automaton_WorldBuffs:CHAT_MSG_MONSTER_YELL()
    if not self.faction then self.faction = UnitFactionGroup("player") end
    for name, info in pairs(config[self.faction]) do
        if arg2 == info.name and strfind(arg1, info.yell) then
            -- 本地目击：立刻起表（不走频道转播，省掉转播延迟），同时转播给不在场的玩家
            self:AnnounceBuff(name, self.faction)
            SendChatMessage('MPWB:' .. name .. ":" .. self.faction, 'CHANNEL', nil, GetChannelName("LFT"))
        end
    end
end

-- 提醒框架
local caution = CreateFrame("Frame", "AutomatonWorldBuffsCaution", UIParent)
caution.string = caution:CreateFontString("AutomatonWorldBuffsText", "BACKGROUND")
caution.string:SetPoint("CENTER", UIParent, "CENTER", 0, 260)
caution.string:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
caution.string:SetDrawLayer("ARTWORK")
caution.string:SetTextHeight(20)
caution:Hide()

-- 炉石按钮
local hotelButton

------------------------------
--    龙头倒计时 / 校准核心   --
------------------------------
-- countdownTime / countdownActive 在这里声明（原先在下面），
-- 保证下面的倒计时、校准函数和事件处理用的是同一份变量。
local countdownTime   = 0
local countdownActive = false

local countdownStart     -- 本次倒计时的起点（GetTime()）
local countdownBoss      -- 本次是哪个龙头（Onyxia / Nefarian）
local countdownFaction   -- 本次阵营
local watchZone          -- 起表时所在区域（用来判断玩家是否移动过）
local watchSnapshot      -- 起表时已有的 buff 贴图，用来识别「新出现」的世界 buff
local watchSnapshotLeft  -- 起表时这些世界 buff 的剩余秒数（识别「同一个 buff 被重新续上」）
local worldBuffWatch     -- 只看 buff 的轻量 OnUpdate 帧

-- 当前使用的倒数基准：手动设定 > 自动学习 > 默认 18 秒
local function GetLeadTime()
    local p = Automaton_WorldBuffs.db and Automaton_WorldBuffs.db.profile
    if p then
        if type(p.leadTime) == 'number' and p.leadTime >= LEAD_TIME_MIN then return p.leadTime end
        if type(p.learnedLead) == 'number' and p.learnedLead >= LEAD_TIME_MIN then return p.learnedLead end
    end
    return DEFAULT_LEAD_TIME
end

-- 记录一次实测的「喊话 -> 生效」间隔（手动固定值时不动）
local function SaveLead(seconds)
    seconds = tonumber(seconds)
    if not seconds or seconds < LEAD_TIME_MIN or seconds > LEAD_TIME_MAX then return end
    local p = Automaton_WorldBuffs.db and Automaton_WorldBuffs.db.profile
    if not p then return end
    if type(p.leadTime) == 'number' and p.leadTime >= LEAD_TIME_MIN then return end
    if not p.learnedLead or math.abs(seconds - p.learnedLead) > 0.5 then
        p.learnedLead = seconds
        PWBPrint(string.format("龙头生效间隔已校准为 %.1f 秒（喊话 → buff 生效），之后按这个倒数", seconds))
    end
end

-- 扫描玩家 buff：返回 {贴图=true} 与 {贴图=剩余秒数}（后者只装 2 小时的世界 buff）
local function ScanBuffs()
    local all, long = {}, {}
    for i = 0, 31 do
        local ok, idx = pcall(GetPlayerBuff, i, "HELPFUL")
        if not ok or not idx or idx < 0 then break end
        local okTex, tex = pcall(GetPlayerBuffTexture, idx)
        if okTex and tex then
            all[tex] = true
            local okLeft, left = pcall(GetPlayerBuffTimeLeft, idx)
            if okLeft and left then
                if left > 100000 then left = left / 1000 end   -- 有的客户端返回毫秒
                if left >= WORLD_BUFF_MIN_LEFT then long[tex] = left end
            end
        end
    end
    return all, long
end

local function StopTracking()
    if worldBuffWatch then worldBuffWatch:Hide() end
end

-- 结束倒计时（buff 已生效，或确认来不及）
local function FinishCountdown(reason)
    countdownActive = false
    countdownTime = 0
    if caution then caution:Hide() end
    if hotelButton then hotelButton:Hide() end
    StopTracking()
    if reason then PWBPrint(reason) end
end

-- 开始倒数 + 开始盯 buff（本地喊话与收到转播都走这里）
local function BeginCountdown(boss, faction)
    countdownTime = GetLeadTime()
    countdownActive = true
    countdownStart = GetTime()
    countdownBoss, countdownFaction = boss, faction
    watchZone = GetZoneText()
    watchSnapshot, watchSnapshotLeft = ScanBuffs()

    if not worldBuffWatch then
        worldBuffWatch = CreateFrame("Frame")
        worldBuffWatch:SetScript("OnUpdate", function()
            if (this.tick or 0) > GetTime() then return end
            this.tick = GetTime() + 0.5

            local elapsed = GetTime() - countdownStart
            if elapsed > GetLeadTime() + 20 then StopTracking(); return end

            local _, long = ScanBuffs()
            for tex, left in pairs(long) do
                -- 新出现的 2 小时世界 buff，或者同一个 buff 剩余时间突然变长 = 刚被续上
                local fresh = not (watchSnapshot and watchSnapshot[tex])
                local refreshed = watchSnapshotLeft and watchSnapshotLeft[tex] and left > watchSnapshotLeft[tex] + 30
                if fresh or refreshed then
                    local sameZone = (watchZone == GetZoneText())
                    StopTracking()
                    if sameZone then
                        -- 全程没换地图 = 这个间隔是真实的「喊话 -> 生效」
                        SaveLead(elapsed)
                        local ch = GetChannelName("LFT")
                        if ch and ch > 0 and countdownBoss and countdownFaction then
                            SendChatMessage(string.format("MPWB_CAST:%s:%s:%.1f", countdownBoss, countdownFaction, elapsed),
                                "CHANNEL", nil, ch)
                        end
                        FinishCountdown(string.format("龙头已生效：喊话后 %.1f 秒（本次倒计时已结束）", elapsed))
                    else
                        FinishCountdown(string.format("龙头已生效（本次你还在路上，用时 %.1f 秒，不用于校准）", elapsed))
                    end
                    return
                end
            end
        end)
    end
    worldBuffWatch:Show()

    local lead = GetLeadTime()
    if lead < HEARTH_CAST_TIME then
        PWBPrint(string.format("注意：生效间隔只有 %.0f 秒，炉石要读 %d 秒 —— 基本只能提前在城里等", lead, HEARTH_CAST_TIME))
    end
end

-- 创建炉石按钮（无边框版本）
local function CreateHotelButton()
    hotelButton = CreateFrame("Button", "AutomatonWorldBuffsHotel", UIParent)
    hotelButton:SetWidth(40)
    hotelButton:SetHeight(40)
    hotelButton:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    
    -- 创建图标纹理，不使用ActionButtonTemplate
    local iconTexture = hotelButton:CreateTexture(nil, "BACKGROUND")
    iconTexture:SetAllPoints()
    iconTexture:SetTexture(hotelicon)
    
    -- 添加鼠标悬停效果
    hotelButton:SetScript("OnEnter", function()
        iconTexture:SetAlpha(0.8)
    end)
    
    hotelButton:SetScript("OnLeave", function()
        iconTexture:SetAlpha(1.0)
    end)
    
    hotelButton:SetScript("OnMouseDown", function()
        iconTexture:SetAlpha(0.6)
    end)
    
    hotelButton:SetScript("OnMouseUp", function()
        iconTexture:SetAlpha(0.8)
    end)
    
    hotelButton:SetScript("OnClick", function()
        -- 优先使用物品ID 6948查找炉石
        local bag, slot = FindItemByID(6948)
        
        -- 如果没有找到，则使用名称查找
        if not bag then
            for bag = 0, NUM_BAG_SLOTS do
                for slot = 1, GetContainerNumSlots(bag) do
                    local itemLink = GetContainerItemLink(bag, slot)
                    if itemLink then
                        local name = GetItemInfo(itemLink)
                        if name and (name == "炉石" or name == "Hearthstone") then
                            UseContainerItem(bag, slot)
                            return
                        end
                    end
                end
            end
        else
            UseContainerItem(bag, slot)
        end
    end)

    -- 到点自动隐藏（1.12 原生没有 C_Timer，改成自己的 OnUpdate，避免依赖缺失时报错）
    hotelButton:SetScript("OnUpdate", function()
        if this.hideAt and GetTime() >= this.hideAt then
            this.hideAt = nil
            this:Hide()
        end
    end)

    hotelButton:Hide()
end

-- 显示炉石按钮
local function ShowHotelButton()
    if not hotelButton then
        CreateHotelButton()
    end
    
    if Automaton_WorldBuffs.db.profile.showhotel then
        hotelButton:Show()
        hotelButton.hideAt = GetTime() + 10   -- 10 秒后自动隐藏
    end
end

-- 龙头播报（本地目击 / 收到转播 共用）：起表 + 文字 + 音效 + 公会通告 + 炉石按钮 + 自动登出
function Automaton_WorldBuffs:AnnounceBuff(name, faction)
    -- 2 秒内的重复播报（自己转播回来 / 多人同时转播）只处理一次
    if timer and timer - GetTime() > 0 then return end
    timer = GetTime() + 2

    BeginCountdown(name, faction)

    if self.db.profile.showbar then
        local buffMsg = config[faction] and config[faction][name] and config[faction][name].msg or name
        caution.string:SetText("注意！" .. buffMsg .. " Buff倒计时，还有" .. math.floor(countdownTime) .. "秒")
        caution:Show()
    end
    if self.db.profile.sound then
        PlayCustomSound()
    end
    if self.db.profile.guild then
        local buffMsg = config[faction] and config[faction][name] and config[faction][name].msg or name
        SendChatMessage("注意！" .. buffMsg .. " Buff倒计时，还有" .. math.floor(countdownTime) .. "秒", "GUILD")
    end
    if self.db.profile.showhotel then
        ShowHotelButton()
    end

    -- 设置自动下线定时器
    if self.db.profile.autoLogout or self.db.profile.autoExit then
        local message = self.db.profile.autoExit and
            "即将获得世界BUFF，自动退出功能已启用。将在1分钟后退出游戏。" or
            "即将获得世界BUFF，自动登出功能已启用。将在1分钟后登出。"
        self:Print(message)
        self.logoutAt = GetTime() + 60  -- 60秒后执行
    end
end

-- 渐变效果变量
local isFadingOut = true

-- 计时器变量 countdownTime / countdownActive 已在上面（龙头倒计时核心）声明

-- 使用第一个代码的OnUpdate脚本，确保倒计时正常工作
caution:SetScript("OnUpdate", function()
    if not caution:IsShown() then return end
    if not this.elapsed then this.elapsed = 0 end
    
    -- 处理颜色渐变
    if isFadingOut then
        this.elapsed = this.elapsed + arg1
    else
        this.elapsed = this.elapsed - arg1
    end
    if this.elapsed >= 1 then
        this.elapsed = 1
        isFadingOut = false
    elseif this.elapsed <= 0 then
        isFadingOut = true
        this.elapsed = 0
    end
    
    -- 处理倒计时
    if countdownActive then
        countdownTime = countdownTime - arg1
        if countdownTime <= 0 then
            countdownActive = false
            caution:Hide()
            if hotelButton then hotelButton:Hide() end
            -- 注意：这里不停止盯 buff —— 万一是基准偏短，还能把真实间隔学回来
        end
        -- 更新倒计时文本
        local currentText = caution.string:GetText()
        if currentText then
            local prefix = string.match(currentText, "(.+)，还有%d+秒")
            if prefix then
                caution.string:SetText(prefix .. "，还有" .. math.floor(countdownTime) .. "秒")
            end
        end
        
        -- 当倒计时小于炉石施法时间时隐藏炉石按钮（点了也来不及）
        if countdownTime < HEARTH_CAST_TIME and hotelButton and hotelButton:IsShown() then
            hotelButton:Hide()
        end
    end
    
    caution.string:SetTextColor(this.elapsed, 1, 0, this.elapsed)
end)

function Automaton_WorldBuffs:CHAT_MSG_CHANNEL()
    if not self.faction then self.faction = UnitFactionGroup("player") end
    if arg9 and string.lower(arg9) == "lft" then
        -- 生效广播（谁在城里看着 buff 真生效就播一次），收到后立刻结束还在跑的倒计时，
        -- 避免「倒计时还剩几秒、实际已经生效」这种白跑一趟炉石的情况。
        local _, _, castBoss, castFaction, castDelay = strfind(arg1, "^MPWB_CAST:([^:]*):([^:]*):([%d%.]+)")
        if castDelay then
            if castFaction == self.faction then
                SaveLead(castDelay)
                if countdownActive then
                    FinishCountdown("龙头已经生效了 —— 本次炉石来不及，等下一次")
                end
            end
            return
        end

        local _, _, name, faction = strfind(arg1, pattern)
        if name and faction and faction == self.faction then
            -- 起表 / 文字 / 音效 / 公会 / 炉石按钮 / 自动登出 全在 AnnounceBuff 里，
            -- 和本地听到喊话走同一条路（2 秒内去重）。
            self:AnnounceBuff(name, faction)
        end
    end
end

-- 测试命令
SLASH_TESTWORLDBUFF1 = "/wbtest"
SlashCmdList["TESTWORLDBUFF"] = function(msg)
    local faction = UnitFactionGroup("player")
    local dragonType = msg and msg ~= "" and msg or "Onyxia"
    
    if config[faction] and config[faction][dragonType] then
        -- 设置倒计时并显示（走和正式播报同一套计时，方便验证）
        BeginCountdown(dragonType, faction)
        local buffMsg = config[faction][dragonType].msg
        caution.string:SetText("注意！" .. buffMsg .. " Buff倒计时，还有" .. math.floor(countdownTime) .. "秒")
        caution:Show()
        
        PlayCustomSound()  -- 测试命令也使用统一音效函数
        print("测试世界BUFF: " .. buffMsg)
        
        -- 测试炉石按钮
        if Automaton_WorldBuffs.db.profile.showhotel then
            ShowHotelButton()
        end
        
        -- 测试自动下线功能
        if Automaton_WorldBuffs.db.profile.autoLogout or Automaton_WorldBuffs.db.profile.autoExit then
            local message = Automaton_WorldBuffs.db.profile.autoExit and 
                "测试自动退出功能已启用。将在1分钟后退出游戏。" or
                "测试自动登出功能已启用。将在1分钟后登出。"
            Automaton_WorldBuffs:Print(message)
            Automaton_WorldBuffs.logoutAt = GetTime() + 60
        end
    else
        print("无效的龙头类型，请使用 Onyxia 或 Nefarian")
    end
end

-- 龙头「喊话 -> 生效」间隔校准
-- /wblead        查看当前基准（手动 / 实测）
-- /wblead 12     固定为 12 秒
-- /wblead 0      改回自动学习（目击一次就记住真实间隔）
SLASH_WORLDBUFFLEAD1 = "/wblead"
SlashCmdList["WORLDBUFFLEAD"] = function(msg)
    local p = Automaton_WorldBuffs.db and Automaton_WorldBuffs.db.profile
    if not p then
        PWBPrint("模块还没初始化完，进游戏后稍等一下再试")
        return
    end

    if not msg or msg == "" then
        local manual = (type(p.leadTime) == 'number' and p.leadTime >= LEAD_TIME_MIN) and (p.leadTime .. " 秒") or "未设置"
        local learned = type(p.learnedLead) == 'number' and string.format("%.1f 秒", p.learnedLead) or "暂无"
        PWBPrint(string.format("当前倒数基准：%.1f 秒（手动：%s / 实测：%s）", GetLeadTime(), manual, learned))
        PWBPrint("用法：/wblead 12 固定断 12 秒；/wblead 0 改回自动学习")
        if GetLeadTime() < HEARTH_CAST_TIME then
            PWBPrint(string.format("提醒：基准小于炉石施法时间 %d 秒，插翅也来不及，只能提前在城里等", HEARTH_CAST_TIME))
        end
        return
    end

    local n = tonumber(msg)
    if not n or n < 0 then
        PWBPrint("请输入数字：/wblead 12 或 /wblead 0")
        return
    end

    p.leadTime = n
    if n >= LEAD_TIME_MIN then
        PWBPrint("龙头倒计时已固定为 " .. n .. " 秒")
    else
        p.learnedLead = nil
        PWBPrint("已切换为自动学习：下次你在城里目击龙头，会把真实间隔记下来")
    end
end