--https://github.com/abalabahaha/eris/blob/master/examples/basicCommands.js
--https://abal.moe/Eris/docs/Command
local Data = {aliases={},cooldowns={}}
local Command = {commands={}}
Command.__index = Command

local Subcommand = {} --TODO
Subcommand.__index = Subcommand

local function start(options)
	options = options or {}
	for i,v in pairs(options) do
		Data[i] = v
	end
	if not options.customHelp then
		Command:registerCommand("help",helpFunction,{
				description = "shows commands and command usage.",
				fullDescription = "shows commands and command usage (such as this one).",
				usage = "<command name>",
			})
	end
	pcall(function()
		local walk = require("luvit-walk")
		if walk and Data.commandDir then walk = walk.readdirRecursive 
			walk(Data.commandDir, function(k, files) 
				for i,v in pairs(files) do
					if v:match(".lua") then
						local cmdName = v:sub(2):match("([^/]-)%..-$")
						local perms, func
						local success, err = pcall(function() perms,func = dofile(v) end)
						if success then
							Command:registerCommand(cmdName,func,perms)
						else
							p("Command error for "..cmdName..": "..err)
						end
					end
				end
			end)
		end
	end)
	return Command
end
function Command:registerCommand(label,func,options)
	assert(label,"Command label cannot be blank!")
	assert(func,"Command must have a function attached!")
	local mt = setmetatable({
		label = label,
		func = func,
		options = options or {},
		subcommands = {},
	},Command)
	Command.commands[label] = mt
	options = options or {}
	options.aliases = options.aliases or {}
	for i,v in pairs(options.aliases) do
		Data.aliases[v] = label
	end
	return mt
end

function helpFunction(data)
	local message,joined,args = data.message,data.joined,data.args
	local author = message.author
	local categories = {}
	local embed
	local bot = message.guild.me
	if not bot then return end
	bot = bot._parent._parent
	if args[1] then
		local cmdName = args[1]
		local command = Command.commands[cmdName]
		if command and not command.options.hidden then
			command.options = command.options or {}
			embed = {
				title = cmdName,
				description = command.options.fullDescription or command.options.description or "N/A",
				fields = {{name="Category",value=command.options.category or "Misc"},{name="Usage",value=command.options.usage or "N/A"}}
			}
			local tab = {}
			for i,v in pairs(command.subcommands) do
				if v.options.description or v.options.fullDescription then
					table.insert(tab,i.." — "..(v.options.fullDescription or v.options.description))
				else
					table.insert(tab,i)
				end
			end
			if #tab == 0 then
				table.insert(embed.fields,{name="Sub Commands",value="None",inline=false})
			else
				table.insert(embed.fields,{name="Sub Commands",value=table.concat(tab,"\n"),inline=false})
			end
			tab = {}
			for i,v in pairs(Data.aliases) do
				if v == cmdName then
					table.insert(tab,i)
				end
			end
			if #tab == 0 then
				table.insert(embed.fields,{name="Aliases",value="None",inline=false})
			else
				table.insert(embed.fields,{name="Aliases",value=table.concat(tab,"\n"),inline=false})
			end
			bot._api:createMessage(message.channel.id, {
				content = "", embed = embed
			})
		else
			message.channel:sendMessage("Could not find the command.")
			return
		end
	else
		embed = {
			author = {name="Commands",icon_url=bot.user.avatarUrl},
			title = (Data.title or bot.user.username)..(Data.owner and " by "..Data.owner or ""),
			description = Data.description or "My amazing bot",
			fields = {}	
		}
		for i,v in pairs(Command.commands) do
			if not v.options.hidden then
				local options = v.options or {}
				local category = options.category or "Misc"
				categories[category] = categories[category] or {}
				local desc = message.prefix..v.label
				if options.description then
					desc = desc.." — "..options.description
				end
				for l,k in pairs(v.subcommands) do
					desc = desc.."\n	"..message.prefix..i.." "..l
					if k.options and k.options.description then
						desc = desc.." — "..k.options.description
					end
				end
				table.insert(categories[category],desc)
			end
		end
		for i,v in pairs(categories) do
			table.insert(embed.fields,{
				name = i,
				value = table.concat(v,"\n"),
				inline = false
			})
		end
		bot._api:createMessage(message.channel.id, {
			content = "", embed = embed
		})
	end
end

function Command:registerCommandAlias(alias)
	Data.aliases[alias] = self.label
end

