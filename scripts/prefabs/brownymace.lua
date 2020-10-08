local assets=
{
	Asset("ANIM", "anim/brownymace.zip"),
	Asset("ANIM", "anim/swap_brownymace.zip"),
	Asset("ATLAS", "images/inventoryimages/brownymace.xml")
}



local function onequip(inst, owner) 
    owner.AnimState:OverrideSymbol("swap_object", "swap_brownymace", "swap_nightmaresword")
    owner.AnimState:Show("ARM_carry") 
    owner.AnimState:Hide("ARM_normal")
end

local function onunequip(inst, owner) 
    owner.AnimState:Hide("ARM_carry") 
    owner.AnimState:Show("ARM_normal") 
end


local function fn(Sim)
	local inst = CreateEntity() 
	
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
    inst.entity:AddNetwork() 
	
    MakeInventoryPhysics(inst)
	
	inst.AnimState:SetBank("brownymace")
    inst.AnimState:SetBuild("brownymace")
    inst.AnimState:PlayAnimation("idle")
	
	inst:AddTag("sharp")
	
    local swap_data = {
		bank = "brownymace",
		sym_build = "swap_brownymace",
		sym_name = "swap_nightmaresword",
	}
	
    MakeInventoryFloatable(inst, "med", 0.05, {1.0, 0.4, 1.0}, true, -17.5, swap_data)
    
    inst.entity:SetPristine()
	
    if not TheWorld.ismastersim then
        return inst
    end
	
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(51)


    -------
    
    MakeHauntableLaunch(inst)
	
    inst:AddComponent("inspectable")
    
    inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/brownymace.xml"
    
    inst:AddComponent("equippable")

    inst.components.equippable:SetOnEquip( onequip )
    inst.components.equippable:SetOnUnequip( onunequip )
	
    inst:AddComponent("lootdropper")
	
    return inst
end


return Prefab( "common/inventory/brownymace", fn, assets, prefabs) 
