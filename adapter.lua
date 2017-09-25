local IGV = InventoryGridView
IGV.adapter = {}

local util = IGV.util
local settings = IGV.settings
local adapter = IGV.adapter

local LEFT_PADDING = 25
--[[----------------------------------------------------------------------------
    Ported ZOS code from esoui\libraries\zo_templates\scrolltemplates.lua
--]]----------------------------------------------------------------------------
local MAX_FADE_VALUE = 64

local ANIMATE_INSTANTLY = true

local function UpdateScrollFade(useFadeGradient, scroll, slider, sliderValue)
    if(useFadeGradient) then
        local sliderMin, sliderMax = slider:GetMinMax()
        sliderValue = sliderValue or slider:GetValue()

        if(sliderValue > sliderMin) then
            scroll:SetFadeGradient(1, 0, 1, zo_min(sliderValue - sliderMin, MAX_FADE_VALUE))
        else
            scroll:SetFadeGradient(1, 0, 0, 0)
        end

        if(sliderValue < sliderMax) then
            scroll:SetFadeGradient(2, 0, -1, zo_min(sliderMax - sliderValue, MAX_FADE_VALUE))
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

local function RemoveAnimationOnControl(control, animationFieldName, animateInstantly)
    if control[animationFieldName] then
        if animateInstantly then
            control[animationFieldName]:PlayInstantlyToStart()
        else
            control[animationFieldName]:PlayBackward()
        end
    end
end

local function UnhighlightControl(self, control)
    RemoveAnimationOnControl(control, "HighlightAnimation")

    self.highlightedControl = nil

    if(self.highlightCallback) then
        self.highlightCallback(control, false)
    end
end

local function UnselectControl(self, control, animateInstantly)
    RemoveAnimationOnControl(control, "SelectionAnimation", animateInstantly)

    self.selectedControl = nil
end

local function AreDataEqualSelections(self, data1, data2)
    if(data1 == data2) then
        return true
    end

    if(data1 == nil or data2 == nil) then
        return false
    end

    local dataEntry1 = data1.dataEntry
    local dataEntry2 = data2.dataEntry
    if(dataEntry1.typeId == dataEntry2.typeId) then
        local equalityFunction = self.dataTypes[dataEntry1.typeId].equalityFunction
        if(equalityFunction) then
            return equalityFunction(data1, data2)
        end
    end

    return false
end

local function FreeActiveScrollListControl(self, i)
    local currentControl = self.activeControls[i]
    local currentDataEntry = currentControl.dataEntry
    local dataType = self.dataTypes[currentDataEntry.typeId]

    if(self.highlightTemplate and currentControl == self.highlightedControl) then
        UnhighlightControl(self, currentControl)
        if(self.highlightLocked) then
            self.highlightLocked = false
        end
    end

    if(currentControl == self.pendingHighlightControl) then
        self.pendingHighlightControl = nil
    end

    if AreSelectionsEnabled(self) and currentControl == self.selectedControl then
        UnselectControl(self, currentControl, ANIMATE_INSTANTLY)
    end

    if(dataType.hideCallback) then
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
    if(scrollableDistance > 0) then
        self.scrollbar:SetEnabled(true)

        if self.ScrollBarHiddenCallback then
            self.ScrollBarHiddenCallback(self, not HIDE_SCROLLBAR)
        else
            self.scrollbar:SetHidden(false)
        end

        self.scrollbar:SetThumbTextureHeight(scrollBarHeight * scrollListHeight /(scrollableDistance + scrollListHeight))
        if(self.offset > scrollableDistance) then
            self.offset = scrollableDistance
        end
        self.scrollbar:SetMinMax(0, scrollableDistance)
    else
        self.offset = 0
        self.scrollbar:SetThumbTextureHeight(scrollBarHeight)
        self.scrollbar:SetMinMax(0, 0)
        self.scrollbar:SetEnabled(false)

        if(self.hideScrollBarOnDisabled) then
            if self.ScrollBarHiddenCallback then
                self.ScrollBarHiddenCallback(self, HIDE_SCROLLBAR)
            else
                self.scrollbar:SetHidden(true)
            end
        end
    end
end

local function CompareEntries(topEdge, compareData)
    return topEdge - compareData.bottom
end

local SCROLL_LIST_UNIFORM = 1
local function FindStartPoint(self, topEdge)
    if(self.mode == SCROLL_LIST_UNIFORM) then
        return zo_floor(topEdge / self.controlHeight)+1
    else
        local found, insertPoint = zo_binarysearch(topEdge, self.data, CompareEntries)
        return insertPoint
    end
end

