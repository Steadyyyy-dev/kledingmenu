-- Same server as previous anim build
local function debugPrint(...)
    if Config.Debug then print('[donut_clothing]', ...) end
end

local function getIdentifier(src)
    local idType = Config.IdentifierType or 'license'
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if idType == 'license' and id:find('license:') == 1 then return id end
        if idType == 'fivem'   and id:find('fivem:')   == 1 then return id end
        if idType == 'discord' and id:find('discord:') == 1 then return id end
    end
    return identifiers[1]
end

local function generateShareCode()
    local function randChunk(n)
        local t = {}
        for i=1,n do
            local c = math.random(0,35)
            t[i] = (c < 10) and string.char(48 + c) or string.char(55 + c)
        end
        return table.concat(t)
    end
    return string.format('%s-%s', randChunk(4), randChunk(4))
end

lib.callback.register('donut_clothing:server:saveOutfit', function(source, name, appearance)
    name = tostring(name or ''):sub(1, Config.MaxOutfitNameLength or 32)
    if name == '' then return false, 'Geen naam opgegeven.' end
    if not appearance or type(appearance) ~= 'table' then return false, 'Ongeldige outfit data.' end

    local identifier = getIdentifier(source)
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM donut_outfits WHERE identifier = ?', { identifier })
    if count and Config.MaxOutfitsPerPlayer and count >= Config.MaxOutfitsPerPlayer then
        return false, ('Maximaal %d outfits bereikt.'):format(Config.MaxOutfitsPerPlayer)
    end

    local code
    for _=1,10 do
        code = generateShareCode()
        local exists = MySQL.scalar.await('SELECT id FROM donut_outfits WHERE share_code = ?', { code })
        if not exists then break end
        code = nil
    end
    if not code then return false, 'Kon geen unieke code genereren.' end

    local ok = MySQL.insert.await('INSERT INTO donut_outfits (identifier, name, appearance, share_code) VALUES (?, ?, ?, ?)', {
        identifier, name, json.encode(appearance), code
    })
    if not ok then return false, 'Database fout bij opslaan.' end
    return true, { share_code = code }
end)

lib.callback.register('donut_clothing:server:listOutfits', function(source)
    local identifier = getIdentifier(source)
    local rows = MySQL.query.await('SELECT id, name, appearance, share_code, created_at FROM donut_outfits WHERE identifier = ? ORDER BY id DESC', { identifier }) or {}
    local result = {}
    for _, r in ipairs(rows) do
        local app; pcall(function() app = json.decode(r.appearance) end)
        result[#result+1] = { id = r.id, name = r.name, appearance = app, share_code = r.share_code, created_at = r.created_at and tostring(r.created_at) or '' }
    end
    return true, result
end)

lib.callback.register('donut_clothing:server:getOutfitByCode', function(source, code)
    if not code or code == '' then return false, 'Geen code.' end
    local row = MySQL.single.await('SELECT appearance FROM donut_outfits WHERE share_code = ?', { code })
    if not row then return false, 'Niet gevonden.' end
    local app; pcall(function() app = json.decode(row.appearance) end)
    if not app then return false, 'Onjuiste data.' end
    return true, { appearance = app }
end)

lib.callback.register('donut_clothing:server:deleteOutfit', function(source, outfitId)
    local identifier = getIdentifier(source)
    if not outfitId then return false, 'Geen ID.' end
    local changed = MySQL.update.await('DELETE FROM donut_outfits WHERE id = ? AND identifier = ?', { outfitId, identifier })
    if (changed or 0) > 0 then return true, 'Ok' end
    return false, 'Niet gevonden of geen rechten.'
end)

-- === Added by assistant: ox_inventory usable item to open clothing menu ===
CreateThread(function()
    local state = GetResourceState and GetResourceState('ox_inventory')
    if state == 'started' then
        exports.ox_inventory:registerUsableItem('kledingtas', function(source, item)
            -- If you want the item to be consumed, set `consume = 1` in items config (see README).
            TriggerClientEvent('donut_clothing:openMenu', source)
        end)
    else
        print('[donut_clothing] ox_inventory not started, usable item not registered.')
    end
end)
