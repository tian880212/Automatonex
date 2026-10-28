assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_LootBOP")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	["LootBOP"] = "团队拾取确认",
	["Ignore BOP confirm message"] = "自动确认装绑物品的拾取",
	["Confirm in party/raid"] = "队伍/团队中也自动确认",
	["Also auto-confirm BOP loot when in a party or raid"] = "在小队或团队中拾取装绑物品时也自动确认",
} end)



----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_LootBOP = Automaton:NewModule("LootBOP")
Automaton_LootBOP.modulename = L["LootBOP"]
Automaton_LootBOP.moduledesc = L["Ignore BOP confirm message"]
Automaton_LootBOP.options = {
	confirmInGroup = {
		type = "toggle",
		name = L["Confirm in party/raid"],
		desc = L["Also auto-confirm BOP loot when in a party or raid"],
		order = 1,
		get = function() return Automaton_LootBOP.db.profile.confirmInGroup end,
		set = function(v) Automaton_LootBOP.db.profile.confirmInGroup = v end,
	},
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_LootBOP:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("LootBOP")
	Automaton:RegisterDefaults("LootBOP", "profile", {
		disabled = true,
		confirmInGroup = false,
	})
	Automaton:SetDisabledAsDefault(self, "LootBOP")

	self:RegisterOptions(self.options)
end

function Automaton_LootBOP:OnEnable()
	self:RegisterEvent("LOOT_BIND_CONFIRM")
end

function Automaton_LootBOP:OnDisable()
	self:UnregisterAllEvents()
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_LootBOP:LOOT_BIND_CONFIRM(slot)
	-- 在队伍/团队中，只有勾选了"队伍/团队中也自动确认"才自动确认
	local inGroup = GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
	if inGroup and not self.db.profile.confirmInGroup then
		return
	end

	-- 防重入：正在自动确认时忽略后续触发，避免连续多件 BoP 竞态
	if self.confirming then
		return
	end

	self.confirming = true
	self:Debug("Looting...")

	-- 参考 AutoNeed 的异步 + pcall 保护，延迟一点再操作弹窗，避开客户端弹窗尚未就绪的时序
	C_Timer.After(0.01, function()
		pcall(function()
			local dialog = StaticPopup_Show("LOOT_BIND")
			if dialog then
				dialog.data = slot
				StaticPopup1Button1:Click()
			end
		end)
		self.confirming = false
	end)
end