assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Plates")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	["Plates"] = "姓名板自动管理",
	["Hides player name in city and shows name plates in combat."] = "主城/副本隐藏玩家名字，战斗中自动显示姓名板",
	["Hide player name in city"] = "主城隐藏玩家名字",
	["Show name plates in combat"] = "战斗中显示姓名板",
	["Hide player name in instance"] = "副本隐藏玩家名字",
	["Add current zone to hide list"] = "添加当前位置隐藏",
	["Custom hide zones"] = "自定义位置列表",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_Plates = Automaton:NewModule("Plates")
Automaton_Plates.modulename = L["Plates"]
Automaton_Plates.moduledesc = L["Hides player name in city and shows name plates in combat."]
Automaton_Plates.options = {
	hidePlayerNameInCity = {
		type = "toggle",
		name = L["Hide player name in city"],
		desc = "在主城中自动隐藏玩家名字",
		get = function() return Automaton_Plates.db.profile.hidePlayerNameInCity end,
		set = function(v) 
			Automaton_Plates.db.profile.hidePlayerNameInCity = v
			Automaton_Plates:CheckZone()
		end,
		order = 2,
	},
	hidePlayerNameInInstance = {
		type = "toggle",
		name = L["Hide player name in instance"],
		desc = "在副本（地下城/团队）中自动隐藏玩家名字，离开副本后恢复",
		get = function() return Automaton_Plates.db.profile.hidePlayerNameInInstance end,
		set = function(v)
			Automaton_Plates.db.profile.hidePlayerNameInInstance = v
			Automaton_Plates:CheckZone()
		end,
		order = 3,
	},
	showNameplatesInCombat = {
		type = "toggle",
		name = L["Show name plates in combat"],
		desc = "战斗中自动显示姓名板，非战斗中自动隐藏",
		get = function() return Automaton_Plates.db.profile.showNameplatesInCombat end,
		set = function(v)
			local wasEnabled = Automaton_Plates.db.profile.showNameplatesInCombat
			Automaton_Plates.db.profile.showNameplatesInCombat = v

			if wasEnabled and not v then
				Automaton_Plates:RestoreNameplatesToOriginal(true)
			elseif not wasEnabled and v then
				Automaton_Plates:CheckCombatState()
			end
		end,
		order = 4
	},
	addCurrentZone = {
		type = "execute",
		name = L["Add current zone to hide list"],
		buttonText = "添加",
		desc = "获取当前位置并加入自定义隐藏列表，进入该位置后自动隐藏玩家名字（姓名板不受影响）",
		order = 5,
		func = function() Automaton_Plates:AddCurrentZone() end,
	},
	customHideZones = {
		type = "group",
		name = L["Custom hide zones"],
		desc = "列表中的位置会自动隐藏玩家名字，点击右侧删除按钮移除",
		order = 6,
		args = {}, -- 动态填充（RebuildCustomZoneArgs）
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Plates:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("Plates")
	Automaton:RegisterDefaults("Plates", "profile", {
		disabled = true,
		hidePlayerNameInCity = false,
		showNameplatesInCombat = false,
		hidePlayerNameInInstance = false,
		playerNameSettingInWild = "1", -- 野外玩家名字显示设置
		playerNameSettingInCity = "0", -- 主城玩家名字显示设置
		playerNameSettingInInstance = "0", -- 副本玩家名字显示设置
		customHideZones = {}, -- 自定义隐藏玩家名字的位置列表
	})
	Automaton:SetDisabledAsDefault(self, "Plates")

	self:RegisterOptions(self.options)

	-- 根据存档生成自定义位置列表的选项行
	self:RebuildCustomZoneArgs()
	
	self.cityZones = {
		["暴风城"] = true, ["铁炉堡"] = true, ["达纳苏斯"] = true, 
		["冬幕谷"] = true, ["奥格瑞玛"] = true, ["雷霆崖"] = true, ["幽暗城"] = true,
		-- 如果需要可以添加更多主城区域
		["艾萨拉"] = false, -- 示例：非主城区域
	}
	
	self.currentZone = nil
	self.initialized = false
	self.hasSavedOriginalNameplates = false
	self.inCombat = false
	self.nameplatesForcedByCombat = false
	self.originalNameplateSettings = nil
	self.zoneHideActive = false -- 当前处于自定义隐藏位置中
end

function Automaton_Plates:OnEnable()
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	
	self.initialized = false
	-- 延迟初始化，确保游戏完全加载
	self:ScheduleEvent(function()
		self.initialized = true
		self:SaveOriginalNameplates()
		self:CheckCustomZone()
		self:CheckZone()
		self:CheckCombatState()
	end, 2)
end

function Automaton_Plates:OnDisable()
	self.initialized = false
	self.zoneHideActive = false
	self:RestorePlayerName()
	self:RestoreNameplatesToOriginal(true)
	self:UnregisterAllEvents()
	self:CancelScheduledEvent("Automaton_Plates_CheckManualChange")
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_Plates:ZONE_CHANGED_NEW_AREA()
	if self.initialized then
		self:CheckCustomZone()
		self:CheckZone()
		-- 加载屏后时序兜底：进出副本时 IsInInstance/ZoneText 可能滞后，延迟再校验一次
		self:ScheduleEvent(function()
			if self.initialized then
				self:CheckCustomZone()
				self:CheckZone()
			end
		end, 1)
	end
end

-- 子区域切换（如从荆棘谷走进藏宝海湾，大区域不变，只触发 ZONE_CHANGED）
function Automaton_Plates:ZONE_CHANGED()
	if self.initialized then
		self:CheckCustomZone()
	end
end

Automaton_Plates.ZONE_CHANGED_INDOORS = Automaton_Plates.ZONE_CHANGED

function Automaton_Plates:PLAYER_ENTERING_WORLD()
	self:ScheduleEvent(function()
		if not self.initialized then
			self.initialized = true
			self:SaveOriginalNameplates()
		end
		self:CheckCustomZone()
		self:CheckZone()
		self:CheckCombatState()
	end, 0.5)
end

function Automaton_Plates:PLAYER_REGEN_ENABLED()
	self.inCombat = false
	if self.initialized then
		self:CheckCombatState()
	end
end

function Automaton_Plates:PLAYER_REGEN_DISABLED()
	self.inCombat = true
	if self.initialized then
		self:CheckCombatState()
	end
end

------------------------------
--      Custom Functions    --
------------------------------

function Automaton_Plates:SaveOriginalNameplates()
	if self.hasSavedOriginalNameplates then
		return
	end
	self.originalNameplateSettings = { state = true }
	self.hasSavedOriginalNameplates = true
end

function Automaton_Plates:RestoreNameplatesToOriginal(force)
	if not force and self.db.profile.showNameplatesInCombat then
		return
	end
	ShowNameplates()
	self.nameplatesForcedByCombat = false
end

-- 是否处于地下城/团队副本中（战场 pvp 不算副本）
function Automaton_Plates:IsInDungeonInstance()
	if type(IsInInstance) ~= "function" then
		return false
	end
	local inInstance, instanceType = IsInInstance()
	if not inInstance then return false end
	if instanceType == nil or instanceType == "party" or instanceType == "raid" then
		return true
	end
	return false
end

-- 检查当前区域并处理玩家名字显示
function Automaton_Plates:CheckZone()
	if not self.initialized then return end

	local zone = GetZoneText()
	local isInCity = self.cityZones[zone] or false
	local inDungeon = self:IsInDungeonInstance()

	-- 判定当前状态：主城 / 副本 / 野外（三者互斥）
	local state = "wild"
	if isInCity then
		state = "city"
	elseif inDungeon then
		state = "instance"
	end
	self.currentZone = state

	-- 自定义位置优先：列表中的位置直接隐藏玩家名字（优先于主城/副本/野外逻辑）
	if self.zoneHideActive then
		SetCVar("UnitNamePlayer", "0")
		return
	end

	-- 根据模块设置决定是否处理玩家名字显示
	if self.db.profile.hidePlayerNameInCity and state == "city" then
		-- 进入主城：设置玩家名字为隐藏
		SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInCity)
	elseif self.db.profile.hidePlayerNameInInstance and state == "instance" then
		-- 进入副本：设置玩家名字为隐藏
		SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInInstance)
	else
		-- 野外，或对应功能未开启：恢复为野外设置
		SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInWild)
	end
