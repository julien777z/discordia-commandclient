## Introduction
This framework allows you to create your own commands in Discordia (https://github.com/SinisterRectus/Discordia) easily. This is based off of Eris (https://github.com/abalabahaha/eris) and matches the syntax of Eris' command client.

## Configuration
In order to fully customize the experience of the framework, you can use configuration options to customize the framework.
First, require the framework by doing ``local command = require("./commands.lua")``.
Then, pass a configuration table like this:
```lua
local command = require("./commands.lua"){
		prefix = "!", --string or a table of prefixes
		owner = "Your username",
		description = "My amazing bot"
	
}
  ```
  Supported options:
  
| Option        | Effect      |  Default      |
| ------------- |:-------------:| -----:|
| prefix      | Sets the prefix of the bot. Pass a table of prefixes or a string.| nil |
| owner      | Sets the owner name in the default help menu.| nil |
| description | Sets the description of your bot in the help menu | My amazing bot |
| yieldError | When enabled, if a command doesn't get executed, the code below the sendMsg function will not run.| false |
| customHelp | If enabled, this will disable the default help command. | false |
| errorMsg | If set to a string, the text will show when a command errors, followed by the error message. If you set a function, the first arg is the error msg, the second arg is the message. | **Error:** |
| successMsg | Similar to errorMsg, except with all other messages | text |
| commandDir | If set, the script will look in this directory for command files. | nil |


## Making a new command
After the command framework file is required and passed with a config table, you can begin making commands.
A command is made like this:
```lua
local cmd = command:registerCommand("ping",function(data)
  return "Pong"
end,{
  --options here
})
```
The first argument is the command label, the second is the function that gets executed, and the third is the command options table.
The data is returned as this:
```
message = message,
joined = joined,
args = args,
command = command
```
The message is the Discord message; joined is the string after the command label; args is a table of arguments the user says; command is the command framework.

## Options
In order to make command permissions more customizable, there are a bunch of options you can use. Refer to https://abal.moe/Eris/docs/Command for specific options you can use. Most are supported.

In addition to the above options, you can also use
__options.hidden__ which hides the command from showing in the help menu.

## Modulated commands
This framework supports modulated commands. In order to achieve this result, the script requires a module called **luvit-walk** in order to recursively look into the command folder for commands.
To do this, install luvit-walk by cding into your project path and running ``lit install kaustavha/luvit-walk``.
Now, change the commandDir option and create a new lua file.
Follow this example:
```lua
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
	
  return "ok"
end
```
Congrats! You made your first modulated command.

## Error/success handling
If you want to use the errorMsg option efficiently, if anywhere in the command file it error(string)s, the bot will show the error message.

If you put a function in for successMsg/errorMsg, the framework will execute the function and pass the text as arg 1 and the message as arg 2. If anything is returned from the function, that returned value will display. If you put a string instead, the string will be displayed, followed by the text.

Example 1:
```lua
{
errorMsg = function(error,message)
	return "**Error**: "..error
end,
successMsg = function(text,message)
	return text
end
}
```
Example 2:
```lua
{
errorMsg = "**Error:** ",
successMsg = ""
}
```
Both examples will produce the same result.
