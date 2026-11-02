assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_AutoShout")
local timers = {}          -- 每组喊话各自的定时器句柄
local DEFAULT_SHOUT_SETS = 1   -- 新角色默认只给 1 组喊话（需要时在面板里添加）
local MAX_SHOUT_SETS = 10      -- 最多可添加的喊话组数
local DEFAULT_ITEM_COUNT = 1   -- 物品列表默认只显示 1 条
local MAX_ITEMS = 10           -- 物品列表上限（对应 {item1}~{item10}）
local DEFAULT_REPLY_COUNT = 1  -- 自动回复默认只显示 1 条（第 1 条固定）
local MAX_REPLY_PAIRS = 10     -- 每个角色最多可添加的「暗号 -> 回复」配对数
local playerName = UnitName("player")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["AutoShout"] = "AutoShout",
		["Automatically send messages to specified channel at intervals"] = "Automatically send messages to specified channel at intervals",
		["Enable AutoShout"] = "Enable AutoShout",
		["Turn on/off automatic shouting"] = "Turn on/off automatic shouting",
		["Message"] = "Message",
		["Set the message to be sent"] = "Set the message to be sent",
		["Interval"] = "Interval (sec)",
		["Set the interval between messages (in seconds)"] = "Set the interval between messages (in seconds)",
		["In Combat"] = "In Combat (Shout)",
		["Allow shouting while in combat"] = "Allow shouting while in combat",
		["Channel"] = "Channel",
		["Select the channel to send messages"] = "Select the channel to send messages",
		["Yell"] = "Yell",
		["Say"] = "Say",
		["Party"] = "Party",
		["Guild"] = "Guild",
		["World"] = "World",
		["Hardcore"] = "Hardcore",
		["Item ID"] = "Item ID",
		["Set the item ID to link in messages (item does not need to be owned)"] = "Set the item ID to link in messages (item does not need to be owned, resolved via client cache or pfQuest database)",
		["Item List"] = "Item List",
		["Item"] = "Item",
		["Insert"] = "Insert",
		["Insert tip"] = "Insert into the message box you edited last:",
		["Add Item"] = "Add item",
		["Add Item desc"] = "Append a new item slot at the end of the list",
		["First Item Locked"] = "The first item slot is permanent and cannot be deleted",
		["Item list full"] = "Too many items (max %d)",
		["Reply"] = "Reply",
		["Add Reply"] = "Add reply",
		["Add Reply desc"] = "Append a new passphrase-rule pair at the end of the list",
		["First Reply Locked"] = "The first reply pair is permanent and cannot be deleted",
		["Reply pairs full"] = "Too many reply pairs (max %d)",
		["Shout"] = "Shout",
		["Shout List"] = "Shout List",
		["Add Shout"] = "Add shout",
		["Add Shout desc"] = "Append a new shout set at the end of the list",
		["First Shout Locked"] = "The first shout set is permanent and cannot be deleted",
		["Move Up"] = "Move up",
		["Move Down"] = "Move down",
		["Delete"] = "Delete",
		["Shout sets full"] = "Too many shout sets (max %d)",
		["Configure and enable this shout set"] = "Configure and enable this set of auto shouting",
		["Set shout content for this set"] = "Set the message to be sent for this set",
		["AutoReply"] = "AutoReply",
		["Settings for automatic whisper reply"] = "Settings for automatic whisper reply",
		["Enable AutoReply"] = "Enable AutoReply",
		["Turn on/off automatic whisper reply"] = "Turn on/off automatic whisper reply",
		["Reply Message"] = "Reply Message",
		["Set the message to reply with (supports {item1}~{item10})"] = "Set the message to reply with (supports {item1}~{item10})",
		["Reply in Combat"] = "Reply in Combat",
		["Allow replying while in combat"] = "Allow replying while in combat",
		["Passphrase"] = "Passphrase",
		["Only reply when the whisper matches this passphrase (leave empty to reply to all)"] = "Only reply when the whisper matches this passphrase (leave empty to reply to all)",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["AutoShout"] = "自动喊话",
		["Automatically send messages to specified channel at intervals"] = "按指定间隔自动向指定频道发送消息",
		["Enable AutoShout"] = "启用自动喊话",
		["Turn on/off automatic shouting"] = "开启/关闭自动喊话功能",
		["Message"] = "消息内容",
		["Set the message to be sent"] = "设置要发送的消息内容，{item1}{item2}为物品链接格式",
		["Interval"] = "间隔时间(秒)",
		["Set the interval between messages (in seconds)"] = "设置消息发送间隔时间(秒)",
		["In Combat"] = "战斗中喊话",
		["Allow shouting while in combat"] = "允许在战斗中继续发送喊话消息",
		["Channel"] = "目标频道",
		["Select the channel to send messages"] = "选择发送消息的目标频道",
		["Yell"] = "喊话频道",
		["Say"] = "说",
		["Party"] = "队伍",
		["Guild"] = "公会",
		["World"] = "世界频道",
		["Hardcore"] = "硬核",
		["Item ID"] = "物品ID",
		["Set the item ID to link in messages (item does not need to be owned)"] = "设置要链接的物品ID（无需背包中持有该物品）；名称优先取客户端缓存，其次借用pfQuest物品名称库",
		["Item List"] = "物品列表",
		["Item"] = "物品",
		["Insert"] = "插入",
		["Insert tip"] = "插入到最近编辑的消息框：",
		["Add Item"] = "添加一个物品",
		["Add Item desc"] = "在列表末尾新增一个物品位",
		["First Item Locked"] = "第 1 个物品为固定项，不能删除（可以清空ID或调整顺序）",
		["Item list full"] = "物品已达上限（最多 %d 个）",
		["Reply"] = "回复",
		["Add Reply"] = "添加一条自动回复",
		["Add Reply desc"] = "在列表末尾新增一组「暗号 -> 回复」配置",
		["First Reply Locked"] = "第 1 条为固定项，不能删除（可以清空暗号或回复内容）",
		["Reply pairs full"] = "自动回复已达上限（最多 %d 条）",
		["Shout"] = "自动喊话",
		["Shout List"] = "喊话列表",
		["Add Shout"] = "添加一条喊话",
		["Add Shout desc"] = "在列表末尾新增一组喊话配置",
		["First Shout Locked"] = "第 1 组为固定组，不能删除（需要时可以清空内容或取消启用）",
		["Move Up"] = "上移",
		["Move Down"] = "下移",
		["Delete"] = "删除",
		["Shout sets full"] = "喊话组已达上限（最多 %d 组）",
		["Configure and enable this shout set"] = "配置并启用这一组自动喊话",
		["Set shout content for this set"] = "设置这一组要发送的消息内容，{item1}{item2}为物品链接格式",
		["AutoReply"] = "自动回复",
		["Settings for automatic whisper reply"] = "自动回复密语的设置",
		["Enable AutoReply"] = "启用自动回复",
		["Turn on/off automatic whisper reply"] = "开启/关闭自动回复密语功能",
		["Reply Message"] = "回复内容",
		["Set the message to reply with (supports {item1}~{item10})"] = "设置自动回复的内容（支持{item1}~{item10}物品链接）",
		["Reply in Combat"] = "战斗中回复",
		["Allow replying while in combat"] = "允许在战斗中自动回复密语",
		["Passphrase"] = "暗号",
		["Only reply when the whisper matches this passphrase (leave empty to reply to all)"] = "填写后仅当密语内容与暗号完全一致时才回复；留空则回复所有密语",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_AutoShout = Automaton:NewModule("AutoShout")
