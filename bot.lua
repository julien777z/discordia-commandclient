local discordia = require('discordia')
local client = discordia.Client()

local command = require("./commands.lua")(client,{
		prefix = "!", --string or a table of prefixes
		owner = "Your username",
		description = "My amazing bot",
		yieldError = true, --makes it so when a command fails to execute, the code below the newMsg func will not run.
		customHelp = false --keeping this to false or nil will inject the default help menu command.
	})

client:on('ready', function()
    print('Logged in as '.. client.user.username)
end)

--An example of how to create commands:
local cmd = command:registerCommand("ping",function(message,args,joined)
		return "Pong"
	end,{
		description = "Replies with pong",
		cooldownMessage = "Slow down! You can retry this command in {cooldown} seconds.", --There are a lot of options we can use.
		cooldown = 3, --remember, this is in seconds!
		aliases = {"poong","p0ng"} --quick way to add more aliases
})
cmd:registerSubcommand("pong",function(message,args,joined)
	return "🏓" --returning anything makes the bot say the value.
end,{
		description = "does absolutely nothing"
	})
cmd:registerCommandAlias("p1ng") --or you can use this to add aliases


--Now let's make an echo command and alias "say" to it.
local echoCommand = command:registerCommand("echo",function(message,args,joined)
		return joined
	end,{
		requirements = {
			roleNames = {"Bot Commander"} --You can add protection to your commands. Refer to https://abal.moe/Eris/docs/Command for more info.
		},
		description = "Makes the bot say something.",
		category = "Test2" --categories are supported
		
}):registerCommandAlias("say") --we can do this too

client:on('messageCreate', function(message)
    command:newMsg(message) --This is how we connect each message to the command framework.
end)

client:run(TOKEN_HERE)
