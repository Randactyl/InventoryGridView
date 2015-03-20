local LAM = LibStub("LibAddonMenu-2.0")
InventoryGridViewSettings = ZO_Object:Subclass()
local settings = nil

local BAGS = ZO_PlayerInventoryBackpack		                          --bagId = 1
local QUEST = ZO_PlayerInventoryQuest		                          --bagId = 2
local BANK = ZO_PlayerBankBackpack			                          --bagId = 3
local GUILD_BANK = ZO_GuildBankBackpack		                          --bagId = 4
local STORE = ZO_StoreWindowList			                          --bagId = 5
local BUYBACK = ZO_BuyBackList				                          --bagId = 6
--local REFINE = ZO_SmithingTopLevelRefinementPanelInventoryBackpack    --bagId = 7

local SKIN_CHOICES = { "Classic", "Rushmik", "Clean: by Tonyleila", "Circles: by Tonyleila" }

local TEXTURES = {
	["Classic"] = {
		BACKGROUND = "InventoryGridView/assets/griditem_background.dds", --set to black?
		OUTLINE = "InventoryGridView/assets/griditem_outline.dds",
		HOVER = "InventoryGridView/assets/griditem_hover.dds",
		TOGGLE = "InventoryGridView/assets/grid_view_toggle_button.dds"
	},
	["Rushmik"] = {
		BACKGROUND = "InventoryGridView/assets/rushmik_background.dds",
		OUTLINE = "InventoryGridView/assets/rushmik_outline.dds",
		HOVER = "InventoryGridView/assets/rushmik_background.dds",
		TOGGLE = "InventoryGridView/assets/grid_view_toggle_button.dds"
	},
	["Clean: by Tonyleila"] = {
		BACKGROUND = "InventoryGridView/assets/tonyleila_background.dds",
		OUTLINE = "InventoryGridView/assets/tonyleila_outline.dds",
		HOVER = "InventoryGridView/assets/tonyleila_hover.dds",
		TOGGLE = "InventoryGridView/assets/tonyleila_toggle_button.dds"
	},
	["Circles: by Tonyleila"] = {
		BACKGROUND = "InventoryGridView/assets/circle_background.dds",
		OUTLINE = "InventoryGridView/assets/circle_outline.dds",
		HOVER = "InventoryGridView/assets/circle_hover.dds",
		TOGGLE = "InventoryGridView/assets/circle_toggle_button.dds"
	},
}

local QUALITY_OPTIONS = {
	"Trash", "Normal", "Magic", "Arcane", "Artifact", "Legendary"
}

local QUALITY = {
	["Trash"] = ITEM_QUALITY_TRASH,
	["Normal"] = ITEM_QUALITY_NORMAL,
	["Magic"] = ITEM_QUALITY_MAGIC,
	["Arcane"] = ITEM_QUALITY_ARCANE,
	["Artifact"] = ITEM_QUALITY_ARTIFACT,
	["Legendary"] = ITEM_QUALITY_LEGENDARY
}

function InventoryGridViewSettings:New()
	local obj = ZO_Object.New(self)
	obj:Initialize()
	return obj
end

function InventoryGridViewSettings:Initialize()
	local defaults = {
        isInventoryGrid = true,
        isBankGrid = true,
        isGuildBankGrid = true,
        isStoreGrid = true,
        isBuybackGrid = true,
        isCraftingGrid = true,
        allowRarityColor = true,
        gridSize = 52,
        minimumQuality = "Magic",
        skinChoice = "Rushmik",
        valueTooltip = true,
        iconZoomLevel = 1.5,
        isTooltipOffset = true,
    }

    settings = ZO_SavedVars:New("InventoryGridView_Settings", 2, nil, defaults)
    self:CreateOptionsMenu()
	InventoryGridView_SetMinimumQuality(QUALITY[settings.minimumQuality])
	InventoryGridView_SetTextureSet(TEXTURES[settings.skinChoice])
end

function InventoryGridViewSettings:IsGrid( inventoryId )
	if(inventoryId == INVENTORY_BACKPACK) then
		return settings.isInventoryGrid
	elseif(inventoryId == INVENTORY_QUEST_ITEM) then
		return settings.isInventoryGrid
	elseif(inventoryId == INVENTORY_BANK) then
		return settings.isBankGrid
	elseif(inventoryId == INVENTORY_GUILD_BANK) then
		return settings.isGuildBankGrid
	elseif(inventoryId == 5) then
		return settings.isStoreGrid
	elseif(inventoryId == 6) then
		return settings.isBuybackGrid
	else
		return settings.isCraftingGrid
	end
end

function InventoryGridViewSettings:ToggleGrid( inventoryId )
	if(inventoryId == INVENTORY_BACKPACK) then
		settings.isInventoryGrid = not settings.isInventoryGrid
	elseif(inventoryId == INVENTORY_QUEST_ITEM) then
		settings.isInventoryGrid = not settings.isInventoryGrid
	elseif(inventoryId == INVENTORY_BANK) then
		settings.isBankGrid = not settings.isBankGrid
	elseif(inventoryId == INVENTORY_GUILD_BANK) then
		settings.isGuildBankGrid = not settings.isGuildBankGrid
	elseif(inventoryId == 5) then
		settings.isStoreGrid = not settings.isStoreGrid
	elseif(inventoryId == 6) then
		settings.isBuybackGrid = not settings.isBuybackGrid
	else
		settings.isCraftingGrid = not settings.isCraftingGrid
	end
