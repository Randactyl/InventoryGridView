local IGV = InventoryGridView
IGV.util = {}

local util = IGV.util
util.lam = LibStub("LibAddonMenu-2.0")

local function AddColor(control)
    if not control.dataEntry then return end
    if control.dataEntry.data.slotIndex == nil then control.dataEntry.data.quality = 0 end

    local quality = control.dataEntry.data.quality
    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, quality)

    local alpha = 1
    if quality < IGV.settings.GetMinOutlineQuality() then
        alpha = 0
    end

    control:GetNamedChild("Bg"):SetColor(r, g, b, 1)
    control:GetNamedChild("Outline"):SetColor(r, g, b, alpha)
    control:GetNamedChild("Highlight"):SetColor(r, g, b, 0)
end

--control = ZO_PlayerInventoryBackpack1Row1 etc.
local oldSetHidden
local function ReshapeSlot(control, isGrid, width, height)
    if control == nil then return end

    local ICON_MULT = 0.77
    local textureSet = IGV.settings.GetTextureSet()

    if control.isGrid ~= isGrid then
        control.isGrid = isGrid

        local bg = control:GetNamedChild("Bg")
        local highlight = control:GetNamedChild("Highlight")
        local outline = control:GetNamedChild("Outline")
        local new = control:GetNamedChild("Status")
        local button = control:GetNamedChild("Button")
        local name = control:GetNamedChild("Name")
        local sell = control:GetNamedChild("SellPrice")
        --local stat = control:GetNamedChild("StatValue")

        --make sure sell price label stays shown/hidden
        if sell then
            if not oldSetHidden then oldSetHidden = sell.SetHidden end

            sell.SetHidden = function(sell, shouldHide)
                if isGrid and shouldHide then
                    oldSetHidden(sell, shouldHide)
                elseif isGrid then
                    return
                else
                    oldSetHidden(sell, shouldHide)
                end
            end
            --show/hide sell price label
            sell:SetHidden(isGrid)
        end

        --create outline texture for control if missing
        if not outline then
            outline = WINDOW_MANAGER:CreateControl(control:GetName() .. "Outline", control, CT_TEXTURE)
            outline:SetAnchor(CENTER, control, CENTER)
        end
        outline:SetDimensions(height, height)

        if button then
            button:ClearAnchors()
            button:SetDimensions(height * ICON_MULT, height * ICON_MULT)
        end

        if new then new:ClearAnchors() end

        control:SetDimensions(width, height)

        if isGrid == true and new ~= nil then
            button:SetAnchor(CENTER, control, CENTER)

            new:SetDimensions(25, 25)
            new:SetAnchor(TOPLEFT, button:GetNamedChild("Icon"), TOPLEFT, -5, -5)
            new:SetDrawTier(DT_HIGH)

            --disable mouse events on status controls
            new:SetMouseEnabled(false)
            new:GetNamedChild("Texture"):SetMouseEnabled(false)

            name:SetHidden(true)
            --stat:SetHidden(true)

            highlight:SetTexture(textureSet.HOVER)
            highlight:SetTextureCoords(0, 1, 0, 1)

            bg:SetTexture(textureSet.BACKGROUND)
            bg:SetTextureCoords(0, 1, 0, 1)

            if IGV.settings.ShowQualityOutline() then
                outline:SetTexture(textureSet.OUTLINE)
                outline:SetHidden(false)
            else
                outline:SetHidden(true)
            end

            AddColor(control)
        else
            local LIST_SLOT_BACKGROUND = "EsoUI/Art/Miscellaneous/listItem_backdrop.dds"
            local LIST_SLOT_HOVER = "EsoUI/Art/Miscellaneous/listitem_highlight.dds"

            if button then button:SetAnchor(CENTER, control, TOPLEFT, 47, 26) end

            if new then
                new:SetDimensions(32, 32)
                new:SetAnchor(CENTER, control, TOPLEFT, 20, 27)

                --enable mouse events on status controls
                new:SetMouseEnabled(true)
                new:GetNamedChild("Texture"):SetMouseEnabled(true)
            end

            if name then name:SetHidden(false) end
            --if stat then stat:SetHidden(false) end
            outline:SetHidden(true)

            if highlight then
                highlight:SetTexture(LIST_SLOT_HOVER)
                highlight:SetColor(1, 1, 1, 0)
                highlight:SetTextureCoords(0, 1, 0, .625)
            end

            if bg then
                bg:SetTexture(LIST_SLOT_BACKGROUND)
                bg:SetTextureCoords(0, 1, 0, .8125)
                bg:SetColor(1, 1, 1, 1)
            end
        end
    end
end

function util.ReshapeSlots()
    local scrollList = IGV.currentScrollList
    if not scrollList then return end
    local parent = scrollList.contents
    local numControls = parent:GetNumChildren()
    local gridIconSize = IGV.settings.GetGridIconSize()
    local IGVId = IGV.currentIGVId
    local isGrid = IGV.settings.IsGrid(IGVId)

    local width, height

    if isGrid then
        width = gridIconSize
        height = gridIconSize
    else
        width = scrollList:GetWidth()
        height = scrollList.controlHeight
    end

    --CRAFT_BAG, QUICKSLOT, and BUY_BACK don't have the same child element pattern, have to start at 1 instead of 2
    if IGVId == 4 or IGVId == 5 or IGVId == 7 then
        for i = 1, numControls do
            ReshapeSlot(parent:GetChild(i), isGrid, width, height)
        end

        for i = 1, numControls do
            parent:GetChild(i).isGrid = isGrid
        end

        if scrollList.dataTypes[1] then
            for _, v in pairs(scrollList.dataTypes[1].pool["m_Free"]) do
                ReshapeSlot(v, isGrid, width, height)
            end
        end

        if scrollList.dataTypes[2] then
            for _, v in pairs(scrollList.dataTypes[2].pool["m_Free"]) do
                ReshapeSlot(v, isGrid, width, height)
            end
        end
    else
        for i = 2, numControls do
            ReshapeSlot(parent:GetChild(i), isGrid, width, height)
        end

        for i = 2, numControls do
            parent:GetChild(i).isGrid = isGrid
        end

        for _, v in pairs(scrollList.dataTypes[1].pool["m_Free"]) do
            ReshapeSlot(v, isGrid, width, height)
        end
    end
end