-- donut_clothing/client.lua — fivem-appearance + animatie + locaties + blips

local function notify(msg, typ)
    lib.notify({ title = 'Kleding Shop', description = msg, type = typ or 'inform' })
end

local function ped() return (cache and cache.ped) or PlayerPedId() end

-- ==== fivem-appearance wrappers ====
local function fa_getAppearance()
    local p = ped()
    if exports['fivem-appearance'] and exports['fivem-appearance'].getPedAppearance then
        return exports['fivem-appearance']:getPedAppearance(p)
    end
    if exports['fivem-appearance'] and exports['fivem-appearance'].getPlayerAppearance then
        return exports['fivem-appearance']:getPlayerAppearance()
    end
    return nil
end

local function fa_setAppearance(appearance)
    local p = ped()
    if exports['fivem-appearance'] and exports['fivem-appearance'].setPedAppearance then
        exports['fivem-appearance']:setPedAppearance(p, appearance); return true
    end
    if exports['fivem-appearance'] and exports['fivem-appearance'].setPlayerAppearance then
        exports['fivem-appearance']:setPlayerAppearance(appearance); return true
    end
    return false
end

local function fa_openClothing()
    if exports['fivem-appearance'] and exports['fivem-appearance'].startPlayerCustomization then
        exports['fivem-appearance']:startPlayerCustomization(function(appearance) end, {
            ped = false, headBlend = false, faceFeatures = false, headOverlays = false,
            components = true, props = true, tattoos = false
        })
        return true
    end
    return false
end

-- ==== Omkleed animatie (met echte, configureerbare anims) ====

local function ensureAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local t = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < t do
        Wait(0)
    end
    return HasAnimDictLoaded(dict)
end

local function isPedMale(p)
    -- true = male freemode (+ meeste male models), false = female freemode
    -- Voor custom peds kun je dit aanpassen, of altijd 'any' laten pakken
    return GetEntityModel(p) == GetHashKey('mp_m_freemode_01')
        or (not (GetEntityModel(p) == GetHashKey('mp_f_freemode_01')))
end

local function pickAnim(kind, p)
    local cfg = Config.DressingAnimation
    if not cfg or not cfg.Anims or not cfg.Anims[kind] then return nil end

    local genderKey = isPedMale(p) and 'male' or 'female'
    local lists = {
        cfg.Anims[kind][genderKey] or {},
        cfg.Anims[kind].any or {}
    }

    for _, list in ipairs(lists) do
        for _, a in ipairs(list) do
            if a.dict and a.anim and ensureAnimDict(a.dict) then
                return a
            end
        end
    end
    return nil
end

local function playDressingAnimation(kind) -- 'save' | 'try'
    local cfg = Config.DressingAnimation
    if not cfg or not cfg.Enabled then return end

    local p = PlayerPedId()
    local anim = pickAnim(kind, p)

    local duration = (anim and anim.duration) or cfg.Duration or 3500
    local txt = (kind == 'try') and (cfg.TextTry or 'Passen...') or (cfg.TextSave or 'Outfit aantrekken...')

    -- Optioneel player invriezen & inputs disablen
    if cfg.FreezePlayer then
        FreezeEntityPosition(p, true)
        DisableControlAction(0, 21, true)  -- sprint
        DisableControlAction(0, 24, true)  -- attack
        DisableControlAction(0, 25, true)  -- aim
        DisableControlAction(0, 22, true)  -- jump
        DisableControlAction(0, 23, true)  -- enter vehicle
        DisableControlAction(0, 75, true)  -- exit vehicle
    end

    local played = false
    if anim then
        local flags = anim.flags or 49
        TaskPlayAnim(p, anim.dict, anim.anim, 8.0, 8.0, duration, flags, 0.0, false, false, false)
        played = true
    end

    if cfg.UseProgress and lib and lib.progressCircle then
        lib.progressCircle({
            duration = duration,
            label = txt,
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = { move = false, car = true, combat = true, mouse = false }
        })
    else
        -- Simple wait als je geen ox_lib gebruikt
        Wait(duration)
    end

    if played then
        ClearPedTasks(p)
    end

    if cfg.FreezePlayer then
        FreezeEntityPosition(p, false)
        EnableControlAction(0, 21, true)
        EnableControlAction(0, 24, true)
        EnableControlAction(0, 25, true)
        EnableControlAction(0, 22, true)
        EnableControlAction(0, 23, true)
        EnableControlAction(0, 75, true)
    end
