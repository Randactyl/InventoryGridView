local IGV = InventoryGridView
IGV.settings = {}

local util = IGV.util
local settings = IGV.settings
local vars
settings.vars = nil
settings.varsVersion = 4
settings.skinChoices = {}
settings.skins = {}

--remove
local BAGS = ZO_PlayerInventoryBackpack		                         --IGVId = 1
local QUEST = ZO_PlayerInventoryQuest		                         --IGVId = 2
local BANK = ZO_PlayerBankBackpack			                         --IGVId = 3
local GUILD_BANK = ZO_GuildBankBackpack		                         --IGVId = 4
local STORE = ZO_StoreWindowList			                         --IGVId = 5
local BUYBACK = ZO_BuyBackList				                         --IGVId = 6
local QUICKSLOT = ZO_QuickSlotList                                   --IGVId = 7
local CRAFT = ZO_CraftBagList                                        --IGVId = 8
--local REFINE = ZO_SmithingTopLevelRefinementPanelInventoryBackpack   --IGVId = 9

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
		gridIconSize = 52,
		gridIconZoomLevel = 1.5,
		isTooltipOffset = true,
		minOutlineQuality = ITEM_QUALITY_MAGIC,
        showQualityOutline = true,
        skinChoice = "Rushmik",
    }

    settings.vars = ZO_SavedVars:NewAccountWide("InventoryGridView_Settings", settings.varsVersion, nil, defaultVars)
	vars = settings.vars

	local function createOptionsMenu()
		local textureSet = settings.GetTextureSet()

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
			name = "Inventory Grid View",
			author = "Randactyl",
			version = IGV.addonVersion,
			slashCommand = "/inventorygridview",
			registerForRefresh = true,
			registerForDefaults = true,
		}
		local optionsData = {
			[1] = {
				type = "dropdown",
                name = "Skin",
                tooltip = "The set of textures that will be used in the grid view.",
                choices = settings.skinChoices,
                getFunc = function() return vars.skinChoice end,
                setFunc = function(value)
					vars.skinChoice = value

					local textureSet = self.GetTextureSet()

					InventoryGridView_SetTextureSet(settings.skins[value], true)
					InventoryGridView_SetToggleButtonTexture()

					exampleBackground:SetTexture(textureSet.BACKGROUND)
                    exampleOutline:SetTexture(textureSet.OUTLINE)
                    exampleHover:SetTexture(textureSet.HOVER)
				end,
				reference = "InventoryGridViewSettingsSkinDropdown",
			},
			[2] = {
				type = "checkbox",
				name = "Quality Outlines",
				tooltip = "Toggle the outlines on or off.",
				getFunc = function()
					return vars.showQualityOutline
				end,
				setFunc = function(value)
					vars.showQualityOutline = value
					exampleOutline:SetHidden(not value)

					if value then
						--InventoryGridView_SetMinimumQuality(QUALITY[vars.minOutlineQuality], true)
					else
						--InventoryGridView_SetMinimumQuality(99, true)
					end
				end,
				reference = "InventoryGridViewSettingsQualityOutlines",
			},
			[3] = {
				type = "dropdown",
				name = "Minimum Outline Quality",
				tooltip = "Don't show outlines under this quality",
				choices = QUALITY_OPTIONS,
				getFunc = function() return QUALITY_OPTIONS[vars.minOutlineQuality + 1] end,
				setFunc = function(value)
					vars.minOutlineQuality = QUALITY[value]

					--InventoryGridView_SetMinimumQuality(QUALITY[value], true)
				end,
				disabled = function() return not vars.showQualityOutline end,
				reference = "InventoryGridViewSettingsMinRarityDropdown",
			},
			[4] = {
				type = "slider",
				name = "Grid Size",
				tooltip = "Set how big or small the grid icons are. Icon area is the square of this number.",
				min = 24,
				max = 96,
				step = 4,
				getFunc = function() return vars.gridIconSize end,
				setFunc = function(value)
					vars.gridIconSize = value

					BAGS.gridIconSize = value
					QUEST.gridIconSize = value
					BANK.gridIconSize = value
					GUILD_BANK.gridIconSize = value
					STORE.gridIconSize = value
					BUYBACK.gridIconSize = value
					QUICKSLOT.gridIconSize = value
					CRAFT.gridIconSize = value
					--REFINE.gridIconSize = value

					InventoryGridView_ToggleOutlines(BAGS, vars.showQualityOutline)
					InventoryGridView_ToggleOutlines(QUEST, vars.showQualityOutline)
					InventoryGridView_ToggleOutlines(BANK, vars.showQualityOutline)
					InventoryGridView_ToggleOutlines(GUILD_BANK, vars.showQualityOutline)
					InventoryGridView_ToggleOutlines(STORE, vars.showQualityOutline)
					InventoryGridView_ToggleOutlines(BUYBACK, vars.showQualityOutline)
					InventoryGridView_ToggleOutlines(QUICKSLOT, vars.showQualityOutline)
					InventoryGridView_ToggleOutlines(CRAFT, vars.showQualityOutline)
					--InventoryGridView_ToggleOutlines(REFINE, vars.showQualityOutline)

					example:SetDimensions(value, value)
				end,
				reference = "InventoryGridViewSettingsGridIconSize",
			},
			[5] = {
				type = "slider",
				name = "Icon Zoom Level",
				tooltip = "Set icon zoom level (on mouse over) from none to default",
				min = 100,
				max = 150,
				step = 10,
				getFunc = function() return vars.gridIconZoomLevel * 100 end,
				setFunc = function(value)
					vars.gridIconZoomLevel = value / 100
				end,
			},
			[6] = {
				type = "custom",
				reference = "InventoryGridViewSettingsExampleTextureLAMControl",
			},
			[7] = {
				type = "checkbox",
				name = "Offset Item Tooltips",
				tooltip = "Should we move item tooltips so they do not cover the item grid?",
				getFunc = function() return vars.isTooltipOffset end,
				setFunc = function(value)
					vars.isTooltipOffset = value
				end,
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

	--InventoryGridView_SetMinimumQuality(QUALITY[vars.minOutlineQuality])
	--InventoryGridView_SetTextureSet(settings.skins[vars.skinChoice])
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