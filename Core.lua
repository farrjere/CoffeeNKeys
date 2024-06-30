MyAddon = LibStub("AceAddon-3.0"):NewAddon("MyAddon", "AceConsole-3.0")

function MyAddon:OnInitialize()
	-- Code that you want to run when the addon is first loaded goes here.
	-- AceConsole used as a mixin for AceAddon
	MyAddon:Print("Hello, world!")
	MyAddon:RegisterChatCommand("cnkl", "ListGroupScore")
end

function MyAddon:OnEnable()
	-- Called when the addon is enabled
end

function MyAddon:OnDisable()
	-- Called when the addon is disabled
end

function MyAddon:ListGroupScore(input)
	MyAddon:Print("Hi from the slash command")
	local playerName = GetUnitName("player")
	local roster = GetRoster(playerName)

	MyAddon:Print(#roster)
	local dpsRanked, healersRanked, tanksRanked = SortRoles(roster)
	MyAddon:Print(tanksRanked)
	local parties = ByParty(roster)
	local newParties = ComputeParties(tanksRanked, healersRanked, dpsRanked)
	if input == "assign" then
		AssignParties(tanksRanked, healersRanked, dpsRanked, parties, newParties)
	else
		MyAddon:Print("Name - Group - Role - Score")
		for i = 1, #newParties do
			local party = newParties[i]
			for pm = 1, #party do
				local entry = party[pm]
				MyAddon:Print(
					entry["name"] .. " - " .. entry["subgroup"] .. " - " .. entry["role"] .. " - " .. entry["score"]
				)
			end
		end
	end
end

function AssignParties(tanksRanked, healersRanked, dpsRanked, parties, newParties)
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
		if ratingSummary ~= nil then
			score = ratingSummary.currentSeasonScore
			MyAddon:Print(ratingSummary.currentSeasonScore)
		end
		local entry = {}
		entry["name"] = name
		entry["score"] = score
		entry["role"] = actualRole
		entry["raidInd"] = i
		entry["subgroup"] = subgroup
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
	local newRoster = {}
	local healersRanked = {}
	local healerInd = 1
	local tanksRanked = {}
	local tanksInd = 1
	local dpsRanked = {}
	local dpsInd = 1
	for i = 1, #roster do
		entry = roster[i]
		if roster["role"] == "DAMAGER" then
			dpsRanked[dpsInd] = entry
			dpsInd = dpsInd + 1
		elseif roster["role"] == "HEALER" then
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
