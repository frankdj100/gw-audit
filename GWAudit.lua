local f=CreateFrame("Frame")
local c=CreateFrame("Frame")
local GuildRosterReady
local gwChannelId,gwChannelCount,guildCount,channelNameStr,guildieName,online,localname,localrealm,gwChannelName

function GWAudit()
	local i,numChannels

	if GuildRosterReady then
        print("|cFF00FF00GWAudit:|r Auditing GreenWall members.")
        numChannels=GetNumDisplayChannels()
        gwChannelName = gw.config.channel.guild.name;
        SetSelectedDisplayChannel(4);
        for i=1,numChannels do
            channelName=GetChannelDisplayInfo(i);
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
		GuildRoster()
	end
end



function GWAuditProcess()
    local gwChannelRoster={}
    for i=1,gwChannelCount do
        local memberName = C_ChatInfo.GetChannelRosterInfo(gwChannelId,i);
        table.insert(gwChannelRoster,memberName);
    end;
    channelNameStr=table.concat(gwChannelRoster,",");
    guildCount=GetNumGuildMembers();
    for i=1,guildCount do
        local guildieName,_,_,_,_,_,_,_,online=GetGuildRosterInfo(i)
        if online then
            localname,localrealm=strsplit("-",guildieName,2)
            if channelNameStr:find(localname)==nil then
                print(localname);
            end
        end
    end
    print("|cFF00FF00GWAudit:|r Audit complete.")
end


f:RegisterEvent("GUILD_ROSTER_UPDATE")
f:SetScript("OnEvent",function(self,event)
	GuildRosterReady = true
	f:UnregisterEvent("GUILD_ROSTER_UPDATE")
end)


c:SetScript("OnEvent",function(self,event,id,count)
    if gwChannelId and id == gwChannelId then
        gwChannelCount=GetNumChannelMembers(id);
        c:UnregisterEvent("CHANNEL_ROSTER_UPDATE");
        GWAuditProcess();
    end
end)

SlashCmdList["GWAUDIT"] = function() GWAudit() end
SLASH_GWAUDIT1 = "/gwaudit"