end

-- Voorbeeld gebruik:
-- playDressingAnimation('try')
-- playDressingAnimation('save')

-- ==== UI helpers ====
local function inputOutfitName()
    local input = lib.inputDialog('Sla outfit op', {
        { type = 'input', label = 'Naam van outfit', placeholder = 'Bijv. Casual blauw', required = true, min = 1, max = Config.MaxOutfitNameLength }
    })
    if not input then return end
    return input[1]
end

local function inputShareCode()
    local input = lib.inputDialog('Gebruik outfit code', {
        { type = 'input', label = 'Deelcode', placeholder = 'Bijv. X7Q9-AB12', required = true }
    })
    if not input then return end
    return input[1]
end

-- ==== Handlers ====
local function handleSaveOutfit()
    local name = inputOutfitName()
    if not name then return end

    local appearance = fa_getAppearance()
    if not appearance then notify('Kon huidige outfit niet ophalen.', 'error'); return end

    playDressingAnimation('save')

    local ok, result = lib.callback.await('donut_clothing:server:saveOutfit', false, name, appearance)
    if not ok then notify(result or 'Opslaan mislukt.', 'error'); return end

    notify(('Outfit opgeslagen als "%s". Code: %s'):format(name, result.share_code), 'success')
    lib.setClipboard(result.share_code)
    notify('Deelcode is naar je klembord gekopieerd.', 'inform')
end

local function handleMyOutfits()
    local ok, outfits = lib.callback.await('donut_clothing:server:listOutfits', false)
    if not ok then notify(outfits or 'Kon outfits niet ophalen.', 'error'); return end
    if #outfits == 0 then notify('Je hebt nog geen outfits opgeslagen.', 'inform'); return end

    local options = {}
    for i, o in ipairs(outfits) do
        options[#options+1] = {
            title = o.name,
            description = ('Code: %s  •  %s'):format(o.share_code or '—', o.created_at or ''),
            icon = 'tshirt',
            onSelect = function()
                lib.registerContext({
                    id = 'donut_clothing_outfit_' .. (o.id or i),
                    title = o.name,
                    options = {
                        {
                            title = 'Deel code',
                            description = o.share_code and ('Klik om te kopiëren: %s'):format(o.share_code) or 'Geen code gevonden',
                            icon = 'share-nodes',
                            onSelect = function()
                                if o.share_code then lib.setClipboard(o.share_code); notify('Deelcode gekopieerd.', 'success')
                                else notify('Geen code beschikbaar.', 'error') end
                            end
                        },
                        {
                            title = 'Trek outfit aan',
                            description = 'Zet deze outfit direct aan',
                            icon = 'user-check',
                            onSelect = function()
                                playDressingAnimation('save')
                                if fa_setAppearance(o.appearance) then notify('Outfit aangetrokken.', 'success')
                                else notify('Kon outfit niet toepassen.', 'error') end
                            end
                        },
                        {
                            title = 'Verwijder outfit',
                            description = 'Verwijder deze outfit uit je lijst',
                            icon = 'trash',
                            onSelect = function()
                                local yes = lib.alertDialog({ header = 'Verwijderen?', content = ('Weet je zeker dat je "%s" wilt verwijderen?'):format(o.name), centered = true, cancel = true })
                                if yes == 'confirm' then
                                    local okDel, msg = lib.callback.await('donut_clothing:server:deleteOutfit', false, o.id)
                                    if okDel then notify('Outfit verwijderd.', 'success'); handleMyOutfits()
                                    else notify(msg or 'Verwijderen mislukt.', 'error') end
                                end
                            end
                        }
                    }
                })
                lib.showContext('donut_clothing_outfit_' .. (o.id or i))
            end
        }
    end

    lib.registerContext({ id = 'donut_clothing_myoutfits', title = 'Mijn outfits', options = options })
    lib.showContext('donut_clothing_myoutfits')
end

