--[[----------------------------------------------------------------------------
    InventoryGridView.lua
    Author: Randactyl, ingeniousclown
    Version: 1.5.0.0
    Inventory Grid View was designed to leverage the default UI as much as
    possible to create a grid view scroll list. The result is somewhat hacky,
    but it works well.
    This file mostly coordinates the two other pieces: the settings and
    the controller.
--]]----------------------------------------------------------------------------
local IGVSettings = nil

local toggleButtonTextures = {}

<<<<<<< HEAD
=======
local SELL_REASON_COLOR = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_SELLS_FOR) )
local REASON_CURRENCY_SPACING = 3
local ITEM_TOOLTIP_CURRENCY_OPTIONS = { showTooltips = false }
local MONEY_LINE_HEIGHT = 18

--override this function so I can display AP cost in the store view. Added currencyType.
function ZO_ItemTooltip_AddMoney(tooltipControl, amount, reason, notEnough, currencyType)
    local moneyLine = GetControl(tooltipControl, "SellPrice")
    local reasonLabel = GetControl(moneyLine, "Reason")
    local currencyControl = GetControl(moneyLine, "Currency")

    local currencyType = currencyType or CURRENCY_TYPE_MONEY

    moneyLine:SetHidden(false)

    local width = 0
    reasonLabel:ClearAnchors()
    currencyControl:ClearAnchors()

     -- right now reason is always a string index
    if(reason and reason ~= 0) then
        reasonLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
        currencyControl:SetAnchor(TOPLEFT, reasonLabel, TOPRIGHT, REASON_CURRENCY_SPACING, -2)

        reasonLabel:SetHidden(false)
        reasonLabel:SetColor(SELL_REASON_COLOR:UnpackRGBA())
        reasonLabel:SetText(GetString(reason))

        local reasonTextWidth, reasonTextHeight = reasonLabel:GetTextDimensions()
        width = width + reasonTextWidth + REASON_CURRENCY_SPACING
    else
        reasonLabel:SetHidden(true)
        currencyControl:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
    end

    if(amount > 0) then
        currencyControl:SetHidden(false)
        ZO_CurrencyControl_SetSimpleCurrency(currencyControl, currencyType, amount, ITEM_TOOLTIP_CURRENCY_OPTIONS, CURRENCY_DONT_SHOW_ALL, notEnough)
        width = width + currencyControl:GetWidth()
    else
        currencyControl:SetHidden(true)
    end

    tooltipControl:AddControl(moneyLine)
    moneyLine:SetAnchor(CENTER)
    moneyLine:SetDimensions(width, MONEY_LINE_HEIGHT)
end

local function AddGold(rowControl)
    if(not rowControl.dataEntry) then return end

    local bagId = rowControl.dataEntry.data.bagId or rowControl:GetParent():GetParent().bagId
    local slotIndex = rowControl.dataEntry.data.slotIndex
    local _, stack, sellPrice
    local currencyType, notEnough

    for _,v in pairs(rowControl:GetNamedChild("SellPrice").currencyArgs) do
        if(v.isUsed == true) then
            currencyType = v.type
            notEnough = v.notEnough
        end
    end

    if bagId == STORE.bagId or bagId == BUYBACK.bagId then
        if(currencyType == CURRENCY_TYPE_ALLIANCE_POINTS) then
            sellPrice = rowControl.dataEntry.data.currencyQuantity1
        else
            sellPrice = rowControl.dataEntry.data.price
        end
        stack = rowControl.dataEntry.data.stack

        ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack, 0, notEnough, currencyType)
    else
        _, stack, sellPrice = GetItemInfo(bagId, slotIndex)
        ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack)
    end
end

local function AddGoldSoon(rowControl)
    if(rowControl:GetParent():GetParent().bagId == INVENTORY_QUEST_ITEM) then return end
    if(rowControl and rowControl.isGrid and IGVSettings:IsShowValueTooltip()) then
        zo_callLater(function() AddGold(rowControl) end, 50)
    end
end

>>>>>>> master
function InventoryGridView_SetToggleButtonTexture()
    for _,v in pairs(toggleButtonTextures) do
        v:SetTexture(IGVSettings:GetTextureSet().TOGGLE)
    end