Automaton_AutoShout.modulename = L["AutoShout"]
Automaton_AutoShout.moduledesc = L["Automatically send messages to specified channel at intervals"]

-- 模块总开关查询：框架（AceModuleCore 封装）没有模块级的 IsEnabled 方法，
-- 必须走 Automaton:IsModuleActive(self)，它还会按「按角色 / 按账户」的存储范围判断。
local function ModuleEnabled()
	return Automaton:IsModuleActive(Automaton_AutoShout)
end

-- 频道选项（各组喊话共用）
local channelValidate = {
	["yell"] = L["Yell"],
	["say"] = L["Say"],
	["party"] = L["Party"],
	["guild"] = L["Guild"],
	["world"] = L["World"],
	["Hardcore"] = L["Hardcore"]
}

----------------------------------------------------------
--   一键插入物品：登记消息输入框 + 插入 {itemN} 占位符   --
----------------------------------------------------------

-- 最近一次获得焦点的字段（kind .. index），以及每个字段对应的「最新」输入框
-- 面板每次重建都会生成新的输入框，所以这里按字段保存引用，插入时永远用最新的那个，
-- 避免插入到上一次渲染遗留的隐藏输入框里（表现为"点了插入但界面没变化"）。
local lastFieldKey = nil
local editByField = {}

-- 消息输入框登记：Core 的文本框支持 opt.onCreateEdit(edit) 钩子，渲染时把引用交回来，
-- 这里顺便接管「失焦存光标」与「直接落库」两件事，供物品插入按钮使用。
local function RegisterMessageEdit(kind, index, edit)
	local key = kind .. index
	local rec = editByField[key]
	if not rec then
		rec = {}
		editByField[key] = rec
	end
	rec.edit = edit

	-- 直接写库（Core 的 CommitTextEdit 是局部函数，这里按 kind 自行落库）
	edit.autoShoutCommit = function()
		local text = edit:GetText() or ""
		if kind == "shout" then
			Automaton_AutoShout.db.char.shouts[index].message = text
		else
			Automaton_AutoShout:EnsureReplyPairs()[index].message = text
		end
	end

	-- 点进输入框即记为插入目标
	edit:SetScript("OnEditFocusGained", function()
		lastFieldKey = key
		rec.edit = edit
		rec.cursor = nil -- 重新聚焦后以输入框实际光标为准
	end)

	-- 失焦时先存一份光标位置：点「插入」按钮会让输入框先失焦再执行按钮回调，
	-- 此时再取光标可能已被重置，所以提前记下来。
	local origLost = edit:GetScript("OnEditFocusLost")
	edit:SetScript("OnEditFocusLost", function()
		if edit.GetCursorPosition then
			local ok, pos = pcall(edit.GetCursorPosition, edit)
			if ok and type(pos) == "number" then
				rec.cursor = pos
			end
		end
		if origLost then origLost() end
	end)
end

-- 面板重建时清空输入框登记表：旧输入框已经被销毁，
-- 留着会在「插入」时往隐藏的旧框里写，界面看起来毫无反应。
local function ResetMessageEditRegistry()
	for k in pairs(editByField) do
		editByField[k] = nil
	end
	lastFieldKey = nil
end

-- 把 {itemN} 插入到最近编辑的消息输入框的光标处，并立即保存
-- 兼容：Lua 5.0 用 string.len/string.sub，不用 #
function Automaton_AutoShout:InsertItemToken(index)
	local rec = lastFieldKey and editByField[lastFieldKey]
	local edit = rec and rec.edit
	if not edit then
		Automaton:print("请先点开一个消息输入框（喊话内容或回复内容），把光标放到要插入的位置，再点「插入」", "自动喊话")
		return
	end

	local token = "{item" .. index .. "}"
	local text = edit:GetText() or ""

	local pos = rec.cursor
	if type(pos) ~= "number" or pos < 0 or pos > string.len(text) then
		-- 没有可用的光标位置（未聚焦过 / 面板刚重建）：默认追加到末尾。
		-- 只有当输入框此刻持有焦点时才采信它的实时光标（未聚焦的框光标恒为 0，会插到开头）。
		pos = string.len(text)
		if edit.HasFocus and edit:HasFocus() and edit.GetCursorPosition then
			local ok, cur = pcall(edit.GetCursorPosition, edit)
			if ok and type(cur) == "number" and cur >= 0 and cur <= string.len(text) then
				pos = cur
			end
		end
	end

	local newText = string.sub(text, 1, pos) .. token .. string.sub(text, pos + 1)
	edit:SetText(newText)
	rec.cursor = pos + string.len(token)
	if edit.SetCursorPosition then
		pcall(edit.SetCursorPosition, edit, rec.cursor)
	end
	if edit.autoShoutCommit then
		edit.autoShoutCommit()
	end

	local item = self.db.profile.items[index]
	if not item or not item.itemID or item.itemID <= 0 then
		Automaton:print("已插入 " .. token .. "（物品" .. index .. " 还没设置ID，发送时不会显示链接）", "自动喊话")
	else
		Automaton:print("已插入 " .. token .. "（物品ID " .. item.itemID .. "）", "自动喊话")
	end
end

----------------------------------------------
--      喊话组管理（动态增删）               --
----------------------------------------------

