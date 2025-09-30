Config = {}

-- ======= Features in het menu (elk kopje aan/uit) =======
Config.Features = {
    SaveOutfit = true,        -- "Sla outfit op"
    MyOutfits = true,         -- "Mijn outfits" (lijst + code tonen + aankleden + verwijderen)
    EnterShareCode = true,    -- "Gebruik outfit code"
    TryOnClothes = true       -- "Pas kleding aan"
}

-- ======= Shop open instellingen =======
Config.Open = {
    Command = 'clothingshop',       -- /clothingshop (globaal, altijd bruikbaar)
    UseOxTarget = true,             -- true = maak target zones op locaties hieronder
    TargetLabel = 'Open Kleding Shop',
    Radius = 2.0,
    ShowBlips = true,               -- laat kaart blips zien voor elke shop
    Blip = { Sprite = 73, Color = 0, Scale = 0.8 }  -- 73 = Clothing Store
}

-- ======= Locaties van kledingwinkels (toegevoegd volgens jouw lijst) =======
Config.Shops = {
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(72.3, -1399.1, 28.4) },
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(-708.71, -152.13, 36.4) },
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(-165.15, -302.49, 38.6) },
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(428.7, -800.1, 28.5) },
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(-829.4, -1073.7, 10.3) },
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(-1449.16, -238.35, 48.8) },
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(11.6, 6514.2, 30.9) },
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(122.98, -222.27, 53.5) },
    { label = 'Kleding Winkel de Havenlijn',  coords = vec3(1696.3, 4829.3, 41.1) },
    { label = 'Kleding Winkel de Havenlijn', coords = vec3(618.1, 2759.6, 41.1) },
    { label = 'Kleding Winkel de Havenlijn', coords = vec3(1190.6, 2713.4, 37.2) },
    { label = 'Kleding Winkel de Havenlijn', coords = vec3(-1193.4, -772.3, 16.3) },
    { label = 'Kleding Winkel de Havenlijn', coords = vec3(-3172.5, 1048.1, 19.9) },
    { label = 'Kleding Winkel de Havenlijn', coords = vec3(-1108.4, 2708.9, 18.1) },
    { label = 'Kleding Winkel de Havenlijn', coords = vec3(466.5602, -1009.8662, 30.7074) },
}

-- ======= Limits en DB =======
Config.MaxOutfitNameLength = 32
Config.MaxOutfitsPerPlayer = 50

-- Welke identifier kolom gebruik je voor spelers
Config.IdentifierType = 'license' -- 'license' | 'fivem' | 'discord'

-- Logging (server console)
Config.Debug = false


-- ======== Animatiie van omkleden ========= 

Config.DressingAnimation = {
    Enabled = false,
    FreezePlayer = true,
    UseProgress = true,

    -- Standaard duur als er geen duur bij de anim staat
    Duration = 3500,

    -- Default labels
    TextTry  = 'Passen...',
    TextSave = 'Outfit aantrekken...',

    -- Per soort actie (try/save) en per gender (male/female/any) kun je 1 of meerdere anims definieren.
    -- De eerste die succesvol laadt wordt afgespeeld.
    Anims = {
        try = {
            male = {
                { dict = 'mp_clothing@male@',   anim = 'try_shirt_positive_a', duration = 3500, flags = 49 },
            },
            female = {
                { dict = 'mp_clothing@female@', anim = 'try_shirt_positive_a', duration = 3500, flags = 49 },
            },
            any = {
                -- Fallback voor als gender niet kan worden bepaald of dict niet laadt
                { dict = 'clothingshop@',       anim = 'check_outfit',         duration = 3000, flags = 49 },
            }
        },
        save = {
            male = {
                -- Iets andere “echte” kledingwinkel-animatie voor opslaan/aantrekken
                { dict = 'clothingshop@',       anim = 'check_outfit',         duration = 3000, flags = 49 },
            },
            female = {
                { dict = 'clothingshop@',       anim = 'check_outfit',         duration = 3000, flags = 49 },
            },
            any = {
                { dict = 'mp_clothing@male@',   anim = 'try_shirt_positive_a', duration = 3500, flags = 49 },
            }
        }
    }
}