--[[----------------------------------------------------------------------------
    Modified version of ZO_ScrollList_UpdateScroll(self) from
    esoui\libraries\zo_templates\scrolltemplates.lua
--]]----------------------------------------------------------------------------
local consideredMap = {}
local function IGV_ScrollList_UpdateScroll_Grid(self)
    local windowHeight = ZO_ScrollList_GetHeight(self)

    --Added---------------------------------------------------------------------
    local gridIconSize = settings.GetGridIconSize()
    local contentsWidth = self.contents:GetWidth()
    local contentsWidthMinusPadding = contentsWidth - LEFT_PADDING
    local itemsPerRow = zo_floor(contentsWidthMinusPadding / gridIconSize)
    local numControls = #self.data or 0
    local numRows = zo_ceil(numControls / itemsPerRow)
    local gridSpacing = .5
    local totalControlHeight = gridIconSize * numRows
    local totalSpacingHeight = gridSpacing * (numRows - 1)
    local scrollableDistance = (totalControlHeight + totalSpacingHeight) - windowHeight

    local function GetTargetTopAndLeftPositions(viewIndex)
        local totalControlWidth = gridIconSize + gridSpacing
        local controlTop = zo_floor((viewIndex - 1) / itemsPerRow) * totalControlWidth
        local controlLeft = ((viewIndex - 1) % itemsPerRow) * totalControlWidth + LEFT_PADDING

        return controlTop, controlLeft
    end

    self.controlHeight = gridIconSize

    ResizeScrollBar(self, scrollableDistance)
    ----------------------------------------------------------------------------

    local controlHeight = self.controlHeight
    local activeControls = self.activeControls
    local offset = self.offset

    UpdateScrollFade(self.useFadeGradient, self.contents, self.scrollbar, offset)

    --remove active controls that are now hidden
    local i = 1
    local numActive = #activeControls
    while(i <= numActive) do
        local currentDataEntry = activeControls[i].dataEntry

        if(currentDataEntry.bottom < offset or currentDataEntry.top > offset + windowHeight) then
            FreeActiveScrollListControl(self, i)
            numActive = numActive - 1
        else
            i = i + 1
        end

        consideredMap[currentDataEntry] = true
    end

    --add revealed controls
    local firstInViewIndex = FindStartPoint(self, offset)

    local data = self.data
    local dataTypes = self.dataTypes
    local visibleData = self.visibleData
    local mode = self.mode

    local i = firstInViewIndex
    local visibleDataIndex = visibleData[i]
    local dataEntry = data[visibleDataIndex]
    local bottomEdge = offset + windowHeight

    --Modified------------------------------------------------------------------
    local controlTop, controlLeft

    if dataEntry then
        --removed isUniform check because we're assuming always uniform
        controlTop, controlLeft = GetTargetTopAndLeftPositions(i)
    end
    ----------------------------------------------------------------------------
    while(dataEntry and controlTop <= bottomEdge) do
        if(not consideredMap[dataEntry]) then
            local dataType = dataTypes[dataEntry.typeId]
            local controlPool = dataType.pool
            local control, key = controlPool:AcquireObject()

            control:SetHidden(false)
            control.dataEntry = dataEntry
            control.key = key
            control.index = visibleDataIndex
            --Added-------------------------------------------------------------
            control.isGrid = false
            --------------------------------------------------------------------
            if(dataType.setupCallback) then
                dataType.setupCallback(control, dataEntry.data, self)
            end
            table.insert(activeControls, control)
            consideredMap[dataEntry] = true

            if(AreDataEqualSelections(self, dataEntry.data, self.selectedData)) then
                SelectControl(self, control)
            end

            --even uniform active controls need to know their position to determine if they are still active
            --Modified----------------------------------------------------------
            --removed isUniform check because we're assuming always uniform
            dataEntry.top = controlTop
            dataEntry.bottom = controlTop + controlHeight
            --------------------------------------------------------------------
            --Added-------------------------------------------------------------
            dataEntry.left = controlLeft
            dataEntry.right = controlLeft + gridIconSize
            --------------------------------------------------------------------
        end
        i = i + 1
        visibleDataIndex = visibleData[i]
        dataEntry = data[visibleDataIndex]
        --Modified--------------------------------------------------------------
        if(dataEntry) then
            --removed isUniform check because we're assuming always uniform
            controlTop, controlLeft = GetTargetTopAndLeftPositions(i)
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
        --Added-----------------------------------------------------------------
        local controlOffsetX = currentData.left
        ------------------------------------------------------------------------
        currentControl:ClearAnchors()
        --Modified--------------------------------------------------------------
        currentControl:SetAnchor(TOPLEFT, contents, TOPLEFT, controlOffsetX, controlOffset)
        --removed other anchor because this will no longer stretch across the contents pane
        ------------------------------------------------------------------------
    end

    --reset considered
    for k,v in pairs(consideredMap) do
        consideredMap[k] = nil
    end
end

