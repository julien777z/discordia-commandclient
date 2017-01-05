local discordia = require('discordia')
local client = discordia.Client()

local command = require("./commands.lua"){
		prefix = "!", --string or a table of prefixes
		owner = "Your username",
		description = "My amazing bot",
		yieldError = true, --makes it so when a command fails to execute, the code below the newMsg func will not run.
		customHelp = false, --keeping this to false or nil will inject the default help menu command.
		errorMsg = "**Error:** ", --yes, you can have your own custom error messages to show if a command errors!
		commandDir = module.dir.."/commands" --location of command files for modulated commands.
		--[[	Information on modulated commands:
					lit install kaustavha/luvit-walk
					-requires the "luvit-walk" module. install it if you don't have it
					-check the echo command as an example
		]]
	
	}

client:on('ready', function()
    print('Logged in as '.. client.user.username)
end)

--An example of how to create commands:
local cmd = command:registerCommand("ping",function(data)
		local message,args,joined = data.message,data.args,data.joined
		return "Pong"
	end,{
		description = "Replies with pong",
		cooldownMessage = "Slow down! You can retry this command in {cooldown} seconds.", --There are a lot of options we can use.
		cooldown = 3, --remember, this is in seconds!
		aliases = {"poong","p0ng"}, --quick way to add more aliases
		hidden = true, --you can hide commands, too!
})
cmd:registerSubcommand("pong",function()
	return "🏓" --returning anything makes the bot say the value.
end,{
		description = "does absolutely nothing"
	})
cmd:registerCommandAlias("p1ng") --or you can use this to add aliases

client:on('messageCreate', function(message)
    command:newMsg(message) --This is how we connect each message to the command framework.
end)

client:run("TOKEN HERE")
