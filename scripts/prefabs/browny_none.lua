local assets =
{
	Asset( "ANIM", "anim/browny.zip" ),
	Asset( "ANIM", "anim/ghost_browny_build.zip" ),
}

local skins =
{
	normal_skin = "browny",
	ghost_skin = "ghost_browny_build",
}

local base_prefab = "browny"

local tags = {"BROWNY", "BASE"}

return CreatePrefabSkin("browny_none",
{
	base_prefab = base_prefab, 
	type = "base",
	skins = skins, 
	assets = assets,
	skin_tags = tags,
	rarity = "Character",
	build_name_override = base_prefab,
})