--[[----------------------------------------------------------------------------
    Modified version of ZO_ItemTooltip_AddMoney(...) from
    esoui\publicallingames\tooltip\tooltip.lua
--]]----------------------------------------------------------------------------
--Added currencyType parameter
local privateKey = {}
function ZO_ItemTooltip_AddMoney(tooltipControl, amount, reason, notEnough, currencyType)
    local moneyLine = GetControl(tooltipControl, "SellPrice")
    local reasonLabel = GetControl(moneyLine, "Reason")
    local currencyControl = GetControl(moneyLine, "Currency")

    --Added---------------------------------------------------------------------
    local currencyType = currencyType or CURT_MONEY
    --these is also from tooltip.lua, outside the function
    local SELL_REASON_COLOR = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_TOOLTIP, ITEM_TOOLTIP_COLOR_SELLS_FOR))
    local REASON_CURRENCY_SPACING = 3
    local MONEY_LINE_HEIGHT = 18
    local ITEM_TOOLTIP_CURRENCY_OPTIONS = {showTooltips = false,}
    ----------------------------------------------------------------------------

    moneyLine:SetHidden(false)

    local width = 0
    reasonLabel:ClearAnchors()
    currencyControl:ClearAnchors()

    -- right now reason is always a string index
    --Added------------------------------------------------------------------
    if reason == privateKey and amount > 0 then
        reasonLabel:SetAnchor(TOPLEFT, nil, TOPLEFT, 0, 0)
        currencyControl:SetAnchor(TOPLEFT, reasonLabel, TOPRIGHT, REASON_CURRENCY_SPACING)

        reasonLabel:SetHidden(false)
        reasonLabel:SetColor(SELL_REASON_COLOR:UnpackRGBA())
        reasonLabel:SetText(GetString(SI_STORE_SORT_TYPE_PRICE)..":")

        local reasonTextWidth, reasonTextHeight = reasonLabel:GetTextDimensions()
        width = width + reasonTextWidth + REASON_CURRENCY_SPACING
    ----------------------------------------------------------------------------
    --Modified------------------------------------------------------------------
    elseif reason and reason ~= 0 and reason ~= privateKey then
    ----------------------------------------------------------------------------
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
        --Modified--------------------------------------------------------------
        ZO_CurrencyControl_SetSimpleCurrency(currencyControl, currencyType,
            amount, ITEM_TOOLTIP_CURRENCY_OPTIONS, CURRENCY_DONT_SHOW_ALL,
            notEnough)
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
local function AddCurrency(rowControl)
    if not rowControl.dataEntry then return end

    local IGVId = IGV.currentIGVId
    local slotIndex = rowControl.dataEntry.data.slotIndex
    local _, stack, sellPrice, currencyType, notEnough

    if IGVId == IGVID_STORE then
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

        ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack, privateKey, notEnough, currencyType)
    else
        local bagId = rowControl.dataEntry.data.bagId
        if not bagId then return end

        _, stack, sellPrice = GetItemInfo(bagId, slotIndex)

        ZO_ItemTooltip_AddMoney(ItemTooltip, sellPrice * stack, privateKey)
    end
end

function adapter.AddCurrencySoon(rowControl)
    if not rowControl and not rowControl.isGrid then return end

    if IGV.currentIGVId == IGVID_CRAFT_BAG or IGV.currentIGVId == IGVID_STORE then
        local function wrapper()
            AddCurrency(rowControl)
        end

        zo_callLater(wrapper, 50)
    end
end

local function freeActiveScrollListControls(scrollList)
    if not scrollList or not scrollList.activeControls then return end

    while #scrollList.activeControls > 0 do
        FreeActiveScrollListControl(scrollList, 1)
    end
end

function adapter.ScrollController(self)
    if self == IGV.currentScrollList and settings.IsGrid(IGV.currentIGVId) then
        freeActiveScrollListControls(self)
        IGV_ScrollList_UpdateScroll_Grid(self)
        util.ReshapeSlots()

        return true
    else
        return false
    end
end

function adapter.ToggleGrid()
    local IGVId = IGV.currentIGVId
    local scrollList = IGV.currentScrollList

    if not scrollList then return end

    settings.ToggleGrid(IGVId)
    local isGrid = settings.IsGrid(IGVId)

    ZO_ScrollList_ResetToTop(scrollList)

    util.ReshapeSlots()
    freeActiveScrollListControls(scrollList)

    ZO_ScrollList_UpdateScroll(scrollList)

    if isGrid then
        util.ReshapeSlots()
    else
        ResizeScrollBar(scrollList, (#scrollList.data * scrollList.controlHeight) - ZO_ScrollList_GetHeight(scrollList))
    end

    ZO_ScrollList_RefreshVisible(scrollList)
    util.ReshapeSlots()
end