local function handleEnterShareCode()
    local code = inputShareCode()
    if not code then return end
    local ok, data = lib.callback.await('donut_clothing:server:getOutfitByCode', false, code)
    if not ok then notify(data or 'Geen outfit gevonden voor deze code.', 'error'); return end
    playDressingAnimation('save')
    if fa_setAppearance(data.appearance) then notify('Outfit aangetrokken.', 'success')
    else notify('Kon outfit niet toepassen.', 'error') end
end

local function openClothingShop()
    if not fa_openClothing() then notify('Kon kledingmenu niet openen.', 'error'); return end
    playDressingAnimation('try')
end

local function openMainMenu()
    local opts = {}
    if Config.Features.SaveOutfit then opts[#opts+1] = { title = 'Sla outfit op', icon = 'floppy-disk', onSelect = handleSaveOutfit } end
    if Config.Features.MyOutfits then opts[#opts+1] = { title = 'Mijn outfits', icon = 'list', onSelect = handleMyOutfits } end
    if Config.Features.EnterShareCode then opts[#opts+1] = { title = 'Gebruik outfit code', icon = 'barcode', onSelect = handleEnterShareCode } end
    if Config.Features.TryOnClothes then opts[#opts+1] = { title = 'Pas kleding aan', icon = 'tshirt', onSelect = openClothingShop } end
    lib.registerContext({ id = 'donut_clothing_main', title = 'Kleding Shop', options = opts })
    lib.showContext('donut_clothing_main')
end

-- Globaal command
if Config.Open.Command and Config.Open.Command ~= '' then
    RegisterCommand(Config.Open.Command, function() openMainMenu() end, false)
end

-- Locaties / ox_target zones + blips
local createdBlips = {}

local function createBlipForShop(shop)
    if not Config.Open.ShowBlips then return end
    local b = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(b, Config.Open.Blip.Sprite or 73)
    SetBlipScale(b, Config.Open.Blip.Scale or 0.8)
    SetBlipColour(b, Config.Open.Blip.Color or 0)
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(shop.label or 'Clothing')
    EndTextCommandSetBlipName(b)
    createdBlips[#createdBlips+1] = b
end

CreateThread(function()
    -- Maak per shop een target zone
    if Config.Open.UseOxTarget and exports.ox_target and Config.Shops then
        for i, shop in ipairs(Config.Shops) do
            exports.ox_target:addSphereZone({
                coords = shop.coords,
                radius = (shop.radius or Config.Open.Radius or 2.0),
                debug = false,
                options = {
                    {
                        name = 'donut_clothing_open_' .. i,
                        label = Config.Open.TargetLabel or 'Open Kleding Shop',
                        icon = 'fa-solid fa-shirt',
                        onSelect = function() openMainMenu() end
                    }
                }
            })
            createBlipForShop(shop)
        end
    else
        -- Zonder ox_target: marker + E prompt
        CreateThread(function()
            while true do
                local sleep = 1000
                local p = ped()
                local my = GetEntityCoords(p)
                for _, shop in ipairs(Config.Shops or {}) do
                    local dist = #(my - shop.coords)
                    if dist < (shop.radius or Config.Open.Radius or 2.0) + 2.0 then
                        sleep = 0
                        DrawMarker(2, shop.coords.x, shop.coords.y, shop.coords.z+0.1, 0,0,0, 0,0,0, 0.25,0.25,0.25, 0,150,255, 120, false, true, 2, nil, nil, false)
                        if dist < (shop.radius or Config.Open.Radius or 2.0) then
                            lib.showTextUI('[E] Kleding Shop')
                            if IsControlJustPressed(0, 38) then openMainMenu() end
                        else
                            lib.hideTextUI()
                        end
                    end
                end
                Wait(sleep)
            end
        end)
        for _, shop in ipairs(Config.Shops or {}) do
            createBlipForShop(shop)
        end
    end
end)

-- === Added by assistant: usable item hook (ox_inventory) ===
RegisterNetEvent('donut_clothing:openMenu', function()
    if openMainMenu then
        openMainMenu()
    else
        -- Fallback: try exports if the resource exposes it in the future
        if exports and exports['donut_clothing'] and exports['donut_clothing'].openMainMenu then
            exports['donut_clothing']:openMainMenu()
        end
    end
end)