-- 确保 db.char.shouts 存在、至少一组、每条字段齐全。
-- 喊话组按位置取用（timers[index] / StartTimer(index)），数组不能有空洞，
-- 所以脏数据一律补成合法条目而不是丢弃。
function Automaton_AutoShout:EnsureShoutSets()
	local shouts = self.db.char.shouts
	if type(shouts) ~= "table" then
		shouts = {}
		self.db.char.shouts = shouts
	end
	if table.getn(shouts) < 1 then
		table.insert(shouts, { enabled = false, message = "", interval = 60, channel = "yell", inCombat = false })
	end
	for i = 1, table.getn(shouts) do
		local s = shouts[i]
		if type(s) ~= "table" then
			s = { enabled = false, message = "", interval = 60, channel = "yell", inCombat = false }
			shouts[i] = s
		end
		if s.enabled == nil then s.enabled = false end
		if s.message == nil then s.message = "" end
		if s.interval == nil then s.interval = 60 end
		if s.channel == nil then s.channel = "yell" end
		if s.inCombat == nil then s.inCombat = false end
	end
	return shouts
end

function Automaton_AutoShout:GetShoutCount()
	return table.getn(self:EnsureShoutSets())
end

-- 列表变化后重启全部定时器：定时器按索引绑定到组，
-- 增删/换位后旧定时器会指向错误的组，必须整体重来。
function Automaton_AutoShout:RestartAllTimers()
	self:StopAllTimers()
	local total = self:GetShoutCount()
	for i = 1, total do
		self:StartTimer(i)
	end
end

-- 重建设置面板（延迟到下一帧，避免在按钮自己的 OnClick 里销毁自身）
-- 用 C_Timer 而不是 AceEvent 的 ScheduleEvent：模块总开关关着的时候，
-- 面板照样要能增删喊话组，不能被模块启用状态卡住。
-- restartTimers 仅在「喊话组增删/换位」时传 true：定时器按索引绑定，必须整体重排；
-- 物品列表与回复配对的变化不影响定时器，重排只会白白重置计时。
function Automaton_AutoShout:RefreshOptions(restartTimers)
	ResetMessageEditRegistry()
	local function rebuild()
		self:RegisterOptions(self:BuildOptions())
		if restartTimers and ModuleEnabled() then
			self:RestartAllTimers()
		end
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(0.05, rebuild)
	else
		rebuild()
	end
end

function Automaton_AutoShout:AddShout()
	local shouts = self:EnsureShoutSets()
	if table.getn(shouts) >= MAX_SHOUT_SETS then
		Automaton:print(string.format(L["Shout sets full"], MAX_SHOUT_SETS), "自动喊话")
		return
	end
	table.insert(shouts, { enabled = false, message = "", interval = 60, channel = "yell", inCombat = false })
	self:RefreshOptions(true)
end

-- 第一组是固定组：只允许从第 2 组往后删除
function Automaton_AutoShout:RemoveShout(index)
	local shouts = self:EnsureShoutSets()
	if index <= 1 or not shouts[index] then return end
	table.remove(shouts, index)
	self:RefreshOptions(true)
end

function Automaton_AutoShout:MoveShout(index, step)
	local shouts = self:EnsureShoutSets()
	local target = index + step
	if target < 1 or not shouts[index] or not shouts[target] then return end
	shouts[index], shouts[target] = shouts[target], shouts[index]
	self:RefreshOptions(true)
end

----------------------------------------------
--    物品列表（动态增删，{itemN} 占位符）    --
----------------------------------------------

-- 确保 profile.items 存在、至少一条、每条都有 itemID 字段。
-- 物品按位置取用（消息里的 {itemN} 中 N 就是位置），数组不能有空洞，
-- 所以脏数据一律补成合法条目而不是丢弃。
function Automaton_AutoShout:EnsureItems()
	local items = self.db.profile.items
	if type(items) ~= "table" then
		items = {}
		self.db.profile.items = items
	end
	if table.getn(items) < DEFAULT_ITEM_COUNT then
		table.insert(items, { itemID = 0 })
	end
	local i
	for i = 1, table.getn(items) do
		local it = items[i]
		if type(it) ~= "table" then
			it = { itemID = 0 }
			items[i] = it
		end
		if it.itemID == nil then it.itemID = 0 end
	end
	return items
end

function Automaton_AutoShout:GetItemCount()
	return table.getn(self:EnsureItems())
end

function Automaton_AutoShout:AddItem()
	local items = self:EnsureItems()
	if table.getn(items) >= MAX_ITEMS then
		Automaton:print(string.format(L["Item list full"], MAX_ITEMS), "自动喊话")
		return
	end
	table.insert(items, { itemID = 0 })
	self:RefreshOptions()
end

-- 第一个物品固定保留：只允许从第 2 个往后删除
function Automaton_AutoShout:RemoveItem(index)
	local items = self:EnsureItems()
	if index <= 1 or not items[index] then return end
	table.remove(items, index)
	-- 占位符按位置取值：后面的物品整体前移，消息里的 {itemN} 含义会跟着变
	Automaton:print("已删除物品" .. index .. "，后面的编号已前移，请检查消息里的 {itemN}", "自动喊话")
	self:RefreshOptions()
end

function Automaton_AutoShout:MoveItem(index, step)
	local items = self:EnsureItems()
	local target = index + step
	if target < 1 or not items[index] or not items[target] then return end
	items[index], items[target] = items[target], items[index]
	self:RefreshOptions()
end

------------------------------------------------
--      AutoReply Pairs (暗号 -> 回复) 配置      --
------------------------------------------------

-- 确保当前角色的配对表存在（每组含 passphrase 暗号 与 message 回复内容）。
-- 与喊话/物品列表一致：默认只有 1 条，需要时在面板里点「添加一条自动回复」。
function Automaton_AutoShout:EnsureReplyPairs()
	local pairsTbl = self.db.profile.autoReplyPairs[playerName]
	if type(pairsTbl) ~= "table" then
		pairsTbl = {}
		self.db.profile.autoReplyPairs[playerName] = pairsTbl
	end
	if table.getn(pairsTbl) < DEFAULT_REPLY_COUNT then
		table.insert(pairsTbl, { passphrase = "", message = "" })
	end
	local i
	for i = 1, table.getn(pairsTbl) do
		local p = pairsTbl[i]
		if type(p) ~= "table" then
			p = { passphrase = "", message = "" }
			pairsTbl[i] = p
		end
		if p.passphrase == nil then p.passphrase = "" end
		if p.message == nil then p.message = "" end
	end
	return pairsTbl
