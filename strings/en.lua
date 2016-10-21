local strings = {
    ["SI_INVENTORYGRIDVIEW_ADDON_NAME"] = "Inventory Grid View",

    ["SI_INVENTORYGRIDVIEW_OFFSETITEMTOOLTIPS_CHECKBOX_LABEL"] = "Offset Item Tooltips",
    ["SI_INVENTORYGRIDVIEW_OFFSETITEMTOOLTIPS_CHECKBOX_TOOLTIP"] = "Move item tooltips to the left of the scroll list so they do not cover the item grid.",

    ["SI_INVENTORYGRIDVIEW_SKIN_DROPDOWN_LABEL"] = "Skin",
    ["SI_INVENTORYGRIDVIEW_SKIN_DROPDOWN_TOOLTIP"] = "The set of textures to use in the grid view.",

    ["SI_INVENTORYGRIDVIEW_QUALITYOUTLINES_CHECKBOX_LABEL"] = "Quality Outlines",
    ["SI_INVENTORYGRIDVIEW_QUALITYOUTLINES_CHECKBOX_TOOLTIP"] = "A prominent outline texture for grid icons.",

    ["SI_INVENTORYGRIDVIEW_MINOUTLINEQUALITY_DROPDOWN_LABEL"] = "Minimum Outline Quality",
    ["SI_INVENTORYGRIDVIEW_MINOUTLINEQUALITY_DROPDOWN_TOOLTIP"] = "Quality outline textures will only be shown on items at or above this quality.",

    ["SI_INVENTORYGRIDVIEW_GRIDICONSIZE_SLIDER_LABEL"] = "Icon Size",
    ["SI_INVENTORYGRIDVIEW_GRIDICONSIZE_SLIDER_TOOLTIP"] = "Set how big or small the grid icons are. Icon area is the square of this number.",

    ["SI_INVENTORYGRIDVIEW_ICONZOOMLEVEL_SLIDER_LABEL"] = "Icon Zoom Level",
    ["SI_INVENTORYGRIDVIEW_ICONZOOMLEVEL_SLIDER_TOOLTIP"] = "Set icon zoom level (on mouse over) from none to default.",

    ["SI_BINDING_NAME_INVENTORYGRIDVIEW_TOGGLE"] = "Toggle Grid/List View",
}

for stringId, stringValue in pairs(strings) do
    ZO_CreateStringId(stringId, stringValue)
	SafeAddVersion(stringId, 1)
end