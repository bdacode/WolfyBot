local pairs = pairs
local error = error
local tonumber = tonumber
local print=print

module "irc"

handlers = {}

handlers["PING"] = function(o, prefix, query)
	o:send("PONG :%s", query)
end

handlers["001"] = function(o, prefix, me)
	o.authed = true
	o.nick = me
end

handlers["PRIVMSG"] = function(o, prefix, channel, message)
	o:invoke("OnChat", parsePrefix(prefix), channel, message)
end

handlers["NOTICE"] = function(o, prefix, channel, message)
	o:invoke("OnNotice", parsePrefix(prefix), channel, message)
end

handlers["JOIN"] = function(o, prefix, channel)
	local user = parsePrefix(prefix)
	if o.track_users then
		if user.nick == o.nick then
			o.channels[channel] = {users = {}}
		else
			o.channels[channel].users[user.nick] = user
		end
	end

	o:invoke("OnJoin", user, channel)
end

handlers["PART"] = function(o, prefix, channel, reason)
	local user = parsePrefix(prefix)
	if o.track_users then
		if user.nick == o.nick then
			o.channels[channel] = nil
		else
			o.channels[channel].users[user.nick] = nil
		end
	end
	o:invoke("OnPart", user, channel, reason)
end

handlers["QUIT"] = function(o, prefix, msg)
	local user = parsePrefix(prefix)
	if o.track_users then
		for channel, v in pairs(o.channels) do
			v.users[user.nick] = nil
		end
	end
	o:invoke("OnQuit", user, msg)
end

handlers["NICK"] = function(o, prefix, newnick)
	local user = parsePrefix(prefix)
	if o.track_users then
		for channel, v in pairs(o.channels) do
			local users = v.users
			local oldinfo = users[user.nick]
			if oldinfo then
				users[newnick] = oldinfo
				users[newnick].nick = newnick
				if users[newnick].fullhost then
					users[newnick].fullhost = users[newnick].nick.."!"..users[newnick].username.."@"..users[newnick].host
				end
				users[user.nick] = nil
				o:invoke("NickChange", user, newnick, channel)
			end
		end
	else
		o:invoke("NickChange", user, newnick)
	end
end
--WHO list
handlers["352"] = function(o, prefix, me, channel, name1, host, serv, name, access1 ,something, something2)
	if o.track_users then
		local user = {nick=name, host=host, username=name1, serv=serv, access=parseWhoAccess(access1), fullhost=name.."!"..name1.."@"..host}
		--print(user.nick,user.host,user.ID,user.serv,user.access)
		o.channels[channel].users[user.nick] = user
	end
end
--NAMES list
handlers["353"] = function(o, prefix, me, chanType, channel, names)
	if o.track_users then
		o.channels[channel] = o.channels[channel] or {users = {}, type = chanType}

		local users = o.channels[channel].users
		for nick in names:gmatch("(%S+)") do
			local access, name = parseNick(nick)
			users[name] = {type = access}
		end
	end
end

--end of NAMES
handlers["366"] = function(o, prefix, me, channel, msg)
	if o.track_users then
		o:invoke("NameList", channel, msg)
	end
end

--no topic
handlers["331"] = function(o, prefix, me, channel)
	o:invoke("OnTopic", channel, nil)
end

--new topic
handlers["TOPIC"] = function(o, prefix, channel, topic)
	o:invoke("OnTopic", channel, topic)
end

handlers["332"] = function(o, prefix, me, channel, topic)
	o:invoke("OnTopic", channel, topic)
end

--topic creation info
handlers["333"] = function(o, prefix, me, channel, nick, time)
	o:invoke("OnTopicInfo", channel, nick, tonumber(time))
end

handlers["KICK"] = function(o, prefix, channel, kicked, reason)
	o:invoke("OnKick", channel, kicked, parsePrefix(prefix), reason)
end

--RPL_UMODEIS
--To answer a query about a client's own mode, RPL_UMODEIS is sent back
handlers["221"] = function(o, prefix, user, modes)
	o:invoke("OnUserMode", modes)
end

--RPL_CHANNELMODEIS
--The result from common irc servers differs from that defined by the rfc
handlers["324"] = function(o, prefix, user, channel, modes)
	o:invoke("OnChannelMode", channel, modes)
end

handlers["MODE"] = function(o, prefix, targetchan, modes, ...)
	print(prefix,target,modes, ...)
	if o.track_users then
	--TODO: track user access changes.
	
	end
	o:invoke("OnModeChange", parsePrefix(prefix), target, modes, ...)
end

handlers["ERROR"] = function(o, prefix, message)
	o:invoke("OnDisconnect", message, true)
	o:shutdown()
	error(message, 3)
end