end

function Automaton_AutoShout:GetReplyCount()
	return table.getn(self:EnsureReplyPairs())
end

function Automaton_AutoShout:AddReply()
	local pairsTbl = self:EnsureReplyPairs()
	if table.getn(pairsTbl) >= MAX_REPLY_PAIRS then
		Automaton:print(string.format(L["Reply pairs full"], MAX_REPLY_PAIRS), "自动回复")
		return
	end
	table.insert(pairsTbl, { passphrase = "", message = "" })
	self:RefreshOptions()
end

-- 第一条固定保留：只允许从第 2 条往后删除
function Automaton_AutoShout:RemoveReply(index)
	local pairsTbl = self:EnsureReplyPairs()
	if index <= 1 or not pairsTbl[index] then return end
	table.remove(pairsTbl, index)
	self:RefreshOptions()
end

function Automaton_AutoShout:MoveReply(index, step)
	local pairsTbl = self:EnsureReplyPairs()
	local target = index + step
	if target < 1 or not pairsTbl[index] or not pairsTbl[target] then return end
	pairsTbl[index], pairsTbl[target] = pairsTbl[target], pairsTbl[index]
	self:RefreshOptions()
end

------------------------------
--      Options Builder      --
------------------------------

-- 每次重建面板都重新生成整份选项表：喊话组数量是可变的，
-- 和 AutoCmd 的「命令列表」保持一致的操作方式（默认 1 条，按需添加）。
function Automaton_AutoShout:BuildOptions()
	local opts = {}
	local shoutCount = self:GetShoutCount()

	opts.shoutHeader = {
		type = "header",
		name = L["Shout List"],
		order = 5,
	}

	-- 动态生成喊话组，每组独立拥有：开关 / 内容 / 间隔 / 频道 / 战斗中喊话
	for i = 1, shoutCount do
		local buttons = {}
		if i > 1 then
			table.insert(buttons, {
				name = "↑",
				tip = L["Move Up"],
				func = (function(index)
					return function() Automaton_AutoShout:MoveShout(index, -1) end
				end)(i),
			})
		end
		if i < shoutCount then
			table.insert(buttons, {
				name = "↓",
				tip = L["Move Down"],
				func = (function(index)
					return function() Automaton_AutoShout:MoveShout(index, 1) end
				end)(i),
			})
		end
		-- 第 1 组固定保留，不提供删除按钮
		if i > 1 then
			table.insert(buttons, {
				name = "×",
				tip = L["Delete"],
				func = (function(index)
					return function() Automaton_AutoShout:RemoveShout(index) end
				end)(i),
			})
		end

		opts["shout" .. i] = {
			type = "group",
			name = L["Shout"] .. " " .. i,
			desc = L["Configure and enable this shout set"],
			order = 10 + i,
			buttons = buttons,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable AutoShout"],
					desc = L["Turn on/off automatic shouting"],
					order = 1,
					get = (function(index)
						return function()
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							return s and s.enabled or false
						end
					end)(i),
					set = (function(index)
						return function(v)
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							if not s then return end
							s.enabled = v
							if v and ModuleEnabled() then
								Automaton_AutoShout:StartTimer(index)
							else
								Automaton_AutoShout:StopTimer(index)
							end
						end
					end)(i),
				},
				message = {
					type = "text",
					name = L["Message"],
					desc = L["Set shout content for this set"],
					order = 2,
					get = (function(index)
						return function()
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							return s and s.message or ""
						end
					end)(i),
					set = (function(index)
						return function(v)
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							if not s then return end
							s.message = v
							Automaton:print("已设置第" .. index .. "组喊话内容: " .. v, "自动喊话")
						end
					end)(i),
					-- 交出输入框引用，供「一键插入物品」使用；顺手加宽，长消息好编辑
					onCreateEdit = (function(index)
						return function(edit)
							edit:SetWidth(300)
							RegisterMessageEdit("shout", index, edit)
						end
					end)(i),
				},
				interval = {
					type = "range",
					name = L["Interval"],
					desc = L["Set the interval between messages (in seconds)"],
					order = 3,
					min = 60,
					max = 1800,
					step = 5,
					get = (function(index)
						return function()
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							return s and s.interval or 60
						end
					end)(i),
					set = (function(index)
						return function(v)
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							if not s then return end
							s.interval = v
							Automaton_AutoShout:RestartTimer(index)
						end
					end)(i),
				},
				channel = {
					type = "text",
					name = L["Channel"],
					desc = L["Select the channel to send messages"],
					order = 4,
					get = (function(index)
						return function()
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							return s and s.channel or "yell"
						end
					end)(i),
					set = (function(index)
						return function(v)
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							if not s then return end
							s.channel = v
						end
					end)(i),
					validate = channelValidate,
				},
				inCombat = {
					type = "toggle",
					name = L["In Combat"],
					desc = L["Allow shouting while in combat"],
					order = 5,
					get = (function(index)
						return function()
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							return s and s.inCombat or false
						end
					end)(i),
					set = (function(index)
						return function(v)
							local s = Automaton_AutoShout:EnsureShoutSets()[index]
							if not s then return end
							s.inCombat = v
						end
					end)(i),
				},
			},
		}
	end

	opts.addShout = {
		type = "execute",
		name = L["Add Shout"],
		desc = L["Add Shout desc"],
		order = 40,
		func = function() Automaton_AutoShout:AddShout() end,
	}

	opts.lockTip = {
		type = "description",
		name = L["First Shout Locked"],
		order = 41,
	}

	-- 物品列表（全局共用一套，供各组喊话与自动回复使用）
	-- 与喊话列表同样的动态样式：默认 1 条，按需添加，第 1 条固定不可删。
	opts.itemHeader = {
		type = "header",
		name = L["Item List"],
		order = 60,
	}

	local itemCount = self:GetItemCount()
	local i
	for i = 1, itemCount do
		local buttons = {}
		-- 「插入」放最左边，删除键（×）放最右，避免误点
		table.insert(buttons, {
			name = L["Insert"],
			tip = L["Insert tip"] .. " {item" .. i .. "}",
			func = (function(index)
				return function()
					Automaton_AutoShout:InsertItemToken(index)
				end
			end)(i),
		})
		if i > 1 then
			table.insert(buttons, {
				name = "↑",
				tip = L["Move Up"],
				func = (function(index)
					return function() Automaton_AutoShout:MoveItem(index, -1) end
				end)(i),
			})
		end
		if i < itemCount then
			table.insert(buttons, {
				name = "↓",
				tip = L["Move Down"],
				func = (function(index)
					return function() Automaton_AutoShout:MoveItem(index, 1) end
				end)(i),
			})
		end
		-- 第 1 个物品固定保留，不提供删除按钮
		if i > 1 then
			table.insert(buttons, {
				name = "×",
				tip = L["Delete"],
				func = (function(index)
					return function() Automaton_AutoShout:RemoveItem(index) end
				end)(i),
			})
		end

		opts["item" .. i] = {
			type = "group",
			name = L["Item"] .. " " .. i,
			inline = true,
			order = 60 + i,
			buttons = buttons,
			args = {
				itemid = {
					type = "text",
					name = L["Item ID"],
					desc = L["Set the item ID to link in messages (item does not need to be owned)"],
					usage = "<物品ID>",
					order = 1,
					get = (function(index)
						return function()
							local item = Automaton_AutoShout:EnsureItems()[index]
							return (item and item.itemID and item.itemID > 0) and tostring(item.itemID) or "0"
						end
					end)(i),
					set = (function(index)
						return function(v)
							local item = Automaton_AutoShout:EnsureItems()[index]
							if not item then return end
							local id = tonumber(v) or 0
							if id < 0 then id = 0 end
							id = math.floor(id)
							item.itemID = id
							if id > 0 then
								-- 触发服务器缓存查询，尽快让客户端拿到名称/品质
								GetItemInfo(id)
								if ModuleEnabled() then
									Automaton_AutoShout:StartItemCacheLoop()
								end
								Automaton:print("已设置物品" .. index .. "的ID: " .. id, "自动喊话")
							else
								Automaton:print("已清空物品" .. index .. "的ID（该物品不生效）", "自动喊话")
							end
						end
					end)(i),
				},
			},
		}
	end

	opts.addItem = {
		type = "execute",
		name = L["Add Item"],
		desc = L["Add Item desc"],
		order = 60 + itemCount + 1,
		func = function() Automaton_AutoShout:AddItem() end,
	}

	opts.itemLockTip = {
		type = "description",
		name = L["First Item Locked"],
		order = 60 + itemCount + 2,
	}

	opts.autoReply = {
		type = "group",
		name = L["AutoReply"],
		desc = L["Settings for automatic whisper reply"],
		-- 放在最后：物品列表的数量可变（最多 10 条，order 会到 72），
		-- 这里留足间隔，避免物品满员时「添加物品」按钮被排到自动回复下面。
		order = 100,
		args = {
			enabled = {
				type = "toggle",
				name = L["Enable AutoReply"],
				desc = L["Turn on/off automatic whisper reply"],
				order = 1,
				get = function() return Automaton_AutoShout.db.profile.autoReplyEnabled end,
				set = function(v) Automaton_AutoShout.db.profile.autoReplyEnabled = v end,
			},
			inCombat = {
				type = "toggle",
				name = L["Reply in Combat"],
				desc = L["Allow replying while in combat"],
				order = 2,
				get = function() return Automaton_AutoShout.db.profile.autoReplyInCombat end,
				set = function(v) Automaton_AutoShout.db.profile.autoReplyInCombat = v end,
			},
		},
	}

	-- 动态生成“暗号 -> 回复”配对：默认 1 条，按需添加，第 1 条固定不可删。
	-- 和喊话列表/物品列表保持一致的操作方式（↑ ↓ × 在组标题行右侧）。
	local replyCount = self:GetReplyCount()
	for i = 1, replyCount do
		local buttons = {}
		if i > 1 then
			table.insert(buttons, {
				name = "↑",
				tip = L["Move Up"],
				func = (function(index)
					return function() Automaton_AutoShout:MoveReply(index, -1) end
				end)(i),
			})
		end
		if i < replyCount then
			table.insert(buttons, {
				name = "↓",
				tip = L["Move Down"],
				func = (function(index)
					return function() Automaton_AutoShout:MoveReply(index, 1) end
				end)(i),
			})
		end
		-- 第 1 条固定保留，不提供删除按钮
		if i > 1 then
			table.insert(buttons, {
				name = "×",
				tip = L["Delete"],
				func = (function(index)
					return function() Automaton_AutoShout:RemoveReply(index) end
				end)(i),
			})
		end

		opts.autoReply.args["pair" .. i] = {
			type = "group",
			name = L["Reply"] .. " " .. i,
			inline = true,
			order = 10 + i,
			buttons = buttons,
			args = {
				passphrase = {
					type = "text",
					name = L["Passphrase"],
					desc = L["Only reply when the whisper matches this passphrase (leave empty to reply to all)"],
					order = 1,
					usage = "<暗号>",
					get = (function(index)
						return function()
							local p = Automaton_AutoShout:EnsureReplyPairs()[index]
							return p and p.passphrase or ""
						end
					end)(i),
					set = (function(index)
						return function(v)
							local p = Automaton_AutoShout:EnsureReplyPairs()[index]
							if not p then return end
							p.passphrase = v or ""
							if v and v ~= "" then
								Automaton:print("已设置第" .. index .. "组暗号: " .. v, "自动回复")
							else
								Automaton:print("已清空第" .. index .. "组暗号（该组不生效）", "自动回复")
							end
						end
					end)(i),
				},
				message = {
					type = "text",
					name = L["Reply Message"],
					desc = L["Set the message to reply with (supports {item1}~{item10})"],
					order = 2,
					get = (function(index)
						return function()
							local p = Automaton_AutoShout:EnsureReplyPairs()[index]
							return p and p.message or ""
						end
					end)(i),
					set = (function(index)
						return function(v)
							local p = Automaton_AutoShout:EnsureReplyPairs()[index]
							if not p then return end
							p.message = v or ""
							Automaton:print("已设置第" .. index .. "组回复内容: " .. (v or ""), "自动回复")
						end
					end)(i),
					-- 交出输入框引用，供「一键插入物品」使用
					onCreateEdit = (function(index)
						return function(edit)
							RegisterMessageEdit("reply", index, edit)
						end
					end)(i),
				},
			},
		}
	end

	opts.autoReply.args.addReply = {
		type = "execute",
		name = L["Add Reply"],
		desc = L["Add Reply desc"],
		order = 10 + replyCount + 1,
		func = function() Automaton_AutoShout:AddReply() end,
	}

	opts.autoReply.args.replyLockTip = {
		type = "description",
		name = L["First Reply Locked"],
		order = 10 + replyCount + 2,
	}

	return opts
