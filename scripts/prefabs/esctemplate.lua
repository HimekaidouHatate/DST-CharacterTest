local MakePlayerCharacter = require "prefabs/player_common"

local assets = {
    Asset("SCRIPT", "scripts/prefabs/player_common.lua"),
}
local prefabs = {}

local start_inv = {
}

local function onbecamehuman(inst)
	inst.components.locomotor:SetExternalSpeedMultiplier(inst, "esctemplate_speed_mod", 1)
end

local function onbecameghost(inst)
   inst.components.locomotor:RemoveExternalSpeedMultiplier(inst, "esctemplate_speed_mod")
end

local function onload(inst)
    inst:ListenForEvent("ms_respawnedfromghost", onbecamehuman)
    inst:ListenForEvent("ms_becameghost", onbecameghost)

    if inst:HasTag("playerghost") then
        onbecameghost(inst)
    else
        onbecamehuman(inst)
    end
end

local FAIL_CHANCE = 1

local function Fail_Craft(inst)
	local _Dobuild = inst.components.builder.DoBuild
	function inst.components.builder.DoBuild(self, recname, pt, rotation, skin)
		if math.random() <= FAIL_CHANCE then
			local recipe = GetValidRecipe(recname)
			if self.buffered_builds[recname] ~= nil then -- is bufferable?
				return _Dobuild(self, recname, pt, rotation, skin)
			end

			self:RemoveIngredients(self:GetIngredients(recname), recipe) -- or Remove its ingredients

			local item = SpawnPrefab(recipe.product, recipe.chooseskin or skin, nil, self.inst.userid) or nil
			if item == nil then return end
			item.Transform:SetPosition(inst.Transform:GetWorldPosition())
			if not item.components.lootdropper then item:AddComponent("lootdropper") end
			if item.components.stackable ~= nil then
				item.components.stackable:SetStackSize(recipe.numtogive)
			end

			self.inst:PushEvent("refreshcrafting")

			inst.components.talker:Say("Oops!")
			item.components.lootdropper:DropLoot()
			item:Remove()
			
			return true -- to prevent action fail speech.
		else
			return _Dobuild(self, recname, pt, rotation, skin)
		end
	end
end

local function HateSpoilageAndMeat(inst)
	local _PrefersToEat = inst.components.eater.PrefersToEat
	function inst.components.eater.PrefersToEat(self, food)
		local condition = not (food:HasTag("stale") or food:HasTag("spoiled") or (food.components.edible.foodtype == FOODTYPE.MEAT and food:HasTag("cookable")) ) 
		return condition and _PrefersToEat(self, food)
	end
end

local AuraRadius = 5

local function AddScienceBonusRemovalHandler(inst)
	if inst.ScienceAuraRangeCheck ~= nil then return end
	inst.ScienceAuraRangeCheck = inst:DoPeriodicTask(10 * FRAMES, function(inst)
		if FindEntity(inst, AuraRadius, nil, {"scienceprovider"}) == nil then
			inst:RemoveTag("scienceaura")
			local bonus = inst.components.builder.science_bonus
			inst.components.builder.science_bonus = bonus - 1 
			inst.ScienceAuraRangeCheck:Cancel()
			inst.ScienceAuraRangeCheck = nil
		end
	end)
end

local function ScienceAura(inst)
	inst:AddTag("scienceprovider")
	inst.components.builder.science_bonus = 1
	inst:DoPeriodicTask(10 * FRAMES, function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, AuraRadius, {"player"}, {"scienceaura", "playerghost", "scienceprovider"})
		-- Added tag check to prevent perk vanishing that increases tech bonus(like Wickerbottom or other modded characters)
		if ents ~= nil then 
			for k, player in pairs(ents) do
				player:AddTag("scienceaura")
				local bonus = player.components.builder.science_bonus -- Rename it if you want.
				-- Available tech trees : science, magic, ancient, shadow   
				player.components.builder.science_bonus = bonus + 1
				AddScienceBonusRemovalHandler(player)
			end
		end
	end)
end

local common_postinit = function(inst) 
	inst.MiniMapEntity:SetIcon( "esctemplate.tex" )
end

local master_postinit = function(inst)
	inst.soundsname = "willow"
	
	inst.components.health:SetMaxHealth(150)
	inst.components.hunger:SetMax(150)
	inst.components.sanity:SetMax(200)
	
    inst.components.combat.damagemultiplier = 1
	
	inst.components.hunger.hungerrate = 1 * TUNING.WILSON_HUNGER_RATE
	
	Fail_Craft(inst)
	--HateSpoilageAndMeat(inst)
	--ScienceAura(inst)
	
	inst.OnLoad = onload
	inst.OnNewSpawn = onload
end

return MakePlayerCharacter("esctemplate", prefabs, assets, common_postinit, master_postinit, start_inv)
