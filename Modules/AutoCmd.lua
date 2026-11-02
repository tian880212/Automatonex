assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_AutoCmd")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["AutoCmd"] = "Login Actions",
		["Run slash commands and macros automatically after login"] = "Run slash commands and macros automatically after login",
		["Execution Settings"] = "Execution Settings",
		["Run On Every Zone"] = "Run on every zone change",
		["Also run when entering a new zone or instance, not only at login"] = "Also run when entering a new zone or instance, not only at login",
		["Base Delay"] = "Base delay (sec)",
		["Delay after entering world before running the list"] = "Delay after entering world before running the list",
		["Command Interval"] = "Command interval (sec)",
		["Gap between two commands (keeps casts / equips from overwriting each other)"] = "Gap between two commands (keeps casts / equips from overwriting each other)",
		["Print Result"] = "Print result",
		["Print each executed command to the chat frame"] = "Print each executed command to the chat frame",
		["Run Now"] = "Run now",
		["Run the whole list once immediately (for testing)"] = "Run the whole list once immediately (for testing)",
		["Command List"] = "Command List",
		["Command list tip"] = "One command per entry: /cast, /use, /equip and other client commands; addon slash commands such as /db track taxi; macro:MacroName to run a macro; /run Lua code; plain text is sent to /say.",
		["Scope tip"] = "Commands are saved per character; execution settings are shared by the account.",
		["Command"] = "Command",
		["Command text example"] = "e.g. /cast Charge | /equip Main Hand | macro:Login | /run print(1) | hello",
		["Extra Delay"] = "Extra delay (sec)",
		["Extra delay before this command"] = "Extra delay for this command, added on top of the base delay",
		["Add Command"] = "Add command",
		["Add Command desc"] = "Append a new empty command slot",
		["First Command Locked"] = "The first command is permanent and cannot be deleted (you can clear its text or disable it)",
		["Move Up"] = "Move up",
		["Move Down"] = "Move down",
		["Delete"] = "Delete",
		["Enable this command"] = "Enable",
		["Enable this command desc"] = "Disable to skip this command without losing its text",
		["List is full"] = "Command list is full (max %d)",
		["Nothing to run"] = "No enabled command to run",
		["Executed"] = "Executed",
		["Failed"] = "Failed",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		["AutoCmd"] = "登录自动执行",
		["Run slash commands and macros automatically after login"] = "上线后自动执行一组斜杠命令、宏或脚本",
		["Execution Settings"] = "执行设置",
		["Run On Every Zone"] = "每次进入世界都执行",
		["Also run when entering a new zone or instance, not only at login"] = "除登录外，换地图 / 进出副本时也执行一遍",
		["Base Delay"] = "基础延迟(秒)",
		["Delay after entering world before running the list"] = "进入世界后等待多久开始执行（避开登录瞬间的界面竞争）",
		["Command Interval"] = "命令间隔(秒)",
		["Gap between two commands (keeps casts / equips from overwriting each other)"] = "两条命令之间的间隔，避免 /cast、/equip 连发时互相顶掉",
		["Print Result"] = "执行后提示",
		["Print each executed command to the chat frame"] = "把执行结果打印到聊天框，方便排查",
		["Run Now"] = "立即执行一次",
		["Run the whole list once immediately (for testing)"] = "马上按顺序跑一遍列表，用于测试",
		["Command List"] = "命令列表",
		["Command list tip"] = "每条填一条命令：/cast、/use、/equip 等客户端命令；/db track taxi 等插件命令；macro:宏名 调用宏；/run Lua代码；不带斜杠的文本按说话频道发送。",
		["Scope tip"] = "命令按角色单独保存，执行设置（延迟/间隔）按账号共享。",
		["Command"] = "命令",
		["Command text example"] = "例如：/cast 冲锋 | /equip 主手武器 | macro:上线 | /run print(1) | 大家好",
		["Extra Delay"] = "额外延迟(秒)",
		["Extra delay before this command"] = "这条命令自己的额外延迟，叠加在基础延迟之上",
		["Add Command"] = "添加一条命令",
		["Add Command desc"] = "在列表末尾新增一个空命令位",
		["First Command Locked"] = "第 1 条为固定项，不能删除（可以清空内容或取消启用）",
		["Move Up"] = "上移",
		["Move Down"] = "下移",
		["Delete"] = "删除",
		["Enable this command"] = "启用",
		["Enable this command desc"] = "取消勾选即可跳过这条命令，文本不会被清掉",
		["List is full"] = "命令列表已满（最多 %d 条）",
		["Nothing to run"] = "没有可执行的命令",
		["Executed"] = "已执行",
		["Failed"] = "执行失败",
	}