end


function Automaton_AutoShout:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("AutoShout")
	-- profile 作用域：物品列表等全局共享配置；并保留旧版 shouts 结构供历史数据迁移
	Automaton:RegisterDefaults("AutoShout", "profile", {
		shouts = {
			{
				enabled = false,
				messages = {
					default = "{item1}自动喊话测试，乌龟服真好玩",
				},
				intervals = {
					default = 60,
				},
				channel = "yell",
				inCombat = false,
			},
			{
				enabled = false,
				messages = {
					default = "",
				},
				intervals = {
					default = 60,
				},
				channel = "yell",
				inCombat = false,
			},
			{
				enabled = false,
				messages = {
					default = "",
				},
				intervals = {
					default = 60,
				},
				channel = "yell",
				inCombat = false,
			},
		},
		-- 物品列表默认只有 1 条，需要更多时在面板里点「添加一个物品」
		items = {
			{ itemID = 0 },
		},
		-- 旧版固定 5 个空物品位的整理标记（每个账号一次）
		itemListPruned = false,
		autoReplyEnabled = false,
		autoReplyInCombat = false,
		autoReplyMessages = {
			default = "我正在忙，稍后回复你。",
		},
		autoReplyPassphrases = {
			default = "",
		},
		-- “暗号 -> 回复”配对，按角色分别保存（每角色默认 1 条）
		autoReplyPairs = {},
		-- 旧版单组喊话配置迁移标记
		shoutsMigrated = false,
	})
	-- char 作用域：自动喊话的完整配置，每个账号/角色独立。
	-- 默认只给 1 组，需要更多时在面板里点「添加一条喊话」。
	Automaton:RegisterDefaults("AutoShout", "char", {
		shouts = {
			{ enabled = false, message = "{item1}自动喊话测试，乌龟服真好玩", interval = 60, channel = "yell", inCombat = false },
		},
		-- 每角色一次的迁移标记（把旧的共享配置继承到本角色）
		shoutCharMigrated = false,
		-- 旧版固定 7 条回复配对的整理标记（每个角色一次）
		replyPairsPruned = false,
	})

	-- 设置模块总开关默认禁用（由 Automaton 框架管理）
	Automaton:SetDisabledAsDefault(self, "AutoShout")

	-- 迁移第一阶段：把最早的单组配置（shoutEnabled/messages/... 顶层键）合并到 profile.shouts[1]
	if not self.db.profile.shoutsMigrated then
		local p = self.db.profile
		local s1 = p.shouts[1]
		if p.shoutEnabled ~= nil then
			s1.enabled = p.shoutEnabled and true or false
		end
		if p.messages and p.messages[playerName] then
			s1.messages[playerName] = p.messages[playerName]
		end
		if p.intervals and p.intervals[playerName] then
			s1.intervals[playerName] = p.intervals[playerName]
		end
		if p.channel ~= nil then
			s1.channel = p.channel
		end
		if p.inCombat ~= nil then
			s1.inCombat = p.inCombat and true or false
		end
		-- 清理旧配置键
		p.shoutEnabled = nil
		p.messages = nil
		p.intervals = nil
		p.channel = nil
		p.inCombat = nil
		p.shoutsMigrated = true
	end

	-- 迁移第二阶段（每角色一次）：把旧的共享配置继承到本角色的 char 作用域
	-- 旧数据保留在 profile.shouts 中不删除，保证其他角色首次登录时也能继承
	if not self.db.char.shoutCharMigrated then
		local c = self.db.char
		local pShouts = self.db.profile.shouts
		local shoutTotal = self:GetShoutCount()
		for i = 1, shoutTotal do
			local src = pShouts and pShouts[i]
			local dst = c.shouts[i]
			if src and dst then
				if type(src.enabled) == "boolean" and src.enabled == true then
					dst.enabled = true
				end
				if type(src.messages) == "table" and src.messages[playerName] then
					dst.message = src.messages[playerName]
				end
				if type(src.intervals) == "table" and src.intervals[playerName] then
					dst.interval = src.intervals[playerName]
				end
				if type(src.channel) == "string" and channelValidate[src.channel] then
					dst.channel = src.channel
				end
				if type(src.inCombat) == "boolean" and src.inCombat == true then
					dst.inCombat = true
				end
			end
		end
		self.db.char.shoutCharMigrated = true
	end

	-- 兼容旧配置：补齐物品列表的 itemID 字段
	local items = self:EnsureItems()

	-- 一次性整理旧数据：旧版固定 5 个物品位里，尾部「没设置ID」的空位直接收掉，
	-- 回到「默认只显示 1 条」；有 ID 的一律保留。每个账号只做一次。
	if not self.db.profile.itemListPruned then
		while table.getn(items) > DEFAULT_ITEM_COUNT do
			local last = items[table.getn(items)]
			if last and (last.itemID == nil or last.itemID <= 0) then
				table.remove(items)
			else
				break
			end
		end
		self.db.profile.itemListPruned = true
	end

	-- 初始化“暗号 -> 回复”配对（每角色默认 1 条）
	local isNewPairs = (self.db.profile.autoReplyPairs[playerName] == nil)
	self:EnsureReplyPairs()

	-- 兼容旧配置：首次生成配对表时，把旧的单条暗号/回复迁移到第1条
	if isNewPairs then
		local oldPass = self.db.profile.autoReplyPassphrases
			and self.db.profile.autoReplyPassphrases[playerName]
		local oldMsg = self.db.profile.autoReplyMessages
			and self.db.profile.autoReplyMessages[playerName]
		local pairsTbl = self.db.profile.autoReplyPairs[playerName]
		if oldPass and oldPass ~= "" then
			pairsTbl[1].passphrase = oldPass
		end
		if oldMsg and oldMsg ~= "" then
			pairsTbl[1].message = oldMsg
		end
	end

	-- 一次性整理旧数据：旧版固定生成 7 条配对，尾部「暗号和回复都为空」的收掉，
	-- 只留 1 条；有内容的一律保留。每角色只做一次。
	if not self.db.char.replyPairsPruned then
		local pairsTbl = self:EnsureReplyPairs()
		while table.getn(pairsTbl) > DEFAULT_REPLY_COUNT do
			local last = pairsTbl[table.getn(pairsTbl)]
			if last
				and (last.passphrase == nil or last.passphrase == "")
				and (last.message == nil or last.message == "") then
				table.remove(pairsTbl)
			else
				break
			end
		end
		self.db.char.replyPairsPruned = true
	end

	-- 一次性整理旧数据：旧版固定生成 3 组，其中尾部「未启用 + 没内容」的空组直接收掉，
	-- 回到「默认只显示 1 条」的状态；有内容的组一律保留。每角色只做一次。
	if not self.db.char.shoutListPruned then
		local shouts = self:EnsureShoutSets()
		while table.getn(shouts) > DEFAULT_SHOUT_SETS do
			local last = shouts[table.getn(shouts)]
			if last and last.enabled ~= true and (last.message == nil or last.message == "") then
				table.remove(shouts)
			else
				break
			end
		end
		self.db.char.shoutListPruned = true
	end

	self:RegisterOptions(self:BuildOptions())
