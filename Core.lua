CoffeeNKeys = LibStub("AceAddon-3.0"):NewAddon("CoffeeNKeys", "AceConsole-3.0")
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")

local bunnyLDB = ldb:NewDataObject("Bunnies", {  
	type = "data source",  
	text = "Bunnies!",  
	icon = "Interface\\Icons\\INV_Chest_Cloth_17",  
	OnClick = function() CoffeeNKeys:OpenSetRoleFrame() end,  
})  
-- Create a container frame
local AceGUI = LibStub("AceGUI-3.0")
local AceComm = LibStub("AceComm-3.0")
local icon = LibStub("LibDBIcon-1.0") 
local TANKS = {}
local HEALERS = {}
local DPS = {}
IS_DPS = false
IS_HEALER = false
IS_TANK = false
LOWER_HEAL = 2
UPPER_HEAL= 2
LOWER_TANK = 2
UPPER_TANK= 2
LOWER_DPS = 2
UPPER_DPS = 2


function Split(inputstr, sep)
	if sep == nil then
	  sep = "%s"
	end
	local t = {}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
	  table.insert(t, str)
	end
	return t
  end

function CoffeeNKeys:OnInitialize()
	-- Code that you want to run when the addon is first loaded goes here.
	-- AceConsole used as a mixin for AceAddon
	CoffeeNKeys:Print("Hello, world!")
	CoffeeNKeys:RegisterChatCommand("cnkl", "HandleCommand")
	AceComm:RegisterComm("CNKRoleSet", CoffeeNKeys.OnCommReceived)
	self.db = LibStub("AceDB-3.0"):New("BunniesDB", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})
	icon:Register("Bunnies", bunnyLDB, self.db.profile.minimap)
end

function CoffeeNKeys:HandleCommand(input)
	if input == "list" then
		CoffeeNKeys:ListGroupScore(input)
	elseif input == "start" then
		CoffeeNKeys:OpenSetRoleFrame(input)
	elseif input == "raid" then
		CoffeeNKeys:ViewRaidFrame(input)
	end
end

function CoffeeNKeys:OnCommReceived(prefix, message, distribution, sender)
	if prefix ~= nil then
		print("Prefix: ".. prefix)
		CoffeeNKeys:AddTableEntry(prefix, distribution)
	end
	if message ~= nil then
		print("\nMessage: ".. message)
		
	end
	if distribution ~= nil then
		print("\ndistribution: ".. distribution)
	end
	if sender ~= nil then
		print("\nSender: ".. sender)
	end
end

function CoffeeNKeys:AddTableEntry(message, sender)
	local stringtoboolean={ ["true"]=true, ["false"]=false }
	local messageValues = Split(message, ",")
	local player = messageValues[1]
	local dps = stringtoboolean[messageValues[2]]
	local heal = stringtoboolean[messageValues[3]]
	local tank = stringtoboolean[messageValues[4]]
	local dpsUpper = messageValues[5]
	local dpsLower = messageValues[6]
	local healUpper = messageValues[7]
	local healLower = messageValues[8]
	local tankUpper = messageValues[9]
	local tankLower = messageValues[10]

	if dps then
		local entry = {}
		entry.low = tonumber(dpsLower)
		entry.high = tonumber(dpsUpper)
		DPS[player] = entry
	end
	if heal then
		local entry = {}
		entry.low = tonumber(healLower)
		entry.high = tonumber(healUpper)
		HEALERS[player] = entry
	end
	if tank then
		local entry = {}
		entry.low = tonumber(tankLower)
		entry.high = tonumber(tankUpper)
		TANKS[player] = entry
	end
	
	for k, v in pairs(DPS) do
		print(k .. " " .. tostring(v.low) .. " " .. tostring(v.high))
	end
	
	for k, v in pairs(HEALERS) do
		print(k .. " " .. tostring(v.low) .. " " .. tostring(v.high))
	end

	for k, v in pairs(TANKS) do
		print(k .. " " .. tostring(v.low) .. " " .. tostring(v.high))
	end
	
