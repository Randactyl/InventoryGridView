--Attempt to access a private function from insecure code?
--NOT ANYMORE!

function PickupCollectible(...)
    CallSecureProtected("PickupCollectible", ...)
end

function PickupInventoryItem(...)
    CallSecureProtected("PickupInventoryItem", ...)
end

function PickupStoreBuybackItem(...)
    CallSecureProtected("PickupStoreBuybackItem", ...)
end

function PickupStoreItem(...)
    CallSecureProtected("PickupStoreItem", ...)
end

function PlaceInInventory(...)
    CallSecureProtected("PlaceInInventory", ...)
end

function PlaceInTransfer(...)
    CallSecureProtected("PlaceInTransfer", ...)
end

function PlaceInWorldLeftClick(...)
    CallSecureProtected("PlaceInWorldLeftClick", ...)
end

function UseItem(...)
    CallSecureProtected("UseItem", ...)
end

--M A D M A N