end

function Automaton_AutoShout:OnEnable()
	-- 模块总开关已打开，注册必要事件
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("CHAT_MSG_WHISPER")  -- 始终注册密语事件，内部由 autoReplyEnabled 控制

	-- 根据各组 enabled 启动各自的喊话定时器
	local shoutTotal = self:GetShoutCount()
	for i = 1, shoutTotal do
		self:StartTimer(i)
	end

	-- 启动物品ID预缓存循环（仅当配置了物品ID模式时才实际工作）
	self:StartItemCacheLoop()

	-- 向 WIM 暴露两个与加载/事件顺序无关的“静默弹窗”判定接口：
	--   WIM_AutoReply_IsPassphrase(content) -> true 表示该内容命中某组暗号
	--   WIM_AutoReply_IsSilentUser(user)    -> true 表示该联系人处于自动回复静默期（3秒内）
	-- WIM 在 PostMessage 中会自行调用（若存在），据此决定对原本未打开的窗口是否弹窗。
	local mod = self
	WIM_AutoReply_SilentUsers = WIM_AutoReply_SilentUsers or {}
	function WIM_AutoReply_IsPassphrase(content)
		return mod:MatchReplyPair(content) ~= nil
	end
	function WIM_AutoReply_IsSilentUser(user)
		if not user or not WIM_AutoReply_SilentUsers then return false end
		local t = WIM_AutoReply_SilentUsers[user]
		if not t then return false end
		if (mod.currentTime or GetTime()) - t > 3 then
			WIM_AutoReply_SilentUsers[user] = nil
			return false
		end
		return true
	end
	-- 定时清理过期的静默用户，避免表无限增长
	self:ScheduleRepeatingEvent(function()
		local now = GetTime()
		for k, v in pairs(WIM_AutoReply_SilentUsers or {}) do
			if now - v > 5 then WIM_AutoReply_SilentUsers[k] = nil end
		end
	end, 10)
