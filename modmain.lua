PrefabFiles = {
	"esctemplate",
	"esctemplate_none",
	"testweapon",
	"teststructure",
}

Assets = {
    Asset( "IMAGE", "images/saveslot_portraits/esctemplate.tex" ),
    Asset( "ATLAS", "images/saveslot_portraits/esctemplate.xml" ),

    Asset( "IMAGE", "images/selectscreen_portraits/esctemplate.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/esctemplate.xml" ),
	
    Asset( "IMAGE", "images/selectscreen_portraits/esctemplate_silho.tex" ),
    Asset( "ATLAS", "images/selectscreen_portraits/esctemplate_silho.xml" ),

    Asset( "IMAGE", "bigportraits/esctemplate.tex" ),
    Asset( "ATLAS", "bigportraits/esctemplate.xml" ),
	
	Asset( "IMAGE", "images/map_icons/esctemplate.tex" ),
	Asset( "ATLAS", "images/map_icons/esctemplate.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_esctemplate.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_esctemplate.xml" ),
	
	Asset( "IMAGE", "images/avatars/avatar_ghost_esctemplate.tex" ),
    Asset( "ATLAS", "images/avatars/avatar_ghost_esctemplate.xml" ),
	
	Asset( "IMAGE", "images/avatars/self_inspect_esctemplate.tex" ),
    Asset( "ATLAS", "images/avatars/self_inspect_esctemplate.xml" ),
	
	Asset( "IMAGE", "images/names_esctemplate.tex" ),
    Asset( "ATLAS", "images/names_esctemplate.xml" ),
	
	Asset( "IMAGE", "images/names_gold_esctemplate.tex" ),
    Asset( "ATLAS", "images/names_gold_esctemplate.xml" ),
	
    Asset( "IMAGE", "bigportraits/esctemplate_none.tex" ),
    Asset( "ATLAS", "bigportraits/esctemplate_none.xml" ),

}

AddMinimapAtlas("images/map_icons/esctemplate.xml")

local require = GLOBAL.require
local STRINGS = GLOBAL.STRINGS

STRINGS.CHARACTER_TITLES.esctemplate = "The Sample Character"
STRINGS.CHARACTER_NAMES.esctemplate = "Esc"
STRINGS.CHARACTER_DESCRIPTIONS.esctemplate = "*Perk 1\n*Perk 2\n*Perk 3"
STRINGS.CHARACTER_QUOTES.esctemplate = "\"Quote\""

STRINGS.CHARACTERS.ESCTEMPLATE = require "speech_esctemplate"

STRINGS.NAMES.ESCTEMPLATE = "Esc"
STRINGS.NAMES.TESTWEAPON = "Test Weapon"
STRINGS.NAMES.TESTSTRUCTURE = "Test Structure"

AddPrefabPostInit("crow", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end
	
	inst.components.lootdropper.randomloot[2]["weight"] = 0.25
end)

AddPrefabPostInit("mound", function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	local DoOldFinishCallback = inst.components.workable.onfinish
		
	inst.components.workable.onfinish = function(inst, worker)
		if not worker.grave_sanity_loss then 
			return DoOldFinishCallback(inst, worker) 
		end

		local sanity_old = worker.components.sanity.current
		DoOldFinishCallback(inst, worker)
		worker.components.sanity.current = sanity_old
	end
end)

local function OnPhaseChanged(inst, phase)
	if phase == "night" then
		inst.components.talker:Say("Oh no its night")	
	else
		inst.components.talker:Say("Good not night time")
	end
end

AddPlayerPostInit(function(inst)
	if not GLOBAL.TheWorld.ismastersim then
		return
	end

	if inst == GLOBAL.AllPlayers[1] then
		inst:WatchWorldState("phase", OnPhaseChanged)
		OnPhaseChanged(inst, GLOBAL.TheWorld.state.phase)
	end
end)

function GLOBAL.SearchUserId(name) 
	local ClientObjs = GLOBAL.TheNet:GetClientTable()
	local result = {}
	if ClientObjs ~= nil and #ClientObjs > 0 then
		for i, v in ipairs(ClientObjs) do
			if v.name == name then
				table.insert(result, v.userid)
			end
		end
	end
	return result
end

function GLOBAL.GetPlayerObjectByUserName(name)
	local ids = GLOBAL.SearchUserId(name) 
	if #ids == 0 then
		print("Couldn't find any user named \""..name.."\"")
		return
	end

	local result = {}
	for k, v in pairs(ids) do
		for _, player in pairs(GLOBAL.AllPlayers) do
			if player.userid == v then
				table.insert(result, player)
			end
		end
	end

	return #result == 1 and result[1] or result
end


AddModCharacter("esctemplate", "FEMALE")


