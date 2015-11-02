local LAM = LibStub("LibAddonMenu-2.0")
InventoryGridViewSettings = ZO_Object:Subclass()
local settings = nil
local addonVersion = "1.5.2.1"

local BAGS = ZO_PlayerInventoryBackpack		                         --IGVId = 1
local QUEST = ZO_PlayerInventoryQuest		                         --IGVId = 2
local BANK = ZO_PlayerBankBackpack			                         --IGVId = 3
local GUILD_BANK = ZO_GuildBankBackpack		                         --IGVId = 4
local STORE = ZO_StoreWindowList			                         --IGVId = 5
local BUYBACK = ZO_BuyBackList				                         --IGVId = 6
local QUICKSLOT = ZO_QuickSlotList                                   --IGVId = 7
--local REFINE = ZO_SmithingTopLevelRefinementPanelInventoryBackpack   --IGVId = 8

local skinChoices = {}
local skins = {}
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

function InventoryGridViewSettings:New()
	local obj = ZO_Object.New(self)
	obj:Initialize()
	return obj
end

function InventoryGridViewSettings:Initialize()
	local defaults = {
		isGrid = {
			[1] = true, --BAGS
			[2] = true, --QUEST
			[3] = true, --BANK
			[4] = true, --GUILD_BANK
			[5] = true, --STORE
			[6] = true, --BUYBACK
			[7] = true, --QUICKSLOT
		},
        allowRarityColor = true,
        gridSize = 52,
        minimumQuality = "Magic",
        skinChoice = "Rushmik",
        iconZoomLevel = 1.5,
        isTooltipOffset = true,
    }

    settings = ZO_SavedVars:NewAccountWide("InventoryGridView_Settings", 3, nil, defaults)
    self:CreateOptionsMenu()
	InventoryGridView_SetMinimumQuality(QUALITY[settings.minimumQuality])
	InventoryGridView_SetTextureSet(skins[settings.skinChoice])
end