end

function Automaton_AutoShout:OnDisable()
	self:UnregisterAllEvents()
	self:StopAllTimers()
	self:StopItemCacheLoop()
end

------------------------------
--      Timer Functions      --
------------------------------

-- 启动第 index 组喊话的定时器（仅当该组已启用）
function Automaton_AutoShout:StartTimer(index)
	local s = self.db.char.shouts[index]
	if s and s.enabled and not timers[index] then
		timers[index] = self:ScheduleRepeatingEvent(self.DoShout, s.interval, self, index)
	end
end

-- 停止第 index 组喊话的定时器
function Automaton_AutoShout:StopTimer(index)
	if timers[index] then
		self:CancelScheduledEvent(timers[index])
		timers[index] = nil
	end
end

-- 停止所有喊话定时器。
-- 这里按上限遍历而不是按当前组数：删掉靠后的组之后，
-- 旧索引上的定时器仍留在 timers 表里，必须一并清掉。
function Automaton_AutoShout:StopAllTimers()
	local i
	for i = 1, MAX_SHOUT_SETS do
		self:StopTimer(i)
	end
end

-- 重启第 index 组喊话的定时器（修改间隔后调用）
function Automaton_AutoShout:RestartTimer(index)
	self:StopTimer(index)
	-- 模块总开关关着的时候不要偷偷把定时器挂起来
	if ModuleEnabled() then
		self:StartTimer(index)
	end
end

------------------------------
--      Event Handlers      --
------------------------------

-- 暗号匹配辅助函数（与 CHAT_MSG_WHISPER 里的判断完全一致），
-- 由自动回复处理器和 WIM 的内容谓词共用，保证两端规则统一：
--   - 去首尾空格；长度≥14 直接不匹配；
--   - 遍历当前角色的全部配对（数量可变），空暗号组跳过；非空暗号且完全相等则命中。
-- 返回：命中组的回复内容（字符串），未命中返回 nil。
function Automaton_AutoShout:MatchReplyPair(message)
	local trimmedMsg = string.gsub(message or "", "^%s*(.-)%s*$", "%1")
	if string.len(trimmedMsg) >= 14 then
		return nil
	end
	local pairsTbl = self:EnsureReplyPairs()
	local i
	for i = 1, table.getn(pairsTbl) do
		local p = pairsTbl[i]
		local passphrase = string.gsub((p and p.passphrase) or "", "^%s*(.-)%s*$", "%1")
		if passphrase ~= "" and trimmedMsg == passphrase then
			local msg = (p and p.message) or ""
			return msg ~= "" and msg or nil
		end
	end
	return nil
end

-- 解析第 index 个物品的链接（纯ID模式，无需背包持有），链接格式与 AtlasLoot 聊天链接完全一致：
--     颜色 .. "|Hitem:ID:0:0:0|h[名称]|h|r"（本服已验证可直接 SendChatMessage 发送）
--   名称/品质的获取优先级：
--     1) 客户端缓存 GetItemInfo（返回官方链接与品质，颜色最准确）
--     2) pfQuest 服务器物品名称库 pfDB["items"]（无需缓存即可构造链接，颜色用白色）
--     3) 均未命中时调用 GetItemInfo 触发客户端向服务器请求缓存，本次返回 nil（显示占位符）
--   itemID 为 0 时表示该物品未配置，返回 nil
local function ResolveItemLink(index)
	local item = Automaton_AutoShout.db.profile.items[index]
	if not item or not item.itemID or item.itemID <= 0 then
		return nil
	end

	local id = item.itemID
	-- 1) 客户端已缓存
	local name, itemLink, quality = GetItemInfo(id)
	if name and itemLink then
		local _, _, _, color = GetItemQualityColor(quality or 0)
		return color .. "|H" .. itemLink .. "|h[" .. name .. "]|h|r"
	end
	-- 2) pfQuest 名称库兜底（兼容 loc 映射与语言键两种存法）
	if pfDB and pfDB["items"] then
		local locTbl = pfDB["items"]["loc"] or pfDB["items"][GetLocale() or "zhCN"]
		local pfName = locTbl and locTbl[id]
		if pfName and pfName ~= "" then
			return "|cffffffff|Hitem:" .. id .. ":0:0:0|h[" .. pfName .. "]|h|r"
		end
	end
	-- 3) 触发服务器缓存查询（本次拿不到，下次喊话即可用）
	GetItemInfo(id)
	return nil
