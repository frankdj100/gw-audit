local f=CreateFrame("Frame")
local c=CreateFrame("Frame")
local GuildRosterReady
local gwChannelId,gwChannelCount
local outputMode
local memberList = ()
local CTL = _G.ChatThrottleLib

-- Main function called when /gwaudit slash command is given

function GWAudit( slashcmd )
    local numChannels

    -- Handle command line args
    local _, _, cmd = string.find(slashcmd, "%s?(%w+)%s?(.*)")
    if cmd == "gchat" or cmd == "g" then
        if CTL then
            outputMode = "gchat"
        else
            print( "|cFF00FF00GWAudit:|r ChatThrottleLib is not available, cannot send guild chat message")
            outputMode = nil
        end
    elseif cmd == "whisper" or cmd == "w" then
        outputMode = "whisper"
    elseif cmd == nil then
        outputMode = nil
    else
        print( "Usage: /gwaudit [gchat|whisper|help]")
        return
    end

    -- See if guild roster info has been received, and if so, request GW channel info
    if GuildRosterReady then
        print("|cFF00FF00GWAudit:|r Auditing GreenWall members.")
        numChannels=GetNumDisplayChannels()
        local gwChannelName = gw.config.channel.guild.name
        SetSelectedDisplayChannel(4);
        for i=1,numChannels do
            local channelName=GetChannelDisplayInfo(i)
            if channelName == gwChannelName then
                gwChannelId = i;
                if GetSelectedDisplayChannel() ~= gwChannelId then
                    c:RegisterEvent("CHANNEL_ROSTER_UPDATE");
                    SetSelectedDisplayChannel(gwChannelId);
                else
                    ChannelRoster_Update(gwChannelId);
                    gwChannelCount = GetNumChannelMembers(gwChannelId);
                    print(gwChannelCount);
                    GWAuditProcess();
                end
            end
        end
        if gwChannelId == nil then
            print("|cFF00FF00GWAudit:|r GreenWall channel not found or joined yet.  Please try again.")
        end
    else
		print("|cFF00FF00GWAudit:|r Retrieving guild roster, try again in a few seconds.")
		GuildRoster()
	end
end

-- Comms function that outputs the list of guildies without GW to gchat or whispers

local function GWAuditDoComms()

    local gchatList = ()

    -- Send out the message
    if outputMode == "gchat" then
        if #memberList > 0 then
            local message = memberList.pop()
            for member in memberList do
                message = member .. ", " .. message
            end
            CTL:SendChatMessage( "BULK",
                        "GWAUDIT",
                        "Reminder to the following guild members to install the Greenwall addon: " .. message,
                        "GUILD" )
        end
    elseif outputMode == "whisper" then
        for member in memberList do
            CTL:SendChatMessage("BULK",
                "GWAUDIT",
                "Please install the Greenwall addon for communication between our guilds", 
                "WHISPER",
                nil,            -- language whatever
                member)
        end
    end
end



-- Worker function that compares people in guild roster with people in global GW channel

local function GWAuditProcess()

    -- Add all names in the greenwall channel roster to the table
    local gwChannelRoster={}
    for i=1,gwChannelCount do
        local memberName = C_ChatInfo.GetChannelRosterInfo(gwChannelId,i);
        table.insert(gwChannelRoster,memberName);
    end

    -- Go through all guild members that are online and see if they appear in the table
    local channelNameStr=table.concat(gwChannelRoster,",")
    local guildCount=GetNumGuildMembers()
    for i=1,guildCount do
        local guildieName,_,_,_,_,_,_,_,online=GetGuildRosterInfo(i)
        if online then
            local localname,localrealm=strsplit("-",guildieName,2)
            if channelNameStr:find(localname)==nil then
                print(localname);
                memberList.push( localname )
            end
        end
    end
    GWAuditDoComms()
    print("|cFF00FF00GWAudit:|r Audit complete.")
end

-- Callback for when GuildRoster() request is made in GWAudit()
f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:SetScript("OnEvent",function(self,event)
	GuildRosterReady = true
	f:UnregisterEvent("GUILD_ROSTER_UPDATE")
end)

-- Callback for when channel change request is made in GWAudit()
c:SetScript("OnEvent",function(self,event,id,count)
    if gwChannelId and id == gwChannelId then
        gwChannelCount=GetNumChannelMembers(id);
        c:UnregisterEvent("CHANNEL_ROSTER_UPDATE");
        GWAuditProcess();
    end
end)

SlashCmdList["GWAUDIT"] = function() GWAudit() end
SLASH_GWAUDIT1 = "/gwaudit"