end

-- 检查战斗状态
function Automaton_Plates:CheckCombatState()
	if not self.initialized then return end

	if self.db.profile.showNameplatesInCombat then
		if self.inCombat then
			self:ShowNameplatesInCombat()
		else
			self:HideNameplatesOutOfCombat()
		end
	else
		self:RestoreNameplatesToOriginal()
	end
end

-- 恢复玩家名字显示
function Automaton_Plates:RestorePlayerName()
	-- 总是恢复为野外设置
	SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInWild)
end

-- 显示战斗中的姓名板
function Automaton_Plates:ShowNameplatesInCombat()
	if not self.hasSavedOriginalNameplates then
		self:SaveOriginalNameplates()
	end
	ShowNameplates()
	self.nameplatesForcedByCombat = true
end

-- 非战斗中隐藏姓名板
function Automaton_Plates:HideNameplatesOutOfCombat()
	if not self.hasSavedOriginalNameplates then
		self:SaveOriginalNameplates()
	end
	HideNameplates()
	self.nameplatesForcedByCombat = true
end

-- 添加一个手动切换玩家名字的函数（可选）
function Automaton_Plates:TogglePlayerName()
	local current = GetCVar("UnitNamePlayer")
	if current == "1" then
		SetCVar("UnitNamePlayer", "0")
	else
		SetCVar("UnitNamePlayer", "1")
	end