end

function CoffeeNKeys:OpenSetRoleFrame(input)
	local f = AceGUI:Create("Frame")
	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetStatusText("")
	f:SetTitle("Coffee and Keys Role")
	f:SetLayout("Flow")
	f:SetHeight(300)

	-- local heading = AceGUI:Create("Heading")
	-- heading:SetText("Key Level")
	-- heading.width = "fill"
	-- f:AddChild(heading)
	
	-- f:AddChild(CoffeeNKeys:CreateRoleCheckbox("Healer"))
	CoffeeNKeys:CreateRole(f, "DPS", LOWER_DPS, UPPER_DPS)
	CoffeeNKeys:CreateRole(f, "Healer", LOWER_HEAL, UPPER_HEAL)
	CoffeeNKeys:CreateRole(f, "Tank", LOWER_TANK, UPPER_TANK)

	-- Create a button
	local btn = AceGUI:Create("Button")
	btn:SetText("Set")
	btn:SetCallback("OnClick", function() CoffeeNKeys:SetRoles(f) end)

	-- Add the button to the container
	f:AddChild(btn)
	f:Show()
end

function ToSortedList(t)
	local newList = {}
	
	for k, v in pairs(t) do
		local entry = {}
		entry.name = k
		entry.low = v.low
		entry.high = v.high
		table.insert(newList, entry)
	end
	table.sort(newList, LevelSort)
	return newList
end

function CreateRow(role, existing) 
	local row = {}
	table.insert(row, {value=role})
	table.insert(row, {value=existing.name})
	table.insert(row, {value=existing.low})
	table.insert(row, {value=existing.high})
	return row
end

