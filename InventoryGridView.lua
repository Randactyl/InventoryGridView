------------------------------------------------------------------
--InventoryGridView.lua
--Author: ingeniousclown, Randactyl
--v1.4.1.0

--InventoryGridView was designed to try and leverage the default
--UI as much as possible to create a grid view.  The result is
--somewhat hacky, but it works well.

--Main functions for the mod.
------------------------------------------------------------------
local IGVSettings = nil

local BAGS = ZO_PlayerInventoryBackpack                               --bagId = 1
local QUEST = ZO_PlayerInventoryQuest                                 --bagId = 2
local BANK = ZO_PlayerBankBackpack                                    --bagId = 3
local GUILD_BANK = ZO_GuildBankBackpack                               --bagId = 4
local STORE = ZO_StoreWindowList                                      --bagId = 5
local BUYBACK = ZO_BuyBackList                                        --bagId = 6
local QUICKSLOT = ZO_QuickSlotList                                    --bagId = 7
--local REFINE = ZO_SmithingTopLevelRefinementPanelInventoryBackpack    --bagId = 8

local toggleButtonTextures = {}

local SELL_REASON_COLOR = ZO_ColorDef:New( GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_SELLS_FOR) )
local REASON_CURRENCY_SPACING = 3
local ITEM_TOOLTIP_CURRENCY_OPTIONS = { showTooltips = false }
local MONEY_LINE_HEIGHT = 18

--override this function so I can display AP cost in the store view. Added currencyType.
--tooltip.lua line 68
function ZO_ItemTooltip_AddMoney(tooltipControl, amount, reason, notEnough, currencyType)
    local moneyLine = GetControl(tooltipControl, "SellPrice")
    local reasonLabel = GetControl(moneyLine, "Reason")
    local currencyControl = GetControl(moneyLine, "Currency")

    --added---------------------------------------------------------------------
    local currencyType = currencyType or CURRENCY_TYPE_MONEY
    ----------------------------------------------------------------------------

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
        --modified--------------------------------------------------------------
        ZO_CurrencyControl_SetSimpleCurrency(currencyControl, currencyType,
            amount, ITEM_TOOLTIP_CURRENCY_OPTIONS, CURRENCY_DONT_SHOW_ALL, notEnough)
        ------------------------------------------------------------------------
        width = width + currencyControl:GetWidth()
    else
        currencyControl:SetHidden(true)
    end

    tooltipControl:AddControl(moneyLine)
    moneyLine:SetAnchor(CENTER)
    moneyLine:SetDimensions(width, MONEY_LINE_HEIGHT)
end

local function AddCurrency(rowControl)
    if(not rowControl.dataEntry) then return end

    local bagId = rowControl.dataEntry.data.bagId or rowControl:GetParent():GetParent().bagId
    local slotIndex = rowControl.dataEntry.data.slotIndex
    local _, stack, sellPrice, currencyType, notEnough

    for _,v in pairs(rowControl:GetNamedChild("SellPrice").currencyArgs) do
        if(v.isUsed == true) then
            currencyType = v.type
            notEnough = v.notEnough
        end
    end

    if bagId == STORE.bagId or bagId == BUYBACK.bagId then
        if currencyType == CURT_MONEY then
            sellPrice = rowControl.dataEntry.data.price
        else
            sellPrice = rowControl.dataEntry.data.currencyQuantity1
        end

        stack = rowControl.dataEntry.data.stack
        ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack, 0, notEnough, currencyType)
    else
        _, stack, sellPrice = GetItemInfo(bagId, slotIndex)
        ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack)
    end
end

local function AddCurrencySoon(rowControl)
    if(rowControl:GetParent():GetParent().bagId == INVENTORY_QUEST_ITEM) then return end
    if(rowControl and rowControl.isGrid and IGVSettings:IsShowValueTooltip()) then
        zo_callLater(function() AddCurrency(rowControl) end, 50)
    end
end

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

    InitGridView()
    InventoryGridView_ToggleOutlines(BAGS, IGVSettings:IsAllowOutline())
    InventoryGridView_ToggleOutlines(QUEST, IGVSettings:IsAllowOutline())
    InventoryGridView_ToggleOutlines(BANK, IGVSettings:IsAllowOutline())
    InventoryGridView_ToggleOutlines(GUILD_BANK, IGVSettings:IsAllowOutline())
    InventoryGridView_ToggleOutlines(STORE, IGVSettings:IsAllowOutline())
    InventoryGridView_ToggleOutlines(BUYBACK, IGVSettings:IsAllowOutline())
    InventoryGridView_ToggleOutlines(QUICKSLOT, IGVSettings:IsAllowOutline())
    --InventoryGridView_ToggleOutlines(REFINE, IGVSettings:IsAllowOutline())

    AddButton(BAGS:GetParent(), BAGS.bagId)
    AddButton(BANK:GetParent(), BANK.bagId)
    AddButton(GUILD_BANK:GetParent(), GUILD_BANK.bagId)
    AddButton(STORE:GetParent(), STORE.bagId)
    AddButton(BUYBACK:GetParent(), BUYBACK.bagId)
    AddButton(QUICKSLOT:GetParent(), QUICKSLOT.bagId)
    --AddButton(REFINE:GetParent(), REFINE.bagId)

    InventoryGridView_SetToggleButtonTexture()

    ZO_PreHook("ZO_InventorySlot_OnMouseEnter", AddCurrencySoon)
end

EVENT_MANAGER:RegisterForEvent("InventoryGridViewLoaded", EVENT_ADD_ON_LOADED, InventoryGridViewLoaded)