end

local function ButtonClickHandler(button)
    IGVSettings:ToggleGrid(button.IGVId)

    -- quest bag uses the same button as inventory, have to piggyback instead of making separate button
    if(button.IGVId == INVENTORY_BACKPACK) then
        InventoryGridView_ToggleGrid(button.itemArea:GetParent():GetNamedChild("Quest"), not button.itemArea.isGrid)
    end
    InventoryGridView_ToggleGrid(button.itemArea, not button.itemArea.isGrid)
end

--parentWindow: parent of ZO_PlayerInventoryBackpack, etc
local function AddButton(parentWindow, IGVId)
    if IGVId == INVENTORY_QUEST_ITEM then return end
    --create the button
    local button = WINDOW_MANAGER:CreateControl(parentWindow:GetName() .. "_GridButton", parentWindow, CT_BUTTON)
    button:SetDimensions(24,24)
    button:SetAnchor(TOP, parentWindow, BOTTOM, 12, 6)
    button:SetFont("ZoFontGameSmall")
    button:SetHandler("OnClicked", ButtonClickHandler)
    button:SetMouseEnabled(true)

    --where should the button go?
    if IGVId == ZO_StoreWindowList.IGVId or IGVId == ZO_BuyBackList.IGVId or IGVId == ZO_QuickSlotList.IGVId then
        button.itemArea = parentWindow:GetNamedChild("List")
    else
        button.itemArea = parentWindow:GetNamedChild("Backpack")
    end
    button.IGVId = IGVId

    local texture = WINDOW_MANAGER:CreateControl(parentWindow:GetName() .. "_GridButtonTexture", button, CT_TEXTURE)
    texture:SetAnchorFill()

    table.insert(toggleButtonTextures, texture)

    -- texture:SetColor(1, 1, 1, 1)
end

local function InventoryGridViewLoaded(eventCode, addOnName)
    if(addOnName ~= "InventoryGridView") then return end
    EVENT_MANAGER:UnregisterForEvent("InventoryGridViewLoaded", EVENT_ADD_ON_LOADED)

    IGVSettings = InventoryGridViewSettings:New()

    --Set up grids
    local leftPadding = 25
    local bags = {
        [1] = ZO_PlayerInventoryBackpack,
        [2] = ZO_PlayerInventoryQuest,
        [3] = ZO_PlayerBankBackpack,
        [4] = ZO_GuildBankBackpack,
        [5] = ZO_StoreWindowList,
        [6] = ZO_BuyBackList,
        [7] = ZO_QuickSlotList,
        --[8] = ZO_SmithingTopLevelRefinementPanelInventoryBackpack,
    }
    for IGVId,bag in ipairs(bags) do
        local controlWidth = bag.controlHeight
        local contentsWidth = bag:GetNamedChild("Contents"):GetWidth()
        local itemsPerRow = zo_floor((contentsWidth - leftPadding) / (controlWidth))
        local gridSpacing = ((contentsWidth - leftPadding) % itemsPerRow) / itemsPerRow
        bag.forceUpdate = true
        bag.listHeight = controlWidth
        bag.leftPadding = leftPadding
        bag.contentsWidth = contentsWidth
        bag.itemsPerRow = itemsPerRow
        bag.gridSpacing = gridSpacing
        bag.IGVId = IGVId
        bag.isGrid = IGVSettings:IsGrid(IGVId)
        bag.isOutlines = IGVSettings:IsAllowOutline()
        bag.gridSize = IGVSettings:GetGridSize()

        --if not IGVId == INVENTORY_QUEST_ITEM then
            AddButton(bag:GetParent(), IGVId)
        --end
    end

    SHARED_INVENTORY.IGViconZoomLevel = IGVSettings:GetIconZoomLevel()

    InventoryGridView_ToggleOutlines(IGVSettings:IsAllowOutline())
    InventoryGridView_SetToggleButtonTexture()
end

EVENT_MANAGER:RegisterForEvent("InventoryGridViewLoaded", EVENT_ADD_ON_LOADED, InventoryGridViewLoaded)
