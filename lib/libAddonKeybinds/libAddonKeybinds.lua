--[========================================================================[

    This is free and unencumbered software released into the public domain.

    Anyone is free to copy, modify, publish, use, compile, sell, or
    distribute this software, either in source code form or as a compiled
    binary, for any purpose, commercial or non-commercial, and by any
    means.

    In jurisdictions that recognize copyright laws, the author or authors
    of this software dedicate any and all copyright interest in the
    software to the public domain. We make this dedication for the benefit
    of the public at large and to the detriment of our heirs and
    successors. We intend this dedication to be an overt act of
    relinquishment in perpetuity of all present and future rights to this
    software under copyright law.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
    OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
    ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
    OTHER DEALINGS IN THE SOFTWARE.

    For more information, please refer to <http://unlicense.org/>

--]========================================================================]

local myNAME, myVERSION = "libAddonKeybinds", 2
local LAK = LibStub:NewLibrary(myNAME, myVERSION)
if not LAK then return end -- already loaded

-- these must match esoui/ingame/keybindings/keyboard/keybindings.lua
local LAYER_DATA_TYPE = 1
local CATEGORY_DATA_TYPE = 2
local KEYBIND_DATA_TYPE = 3


LAK.showAddonKeybinds = false


local function addGameMenuEntry(panelName)

    local panelId = KEYBOARD_OPTIONS.currentPanelId
    KEYBOARD_OPTIONS.currentPanelId = panelId + 1
    KEYBOARD_OPTIONS.panelNames[panelId] = panelName

    local sflist = KEYBINDING_MANAGER.list
    local savedScrollPos = {[false] = 0, [true] = 0}

    -- saved keybinding scroll list positions are not forgotten when
    -- you close the game menu; this was not originally intended, but
    -- is a pretty neat feature ;)

    local function setShowAddonKeybinds(state, forceRefresh)
        if LAK.showAddonKeybinds ~= state then
            -- save current scroll position for the old state
            savedScrollPos[not state] = sflist.list.scrollbar:GetValue()
            -- update state and refresh list
            LAK.showAddonKeybinds = state
            sflist:RefreshFilters()
            -- restore saved scroll position for the new state
            sflist.list.timeline:Stop()
            sflist.list.scrollbar:SetValue(savedScrollPos[state])
        elseif forceRefresh then
            sflist:RefreshFilters()
        end
    end

    local function selectedCallback()
        --df("addon keybinds selected")
        SCENE_MANAGER:AddFragment(KEYBINDINGS_FRAGMENT)
        setShowAddonKeybinds(true)
    end

    local function unselectedCallback()
        --df("addon keybinds unselected")
        SCENE_MANAGER:RemoveFragment(KEYBINDINGS_FRAGMENT)
        setShowAddonKeybinds(false)
    end

    ZO_GameMenu_AddControlsPanel{id = panelId,
                                 name = panelName,
                                 callback = selectedCallback,
                                 unselectedCallback = unselectedCallback}

    -- gameMenu.navigationTree is rebuilt every time the menu is re-open;
    -- previously active menu entry's unselectedCallback won't be called,
    -- because ZO_Tree:Reset() doesn't call any selection callbacks
    local gameMenu = ZO_GameMenu_InGame.gameMenu

    -- reset our filter before the menu tree is rebuilt, so that when
    -- the user clicks on "Controls" (which auto-selects the first entry,
    -- i.e. built-in "Keybindings"), we will show the correct list
    ZO_PreHook(gameMenu.navigationTree, "Reset",
        function(self) setShowAddonKeybinds(false, true) end)
end


local function hookKeybindingListCallbacks(typeId, setupCallbackName, hideCallbackName)

    local dataType = ZO_ScrollList_GetDataTypeTable(ZO_KeybindingsList, typeId)
    local setupCallbackOriginal = dataType.setupCallback
    local hideCallbackOriginal = dataType.hideCallback
    local CM = CALLBACK_MANAGER

    function dataType.setupCallback(control, data, list)
        setupCallbackOriginal(control, data, list)
        CM:FireCallbacks(setupCallbackName, control, data)
    end

    if hideCallbackOriginal then
        function dataType.hideCallback(control, data)
            hideCallbackOriginal(control, data)
            CM:FireCallbacks(hideCallbackName, control, data)
        end
    else
        function dataType.hideCallback(control, data)
            CM:FireCallbacks(hideCallbackName, control, data)
        end
    end
end


local function hookKeybindingListFilter()

    function KEYBINDING_MANAGER.list:FilterScrollList()
        local scrollData = ZO_ScrollList_GetDataList(self.list)
        local layerHeader = nil
        local categoryHeader = nil
        local lastSI = SI_NONSTR_INGAMESHAREDSTRINGS_LAST_ENTRY

        ZO_ScrollList_Clear(self.list)

        for _, dataEntry in ipairs(self.masterList) do
            if dataEntry.typeId == LAYER_DATA_TYPE then
                layerHeader, categoryHeader = dataEntry
            elseif dataEntry.typeId == CATEGORY_DATA_TYPE then
                categoryHeader = dataEntry
            else
                local insertEntry = LAK.showAddonKeybinds
                local actionSI = _G["SI_BINDING_NAME_" .. dataEntry.data.actionName]
                if type(actionSI) == "number" and actionSI < lastSI then
                    insertEntry = not insertEntry
                end
                if insertEntry then
                    if layerHeader then
                        scrollData[#scrollData + 1], layerHeader = layerHeader
                    end
                    if categoryHeader then
                        scrollData[#scrollData + 1], categoryHeader = categoryHeader
                    end
                    scrollData[#scrollData + 1] = dataEntry
                end
            end
        end
    end
end


local function onLoad(eventCode, addonName)

    if addonName ~= "ZO_Ingame" then return end
    EVENT_MANAGER:UnregisterForEvent(myNAME, eventCode)

    local language = GetCVar("Language.2")
    if language == "de" then
        SafeAddString(SI_GAME_MENU_KEYBINDINGS, "Standard", 1)
        addGameMenuEntry("Erweiterungen")
    elseif language == "fr" then
        addGameMenuEntry("Extensions")
    else
        SafeAddString(SI_GAME_MENU_KEYBINDINGS, "Standard Keybinds", 1)
        addGameMenuEntry("Addon Keybinds")
    end

    hookKeybindingListCallbacks(CATEGORY_DATA_TYPE,
                                "libAddonKeybinds.SetupCategoryHeader",
                                "libAddonKeybinds.HideCategoryHeader")
    hookKeybindingListCallbacks(KEYBIND_DATA_TYPE,
                                "libAddonKeybinds.SetupKeybindRow",
                                "libAddonKeybinds.HideKeybindRow")
    hookKeybindingListFilter()
end


EVENT_MANAGER:UnregisterForEvent(myNAME, EVENT_ADD_ON_LOADED)
EVENT_MANAGER:RegisterForEvent(myNAME, EVENT_ADD_ON_LOADED, onLoad)