end

------------------------------
--   自定义位置隐藏玩家名字   --
------------------------------

-- 重新生成"自定义位置列表"的选项行（每行：区域名 + 删除按钮）
function Automaton_Plates:RebuildCustomZoneArgs()
	local args = self.options.customHideZones.args
	for k in pairs(args) do
		args[k] = nil
	end
	-- 收集后按名称排序，保证每次渲染顺序一致（不依赖 pairs 遍历序）
	local zones = {}
	for zone in pairs(self.db.profile.customHideZones) do
		table.insert(zones, zone)
	end
	table.sort(zones)
	for i = 1, table.getn(zones) do
		local zone = zones[i]
		args["zone" .. i] = {
			type = "execute",
			name = zone,
			buttonText = "删除",
			desc = "从自定义隐藏列表移除 " .. zone,
			order = i,
			func = function() Automaton_Plates:RemoveCustomZone(zone) end,
		}
	end
end

-- 获取当前精确位置：优先子区域（如藏宝海湾），无子区域时回退大区域（如荆棘谷）
function Automaton_Plates:GetCurrentLocationKey()
	local sub = GetSubZoneText()
	if sub and sub ~= "" then
		return sub
	end
	return GetZoneText()
end

-- 添加当前位置到自定义隐藏列表
function Automaton_Plates:AddCurrentZone()
	local zone = self:GetCurrentLocationKey()
	if not zone or zone == "" then
		self:print("无法获取当前位置", L["Plates"])
		return
	end
	if self.db.profile.customHideZones[zone] then
		self:print(zone .. " 已在隐藏列表中", L["Plates"])
		return
	end
	self.db.profile.customHideZones[zone] = true
	self:print("已添加 " .. zone .. " 到玩家名字隐藏列表", L["Plates"])
	self:RebuildCustomZoneArgs()
	-- 立即生效：当前位置隐藏玩家名字（走 CheckZone 统一出口）
	self.zoneHideActive = true
	if self.initialized then
		self:CheckZone()
	end
	self:RefreshPanel()
end

-- 从自定义隐藏列表移除位置
function Automaton_Plates:RemoveCustomZone(zone)
	if not self.db.profile.customHideZones[zone] then
		return
	end
	self.db.profile.customHideZones[zone] = nil
	self:print("已从玩家名字隐藏列表移除 " .. zone, L["Plates"])
	self:RebuildCustomZoneArgs()
	-- 若删的就是当前位置，立即恢复玩家名字（交给 CheckZone 按主城/副本/野外逻辑决定）
	local sub = GetSubZoneText()
	if (sub and sub ~= "" and sub == zone) or GetZoneText() == zone then
		self.zoneHideActive = false
		if self.initialized then
			self:CheckZone()
		else
			SetCVar("UnitNamePlayer", self.db.profile.playerNameSettingInWild)
		end
	end
	self:RefreshPanel()
end

-- 检查当前位置是否在自定义隐藏列表中，切换玩家名字隐/显状态
function Automaton_Plates:CheckCustomZone()
	if not self.initialized then return end

	-- 列表条目可能是子区域（贸易区）或大区域（暴风城），两者任一命中即隐藏
	local sub = GetSubZoneText()
	local zone = GetZoneText()
	local inCustom = (sub and sub ~= "" and self.db.profile.customHideZones[sub]) or self.db.profile.customHideZones[zone]
	inCustom = inCustom and true or false
	if inCustom == self.zoneHideActive then
		return
	end
	self.zoneHideActive = inCustom

	-- 玩家名字统一由 CheckZone 决定（自定义位置优先分支已在其内部）
	self:CheckZone()
end

-- 面板正在显示本模块时原地刷新（增删列表行后调用）
function Automaton_Plates:RefreshPanel()
	if Automaton.mainFrame and Automaton.mainFrame:IsShown() and Automaton.selectedModule == "Plates" then
		Automaton:RefreshModuleSettings("Plates")
	end
end