CoffeeNKeys = LibStub("AceAddon-3.0"):NewAddon("CoffeeNKeys", "AceConsole-3.0")
-- Create a container frame
local AceGUI = LibStub("AceGUI-3.0")
local AceComm = LibStub("AceComm-3.0")

IS_DPS = false
IS_HEALER = false
IS_TANK = false
LOWER = 0
UPPER = 0

function CoffeeNKeys:OnInitialize()
	-- Code that you want to run when the addon is first loaded goes here.
	-- AceConsole used as a mixin for AceAddon
	CoffeeNKeys:Print("Hello, world!")
	CoffeeNKeys:RegisterChatCommand("cnkl", "HandleCommand")
	AceComm:RegisterComm("CNKRoleSet", CoffeeNKeys.OnCommReceived)
end

function CoffeeNKeys:HandleCommand(input)
	if input == "list" then
		CoffeeNKeys:ListGroupScore(input)
	elseif input == "start" then
		CoffeeNKeys:OpenAssignFrame(input)
	end
end

function CoffeeNKeys:OnCommReceived(prefix, message, distribution, sender)
	if prefix ~= nil then
		print("Prefix: ".. prefix)
	end
	if message ~= nil then
		print("Message: ".. message)
	end
	if distribution ~= nil then
		print("distribution: ".. distribution)
	end
	if sender ~= nil then
		print("Sender: ".. sender)
	end
end

function CoffeeNKeys:OpenAssignFrame(input)
	local f = AceGUI:Create("Frame")
	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetStatusText("")
	f:SetTitle("Coffee and Keys Role")
	f:SetLayout("Flow")
	f:SetHeight(200)
	local heading = AceGUI:Create("Heading")
	heading.width = "fill"
	heading:SetText("Roles")
	f:AddChild(heading)

	f:AddChild(CoffeeNKeys:CreateRoleCheckbox("DPS"))
	f:AddChild(CoffeeNKeys:CreateRoleCheckbox("Healer"))
	f:AddChild(CoffeeNKeys:CreateRoleCheckbox("Tank"))
	
	local heading = AceGUI:Create("Heading")
	heading:SetText("Key Level")
	heading.width = "fill"
	f:AddChild(heading)

	local keyLowerSlider = AceGUI:Create("Slider")
	keyLowerSlider:SetValue(LOWER)
	keyLowerSlider:SetSliderValues(0, 40, 1)
	keyLowerSlider:SetLabel("Lower Level")
	keyLowerSlider:SetCallback("OnValueChanged", function(widget, event, value) LOWER = value end)
	
	f:AddChild(keyLowerSlider)

	local keyUpperSlider = AceGUI:Create("Slider")
	keyUpperSlider:SetValue(UPPER)
	keyUpperSlider:SetSliderValues(0, 40, 1)
	keyUpperSlider:SetLabel("Upper Level")
	keyUpperSlider:SetCallback("OnValueChanged", function(widget, event, value) UPPER = value end)
	f:AddChild(keyUpperSlider)

	-- Create a button
	local btn = AceGUI:Create("Button")
	btn:SetText("Set")
	btn:SetCallback("OnClick", function() CoffeeNKeys:SetRoles(f) end)

	-- Add the button to the container
	f:AddChild(btn)
	f:Show()
end

function CoffeeNKeys:SetRoles(widget)
	print("DPS: "..tostring(IS_DPS))
	print("Healer: "..tostring(IS_HEALER))
	print("Tank: "..tostring(IS_TANK))
	print("Upper:"..tostring(UPPER))
	print("Lower:"..tostring(LOWER))
	local playerName = GetUnitName("player", false)
	local message = playerName .. "," .. tostring(IS_DPS) .. "," .. tostring(IS_HEALER) .. "," .. tostring(IS_TANK) .. "," .. tostring(UPPER) .. "," .. tostring(LOWER)
	local leader = GetLeader()
	AceComm:SendCommMessage("CNKRoleSet", message, "RAID", leader, "NORMAL")
	AceGUI:Release(widget)
end

function SetRole(role, value)
	if role == "DPS" then
		IS_DPS = value
	elseif role == "Tank" then
		IS_TANK = value
	else
		IS_HEALER = value
	end
end

function CoffeeNKeys:CreateRoleCheckbox(role)
	local radio = AceGUI:Create("CheckBox")
	radio:SetLabel(role)
	radio:SetCallback("OnValueChanged",function(widget,event,value) SetRole(role, value) end )
	radio:SetType("radio")
	return radio
end

function CoffeeNKeys:OnEnable()
	-- Called when the addon is enabled
end

function CoffeeNKeys:OnDisable()
	-- Called when the addon is disabled
end

function CoffeeNKeys:PrintRating(input)
	local ratingS = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(input)
	CoffeeNKeys:Print("Score " .. ratingS.currentSeasonScore)
end

function GetLeader()
	local playerName = GetUnitName("player", false)
	local roster = GetRoster(playerName)
	for i = 1, #roster do
		local entry = roster[i]
		if entry["rank"] == 2 then 
			return entry["name"]
		end
	end