function Command:newMsg(message)
	local bot = message.guild.me
	if not bot then return end
	local member = message.member
	local author = message.author
	local content = message.content
	local channel = message.channel
	local function isAllowed(options,joined)
		local isCoolDown = Data.cooldowns[author.id]
		options = options or {}
		local caseInsensitive = options.caseInsensitive or false
		local deleteCommand = options.deleteCommand or false
		local argsRequired = options.argsRequired or false
		local guildOnly = options.guildOnly or false
		local dmOnly = options.dmOnly or false
		local cooldown = options.cooldown or 0
		local cooldownMessage = string.gsub(options.cooldownMessage or "Slow down!","{cooldown}",isCoolDown and isCoolDown - os.time() or "0")
		local permissionMessage = options.permissionMessage or "You do not have permission to use this command."
		local requirements = options.requirements or {}
		requirements.userIDs = requirements.userIDs or {}
		requirements.permissions = requirements.permissions or {}
		requirements.roleIDs = requirements.roleIDs or {}
		requirements.roleNames = requirements.roleNames or {}
		options.requirements = requirements
		local ignoreBots = (Data.ignoreBots == nil or Data.ignoreBots == true) or false
		local ignoreSelf = (Data.ignoreSelf == nil or Data.ignoreSelf == true) or false
		if ignoreBots and author.bot then return end
		if ignoreSelf and author.id == bot.id then return end
		if isCoolDown and isCoolDown > os.time() then channel:sendMessage(cooldownMessage) return false end
		if argsRequired then
			if #joined == 0 then
				channel:sendMessage("Arguments are required for this command.")
				return
			end
		end
		if guildOnly then
			if not message.guild then return end
		end
		if dmOnly then
			if message.guild then return end
		end
		for i,v in pairs(requirements.userIDs) do
			if v ~= author.id then channel:sendMessage(permissionMessage) return false end
		end
		for i,v in pairs(requirements.roleIDs) do
			if not member:getRole(v) then channel:sendMessage(permissionMessage) return false end
		end
		for i,v in pairs(requirements.roleNames) do
			if not member:getRole("name",v) then channel:sendMessage(permissionMessage) return false end
		end
		for i,v in pairs(requirements.permissions) do
			--TODO
		end
		Data.cooldowns[author.id] = os.time() + cooldown
		return true
	end
	local function execute(beginning)
		local rest = content:sub(beginning:len()+1)
		local command,args = string.match(rest, '(%S+) (.*)')
		if not args then args = rest command = rest end
		local joined = {}
		local i = 0
		for match in rest:gmatch("%S+") do
			i = i + 1
			if i ~= 1 then
				table.insert(joined,match)
			end
		end
		message.prefix = beginning
		if not command then return end
		local skip = nil
		for i,v in pairs(Data.aliases) do
			if command == i and Command.commands[v] then
				command = Command.commands[v]
				skip = true
				break
			end
		end
		if not skip then
			command = Command.commands[command]
			if command and joined[1] then
				for l,k in pairs(command.subcommands) do
					if l == joined[1] then
						command = k
						skip = true
						break
					end
				end
			end
		end
		if not command then return end
		if not isAllowed(command.options,joined) then return end
		local res
		local success,err = pcall(function()
			res = command.func{command = command,message=message,joined=args,args=joined}
		end)
		if success and res and type(res) == "string" then
			channel:sendMessage(res)
		elseif not success and err then
			local filepath,num,msg = err:match('(.*):(.*):(.*)')
			if msg then
				msg = msg:sub(2)
			end
			channel:sendMessage((Data.errorMsg or "**Error:** ")..msg)
		end
		return args,joined,command
	end
	local prefix = Data.prefix or ""
	if type(prefix) == "table" then
		for i,v in pairs(prefix) do
			v = caseInsensitive and v:lower() or v
			local beginning = content:sub(1,v:len())
			beginning = caseInsensitive and beginning:lower() or beginning
			if beginning == v then
				local args,joined,command = execute(beginning)
				return args,joined,command
			end
		end
	else
		prefix = caseInsensitive and prefix:lower() or prefix
		local beginning = content:sub(1,prefix:len())
		beginning = caseInsensitive and beginning:lower() or beginning
		if beginning == prefix then
			local args,joined,command = execute(beginning)
			return args,joined,command
		end
	end
	if Data.errorYield then
		coroutine.yield()
	end
end

function Command:registerSubcommand(label, func, options)
	self.subcommands[label] = {func = func, options = options}
	return Subcommand(label, func, options)
end

setmetatable(Subcommand,{
    __call = function(self,label,func,options)
    return setmetatable({
      label = label,
			func = func,
			options = options
    },self)
end})




return start
