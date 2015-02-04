--[[ 
########################################################## 
THREAT O METER   By: Munglunch
##########################################################
]]--
--[[ GLOBALS ]]--
local _G = _G;
local unpack 	= _G.unpack;
local select 	= _G.select;
local pairs 	= _G.pairs;
local ipairs 	= _G.ipairs;
local type 		= _G.type;
local tinsert 	= _G.tinsert;
local math 		= _G.math;
local wipe 		= _G.wipe;

local ThreatMeter = _G["Threat_O_Meter"];

--[[ LOCALS ]]--
local BARFILE = [[Interface\AddOns\ThreatOMeter\assets\THREAT-BAR]];
local TEXTUREFILE = [[Interface\AddOns\ThreatOMeter\assets\THREAT-BAR-ELEMENTS]];
local REACTION_COLORS = {
	[1] = {0.92, 0.15, 0.15}, 
	[2] = {0.92, 0.15, 0.15}, 
	[3] = {0.92, 0.15, 0.15}, 
	[4] = {0.85, 0.85, 0.13}, 
	[5] = {0.19, 0.85, 0.13}, 
	[6] = {0.19, 0.85, 0.13}, 
	[7] = {0.19, 0.85, 0.13}, 
	[8] = {0.19, 0.85, 0.13}, 
};

--[[ HELPER ]]--
local function GetThreatBarColor(highest)
	local unitReaction = UnitReaction(highest, 'player');
	local r, g, b = 0.5, 0.5, 0.5;

	if(UnitIsPlayer(highest)) then
		local _,token = UnitClass(highest);
		local colors = RAID_CLASS_COLORS[token];
		if(colors) then
			r, g, b = colors.r*255, colors.g*255, colors.b*255
		end 
	elseif(unitReaction) then 
		local colors = REACTION_COLORS[unitReaction];
		if(colors) then
			r, g, b = colors[1], colors[2], colors[3]
		end
	end

	return r, g, b
end 

--[[ HANDLER ]]--
local ThreatBar_OnEvent = function(self, event)
	local isTanking, status, scaledPercent = UnitDetailedThreatSituation('player', 'target')
	if(scaledPercent and (scaledPercent > 0)) then
		-- if SVUI is installed then fade instead of show
		if(self.FadeIn) then
			self:FadeIn()
		else
			self:Show()
		end

		local r,g,b = 0,0.9,0;
		local peak = 0;
		local unitKey, highest;

		if(UnitExists('pet')) then 
			local threat = select(3, UnitDetailedThreatSituation('pet', 'target'))
			if(threat > peak) then 
				peak = threat;
				highest = 'pet';
			end
		end

		if(IsInRaid()) then 
			for i=1,40 do
				unitKey = 'raid'..i;
				if(UnitExists(unitKey) and not UnitIsUnit(unitKey, 'player')) then 
					local threat = select(3, UnitDetailedThreatSituation(unitKey, 'target'))
					if(threat > peak) then 
						peak = threat;
						highest = 'pet';
					end
				end 
			end
		elseif(IsInGroup()) then
			for i=1,4 do
				unitKey = 'party'..i; 
				if(UnitExists(unitKey)) then 
					local threat = select(3, UnitDetailedThreatSituation(unitKey, 'target'))
					if(threat > peak) then 
						peak = threat;
						highest = 'pet';
					end
				end 
			end
		end

		if(highest) then
			if(isTanking or (scaledPercent == 100)) then
				peak = (scaledPercent - peak);
				if(peak > 0) then
					scaledPercent = peak;
				end
			else
				r,g,b = GetThreatBarColor(highest)
			end
		elseif(status) then
			r,g,b = GetThreatStatusColor(status);
		end

		self:SetStatusBarColor(r,g,b)
		self:SetValue(scaledPercent)
		self.text:SetFormattedText('%.0f%%', scaledPercent)
	else
		-- if SVUI is installed then fade instead of hide
		if(self.FadeOut) then
			self:FadeOut(0.2, 1, 0, true)
		else
			self:Hide()
		end
	end 
end 

--[[ LOADER ]]--
function ThreatMeter:Initialize()
	self:SetPoint('LEFT', UIParent, 'CENTER', 50, -50)
	self:SetSize(50, 100)
	self:SetStatusBarTexture(BARFILE)
	self:SetFrameStrata('MEDIUM')
	self:SetOrientation("VERTICAL")
	self:SetMinMaxValues(0, 100)

	self.backdrop = self:CreateTexture(nil,"BACKGROUND")
	self.backdrop:SetAllPoints(self)
	self.backdrop:SetTexture(TEXTUREFILE)
	self.backdrop:SetTexCoord(0.5,0.75,0,0.5)
	self.backdrop:SetBlendMode("ADD")

	self.overlay = self:CreateTexture(nil,"OVERLAY",nil,1)
	self.overlay:SetAllPoints(self)
	self.overlay:SetTexture(TEXTUREFILE)
	self.overlay:SetTexCoord(0.75,1,0,0.5)

	self.text = self:CreateFontString(nil, 'OVERLAY', NumberFontNormal)
	self.text:SetPoint('TOP',self,'BOTTOM',0,0)

	self:RegisterEvent('PLAYER_TARGET_CHANGED');
	self:RegisterEvent('UNIT_THREAT_LIST_UPDATE');
	self:RegisterEvent('GROUP_ROSTER_UPDATE');
	self:RegisterEvent('UNIT_PET');
	self:SetScript("OnEvent", ThreatBar_OnEvent);

	self:SetMovable(true);
	self:RegisterForDrag("LeftButton");
	self:SetClampedToScreen(true);
end