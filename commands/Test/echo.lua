return {
	requirements = {
		roleNames = {"Bot Commander"}
	}
},function(data)
	local command = data.command
	command:registerSubcommand("test",function(message,args,joined)
		--command becomes the current command. you can't add more commands via the command argument
		return "this is executed from a subcommand"
	end)
	
	error("kid gtfo") --an error will make the bot say the error message
end