end)

------------------------------
--      Module Declaration      --
------------------------------

local Automaton_AutoCmd = Automaton:NewModule("AutoCmd")
Automaton_AutoCmd.modulename = L["AutoCmd"]
Automaton_AutoCmd.moduledesc = L["Run slash commands and macros automatically after login"]

local MAX_COMMANDS = 20

-- 同一次登录内 PLAYER_ENTERING_WORLD 可能触发多次（载入界面 / 切换地图），
-- 用来区分"登录首次进世界"和"之后换地图"，避免重复执行整个列表。
local sessionWorldEntered = false

-- 模块被停用时也要记录世界事件，否则在游戏里临时启用后，
-- 第一次换地图会被误判成登录而直接跑一遍列表。
local worldWatcher = CreateFrame("Frame")
worldWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
worldWatcher:SetScript("OnEvent", function()
	if not Automaton:IsModuleActive("AutoCmd") then
		sessionWorldEntered = true
	end
end)

------------------------------
--      Helper Functions      --
------------------------------

local function Trim(s)
	s = s or ""
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	return s
end

local function Schedule(delay, func)
	if C_Timer and C_Timer.After then
		C_Timer.After(delay, func)
	else
		func()
	end
end

------------------------------
--      Initialization      --
------------------------------

function Automaton_AutoCmd:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("AutoCmd")

	-- 执行设置按账号共享：延迟、间隔、提示等通用偏好
	Automaton:RegisterDefaults("AutoCmd", "profile", {
		disabled = true,     -- 新模块默认关闭，避免上线就乱跑命令
		everyZone = false,
		loginDelay = 5,
		interval = 1,
		verbose = true,
	})

	-- 命令列表按角色保存：技能 / 装备 / 宏基本都是角色相关的
	Automaton:RegisterDefaults("AutoCmd", "char", {
		commands = {
			{ cmd = "", on = true, delay = 0 },
		},
	})

	Automaton:SetDisabledAsDefault(self, "AutoCmd")

	self.slashCache = {}
	self.runToken = 0

	self:RegisterOptions(self:BuildOptions())
end

function Automaton_AutoCmd:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Automaton_AutoCmd:OnDisable()
	self:UnregisterAllEvents()
	-- 让所有已排队但还没跑的定时器失效
	self.runToken = (self.runToken or 0) + 1
end

------------------------------
--      Event Handlers      --
------------------------------

function Automaton_AutoCmd:PLAYER_ENTERING_WORLD()
	local isLogin = not sessionWorldEntered
	sessionWorldEntered = true

	if isLogin or self.db.profile.everyZone then
		self:RunAll(false)
	end
end

------------------------------
--      Command Execution      --
------------------------------

-- 反查斜杠命令对应的 SlashCmdList 处理函数。
-- 客户端注册方式是 SLASH_<KEY><n> = "/别名"，入口是 SlashCmdList[<KEY>]；
-- 因此 /db 这类命令要按别名遍历 SLASH_* 反查，不能直接查 SlashCmdList["DB"]。
function Automaton_AutoCmd:ResolveSlashHandler(slash)
	if not slash or slash == "" then return nil end

	local key = string.lower(slash)
	local cached = self.slashCache[key]
	if cached ~= nil then
		if cached == false then return nil end
		return cached
	end

	local handler
	local name, value
	for name, value in pairs(_G) do
		if type(name) == "string" and type(value) == "string"
			and string.sub(name, 1, 6) == "SLASH_"
			and string.lower(value) == key then
			local listKey = string.gsub(string.sub(name, 7), "%d+$", "")
			if SlashCmdList[listKey] then
				handler = SlashCmdList[listKey]
				break
			end
		end
	end

	-- 回退：命令名大写直查
	if not handler then
		handler = SlashCmdList[string.upper(string.sub(key, 2))]
	end

	self.slashCache[key] = handler or false
	return handler