function InventoryGridViewSettings:CreateOptionsMenu()
	local textureSet = self:GetTextureSet()
	--example texture for skin and slider
	local example = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture", GuiRoot, CT_CONTROL)
	example:SetMouseEnabled(true)

	local ex_bg = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_BG", example, CT_TEXTURE)
	ex_bg:SetAnchorFill(example)
	ex_bg:SetTexture(textureSet.BACKGROUND)

	local ex_outline = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_Outline", example, CT_TEXTURE)
	ex_outline:SetAnchorFill(example)
	ex_outline:SetTexture(textureSet.OUTLINE)
	ex_outline:SetHidden(not settings.allowRarityColor)

	local ex_hover = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_Hover", example, CT_TEXTURE)
	ex_hover:SetAnchorFill(example)
	ex_hover:SetTexture(textureSet.HOVER)
	ex_hover:SetHidden(true)


	local custom = {
		type = "custom",
		reference = "IGV_Grid_Size_Example",
	}

	--now actually set up the panel
	local panel = {
		type = "panel",
		name = "Inventory Grid View",
		author = "ingeniousclown and Randactyl",
		version = addonVersion,
		slashCommand = "/inventorygridview",
		registerForRefresh = true,
		--registerForDefaults = true,
	}
	local optionsData = {
		[1] = {
			type = "dropdown",
			name = "Skin",
			tooltip = "Which skin would you like to use for Grid View?",
			choices = skinChoices,
			getFunc = function() return settings.skinChoice end,
			setFunc = function(value)
				settings.skinChoice = value
				local textureSet = self.GetTextureSet()
				InventoryGridView_SetTextureSet(skins[value], true)
				ex_bg:SetTexture(textureSet.BACKGROUND)
				ex_outline:SetTexture(textureSet.OUTLINE)
				ex_hover:SetTexture(textureSet.HOVER)
				InventoryGridView_SetToggleButtonTexture()
			end,
			reference = "IGV_Skin_Dropdown",
		},
		[2] = {
			type = "checkbox",
			name = "Rarity Outlines",
			tooltip = "Toggle the outlines on or off.",
			getFunc = function()
				return settings.allowRarityColor
			end,
			setFunc = function(value)
				settings.allowRarityColor = value
				ex_outline:SetHidden(not value)
				if value == true then
					InventoryGridView_SetMinimumQuality(QUALITY[settings.minimumQuality], true)
				else
					InventoryGridView_SetMinimumQuality(99, true)
				end
			end,
			reference = "IGV_Rarity_Outlines",
		},
		[3] = {
			type = "dropdown",
			name = "Minimum Outline Quality",
			tooltip = "Don't show outlines under this quality",
			choices = QUALITY_OPTIONS,
			getFunc = function() return settings.minimumQuality end,
			setFunc = function(value)
				settings.minimumQuality = value
				InventoryGridView_SetMinimumQuality(QUALITY[value], true)
			end,
			disabled = function() return not settings.allowRarityColor end,
			reference = "IGV_Min_Rarity_Dropdown",
		},
		[4] = {
			type = "slider",
			name = "Grid Size",
			tooltip = "Set how big or small the grid icons are.",
			min = 24,
			max = 96,
			step = 4,
			getFunc = function() return settings.gridSize end,
			setFunc = function(value)
				settings.gridSize = value
				BAGS.gridSize = value
				QUEST.gridSize = value
				BANK.gridSize = value
				GUILD_BANK.gridSize = value
				STORE.gridSize = value
				BUYBACK.gridSize = value
				QUICKSLOT.gridSize = value
				--REFINE.gridSize = value
				InventoryGridView_ToggleOutlines(BAGS, settings.allowRarityColor)
				InventoryGridView_ToggleOutlines(QUEST, settings.allowRarityColor)
				InventoryGridView_ToggleOutlines(BANK, settings.allowRarityColor)
				InventoryGridView_ToggleOutlines(GUILD_BANK, settings.allowRarityColor)
				InventoryGridView_ToggleOutlines(STORE, settings.allowRarityColor)
				InventoryGridView_ToggleOutlines(BUYBACK, settings.allowRarityColor)
				InventoryGridView_ToggleOutlines(QUICKSLOT, settings.allowRarityColor)
				--InventoryGridView_ToggleOutlines(REFINE, settings.allowRarityColor)
				example:SetDimensions(value, value)
			end,
			reference = "IGV_Grid_Size",
		},
		[5] = {
			type = "slider",
			name = "Icon Zoom Level",
			tooltip = "Set icon zoom level from none to default",
			min = 100,
			max = 150,
			step = 10,
			getFunc = function() return settings.iconZoomLevel * 100 end,
			setFunc = function(value)
				settings.iconZoomLevel = value / 100
				SHARED_INVENTORY.IGViconZoomLevel = value / 100
			end,
		},
		[6] = custom,
		[7] = {
			type = "checkbox",
			name = "Offset Item Tooltips",
			tooltip = "Should we move item tooltips so they do not cover the item grid?",
			getFunc = function() return settings.isTooltipOffset end,
			setFunc = function(value)
				settings.isTooltipOffset = value
			end,
		},
	}

	LAM:RegisterAddonPanel("InventoryGridViewSettingsPanel", panel)
	LAM:RegisterOptionControls("InventoryGridViewSettingsPanel", optionsData)

	CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated",
		function(createdPanel)
			if createdPanel:GetName() ~= "InventoryGridViewSettingsPanel" then return end

			example:SetParent(InventoryGridViewSettingsPanel)
			example:SetDimensions(settings.gridSize, settings.gridSize)
			example:SetAnchor(CENTER, IGV_Grid_Size_Example, CENTER)
			example:SetHandler("OnMouseEnter",
				function()
					ex_hover:SetHidden(false)
				end)
			example:SetHandler("OnMouseExit",
				function()
					ex_hover:SetHidden(true)
				end)
		end)
end

function InventoryGridViewSettings:IsGrid(IGVId)
	return settings.isGrid[IGVId]
end

function InventoryGridViewSettings:ToggleGrid(IGVId)
	settings.isGrid[IGVId] = not settings.isGrid[IGVId]
end

function InventoryGridViewSettings:IsAllowOutline()
	return settings.allowRarityColor
end

function InventoryGridViewSettings:GetGridSize()
	return settings.gridSize
end

function InventoryGridViewSettings:GetTextureSet()
	if skins[settings.skinChoice] == nil then
		settings.skinChoice = "Rushmik"
	end
	return skins[settings.skinChoice]
end

function InventoryGridViewSettings:GetIconZoomLevel()
	return settings.iconZoomLevel
end

function InventoryGridViewSettings:IsTooltipOffset()
	return settings.isTooltipOffset
end

function InventoryGridView_RegisterSkin(name, background, outline, highlight, toggle)
	table.insert(skinChoices, name)
	skins[name] = {
		BACKGROUND = background or "InventoryGridView/skins/Classic/classic_background.dds",
		OUTLINE = outline or "InventoryGridView/skins/Classic/classic_outline.dds",
		HOVER = highlight or "InventoryGridView/skins/Classic/classic_hover.dds",
		TOGGLE = toggle or "InventoryGridView/skins/Classic/classic_toggle_button.dds",
	}
end
