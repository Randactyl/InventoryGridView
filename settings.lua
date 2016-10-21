local IGV = InventoryGridView
IGV.settings = {}

local util = IGV.util
local settings = IGV.settings
local vars
settings.vars = nil
settings.varsVersion = 4
settings.skinChoices = {}
settings.skins = {}

function settings.InitializeSettings()
	local defaultVars = {
		isGrid = {
			[IGVID_INVENTORY]  = true,
            [IGVID_BANK]       = true,
            [IGVID_GUILD_BANK] = true,
            [IGVID_CRAFT_BAG]  = true,
            [IGVID_QUICKSLOT]  = true,
            [IGVID_STORE]      = true,
            [IGVID_BUY_BACK]   = true,
		},
		gridIconSize = 64,
		gridIconZoomLevel = 1.2,
		isTooltipOffset = true,
		minOutlineQuality = ITEM_QUALITY_MAGIC,
        showQualityOutline = true,
        skinChoice = "Clean by Tonyleila",
    }

    settings.vars = ZO_SavedVars:NewAccountWide("InventoryGridView_Settings", settings.varsVersion, nil, defaultVars)
	vars = settings.vars

	local function createOptionsMenu()
		local textureSet = settings.GetTextureSet()
		local QUALITY_OPTIONS = {
			"Trash", "Normal", "Magic", "Arcane", "Artifact", "Legendary",
		}
		local QUALITY = {
			["Trash"] = ITEM_QUALITY_TRASH,
			["Normal"] = ITEM_QUALITY_NORMAL,
			["Magic"] = ITEM_QUALITY_MAGIC,
			["Arcane"] = ITEM_QUALITY_ARCANE,
			["Artifact"] = ITEM_QUALITY_ARTIFACT,
			["Legendary"] = ITEM_QUALITY_LEGENDARY,
		}

		--example texture for skin and slider
		local example = WINDOW_MANAGER:CreateControl("InventoryGridViewSettingsExampleTextureControl", GuiRoot, CT_CONTROL)
		example:SetMouseEnabled(true)

		local exampleBackground = WINDOW_MANAGER:CreateControl("$(parent)Background", example, CT_TEXTURE)
        exampleBackground:SetAnchorFill(example)
        exampleBackground:SetTexture(textureSet.BACKGROUND)

        local exampleOutline = WINDOW_MANAGER:CreateControl("$(parent)Outline", example, CT_TEXTURE)
        exampleOutline:SetAnchorFill(example)
        exampleOutline:SetTexture(textureSet.OUTLINE)
		exampleOutline:SetHidden(not vars.allowRarityColor)

	 	local exampleHover = WINDOW_MANAGER:CreateControl("$(parent)Hover", example, CT_TEXTURE)
        exampleHover:SetAnchorFill(example)
        exampleHover:SetTexture(textureSet.HOVER)
        exampleHover:SetHidden(true)

		--now actually set up the panel
		local panel = {
			type = "panel",
			name = GetString(SI_INVENTORYGRIDVIEW_ADDON_NAME),
			author = "Randactyl",
			version = IGV.addonVersion,
			website = "http://www.esoui.com/downloads/info65-InventoryGridView.html",
			slashCommand = "/inventorygridview",
			registerForRefresh = true,
			registerForDefaults = true,
		}
		local optionsData = {
			[1] = {
				type = "checkbox",
				name = SI_INVENTORYGRIDVIEW_OFFSETITEMTOOLTIPS_CHECKBOX_LABEL,
				tooltip = SI_INVENTORYGRIDVIEW_OFFSETITEMTOOLTIPS_CHECKBOX_TOOLTIP,
				getFunc = function() return vars.isTooltipOffset end,
				setFunc = function(value)
					vars.isTooltipOffset = value
				end,
				default = defaultVars.isTooltipOffset,
			},
			[2] = {
				type = "dropdown",
                name = SI_INVENTORYGRIDVIEW_SKIN_DROPDOWN_LABEL,
                tooltip = SI_INVENTORYGRIDVIEW_SKIN_DROPDOWN_TOOLTIP,
                choices = settings.skinChoices,
                getFunc = function() return vars.skinChoice end,
                setFunc = function(value)
					vars.skinChoice = value

					local textureSet = settings.GetTextureSet()

					exampleBackground:SetTexture(textureSet.BACKGROUND)
                    exampleOutline:SetTexture(textureSet.OUTLINE)
                    exampleHover:SetTexture(textureSet.HOVER)
				end,
				default = defaultVars.skinChoice,
				reference = "InventoryGridViewSettingsSkinDropdown",
			},
			[3] = {
				type = "checkbox",
				name = SI_INVENTORYGRIDVIEW_QUALITYOUTLINES_CHECKBOX_LABEL,
				tooltip = SI_INVENTORYGRIDVIEW_QUALITYOUTLINES_CHECKBOX_TOOLTIP,
				getFunc = function()
					return vars.showQualityOutline
				end,
				setFunc = function(value)
					vars.showQualityOutline = value
					exampleOutline:SetHidden(not value)
				end,
				default = defaultVars.showQualityOutline,
				reference = "InventoryGridViewSettingsQualityOutlines",
			},
			[4] = {
				type = "dropdown",
				name = SI_INVENTORYGRIDVIEW_MINOUTLINEQUALITY_DROPDOWN_LABEL,
				tooltip = SI_INVENTORYGRIDVIEW_MINOUTLINEQUALITY_DROPDOWN_TOOLTIP,
				choices = QUALITY_OPTIONS,
				getFunc = function() return QUALITY_OPTIONS[vars.minOutlineQuality + 1] end,
				setFunc = function(value)
					vars.minOutlineQuality = QUALITY[value]
				end,
				disabled = function() return not vars.showQualityOutline end,
				default = QUALITY_OPTIONS[defaultVars.minOutlineQuality + 1],
				reference = "InventoryGridViewSettingsMinRarityDropdown",
			},
			[5] = {
				type = "slider",
				name = SI_INVENTORYGRIDVIEW_GRIDICONSIZE_SLIDER_LABEL,
				tooltip = SI_INVENTORYGRIDVIEW_GRIDICONSIZE_SLIDER_TOOLTIP,
				min = 24,
				max = 96,
				step = 4,
				getFunc = function() return vars.gridIconSize end,
				setFunc = function(value)
					vars.gridIconSize = value

					example:SetDimensions(value, value)
				end,
				default = defaultVars.gridIconSize,
				reference = "InventoryGridViewSettingsGridIconSize",
			},
			[6] = {
				type = "slider",
				name = SI_INVENTORYGRIDVIEW_ICONZOOMLEVEL_SLIDER_LABEL,
				tooltip = SI_INVENTORYGRIDVIEW_ICONZOOMLEVEL_SLIDER_TOOLTIP,
				min = 100,
				max = 150,
				step = 10,
				getFunc = function() return vars.gridIconZoomLevel * 100 end,
				setFunc = function(value)
					vars.gridIconZoomLevel = value / 100
				end,
				default = defaultVars.gridIconZoomLevel * 100,
			},
			[7] = {
				type = "custom",
				reference = "InventoryGridViewSettingsExampleTextureLAMControl",
			},
		}

		util.lam:RegisterAddonPanel("InventoryGridViewSettingsPanel", panel)
		util.lam:RegisterOptionControls("InventoryGridViewSettingsPanel", optionsData)

		local function onLAMPanelCreated(createdPanel)
			if createdPanel:GetName() ~= "InventoryGridViewSettingsPanel" then return end

			local function onMouseEnter()
				exampleHover:SetHidden(false)
            end
            local function onMouseExit()
                exampleHover:SetHidden(true)
            end

			example:SetParent(InventoryGridViewSettingsPanel)
			example:SetDimensions(vars.gridIconSize, vars.gridIconSize)
			example:SetAnchor(CENTER, InventoryGridViewSettingsExampleTextureLAMControl, CENTER)
			example:SetHandler("OnMouseEnter", onMouseEnter)
			example:SetHandler("OnMouseExit", onMouseExit)
		end
		CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", onLAMPanelCreated)
	end

    createOptionsMenu()
end

function settings.IsGrid(IGVId)
	return vars.isGrid[IGVId]
end

function settings.ToggleGrid(IGVId)
	vars.isGrid[IGVId] = not vars.isGrid[IGVId]
end

function settings.ShowQualityOutline()
	return vars.showQualityOutline
end

function settings.GetMinOutlineQuality()
	return vars.minOutlineQuality
end

function settings.GetGridIconSize()
	return vars.gridIconSize
end

function settings.GetTextureSet()
	if settings.skins[vars.skinChoice] == nil then
		vars.skinChoice = "Rushmik"
	end

	return settings.skins[vars.skinChoice]
end

function settings.GetGridIconZoomLevel()
	return vars.gridIconZoomLevel
end

function settings.IsTooltipOffset()
	return vars.isTooltipOffset
end