end

function InventoryGridViewSettings:IsAllowOutline()
	return settings.allowRarityColor
end

function InventoryGridViewSettings:GetGridSize()
	return settings.gridSize
end

function InventoryGridViewSettings:GetTextureSet()
	if TEXTURES[settings.skinChoice] == nil then
		settings.skinChoice = "Rushmik"
	end
	return TEXTURES[settings.skinChoice]
end

function InventoryGridViewSettings:GetIconZoomLevel()
	return settings.iconZoomLevel
end

function InventoryGridViewSettings:IsTooltipOffset()
	return settings.isTooltipOffset
end

function InventoryGridViewSettings:IsShowValueTooltip()
	return settings.valueTooltip
end

function InventoryGridViewSettings:CreateOptionsMenu()
	--example texture for skin and slider
	local example = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture", GuiRoot, CT_CONTROL)
	example:SetMouseEnabled(true)

	local ex_bg = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_BG", example, CT_TEXTURE)
	ex_bg:SetAnchorFill(example)
	ex_bg:SetTexture(self:GetTextureSet().BACKGROUND)

	local ex_outline = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_Outline", example, CT_TEXTURE)
	ex_outline:SetAnchorFill(example)
	ex_outline:SetTexture(self:GetTextureSet().OUTLINE)
	ex_outline:SetHidden(not self:IsAllowOutline())

	local ex_hover = WINDOW_MANAGER:CreateControl("IGV_Grid_Size_Example_Texture_Hover", example, CT_TEXTURE)
	ex_hover:SetAnchorFill(example)
	ex_hover:SetTexture(self:GetTextureSet().HOVER)
	ex_hover:SetHidden(true)


	local custom = {
		type = "custom",
		reference = "IGV_Grid_Size_Example"
	}

	--now actually set up the panel
	local panel = {
		type = "panel",
		name = "Inventory Grid View",
		author = "ingeniousclown and Randactyl",
		version = "1.4.0.0",
		slashCommand = "/inventorygridview",
		registerForRefresh = true,
		--registerForDefaults = true,
	}

	local optionsData = {
		[1] = {
			type = "dropdown",
			name = "Skin",
			tooltip = "Which skin would you like to use for Grid View?",
			choices = SKIN_CHOICES,
			getFunc = function() return settings.skinChoice end,
			setFunc = function(value)
						settings.skinChoice = value
						InventoryGridView_SetTextureSet(TEXTURES[value], true)
						ex_bg:SetTexture(self:GetTextureSet().BACKGROUND)
						ex_outline:SetTexture(self:GetTextureSet().OUTLINE)
						ex_hover:SetTexture(self:GetTextureSet().HOVER)
						InventoryGridView_SetToggleButtonTexture()
					end,
			reference = "IGV_Skin_Dropdown"
		},
		[2] = {
			type = "checkbox",
			name = "Rarity Outlines",
			tooltip = "Toggle the outlines on or off.",
			getFunc = function()
						return self:IsAllowOutline() 
					end,
			setFunc = function(value)
						settings.allowRarityColor = value
						ex_outline:SetHidden(not self:IsAllowOutline())
						InventoryGridView_ToggleOutlines(BAGS, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(QUEST, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(BANK, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(GUILD_BANK, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(STORE, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(BUYBACK, settings.allowRarityColor)
						--InventoryGridView_ToggleOutlines(REFINE, settings.allowRarityColor)
					end,
			reference = "IGV_Rarity_Outlines"
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
			disabled = function() return not self:IsAllowOutline() end,
			reference = "IGV_Min_Rarity_Dropdown"
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
						--REFINE.gridSize = value
						InventoryGridView_ToggleOutlines(BAGS, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(QUEST, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(BANK, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(GUILD_BANK, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(STORE, settings.allowRarityColor)
						InventoryGridView_ToggleOutlines(BUYBACK, settings.allowRarityColor)
						--InventoryGridView_ToggleOutlines(REFINE, settings.allowRarityColor)
						example:SetDimensions(value, value)
					end,
			reference = "IGV_Grid_Size"
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
			name = "Tooltip Gold",
			tooltip = "Should we add the stack's value to the tooltip in grid view?",
			getFunc = function() return settings.valueTooltip end,
			setFunc = function(value)
						settings.valueTooltip = value
					end,
			reference = "IGV_Value_Tooltip"
		},
		[8] = {
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
			if(createdPanel:GetName() ~= "InventoryGridViewSettingsPanel") then return end

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

function InventoryGridView_RegisterSkin( name, background, outline, highlight, toggle )
	table.insert(SKIN_CHOICES, name)
	TEXTURES[name] = {
		BACKGROUND = background or "InventoryGridView/assets/griditem_background.dds",
		OUTLINE = outline or "InventoryGridView/assets/griditem_outline.dds",
		HOVER = highlight or "InventoryGridView/assets/griditem_hover.dds",
		TOGGLE = toggle or "InventoryGridView/assets/grid_view_toggle_button.dds"
	}
end