end

-- 按宏名执行宏：先按名字换索引（1.12 的 RunMacro 主要认索引），再按名字兜底
function Automaton_AutoCmd:RunMacroByName(name)
	name = Trim(name)
	if name == "" then return false, L["Nothing to run"] end

	local index = 0
	if GetMacroIndexByName then
		local ok, idx = pcall(GetMacroIndexByName, name)
		if ok and idx then index = idx end
	end

	if index and index > 0 then
		local ok, err = pcall(RunMacro, index)
		if ok then return true, nil, "macro" end
		return false, tostring(err)
	end

	local ok, err = pcall(RunMacro, name)
	if ok then return true, nil, "macro" end
	return false, tostring(err)
end

-- 执行 Lua 代码（/run、/script）
function Automaton_AutoCmd:RunLua(code)
	code = Trim(code)
	if code == "" then return false, L["Nothing to run"] end

	if type(loadstring) == "function" then
		local fn, err = loadstring(code)
		if not fn then
			-- 语法错误：原样交给客户端 /script，报错信息更准确
			return self:SendViaChat("/script " .. code)
		end
		local ok, err2 = pcall(fn)
		if ok then return true, nil, "lua" end
		return false, tostring(err2)
	end

	return self:SendViaChat("/script " .. code)
end

-- 兜底通道：把命令塞进聊天输入框再发送。
-- 客户端内建命令（/cast、/use、/equip、/startattack 等）不在 SlashCmdList 里，
-- 只能走这条路由；第二参必须显式传 false，否则会写进聊天上翻历史。
function Automaton_AutoCmd:SendViaChat(command)
	local editBox = DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox
	if not editBox then return false, "no chat edit box" end

	-- 玩家可能正在打字，不要覆盖输入框内容
	local current = editBox:GetText()
	if current and string.len(current) > 0 then
		return false, "chat edit box is not empty"
	end

	editBox:SetText(command)
	local ok = pcall(ChatEdit_SendText, editBox, false)
	editBox:SetText("")
	if not ok then return false, "ChatEdit_SendText failed" end

	return true, nil, "chat"
end

-- 单条命令执行：宏 → 脚本 → 插件斜杠命令 → 聊天通道
function Automaton_AutoCmd:ExecuteCommand(raw)
	local text = Trim(raw)
	if text == "" then return false, L["Nothing to run"] end

	-- macro:宏名 / macro：宏名 / /macro 宏名
	-- 注意：中文全角冒号是多字节字符，不能和半角冒号写在同一个 [...] 集合里
	-- （Lua 的集合按字节匹配，会把全角冒号拆成三个字节逐个匹配，截出乱码宏名）
	local _, _, macroName = string.find(text, "^[Mm][Aa][Cc][Rr][Oo]%s*:%s*(.+)$")
	if not macroName then
		_, _, macroName = string.find(text, "^[Mm][Aa][Cc][Rr][Oo]%s*：%s*(.+)$")
	end
	if not macroName then
		_, _, macroName = string.find(text, "^/[Mm][Aa][Cc][Rr][Oo]%s+(.+)$")
	end
	if macroName then
		return self:RunMacroByName(macroName)
	end

	-- /run 代码 / /script 代码
	local _, _, code = string.find(text, "^/[Rr][Uu][Nn]%s+(.+)$")
	if not code then
		_, _, code = string.find(text, "^/[Ss][Cc][Rr][Ii][Pp][Tt]%s+(.+)$")
	end
	if code then
		return self:RunLua(code)
	end

	-- 不带斜杠：当成说话内容发出去
	if string.sub(text, 1, 1) ~= "/" then
		local ok = pcall(SendChatMessage, text, "SAY")
		if ok then return true, nil, "say" end
		return false, "SendChatMessage failed"
	end

	-- 插件斜杠命令：直接调处理函数，不经过聊天框
	local _, _, slash, args = string.find(text, "^(%S+)%s*(.-)$")
	if slash then
		local handler = self:ResolveSlashHandler(slash)
		if handler then
			local ok = pcall(handler, args or "")
			if ok then return true, nil, "handler" end
			-- 处理函数报错：退回聊天框（部分旧插件依赖 arg1 / this 全局）
		end
	end

	return self:SendViaChat(text)
