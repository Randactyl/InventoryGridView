InventoryGridView = {}
local IGV = InventoryGridView
IGV.addonVersion = "2.0.5.0"
IGV.currentIGVId = nil
IGV.currentScrollList = nil

IGVID_INVENTORY  = 1
IGVID_BANK       = 2
IGVID_GUILD_BANK = 3
IGVID_CRAFT_BAG  = 4
IGVID_QUICKSLOT  = 5
IGVID_STORE      = 6
IGVID_BUY_BACK   = 7

local util, settings, adapter

local function InventoryGridViewLoaded(eventCode, addOnName)
    if addOnName ~= "InventoryGridView" then return end
    EVENT_MANAGER:UnregisterForEvent("InventoryGridViewLoaded", EVENT_ADD_ON_LOADED)

    util = IGV.util
    settings = IGV.settings
    adapter = IGV.adapter

    settings.InitializeSettings()

    local function initializeHooks()
        local function hookFragment(fragment, IGVId)
            local scrollList = fragment.control:GetNamedChild("List") or fragment.control:GetNamedChild("Backpack")

            if not scrollList then return end

            local function onFragmentStateChange(oldState, newState)
                local keybindButtonDescriptor = {
                    alignment = KEYBIND_STRIP_ALIGN_LEFT,
                    order = 100,
                    name = GetString(SI_BINDING_NAME_INVENTORYGRIDVIEW_TOGGLE),
                    keybind = "INVENTORYGRIDVIEW_TOGGLE",
                    callback = adapter.ToggleGrid,
                }

                local function onFragmentShowing()
                    IGV.currentIGVId = IGVId
                    IGV.currentScrollList = scrollList

                    ZO_ScrollList_UpdateScroll(scrollList)

                    KEYBIND_STRIP:AddKeybindButton(keybindButtonDescriptor)
                end

                local function onFragmentHiding()
                    IGV.currentIGVId = nil
                    IGV.currentScrollList = nil

                    KEYBIND_STRIP:RemoveKeybindButton(keybindButtonDescriptor)
                end

                if newState == SCENE_FRAGMENT_SHOWING then
                    onFragmentShowing()
                elseif newState == SCENE_FRAGMENT_HIDING then
                    onFragmentHiding()
                end
            end
            fragment:RegisterCallback("StateChange", onFragmentStateChange)

            --set tooltip offset
            local function igvTooltipAnchor(tooltip, buttonPart, comparativeTooltip1, comparativeTooltip2)
                -- call the regular one, not ideal but probably better than copying most of the code here :)
                ZO_Tooltips_SetupDynamicTooltipAnchors(tooltip, buttonPart, comparativeTooltip1, comparativeTooltip2)

                -- custom setup
                local rowControl = buttonPart:GetParent()

                if settings.IsTooltipOffset() and rowControl.isGrid then
                    local owner = scrollList

                    tooltip:ClearAnchors()
                    tooltip:SetOwner(owner, RIGHT, 0, -10)
                else
                    local owner = rowControl

                    tooltip:SetOwner(owner, RIGHT, 0, 0)
                end
            end
            if scrollList.dataTypes[1] then
                local hookedFunctions = scrollList.dataTypes[1].setupCallback

                local function customSetupCallback(rowControl, slot)
                    rowControl:GetNamedChild("Button").customTooltipAnchor = igvTooltipAnchor
                    hookedFunctions(rowControl, slot)
                end

                scrollList.dataTypes[1].setupCallback = customSetupCallback
            end
        end
        hookFragment(INVENTORY_FRAGMENT, IGVID_INVENTORY)
        hookFragment(BANK_FRAGMENT, IGVID_BANK)
        hookFragment(GUILD_BANK_FRAGMENT, IGVID_GUILD_BANK)
        hookFragment(CRAFT_BAG_FRAGMENT, IGVID_CRAFT_BAG)
        hookFragment(QUICKSLOT_FRAGMENT, IGVID_QUICKSLOT)
        hookFragment(STORE_FRAGMENT, IGVID_STORE)
        hookFragment(BUY_BACK_FRAGMENT, IGVID_BUY_BACK)

        --custom icon zoom level
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
                    control.animation:GetFirstAnimation():SetEndScale(settings.vars.gridIconZoomLevel)
                end
            end
        end
        ZO_PreHook("ZO_InventorySlot_OnMouseEnter", CreateSlotAnimation)

        --append item cost to tooltip
        ZO_PreHook("ZO_InventorySlot_OnMouseEnter", adapter.AddCurrencySoon)

        --hook into scroll list updates
        ZO_PreHook("ZO_ScrollList_UpdateScroll", adapter.ScrollController)
    end
    initializeHooks()
end
EVENT_MANAGER:RegisterForEvent("InventoryGridViewLoaded", EVENT_ADD_ON_LOADED, InventoryGridViewLoaded)