function CoffeeNKeys:ViewRaidFrame(input)
	local frame = AceGUI:Create("Frame")
	local ScrollingTable = LibStub("ScrollingTable");
	local columnsList = {
        { ["name"] = "Role",    ["width"] = 60 },
        { ["name"] = "Name", ["width"] = 150, },
        { ["name"] = "Lower Level",   ["width"] = 90, },
        { ["name"] = "Upper Level",  ["width"] = 90, ["defaultsort"] = "dsc"},
    }


	self.roleTable = ScrollingTable:CreateST(columnsList, 16, 16, nil, frame.frame);
	-- self.roleTable.frame:SetPoint("TOP", frame.frame, "TOP", self.defaults.tables.anchors.top.x, self.defaults.tables.anchors.top.y);
	-- self.tables.roleTable.frame:SetPoint("LEFT", frame.frame, "LEFT", self.defaults.tables.anchors.left.x, self.defaults.tables.anchors.left.y);
	self.roleTable:EnableSelection(true)
	self.roleTable:SortData()
	self.roleTable:Hide()
	local tableData = {}
	local tanks = ToSortedList(TANKS)
	local healers = ToSortedList(HEALERS)
	local dpss = ToSortedList(DPS)
	local dpsInd = 1
	for i = 1, #tanks do
		local tank = tanks[i]
		local row = CreateRow("TANK", tank)
		table.insert(tableData, {cols = row})
		if i <= #healers then
			local healer = healers[i]
			row = CreateRow("HEAL", healer)
			table.insert(tableData, {cols = row})
		end
		if dpsInd <= #dpss then
			local step = math.min(dpsInd+2, #dpss)
			for j = dpsInd,step do
				local dps = dpss[j]
				row = CreateRow("DPS", dps)
				table.insert(tableData, {cols = row})
			end
			dpsInd = step + 1
		end
	end

	for i = #tanks+1, #healers do
		if i <= #healers then
			local healer = healers[i]
			local row = CreateRow("HEAL", healer)
			table.insert(tableData, {cols = row})
		end
	end

	for i = dpsInd, #dpss do
		local dps = dpss[i]
		local row = CreateRow("DPS", dps)
		table.insert(tableData, {cols = row})
	end
	
	-- for k, v in pairs(DPS) do
	-- 	local row = {}
	-- 	table.insert(row, {value="DPS"})
	-- 	table.insert(row, {value=k})
	-- 	table.insert(row, {value=v[1]})
	-- 	table.insert(row, {value=v[2]})
	-- 	table.insert(tableData, {cols = row})
	-- end
	
	-- for k, v in pairs(HEALERS) do
	-- 	local row = {}
	-- 	table.insert(row, {value="HEAL"})
	-- 	table.insert(row, {value=k})
	-- 	table.insert(row, {value=v[1]})
	-- 	table.insert(row, {value=v[2]})
	-- 	table.insert(tableData, {cols = row})
	-- end

	self.roleTable:Show()
	self.roleTable:SetData(tableData)
	self.roleTable:SortData()
	self.roleTable:Refresh()
end

function CoffeeNKeys:SetRoles(widget)
	-- print("DPS: "..tostring(IS_DPS))
	-- print("Healer: "..tostring(IS_HEALER))
	-- print("Tank: "..tostring(IS_TANK))
	-- print("Upper:"..tostring(UPPER_DPS).." "..tostring(UPPER_HEAL).." "..tostring(UPPER_TANK))
	-- print("Lower:"..tostring(LOWER_DPS).." "..tostring(LOWER_HEAL).." "..tostring(LOWER_TANK))
	local playerName = GetUnitName("player", false)
	local message = playerName .. "," .. tostring(IS_DPS) .. "," .. tostring(IS_HEALER) .. "," .. tostring(IS_TANK) .. "," .. tostring(UPPER_DPS) .. "," .. tostring(LOWER_DPS) .. "," .. tostring(UPPER_HEAL) .. "," .. tostring(LOWER_HEAL) .. "," .. tostring(UPPER_TANK) .. "," .. tostring(LOWER_TANK)
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

function SetRoleLowerSlider(role, value)
	if role == "DPS" then
		LOWER_DPS = value
	elseif role == "Tank" then
		LOWER_TANK = value
	else
		LOWER_HEAL = value
	end
end

function SetRoleUpperSlider(role, value)
	if role == "DPS" then
		UPPER_DPS = value
	elseif role == "Tank" then
		UPPER_TANK = value
	else
		UPPER_HEAL = value
	end
end

function CoffeeNKeys:CreateRoleCheckbox(role)
	local radio = AceGUI:Create("CheckBox")
	radio:SetLabel(role)
	radio:SetCallback("OnValueChanged",function(widget,event,value) SetRole(role, value) end )
	radio:SetType("radio")
	return radio
end

function CoffeeNKeys:CreateRole(parent, role, lower, upper)
	
	local heading = AceGUI:Create("Heading")
	heading.width = "fill"
	heading:SetText(role)
	parent:AddChild(heading)

	local radio = AceGUI:Create("CheckBox")
	radio:SetLabel(role)
	radio:SetCallback("OnValueChanged",function(widget,event,value) SetRole(role, value) end )
	radio:SetType("radio")
	parent:AddChild(radio)

	local lowSlider = AceGUI:Create("Slider")
	lowSlider:SetValue(lower)
	lowSlider:SetSliderValues(2, 20, 1)
	lowSlider:SetLabel("Lower Level")
	lowSlider:SetCallback("OnValueChanged", function(widget, event, value) SetRoleLowerSlider(role, value) end)
	
	parent:AddChild(lowSlider)

	local upperSlider = AceGUI:Create("Slider")
	upperSlider:SetValue(upper)
	upperSlider:SetSliderValues(2, 20, 1)
	upperSlider:SetLabel("Upper Level")
	upperSlider:SetCallback("OnValueChanged", function(widget, event, value)  SetRoleUpperSlider(role, value) end)
	parent:AddChild(upperSlider)
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

function LevelSort(a, b)
	return a.high > b.high
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
