--[[----------------------------------------------------------------------------
    GridViewController.lua
    Author: ingeniousclown, Randactyl
    This is mostly a re-implementation of ZO_ScrollList_UpdateScroll and copies
    of the local functions and variables required to make it work. This file
    also initializes all of the necessary fields to convert a list to grid view.
--]]----------------------------------------------------------------------------
--[[----------------------------------------------------------------------------
    Ported ZOS code from esoui\libraries\zo_templates\scrolltemplates.lua
--]]----------------------------------------------------------------------------
local function UpdateScrollFade(useFadeGradient, scroll, slider, sliderValue)
    if useFadeGradient then
        local sliderMin, sliderMax = slider:GetMinMax()
        sliderValue = sliderValue or slider:GetValue()

        if sliderValue > sliderMin then
            scroll:SetFadeGradient(1, 0, 1, zo_min(sliderValue - sliderMin, 64))
        else
            scroll:SetFadeGradient(1, 0, 0, 0)
        end

        if sliderValue < sliderMax then
            scroll:SetFadeGradient(2, 0, -1, zo_min(sliderMax - sliderValue, 64))
        else
            scroll:SetFadeGradient(2, 0, 0, 0);
        end
    else
        scroll:SetFadeGradient(1, 0, 0, 0)
        scroll:SetFadeGradient(2, 0, 0, 0)
    end
end

local function AreSelectionsEnabled(self)
    return self.selectionTemplate or self.selectionCallback
end

local function RemoveAnimationOnControl(control, animationFieldName)
    if control[animationFieldName] then
        control[animationFieldName]:PlayBackward()
    end
end

local function UnhighlightControl(self, control)
    RemoveAnimationOnControl(control, "HighlightAnimation")

    self.highlightedControl = nil

    if self.highlightCallback then
        self.highlightCallback(control, false)
    end
end

local function UnselectControl(self, control)
    RemoveAnimationOnControl(control, "SelectionAnimation")

    self.selectedControl = nil
end

local function AreDataEqualSelections(self, data1, data2)
    if data1 == data2 then
        return true
    end

    if data1 == nil or data2 == nil then
        return false
    end

    local dataEntry1 = data1.dataEntry
    local dataEntry2 = data2.dataEntry
    if dataEntry1.typeId == dataEntry2.typeId then
        local equalityFunction = self.dataTypes[dataEntry1.typeId].equalityFunction
        if equalityFunction then
            return equalityFunction(data1, data2)
        end
    end

    return false
end