end

function CoffeeNKeys:ListGroupScore(input)
	local playerName = GetUnitName("player", false)
	local roster = GetRoster(playerName)

	local dpsRanked, healersRanked, tanksRanked = SortRoles(roster)
	local parties = ByParty(roster)
	local newParties = ComputeParties(tanksRanked, healersRanked, dpsRanked)
	CoffeeNKeys:Print("new parties: " .. #newParties)
	if input == "assign" then
		AssignParties(parties, newParties)
	else
		CoffeeNKeys:Print("Name - Group - New Group - Role - Score")
		for i = 1, #newParties do
			local party = newParties[i]
			for pm = 1, #party do
				local entry = party[pm]
				CoffeeNKeys:Print(
					entry["name"]
						.. " - "
						.. entry["subgroup"]
						.. " - "
						.. i
						.. " - "
						.. entry["role"]
						.. " - "
						.. entry["score"]
				)
			end
		end
	end
end

function AssignParties(parties, newParties)
	for pInd = 1, 8 do
		local party = newParties[pInd]
		for ind = 1, #party do
			if #party > 0 then
				local entry = party[ind]
				if entry["subgroup"] == pInd then
					-- do nothing
					entry["assignedGroup"] = pInd
				elseif #parties[pInd] < 5 then
					table.insert(parties[pInd], entry)
					entry["assignedGroup"] = pInd
					SetRaidSubgroup(entry["raidInd"], pInd)
				else
					local swapMember = nil
					local swapParty = parties[pInd]
					for pi = 1, #swapParty do
						if swapParty[pi]["assignedGroup"] == nil then
							swapMember = swapParty[pi]
							table.remove(swapParty, pi)
						end
					end
					if swapMember ~= nil then
						local existingParty = parties[entry["subgroup"]]
						table.insert(existingParty, swapMember)
						entry["assignedGroup"] = pInd
						SwapRaidSubgroup(swapMember["raidInd"], entry["raidInd"])
					end
				end
			end
		end
	end
end

function ComputeParties(tanksRanked, healersRanked, dpsRanked)
	local newParties = {}
	for i = 1, 8 do
		newParties[i] = {}
	end

	for tInd = 1, #tanksRanked do
		local entry = tanksRanked[tInd]
		table.insert(newParties[tInd], entry)
	end
	for hInd = 1, #healersRanked do
		local entry = healersRanked[hInd]
		if hInd < #tanksRanked and hInd < 9 then
			table.insert(newParties[hInd], entry)
		else
			table.insert(newParties[8], entry)
		end
	end

	local dCount = 0
	local pInd = 1
	for dInd = 1, #dpsRanked do
		local entry = dpsRanked[dInd]
		table.insert(newParties[pInd], entry)
		dCount = dCount + 1
		if dCount == 3 then
			dCount = 0
			pInd = pInd + 1
		end
	end
	return newParties
end

function GetRoster(playerName)
	local roster = {}
	local groupMems = GetNumGroupMembers()
	for i = 1, groupMems do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
		local playerToken = ""
		if name == playerName then
			playerToken = "player"
		else
			playerToken = "raid" .. i
		end

		local actualRole = UnitGroupRolesAssigned(playerToken)
		local score = 0
		local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(playerToken)
		if false then
			score = ratingSummary.currentSeasonScore
			CoffeeNKeys:Print(ratingSummary.currentSeasonScore)
		else
			ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(name)
			if ratingSummary then
				score = ratingSummary.currentSeasonScore
				CoffeeNKeys:Print(ratingSummary.currentSeasonScore)
			end
		end
		local entry = {}
		entry["name"] = name
		entry["score"] = score
		entry["role"] = actualRole
		entry["raidInd"] = i
		entry["subgroup"] = subgroup
		entry["rank"] = rank
		roster[i] = entry
	end
	return roster
end

function ScoreSort(a, b)
	return a.score > b.score
end

function ByParty(roster)
	local partyRoster = {}
	for i = 1, 8 do
		partyRoster[i] = {}
	end

	for i = 1, #roster do
		local entry = roster[i]
		table.insert(partyRoster[entry["subgroup"]], entry)
	end
	return partyRoster
end

function SortRoles(roster)
	local healersRanked = {}
	local healerInd = 1
	local tanksRanked = {}
	local tanksInd = 1
	local dpsRanked = {}
	local dpsInd = 1
	for i = 1, #roster do
		local entry = roster[i]
		if entry["role"] == "DAMAGER" then
			dpsRanked[dpsInd] = entry
			dpsInd = dpsInd + 1
		elseif entry["role"] == "HEALER" then
			healersRanked[healerInd] = entry
			healerInd = healerInd + 1
		else
			tanksRanked[tanksInd] = entry
			tanksInd = tanksInd + 1
		end
	end
	table.sort(dpsRanked, ScoreSort)
	table.sort(healersRanked, ScoreSort)
	table.sort(tanksRanked, ScoreSort)
	return dpsRanked, healersRanked, tanksRanked
end
