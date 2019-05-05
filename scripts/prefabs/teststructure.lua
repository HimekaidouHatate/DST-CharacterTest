local assets = {
    Asset("ANIM", "anim/sentryward.zip"),
}

local function OnInit(inst)
	inst.icon = SpawnPrefab("globalmapicon")
	inst.icon:TrackEntity(inst)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork()
	inst.entity:AddMiniMapEntity()
	MakeObstaclePhysics(inst, .75)

    inst:AddTag("structure")

	inst.MiniMapEntity:SetIcon("sentryward.png")
	inst.MiniMapEntity:SetCanUseCache(false)
	inst.MiniMapEntity:SetDrawOverFogOfWar(true)

	inst.AnimState:SetBank("sentryward")
    inst.AnimState:SetBuild("sentryward")
    inst.AnimState:PlayAnimation("idle_full_loop", true)
	
    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

	inst:AddComponent("inspectable")

	inst:DoTaskInTime(0, OnInit)

    return inst
end

return Prefab("teststructure", fn, assets) 