end

function Automaton_AutoCmd:ExecuteAndReport(cmd)
	local ok, err = self:ExecuteCommand(cmd)
	if self.db.profile.verbose then
		if ok then
			self:Print(L["Executed"] .. ": " .. cmd)
		else
			self:Print(L["Failed"] .. ": " .. cmd .. " - " .. tostring(err or "?"))
		end
	end
	return ok
end

-- 按顺序排队执行整个列表；isManual = 面板上的"立即执行一次"
function Automaton_AutoCmd:RunAll(isManual)
	local now = GetTime()
	-- 登录时 PLAYER_ENTERING_WORLD 可能连发，短时间内不重复排队
	if not isManual and self.lastAutoRun and (now - self.lastAutoRun) < 5 then
		return
	end
	if not isManual then
		self.lastAutoRun = now
	end

	self.runToken = (self.runToken or 0) + 1
	local token = self.runToken

	local base = isManual and 0 or (self.db.profile.loginDelay or 0)
	local gap = self.db.profile.interval or 0
	local commands = self:GetCommands()
	local offset = 0
	local scheduled = 0

	local i
	for i = 1, table.getn(commands) do
		local entry = commands[i]
		-- 存档被手工改坏 / 旧版本残留的脏数据：补成合法条目，不让整轮执行中断
		if type(entry) ~= "table" then
			entry = { cmd = "", on = true, delay = 0 }
			commands[i] = entry
		end
		local cmd = Trim(entry.cmd)
		if entry.on ~= false and cmd ~= "" then
			local delay = base + offset + (tonumber(entry.delay) or 0)
			scheduled = scheduled + 1
			Schedule(delay, function()
				if token ~= self.runToken then return end
				if not Automaton:IsModuleActive("AutoCmd") then return end
				self:ExecuteAndReport(cmd)
			end)
			offset = offset + gap
		end
	end

	if scheduled == 0 and self.db.profile.verbose then
		self:Print(L["Nothing to run"])
	end
end

------------------------------
--      Command List Edit      --
------------------------------

function Automaton_AutoCmd:GetCommands()
	if type(self.db.char.commands) ~= "table" then
		self.db.char.commands = {}
	end
	-- 第 1 条是固定项（不可删除），所以列表至少要有一条：
	-- 旧存档里被删空的列表在这里补回来，否则面板上连"第 1 条"都没有。
	if table.getn(self.db.char.commands) < 1 then
		table.insert(self.db.char.commands, { cmd = "", on = true, delay = 0 })
	end
	return self.db.char.commands
end

-- 列表变动后重建选项面板（延迟到下一次刷新，避免在按钮自己的 OnClick 里销毁自己）
function Automaton_AutoCmd:RebuildOptions()
	Schedule(0.05, function()
		self.slashCache = {}
		self:RegisterOptions(self:BuildOptions())
	end)
end

function Automaton_AutoCmd:AddCommand()
	local commands = self:GetCommands()
	if table.getn(commands) >= MAX_COMMANDS then
		self:Print(string.format(L["List is full"], MAX_COMMANDS))
		return
	end
	table.insert(commands, { cmd = "", on = true, delay = 0 })
	self:RebuildOptions()
end

-- 第 1 条是固定项（和喊话/物品列表一致）：只允许从第 2 条往后删除
function Automaton_AutoCmd:RemoveCommand(index)
	local commands = self:GetCommands()
	if index <= 1 or not commands[index] then return end
	table.remove(commands, index)
	self:RebuildOptions()
end

function Automaton_AutoCmd:MoveCommand(index, step)
	local commands = self:GetCommands()
	local target = index + step
	if not commands[index] or not commands[target] then return end
	commands[index], commands[target] = commands[target], commands[index]
	self:RebuildOptions()
end

------------------------------
--      Options Panel      --
------------------------------

