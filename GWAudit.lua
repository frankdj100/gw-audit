local f=CreateFrame("Frame")
local c=CreateFrame("Frame")
local guildRosterReady
local gwChannelId
local outputMode
local onlineGuildies = {}
local CTL = _G.ChatThrottleLib

-- Main function called when /gwaudit slash command is given

function GWAudit( slashcmd )

    -- Handle command line args
    outputMode = nil
    if slashcmd ~= nil then
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
        elseif cmd ~= nil then
            print( "Usage: /gwaudit [gchat||whisper||help]")
            return
        end
    end

    -- See if guild roster info has been received, and if so, request GW channel info
    if guildRosterReady then
        print("|cFF00FF00GWAudit:|r Auditing GreenWall members.")
        local numChannels = GetNumDisplayChannels()
        local gwChannelName = gw.config.channel.guild.name
        SetSelectedDisplayChannel(4);
        for i=1,numChannels do
            local channelName=GetChannelDisplayInfo(i)
            if channelName == gwChannelName then
                gwChannelId = i;
                if GetSelectedDisplayChannel() ~= gwChannelId then
                    c:RegisterEvent("CHANNEL_ROSTER_UPDATE");
                    SetSelectedDisplayChannel(gwChannelId);     -- GWAuditProcess() called by callback for CHANNEL_ROSTER_UPDATE
                else
                    ChannelRoster_Update(gwChannelId);
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

local function GWAuditDoComms( nonGWMemberList )

    -- Send out the message
    if outputMode == "gchat" then
        if #nonGWMemberList > 0 then
            local message = table.remove( nonGWMemberList )
            for _, member in ipairs(nonGWMemberList) do
                message = member .. ", " .. message
            end
            --print("Guild message to " .. message )
            CTL:SendChatMessage( "BULK",
                        "GWAUDIT",
                        "Reminder for the following guild members to install the Greenwall addon: " .. message,
                        "GUILD" )
        end
    elseif outputMode == "whisper" then
        for _, member in ipairs(nonGWMemberList) do
            --print("Whisper to " .. member )
            CTL:SendChatMessage("BULK",
                "GWAUDIT",
                "Please install the Greenwall addon for communication between our guilds. Thank you!", 
                "WHISPER",
                nil,            -- language whatever
                member)
        end
    end
end

-- Worker function that double checks if the "non-GW" people on the first pass are still
-- not on the GW channel

local function GWAuditProcessPhaseTwo()

    -- Add all names in the greenwall channel roster to the table
    print( "|cFF00FF00GWAudit:|r Retrieving GW channel roster on channel " .. gwChannelId );
    local gwChannelRoster = {}
    local gwChannelCount = GetNumChannelMembers( gwChannelId );
    for i = 1, gwChannelCount do
        local memberName = C_ChatInfo.GetChannelRosterInfo( gwChannelId, i );
        gwChannelRoster[ memberName ] = 1
    end

    -- Prune all the guildies that have logged out in the last 10 seconds
    print( "|cFF00FF00GWAudit:|r Checking who's still online" );
    local stillOnlineGuildies = {}
    local guildCount = GetNumGuildMembers()
    for i = 1, guildCount do
        local guildieName,_,_,_,_,_,_,_,online = GetGuildRosterInfo(i)
        local localName, _ = strsplit( "-", guildieName, 2)
        if online then
            if onlineGuildies[ localName ] then
                table.insert( stillOnlineGuildies, localName )
            else
                print("|cFF00FF00GWAudit:|r " .. localName .. " newly logged in -- skipping")
            end
        end
    end

    -- Compare the online guildies from 10 second ago with the current GW channel roster
    print( "|cFF00FF00GWAudit:|r Performing audit" );
    local nonGWMemberList = {}
    for i, v in ipairs( stillOnlineGuildies ) do
        if gwChannelRoster[ v ] == nil then
            table.insert( nonGWMemberList, v )
            print( v )      -- For no-comms
        end
    end

    -- Do comms
    GWAuditDoComms( nonGWMemberList )

    -- Done
    print("|cFF00FF00GWAudit:|r Audit complete.")

end


-- Worker function that compares people in guild roster with people in global GW channel

local function GWAuditProcess()

    -- Go through all guild members and add the ones that are online to the table;
    -- we check this against the people that are in the GW channel in 10 seconds.
    onlineGuildies = {}
    local guildCount = GetNumGuildMembers()
    for i = 1, guildCount do
        local guildieName,_,_,_,_,_,_,_,online = GetGuildRosterInfo(i)
        if online then
            local localName, _ = strsplit( "-", guildieName, 2)
            onlineGuildies[ localName ] = 1
        end
    end

    print("|cFF00FF00GWAudit:|r Guild roster retrieval complete, pausing 10 seconds...")
    C_Timer.After(10.0, GWAuditProcessPhaseTwo )

end

-- Callback for when GuildRoster() request is made in GWAudit()
f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:SetScript("OnEvent",function(self,event)
	guildRosterReady = true
	f:UnregisterEvent("GUILD_ROSTER_UPDATE")
end)

-- Callback for when channel change request is made in GWAudit()
c:SetScript("OnEvent",function(self,event,id,count)
    if gwChannelId and id == gwChannelId then
        c:UnregisterEvent("CHANNEL_ROSTER_UPDATE");
        GWAuditProcess();
    end
end)

SlashCmdList["GWAUDIT"] = GWAudit
SLASH_GWAUDIT1 = "/gwaudit"