end

-- 检查所有配置的物品ID是否已全部被客户端缓存
local function AreConfiguredItemsCached()
	local items = Automaton_AutoShout.db.profile.items
	local i
	for i = 1, MAX_ITEMS do
		local item = items and items[i]
		if item and item.itemID and item.itemID > 0 and not GetItemInfo(item.itemID) then
			return false
		end
	end
	return true
end

-- 启动物品ID预缓存循环：每3秒对未缓存的ID调用一次 GetItemInfo 触发服务器查询，
-- 全部缓存成功或重试20次（约1分钟）后自动停止，避免无效ID导致死循环
function Automaton_AutoShout:StartItemCacheLoop()
	self:StopItemCacheLoop()
	self.itemCacheAttempts = 0
	self.itemCacheTimer = self:ScheduleRepeatingEvent(function()
		self.itemCacheAttempts = self.itemCacheAttempts + 1
		-- GetItemInfo 调用本身即触发服务器查询
		local allCached = AreConfiguredItemsCached()
		if allCached or self.itemCacheAttempts >= 20 then
			self:StopItemCacheLoop()
		end
	end, 3)
end

function Automaton_AutoShout:StopItemCacheLoop()
	if self.itemCacheTimer then
		self:CancelScheduledEvent(self.itemCacheTimer)
		self.itemCacheTimer = nil
	end
end

-- 把消息中的 {item1}~{itemN} 占位符替换为物品链接
-- 上限按 MAX_ITEMS 遍历：删掉靠后的物品后，消息里残留的 {itemN} 仍会显示为缺失提示，
-- 而不是把 "{item2}" 这种原始占位符直接发到频道里。
local function ReplaceItemPlaceholders(message)
	local i
	for i = 1, MAX_ITEMS do
		local itemLink = ResolveItemLink(i)
		if itemLink then
			message = string.gsub(message, "{item" .. i .. "}", itemLink)
		else
			message = string.gsub(message, "{item" .. i .. "}", "[物品" .. i .. "缺失]")
		end
	end
	return message
end

function Automaton_AutoShout:PLAYER_REGEN_ENABLED()
	-- 脱离战斗：恢复所有已启用组的定时器（StartTimer 内部会检查 enabled）
	local shoutTotal = self:GetShoutCount()
	for i = 1, shoutTotal do
		self:StartTimer(i)
	end
end

function Automaton_AutoShout:PLAYER_REGEN_DISABLED()
	-- 进入战斗：停止未勾选“战斗中喊话”的组的定时器
	local shoutTotal = self:GetShoutCount()
	for i = 1, shoutTotal do
		local s = self.db.char.shouts[i]
		if s and not s.inCombat then
			self:StopTimer(i)
		end
	end
end

function Automaton_AutoShout:CHAT_MSG_WHISPER(message, sender)
	-- 自动回复独立开关检查
	if not self.db.profile.autoReplyEnabled then
		return
	end

	-- 战斗中是否回复
	if UnitAffectingCombat("player") and not self.db.profile.autoReplyInCombat then
		return
	end

	-- 匹配暗号，命中才回复（长度、暗号一致性、回复内容非空都由 MatchReplyPair 统一判断）
	local replyMsg = self:MatchReplyPair(message)
	if not replyMsg then
		return
	end

	-- 命中暗号：把该发信人加入“自动回复静默用户”集合（3 秒有效）。
	-- WIM 在 PostMessage 时会检查这个集合（发出密语时对收件人、以及通过密语内容谓词），
	-- 因此无论事件先后顺序如何，原本未打开的窗口都不会弹出。
	if WIM_AutoReply_SilentUsers then
		WIM_AutoReply_SilentUsers[sender] = GetTime()
	end

	-- 替换物品占位符
	replyMsg = ReplaceItemPlaceholders(replyMsg)

	SendChatMessage(replyMsg, "WHISPER", nil, sender)
end

------------------------------
--      Channel Handling     --
------------------------------

local function GetWorldChannelID()
    for i = 1, 10 do
        local id, name = GetChannelName(i)
        if name then
            local nameLower = string.lower(name)
            -- 1. 精确匹配 "世界" / "world" / "世界频道"
            if nameLower == "世界" or nameLower == "world" or nameLower == "世界频道" then
                return id
            end
            -- 2. 前缀匹配（以"世界"或"world"开头），但排除防务频道
            if (string.find(nameLower, "^世界") or string.find(nameLower, "^world")) then
                if not (string.find(nameLower, "防务") or string.find(nameLower, "defense")) then
                    return id
                end
            end
        end
    end
    return nil
end

------------------------------
--      Core Function       --
------------------------------

-- 发送第 index 组的喊话消息
function Automaton_AutoShout:DoShout(index)
	local s = self.db.char.shouts[index]
	if not s or not s.enabled then
		return
	end

	local message = s.message
	if not message or message == "" then
		return
	end

	if UnitAffectingCombat("player") and not s.inCombat then
		return
	end

	message = ReplaceItemPlaceholders(message)

	local channel = s.channel
	if channel == "yell" then
		SendChatMessage(message, "YELL")
	elseif channel == "say" then
		SendChatMessage(message, "SAY")
	elseif channel == "party" then
		SendChatMessage(message, "PARTY")
	elseif channel == "guild" then
		SendChatMessage(message, "GUILD")
	elseif channel == "Hardcore" then
		SendChatMessage(message, "Hardcore")
	elseif channel == "world" then
		local worldChannelID = GetWorldChannelID()
		if worldChannelID then
			SendChatMessage(message, "CHANNEL", nil, worldChannelID)
		else
			Automaton:print("无法找到世界频道，请手动加入后重试", "自动喊话")
		end
	end
end
