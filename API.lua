local IGV = InventoryGridView
local settings = IGV.settings

--returns true if the skin was successfully registered, false if it was not.
function InventoryGridView_RegisterSkin(name, background, outline, highlight)
	table.insert(settings.skinChoices, name)

	settings.skins[name] = {
		BACKGROUND = background or "InventoryGridView/skins/Classic/classic_background.dds",
		OUTLINE = outline or "InventoryGridView/skins/Classic/classic_outline.dds",
		HOVER = highlight or "InventoryGridView/skins/Classic/classic_hover.dds",
	}
end