function Automaton_AutoCmd:BuildOptions()
	local opts = {}

	opts.execHeader = {
		type = "header",
		name = L["Execution Settings"],
		order = 10,
	}

	opts.everyZone = {
		type = "toggle",
		name = L["Run On Every Zone"],
		desc = L["Also run when entering a new zone or instance, not only at login"],
		order = 11,
		get = function() return self.db.profile.everyZone end,
		set = function(v) self.db.profile.everyZone = v and true or false end,
	}

	opts.loginDelay = {
		type = "range",
		name = L["Base Delay"],
		desc = L["Delay after entering world before running the list"],
		min = 0, max = 60, step = 1,
		order = 12,
		get = function() return self.db.profile.loginDelay end,
		set = function(v) self.db.profile.loginDelay = v end,
	}

	opts.interval = {
		type = "range",
		name = L["Command Interval"],
		desc = L["Gap between two commands (keeps casts / equips from overwriting each other)"],
		min = 0, max = 10, step = 1,
		order = 13,
		get = function() return self.db.profile.interval end,
		set = function(v) self.db.profile.interval = v end,
	}

	opts.verbose = {
		type = "toggle",
		name = L["Print Result"],
		desc = L["Print each executed command to the chat frame"],
		order = 14,
		get = function() return self.db.profile.verbose end,
		set = function(v) self.db.profile.verbose = v and true or false end,
	}

	opts.runNow = {
		type = "execute",
		name = L["Run Now"],
		desc = L["Run the whole list once immediately (for testing)"],
		order = 15,
		func = function() self:RunAll(true) end,
	}

	opts.listHeader = {
		type = "header",
		name = L["Command List"],
		order = 20,
	}

	opts.tip = {
		type = "description",
		name = L["Command list tip"],
		order = 21,
	}

	opts.scopeTip = {
		type = "description",
		name = L["Scope tip"],
		order = 22,
	}

	local commands = self:GetCommands()
	local total = table.getn(commands)

	local i
	for i = 1, total do
		local entry = commands[i]
		if type(entry) ~= "table" then
			entry = { cmd = "", on = true, delay = 0 }
			commands[i] = entry
		end

		-- 单条命令独立成组：标题栏放上移 / 下移 / 删除按钮
		-- 第 1 条固定保留：没有上移和删除按钮；末尾手动去掉下移
		local buttons = {}
		if i > 1 then
			table.insert(buttons, {
				name = "↑",
				tip = L["Move Up"],
				func = function() self:MoveCommand(i, -1) end,
			})
		end
		if i < total then
			table.insert(buttons, {
				name = "↓",
				tip = L["Move Down"],
				func = function() self:MoveCommand(i, 1) end,
			})
		end
		if i > 1 then
			table.insert(buttons, {
				name = "×",
				tip = L["Delete"],
				func = function() self:RemoveCommand(i) end,
			})
		end

		opts["cmd" .. i] = {
			type = "group",
			name = L["Command"] .. " " .. i,
			order = 30 + i,
			buttons = buttons,
			args = {
				enabled = {
					type = "toggle",
					name = L["Enable this command"],
					desc = L["Enable this command desc"],
					order = 1,
					get = function() return entry.on ~= false end,
					set = function(v) entry.on = v and true or false end,
				},
				text = {
					type = "text",
					name = L["Command"],
					desc = L["Command text example"],
					order = 2,
					get = function() return entry.cmd or "" end,
					set = function(v) entry.cmd = v or "" end,
					-- 默认输入框只有 120 宽，命令往往更长，这里加宽
					onCreateEdit = function(edit)
						edit:SetWidth(300)
					end,
				},
				delay = {
					type = "range",
					name = L["Extra Delay"],
					desc = L["Extra delay before this command"],
					min = 0, max = 60, step = 1,
					order = 3,
					get = function() return entry.delay or 0 end,
					set = function(v) entry.delay = v or 0 end,
				},
			},
		}
	end

	opts.add = {
		type = "execute",
		name = L["Add Command"],
		desc = L["Add Command desc"],
		order = 200,
		func = function() self:AddCommand() end,
	}

	opts.lockTip = {
		type = "description",
		name = L["First Command Locked"],
		order = 201,
	}

	return opts
end