local function FreeActiveScrollListControl(self, i)
    local currentControl = self.activeControls[i]
    local currentDataEntry = currentControl.dataEntry
    local dataType = self.dataTypes[currentDataEntry.typeId]

    if self.highlightTemplate and currentControl == self.highlightedControl then
        UnhighlightControl(self, currentControl)
        if self.highlightLocked then
            self.highlightLocked = false
        end
    end

    if currentControl == self.pendingHighlightControl then
        self.pendingHighlightControl = nil
    end

    if AreSelectionsEnabled(self) and currentControl == self.selectedControl then
        UnselectControl(self, currentControl)
    end

    if dataType.hideCallback then
        dataType.hideCallback(currentControl, currentControl.dataEntry.data)
    end

    dataType.pool:ReleaseObject(currentControl.key)
    currentControl.key = nil
    currentControl.dataEntry = nil
    self.activeControls[i] = self.activeControls[#self.activeControls]
    self.activeControls[#self.activeControls] = nil
end

local HIDE_SCROLLBAR = true
local function ResizeScrollBar(self, scrollableDistance)
    local scrollBarHeight = self.scrollbar:GetHeight()
    local scrollListHeight = ZO_ScrollList_GetHeight(self)
    if scrollableDistance > 0 then
        self.scrollbar:SetEnabled(true)

        if self.ScrollBarHiddenCallback then
            self.ScrollBarHiddenCallback(self, not HIDE_SCROLLBAR)
        else
            self.scrollbar:SetHidden(false)
        end

        self.scrollbar:SetThumbTextureHeight(scrollBarHeight * scrollListHeight /(scrollableDistance + scrollListHeight))
        if self.offset > scrollableDistance then
            self.offset = scrollableDistance
        end
        self.scrollbar:SetMinMax(0, scrollableDistance)
    else
        self.offset = 0
        self.scrollbar:SetThumbTextureHeight(scrollBarHeight)
        self.scrollbar:SetMinMax(0, 0)
        self.scrollbar:SetEnabled(false)

        if self.hideScrollBarOnDisabled then
            if self.ScrollBarHiddenCallback then
                self.ScrollBarHiddenCallback(self, HIDE_SCROLLBAR)
            else
                self.scrollbar:SetHidden(true)
            end
        end
    end
end
--[[----------------------------------------------------------------------------
    Modified version of ZO_ScrollList_UpdateScroll(self) from
    esoui\libraries\zo_templates\scrolltemplates.lua
--]]----------------------------------------------------------------------------
local consideredMap = {}
local function IGV_ScrollList_UpdateScroll_Grid(self)
    --added---------------------------------------------------------------------
    local function GetTopLeftTargetPosition(index, itemsPerRow, controlWidth, controlHeight, leftPadding, gridSpacing)
        local controlTop = zo_floor((index-1) / itemsPerRow) * (controlHeight + gridSpacing)
        local controlLeft = ((index-1) % itemsPerRow) * (controlWidth + gridSpacing) + leftPadding

        return controlTop, controlLeft
    end
    ----------------------------------------------------------------------------
    local windowHeight = ZO_ScrollList_GetHeight(self)
    local controlHeight = self.gridSize
    local controlWidth = self.gridSize
    local activeControls = self.activeControls
    local leftPadding = self.leftPadding
    local offset = self.offset

    --Added---------------------------------------------------------------------
    local itemsPerRow = zo_floor((self.contentsWidth - leftPadding) / (controlWidth))
    --data is the table of rows which respectively contain the item's info. The number of entries in this table is the number of items in that inventory
    local numRows = zo_ceil((#self.data or 0) / itemsPerRow)
    local gridSpacing = ((self.contentsWidth - leftPadding) - (itemsPerRow * controlWidth)) / (itemsPerRow - 1)

    ResizeScrollBar(self, (numRows * controlHeight + gridSpacing * (numRows - 1)) - windowHeight)
    ----------------------------------------------------------------------------

    UpdateScrollFade(self.useFadeGradient, self.contents, self.scrollbar, offset)

    --remove active controls that are now hidden
    local i = 1
    local numActive = #activeControls
    while i <= numActive do
        local currentDataEntry = activeControls[i].dataEntry

        if currentDataEntry.bottom < offset or currentDataEntry.top > offset + windowHeight then
            FreeActiveScrollListControl(self, i)
            numActive = numActive - 1
        else
            i = i + 1
        end

        consideredMap[currentDataEntry] = true
    end

    --add revealed controls
    local firstInViewIndex = zo_floor(offset / controlHeight)+1

    local data = self.data
    local dataTypes = self.dataTypes
    local visibleData = self.visibleData
    local mode = self.mode

    local i = firstInViewIndex
    local visibleDataIndex = visibleData[i]
    local dataEntry = data[visibleDataIndex]
    local bottomEdge = offset + windowHeight

    --modified------------------------------------------------------------------
    local controlTop, controlLeft

    if dataEntry then
        --removed isUniform check because we're assuming always uniform
        controlTop, controlLeft = GetTopLeftTargetPosition(i, itemsPerRow, controlWidth, controlHeight, leftPadding, gridSpacing)
    end
    ----------------------------------------------------------------------------
    while dataEntry and controlTop <= bottomEdge do
        if not consideredMap[dataEntry] then
            local dataType = dataTypes[dataEntry.typeId]
            local controlPool = dataType.pool
            local control, key = controlPool:AcquireObject()

            control:SetHidden(false)
            control.dataEntry = dataEntry
            control.key = key
            control.index = visibleDataIndex
            --added-------------------------------------------------------------
            control.isGrid = false
            --------------------------------------------------------------------
            if dataType.setupCallback then
                dataType.setupCallback(control, dataEntry.data, self)
            end
            table.insert(activeControls, control)
            consideredMap[dataEntry] = true

            if AreDataEqualSelections(self, dataEntry.data, self.selectedData) then
                SelectControl(self, control)
            end

            --even uniform active controls need to know their position to determine if they are still active
            --modified----------------------------------------------------------
            --removed isUniform check because we're assuming always uniform
            dataEntry.top = controlTop
            dataEntry.bottom = controlTop + controlHeight
            --------------------------------------------------------------------
            --added-------------------------------------------------------------
            dataEntry.left = controlLeft
            dataEntry.right = controlLeft + controlWidth
            --------------------------------------------------------------------
        end
        i = i + 1
        visibleDataIndex = visibleData[i]
        dataEntry = data[visibleDataIndex]
        --modified--------------------------------------------------------------
        if dataEntry then
            --removed isUniform check because we're assuming always uniform
            controlTop, controlLeft = GetTopLeftTargetPosition(i, itemsPerRow, controlWidth, controlHeight, leftPadding, gridSpacing)
        end
        ------------------------------------------------------------------------
    end

    --update positions
    local contents = self.contents
    local numActive = #activeControls

    for i = 1, numActive do
        local currentControl = activeControls[i]
        local currentData = currentControl.dataEntry
        local controlOffset = currentData.top - offset
        --added-----------------------------------------------------------------
        local controlOffsetX = currentData.left
        ------------------------------------------------------------------------

        currentControl:ClearAnchors()
        --modified--------------------------------------------------------------
        currentControl:SetAnchor(TOPLEFT, contents, TOPLEFT, controlOffsetX, controlOffset)
        --removed other anchor because this will no longer stretch across the contents pane
        ------------------------------------------------------------------------
    end

    --reset considered
    for k, v in pairs(consideredMap) do
        consideredMap[k] = nil
    end
end
--[[----------------------------------------------------------------------------
    Modified version of ZO_ItemTooltip_AddMoney(...) from
    esoui\ingame\tooltip\tooltip.lua
--]]----------------------------------------------------------------------------
--added currencyType parameter
function ZO_ItemTooltip_AddMoney(tooltipControl, amount, reason, notEnough, currencyType)
    local moneyLine = GetControl(tooltipControl, "SellPrice")
    local reasonLabel = GetControl(moneyLine, "Reason")
    local currencyControl = GetControl(moneyLine, "Currency")

    --added---------------------------------------------------------------------
    local currencyType = currencyType or CURT_MONEY
    --these is also from tooltip.lua, outside the function
    local SELL_REASON_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_SELLS_FOR))
    local REASON_CURRENCY_SPACING = 3
    local MONEY_LINE_HEIGHT = 18
    local ITEM_TOOLTIP_CURRENCY_OPTIONS = { showTooltips = false, }
    ----------------------------------------------------------------------------

    moneyLine:SetHidden(false)

    local width = 0
    reasonLabel:ClearAnchors()
    currencyControl:ClearAnchors()

     -- right now reason is always a string index
    if reason and reason ~= 0 then
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

    if amount > 0 then
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
--[[----------------------------------------------------------------------------
    Our own code
--]]----------------------------------------------------------------------------
local minimumQuality = ITEM_QUALITY_TRASH
local TEXTURE_SET = nil

local function AddColor(control)
    if not control.dataEntry then return end
    if control.dataEntry.data.slotIndex == nil then control.dataEntry.data.quality = 0 end

    local quality = control.dataEntry.data.quality
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)

    local alpha = 1
    if quality < minimumQuality then
        alpha = 0
    end

    control:GetNamedChild("Bg"):SetColor(r, g, b, 1)
    control:GetNamedChild("Outline"):SetColor(r, g, b, alpha)
    control:GetNamedChild("Highlight"):SetColor(r, g, b, 0)
end

--control = ZO_PlayerInventoryBackpack1Row1 etc.
local function ReshapeSlot(control, isGrid, isOutlines, width, height, forceUpdate)
    if control == nil then return end

    local LIST_SLOT_BACKGROUND = [[EsoUI/Art/Miscellaneous/listItem_backdrop.dds]]
    local LIST_SLOT_HOVER = [[EsoUI/Art/Miscellaneous/listitem_highlight.dds]]
    local ICON_MULT = 0.77

    control:GetNamedChild("SellPrice"):SetHidden(isGrid)

    if control.isGrid ~= isGrid or forceUpdate then
        control.isGrid = isGrid
        local thisName = control:GetName()

        local button = control:GetNamedChild("Button")
        local bg = control:GetNamedChild("Bg")
        local new = control:GetNamedChild("Status")
        local name = control:GetNamedChild("Name")
        local stat = control:GetNamedChild("StatValue")
        local sell = control:GetNamedChild("SellPrice")
        local highlight = control:GetNamedChild("Highlight")
        local outline = control:GetNamedChild("Outline")
        if not outline then
            outline = WINDOW_MANAGER:CreateControl(control:GetName() .. "Outline", control, CT_TEXTURE)
            outline:SetAnchor(CENTER, control, CENTER)
        end

        button:ClearAnchors()
        if new then new:ClearAnchors() end
        control:SetDimensions(width, height)
        button:SetDimensions(height * ICON_MULT, height * ICON_MULT)
        outline:SetDimensions(height, height)

        if isGrid == true and new ~= nil then
            button:SetAnchor(CENTER, control, CENTER)

            new:SetDimensions(5,5)
            new:SetAnchor(TOPLEFT, control, TOPLEFT, 10, 10)

            name:SetHidden(true)
            stat:SetHidden(true)
            highlight:SetTexture(TEXTURE_SET.HOVER)
            highlight:SetTextureCoords(0, 1, 0, 1)

            bg:SetTexture(TEXTURE_SET.BACKGROUND)
            bg:SetTextureCoords(0, 1, 0, 1)
            sell:SetAlpha(0)

            if isOutlines then
                outline:SetTexture(TEXTURE_SET.OUTLINE)
                outline:SetHidden(false)
            else
                outline:SetHidden(true)
            end
            AddColor(control)
        else
            button:SetAnchor(CENTER, control, TOPLEFT, 47, 26)

            if new then new:SetAnchor(CENTER, control, TOPLEFT, 20, 27) end

            name:SetHidden(false)
            stat:SetHidden(false)
            outline:SetHidden(true)

            highlight:SetTexture(LIST_SLOT_HOVER)
            highlight:SetColor(1, 1, 1, 0)
            highlight:SetTextureCoords(0, 1, 0, .625)

            bg:SetTexture(LIST_SLOT_BACKGROUND)
            bg:SetTextureCoords(0, 1, 0, .8125)
            bg:SetColor(1, 1, 1, 1)
            sell:SetAlpha(1)
        end
    end
end

local function ReshapeSlots(self)
    local allControlsParent = self:GetNamedChild("Contents")
    local numControls = allControlsParent:GetNumChildren()

    local width, height
    if self.isGrid == true then
        width = self.gridSize
        height = self.gridSize
    else
        width = self.contentsWidth
        height = self.listHeight
    end

    --BUYBACK and QUICKSLOT don't have the same child element pattern, have to start at 1 instead of 2
    if self.IGVId == INVENTORY_QUEST_ITEM or self.IGVId == 6 or self.IGVId == 7 then
        for i = 1, numControls do
            ReshapeSlot(allControlsParent:GetChild(i), self.isGrid, self.isOutlines, width, height, self.forceUpdate)
        end

        if self.forceUpdate then
            for i = 1, numControls do
               allControlsParent:GetChild(i).isGrid = self.isGrid
            end

            if self.IGVId == INVENTORY_QUEST_ITEM then
                for _, v in pairs(self.dataTypes[2].pool["m_Free"]) do
                    ReshapeSlot(v, self.isGrid, self.isOutlines, width, height, self.forceUpdate)
                end
            else
                for _, v in pairs(self.dataTypes[1].pool["m_Free"]) do
                    ReshapeSlot(v, self.isGrid, self.isOutlines, width, height, self.forceUpdate)
                end
            end
        end
    else
        for i = 2, numControls do
            ReshapeSlot(allControlsParent:GetChild(i), self.isGrid, self.isOutlines, width, height, self.forceUpdate)
        end

        if self.forceUpdate then
            for i = 2, numControls do
                allControlsParent:GetChild(i).isGrid = self.isGrid
            end
            for _, v in pairs(self.dataTypes[1].pool["m_Free"]) do
                ReshapeSlot(v, self.isGrid, self.isOutlines, width, height, self.forceUpdate)
            end
        end
    end

    self.forceUpdate = false
end

function InventoryGridView_ToggleOutlines(toggle)
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

    for _, self in ipairs(bags) do
        self.isOutlines = toggle
        self.forceUpdate = self.isGrid

        --no need to update if current in list view
        if not self.forceUpdate then return end

        while #self.activeControls > 0 do
            FreeActiveScrollListControl(self, 1)
        end

        if self.isGrid then
            IGV_ScrollList_UpdateScroll_Grid(self)
            --this is done in the toggle function, but this ensures that any NEW slots get reshaped
            ReshapeSlots(self)
        else
            ZO_ScrollList_UpdateScroll(self)
        end

        ReshapeSlots(self)
    end
end

function InventoryGridView_ToggleGrid(self, toggle)
    self.isGrid = toggle
    self.forceUpdate = true
    ZO_ScrollList_ResetToTop(self)

    ReshapeSlots(self)
    while #self.activeControls > 0 do
        FreeActiveScrollListControl(self, 1)
    end

    if toggle then
        IGV_ScrollList_UpdateScroll_Grid(self)
        --this is done in the toggle function, but this ensures that any NEW slots get reshaped
        ReshapeSlots(self)
    else
        ZO_ScrollList_UpdateScroll(self)
        ResizeScrollBar(self, (#self.data * self.controlHeight) - ZO_ScrollList_GetHeight(self))
    end

    ZO_ScrollList_RefreshVisible(self)
    ReshapeSlots(self)
end

function InventoryGridView_SetMinimumQuality(quality, forceUpdate)
    minimumQuality = quality
    ZO_PlayerInventoryBackpack.forceUpdate = forceUpdate or false
    ZO_PlayerBankBackpack.forceUpdate = forceUpdate or false
    ZO_GuildBankBackpack.forceUpdate = forceUpdate or false
    ZO_StoreWindowList.forceUpdate = forceUpdate or false
    --ZO_BuyBackList.forceUpdate = forceUpdate or false
    ReshapeSlots(ZO_PlayerInventoryBackpack)
    ReshapeSlots(ZO_PlayerBankBackpack)
    ReshapeSlots(ZO_GuildBankBackpack)
    ReshapeSlots(ZO_StoreWindowList)
    --ReshapeSlots(ZO_BuyBackList)
end

function InventoryGridView_SetTextureSet(textureSet, forceUpdate)
    TEXTURE_SET = textureSet
    ZO_PlayerInventoryBackpack.forceUpdate = forceUpdate or false
    ZO_PlayerBankBackpack.forceUpdate = forceUpdate or false
    ZO_GuildBankBackpack.forceUpdate = forceUpdate or false
    ZO_StoreWindowList.forceUpdate = forceUpdate or false
    --ZO_BuyBackList.forceUpdate = forceUpdate or false
    ReshapeSlots(ZO_PlayerInventoryBackpack)
    ReshapeSlots(ZO_PlayerBankBackpack)
    ReshapeSlots(ZO_GuildBankBackpack)
    ReshapeSlots(ZO_StoreWindowList)
    --ReshapeSlots(ZO_BuyBackList)
end

--init the grid view data
do
    --function to set tooltip offset
    local function igvTooltipAnchor(tooltip, buttonPart, comparativeTooltip1, comparativeTooltip2)
        -- call the regular one, not ideal but probably better than copying most of the code here :)
        ZO_Tooltips_SetupDynamicTooltipAnchors(tooltip, buttonPart, comparativeTooltip1, comparativeTooltip2)
        -- custom setup
        tooltip:ClearAnchors()
        if InventoryGridViewSettings:IsTooltipOffset() and buttonPart:GetParent().isGrid then
            local anchorPoint = buttonPart:GetParent()
            local gridSize = InventoryGridViewSettings:GetGridSize()
            local edge = ZO_PlayerInventoryBackpackContents:GetLeft()
            local col = ((anchorPoint:GetLeft() - edge) / gridSize) + 1
            local offsetX = -(gridSize * col - gridSize)
            tooltip:SetOwner(anchorPoint, RIGHT, offsetX, 0)
        else
            tooltip:SetOwner(anchorPoint, RIGHT, 0, 0)
        end
    end
    local function prepListView(listView)
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback

            listView.dataTypes[1].setupCallback =
                function(rowControl, slot)
                    rowControl.isGrid = nil
                    rowControl:GetNamedChild("Button").customTooltipAnchor = igvTooltipAnchor
                    hookedFunctions(rowControl, slot)
                end
        end
    end
    --hook function!  to be called before "ZO_ScrollList_UpdateScroll"
    --thanks to Seerah for teaching me about this possibility
    local function ScrollController(self)
        if self.isGrid then
            IGV_ScrollList_UpdateScroll_Grid(self)
            --this is done in the toggle function, but this ensures that any NEW slots get reshaped
            ReshapeSlots(self)
            return true
        else
            return false
        end
    end
    --function to set custom icon scaling
    local function CreateSlotAnimation(inventorySlot)
        if inventorySlot.slotControlType == "listSlot" and inventorySlot.isGrid == true then
            local control = inventorySlot
            local controlType = inventorySlot:GetType()

            if controlType == CT_CONTROL and control.slotControlType == "listSlot" then
                control = inventorySlot:GetNamedChild("MultiIcon") or inventorySlot:GetNamedChild("Button")
            end

     		--want to force refresh of control animation
            if control then
                control.animation = ANIMATION_MANAGER:CreateTimelineFromVirtual("IconSlotMouseOverAnimation", control)
                control.animation:GetFirstAnimation():SetEndScale(SHARED_INVENTORY.IGViconZoomLevel)
            end
        end
    end
    local function AddCurrency(rowControl)
        if not rowControl.dataEntry then return end

        local IGVId = rowControl.dataEntry.data.bagId or rowControl:GetParent():GetParent().IGVId
        local slotIndex = rowControl.dataEntry.data.slotIndex
        local _, stack, sellPrice, currencyType, notEnough

        if IGVId == ZO_StoreWindowList.IGVId or IGVId == ZO_BuyBackList.IGVId then
            for _, v in pairs(rowControl:GetNamedChild("SellPrice").currencyArgs) do
                if v.isUsed == true then
                    currencyType = v.type
                    notEnough = v.notEnough
                end
            end

            if currencyType == CURT_MONEY then
                sellPrice = rowControl.dataEntry.data.price
            else
                sellPrice = rowControl.dataEntry.data.currencyQuantity1
            end
            --bandaid catch all for sellPrice == nil
            sellPrice = sellPrice or 0

            stack = rowControl.dataEntry.data.stack
            ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack, 0, notEnough, currencyType)
        else
            _, stack, sellPrice = GetItemInfo(IGVId, slotIndex)
            ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack)
        end
    end
    local function AddCurrencySoon(rowControl)
        if rowControl:GetParent():GetParent().IGVId == INVENTORY_QUEST_ITEM then return end
        if rowControl and rowControl.isGrid then
            zo_callLater(function() AddCurrency(rowControl) end, 50)
        end
    end

    for _, v in pairs(PLAYER_INVENTORY.inventories) do
        prepListView(v.listView)
    end
    prepListView(ZO_StoreWindowList)
    prepListView(ZO_BuyBackList)
    prepListView(ZO_QuickSlotList)

    ZO_PreHook("ZO_ScrollList_UpdateScroll", ScrollController)
    ZO_PreHook("ZO_InventorySlot_OnMouseEnter", CreateSlotAnimation)
    ZO_PreHook("ZO_InventorySlot_OnMouseEnter", AddCurrencySoon)
end
