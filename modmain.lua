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

-------------------------------------------------------------------------------------------------------------------------------------------

local function PatchGoggleHUD(inst) -- run this on client because HUD doesn't exist in server.
	if inst._parent.HUD == nil then return end -- If it's running in client, stop here.

	inst._parent.HUD.gogglesover.showother = false
	inst._parent.HUD.gogglesover.ToggleGoggles = function(self, show)
		if show then
			if not self.shown then
				self:Show()
				self:AddChild(self.storm_overlays):MoveToBack()
			end
		elseif not self.showother and not self.owner.replica.inventory:EquipHasTag("goggles") then
			if self.shown then
				self:Hide()
				self.storm_root:AddChild(self.storm_overlays)
			end
		end
	end
end

local function SetGoggleEffect(inst) -- run this on client because HUD doesn't exist in server.
	if inst._parent.HUD == nil then return end -- If it's running in client, stop here.
	local var = inst.setgoggle:value()
	inst._parent.HUD.gogglesover.showother = var
	inst._parent.HUD.gogglesover:ToggleGoggles(var)
end

-------------------------------------------------------------------------------------------------------------------------------------------

local function KeyCheckCommon(inst)
	return inst == GLOBAL.ThePlayer and GLOBAL.TheFrontEnd:GetActiveScreen() ~= nil and GLOBAL.TheFrontEnd:GetActiveScreen().name == "HUD"
end

local function RegisterKeyEvents(classified)
	local parent = classified._parent
	if parent.HUD == nil then return end -- if it's not a client, stop here.

	local modname = GLOBAL.KnownModIndex:GetModActualName("modprettyname")
	local INFOKEY = GetModConfigData("mogglevisionkey", modname) or "KEY_X"
	GLOBAL.TheInput:AddKeyDownHandler(GLOBAL["KEY_"..INFOKEY], function() 
		if KeyCheckCommon(parent) then
			SendModRPCToServer(MOD_RPC["globaltest"]["togglemoggle"], parent) 
		end
	end) 
end

local function ToggleMoggleRPC(inst)
	inst.player_classified.mogglevision:set(not inst.components.playervision.forcenightvision)
end
AddModRPCHandler("globaltest", "togglemoggle", ToggleMoggleRPC)

local NIGHTVISION_COLOURCUBES = {
	day = "images/colour_cubes/mole_vision_off_cc.tex",
    dusk = "images/colour_cubes/mole_vision_on_cc.tex",
    night = "images/colour_cubes/mole_vision_on_cc.tex",
    full_moon = "images/colour_cubes/mole_vision_off_cc.tex",
}

local function ToggleMoggoleScreen(inst)
	local var = inst.mogglevision:value()
	inst._parent.components.playervision:ForceNightVision(var)
	inst._parent.components.playervision:SetCustomCCTable(var and NIGHTVISION_COLOURCUBES or nil)
end

-------------------------------------------------------------------------------------------------------------------------------------------

local function RegisterModNetListeners(inst)
	if GLOBAL.TheWorld and GLOBAL.TheWorld.ismastersim then
		inst._parent = inst.entity:GetParent()
	end

	PatchGoggleHUD(inst) -- Patch both client and server, because it should be synced.
	inst:ListenForEvent("setgoggledirty", SetGoggleEffect) -- Patch both client and server, because it should be synced.

	RegisterKeyEvents(inst)
	inst:ListenForEvent("setmogglevisiondirty", ToggleMoggoleScreen)
end

AddPrefabPostInit("player_classified", function(inst)
	inst.setgoggle = GLOBAL.net_bool(inst.GUID, "setgoggle", "setgoggledirty")
	inst.setgoggle:set(false)

	inst.mogglevision = GLOBAL.net_bool(inst.GUID, "setmogglevision", "setmogglevisiondirty")
	inst.mogglevision:set(false)

	inst:DoTaskInTime(2 * GLOBAL.FRAMES, RegisterModNetListeners) 
	-- delay two more FRAMES to ensure the original NetListeners to run first.
end)

AddModCharacter("esctemplate", "FEMALE")


