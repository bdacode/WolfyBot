permissions = {}
--insert host into permissions here
--example: permissions["Powder/Developer/cracker64"] = 101
--Owner should be 101

--Get perm value for part of a hostmask (usually just host)
function getPerms(host)
	local highest=-99
	for k,v in pairs(permissions) do
		if host:find(k) then
			if v>highest then
				highest=v
			end
		end
	end
	if highest<-1 then highest=0 end
	return highest
end

--This has server specific data
local config={
	--Network to connect to, change to whatever network you use
	network = {
		server = "irc.freenode.net",
		port = 6667,
		--password = ""
	},
	--User info, set these to whatever you need
	user = {
		nick = "Crackbot",
		username = "Meow",
		realname = "moo",
		
		--account = "Crackbot",
		--password = "password"
	},
	--Channels to join on start
	autojoin = {
		--"##foo",
	},
	logchannel = "##foo",
	prefix = "%./",
	suffix = "moo+"
}

return config
