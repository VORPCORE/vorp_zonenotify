-- credits to freedy69 for the original code
local LOCATION_UI_TIME <const> = 5000 -- How long the location ui should be shown for

local eMAP_ZONE_TYPE <const> = {
    STATE = 0,
    TOWN = 1,
    LAKE = 2,
    RIVER = 3,
    OIL_SPILL = 4,
    SWAMP = 5,
    OCEAN = 6,
    CREEK = 7,
    POND = 8,
    GLACIER = 9,
    DISTRICT = 10,
    TEXT_PRINTED = 11,
    TEXT_WRITTEN = 12
}

-- Main data for location display
local m_StateDisplayData = {
    iCheckLastDone = 0,
    hStoredState = GetMapZoneAtCoords(GetEntityCoords(PlayerPedId()), eMAP_ZONE_TYPE.STATE),
    hStoredDistrict = GetMapZoneAtCoords(GetEntityCoords(PlayerPedId()), eMAP_ZONE_TYPE.DISTRICT),
    hStoredTown = GetMapZoneAtCoords(GetEntityCoords(PlayerPedId()), eMAP_ZONE_TYPE.TOWN)
}

function GetBigInt(text)
    local string1 = DataView.ArrayBuffer(16)
    string1:SetInt64(0, text)
    return string1:GetInt64(0)
end

---Shows the location HUD display
---@param text string
---@param location string
---@param duration integer
local function ShowLocationUi(text, location, duration)
    local string1 = CreateVarString(10, "LITERAL_STRING", location)
    local string2 = CreateVarString(10, "LITERAL_STRING", text)
    local struct1 = DataView.ArrayBuffer(8 * 7)
    local struct2 = DataView.ArrayBuffer(8 * 5)
    struct1:SetInt32(8 * 0, duration)
    --struct1:SetInt64(8*1,bigInt(sound_dict))
    --struct1:SetInt64(8*2,bigInt(sound))
    struct2:SetInt64(8 * 1, GetBigInt(string1))
    struct2:SetInt64(8 * 2, GetBigInt(string2))

    Citizen.InvokeNative(0xD05590C1AB38F068, struct1:Buffer(), struct2:Buffer(), 0, 1)
end

local function getIGWindSpeed()

	local metric = ShouldUseMetricTemperature();
	local windSpeed
	local windSpeedUnit
	if metric then
		windSpeed = math.floor(GetWindSpeed())
		windSpeedUnit = 'kph'
	else
		windSpeed = math.floor(GetWindSpeed() * 0.621371)
		windSpeedUnit = 'mph'
	end

	return string.format('%d °%s', windSpeed, windSpeedUnit)
end

---Formats hours and minutes for clock display
---@param iHours integer
---@param iMinutes integer
---@return string
local function FormatHoursAndMinutes(iHours, iMinutes)
    return string.format("%02d:%02d", iHours, iMinutes)
end

---Converts 24 hour time to 12 hour time
---@param hour integer
---@param minutes integer
---@return string
local function ConvertTo12Hour(hour, minutes)
    local period = "AM"

    if hour == 0 then
        hour = 12
    elseif hour == 12 then
        period = "PM"
    elseif hour > 12 then
        hour = hour - 12
        period = "PM"
    end

    return FormatHoursAndMinutes(hour, minutes) .. period
end

---Converts celsius to fahrenheit
local function CelsiusToFahrenheit(celsius)
    return (celsius * 9 / 5) + 32.0
end

---This is a literal string, returns bottom text that shows temperature etc
---@param vPlayerCoords vector3
---@return string
local function LocationUiGetBottomText(vPlayerCoords)
    local iHours, iMinute = GetClockHours(), GetClockMinutes()
    local sText = ""

    if Config.ShowTime then
        local sTime = FormatHoursAndMinutes(iHours, iMinute)
        if not ShouldUse_24HourClock() then
            sTime = ConvertTo12Hour(iHours, iMinute)
        end
        local timeColor = (iHours >= 22 or iHours < 6) and Config.TimeNightColor or Config.TimeDayColor
        sText = sText .. timeColor .. sTime
    end

    if Config.ShowTemperature then
        local fTemperature = GetTemperatureAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z)
        local tempColor = (fTemperature < Config.TemperatureColdDegree) and Config.TemperatureColdColor or Config.TemperatureHotColor
        local sTemperature = ShouldUseMetricTemperature() and math.ceil(fTemperature) .. '°C' or math.ceil(CelsiusToFahrenheit(fTemperature)) .. '°F'
        
        if sText ~= "" then
            sText = sText .. " " .. '~COLOR_WHITE~| '
        end
        sText = sText .. tempColor .. sTemperature
    end

    if Config.ShowWind then
        local fWindSpeed = getIGWindSpeed(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z)
        if sText ~= "" then
            sText = sText .. " " .. '~COLOR_WHITE~| '
        end
        sText = sText .. Config.WindColor .. fWindSpeed
    end

    return sText
end

local function LocationUiCheckTownsFromHash(hTownZone)
    local tTownReturns = {
        [459833523] = 'TOWN_VALENTINE',    -- valentine
        [2046780049] = 'TOWN_RHODES',      -- rhodes
        [-765540529] = 'TOWN_SAINTDENIS',  -- saint denis
        [427683330] = 'TOWN_STRAWBERRY',   -- strawberry
        [1053078005] = 'TOWN_BLACKWATER',  -- blackwater
        [-744494798] = 'TOWN_ARMADILLO',   -- armadillo
        [-1524959147] = 'TOWN_TUMBLEWEED', -- tumbleweed
        [7359335] = 'TOWN_ANNESBURG',      -- annesburg
        [2126321341] = 'TOWN_VANHORN',     -- van horn
        [201158410] = 'TOWN_MANICATO',
        [1463094051] = 'SETTLEMENT_MANZANITA_POST'
    }

    return tTownReturns[hTownZone]
end

local function LocationUiCheckTowns(vPlayerCoords)
    local hTownZone = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.TOWN)
    return LocationUiCheckTownsFromHash(hTownZone)
end

local function LocationUiCheckMiscLocations(vPlayerCoords)
    local tReturnsTextWritten <const> = { -- 12 / written
        [1350749955] = 'LANDMARK_MERKINS_WALLER',
        [1062452343] = 'LANDMARK_MACOMBS_END',
        [30800579] = 'LANDMARK_HAGEN_ORCHARDS',
        [866178028] = 'HIDEOUT_SHADY_BELLE',
        [930788089] = 'LANDMARK_SILTWATER_STRAND',
        [-419963911] = 'SETTLEMENT_APPLESEED_TIMBER_CO',
        [1212679502] = 'LANDMARK_BERYLS_DREAM',
        [-828659305] = 'SETTLEMENT_FORT_RIGGS_HOLDING_CAMP',
        [-103399754] = 'HIDEOUT_HANGING_DOG_RANCH',
        [-576782619] = 'HOMESTEAD_LONE_MULE_STEAD',
        [-1521776363] = 'HOMESTEAD_PAINTED_SKY',
        [-120578354] = IsIplActiveByHash(`PRO_MANSION_INT_MILO`) and 'SETTLEMENT_PRONGHORN_RANCH' or nil,
        [-504005310] = 'HOMESTEAD_SHEPHERDS_RISE',
        [-1161186391] = 'HOMESTEAD_WATSONS_CABIN',
        [580715948] = 'LANDMARK_CANEBREAK_MANOR',
        [1082216465] = 'LANDMARK_COPPERHEAD_LANDING',
        [-61172588] = 'SETTLEMENT_COOTS_CHAPEL',
        [1544029611] = 'SETTLEMENT_RIDGEWOOD_FARM',
        [738939338] = 'LANDMARK_RILEYS_CHARGE',
        [-146460093] = 'HOMESTEAD_FIRWOOD_RISE',
        [2056953687] = 'HIDEOUT_SIX_POINT_CABIN',
        [39999178] = 'HIDEOUT_GAPTOOTH_BREACH',
        [1677148641] = 'SETTLEMENT_BEECHERS_HOPE',
        [-1043500161] = 'HOMESTEAD_ADLER_RANCH',
        [-2034338067] = 'HOMESTEAD_CHEZ_PORTER',
        [-1496551068] = 'HIDEOUT_COLTER',
        [2132554759] = 'LANDMARK_MILLESANI_CLAIM',
        [-438809735] = 'LANDMARK_THE_LOFT',
        [-291091669] = 'LANDMARK_OLD_GREENBANK_MILL',
        [-1902025470] = 'HOMESTEAD_CARMODY_DELL',
        [492552869] = 'SETTLEMENT_CORNWALL_KEROSENE_TAR',
        [-1472363892] = 'HOMESTEAD_GUTHRIE_FARM',
        [-657053325] = 'HOMESTEAD_DOWNES_RANCH',
        [-870780939] = 'LANDMARK_GRANGERS_HOGGERY',
        [1767462106] = 'HOMESTEAD_LARNED_SOD',
        [229479634] = 'LANDMARK_LUCKYS_CABIN',
        [219097977] = 'HOMESTEAD_ABERDEEN_PIG_FARM',
        [-425430549] = 'SETTLEMENT_BUTCHER_CREEK',
        [-969933882] = 'LANDMARK_BLACK_BALSAM_RISE',
        [-645154787] = 'HOMESTEAD_DOVERHILL',
        [-1592070727] = 'HOMESTEAD_MACLEANS_HOUSE',
        [1016304714] = 'LANDMARK_MOSSY_FLATS',
        [-154855189] = 'HOMESTEAD_WILLARDS_REST',
        [1701820039] = 'HOMESTEAD_CATFISH_JACKSONS',
        [1830267951] = 'HIDEOUT_CLEMENS_POINT',
        [522499758] = 'HOMESTEAD_COMPSONS_STEAD',
        [-1769528472] = 'HOMESTEAD_HILL_HAVEN_RANCH',
        [770707682] = 'HOMESTEAD_LONNIES_SHACK',
        [-259784188] = 'LANDMARK_RADLEYS_PASTURE',
        [-264897431] = 'LANDMARK_BEAR_CLAW',
        [1557904547] = 'SETTLEMENT_CENTRAL_UNION_RAILROAD_CAMP',
        [-1419869345] = 'LANDMARK_TANNERS_REACH',
        [690770514] = 'LANDMARK_VALLEY_VIEW',
        [-545967610] = 'LANDMARK_EWING_BASIN',
        -- test the ones below
        [`W_5_BEAVER_HOLLOW`] = 'HIDEOUT_BEAVER_HOLLOW',
        [`w_4_pleasance`] = 'LANDMARK_PLEASANCE_HOUSE',
        [`w_5_limpany`] = 'SETTLEMENT_LIMPANY',
        [`W_4_SCRATCHING_POST`] = 'LANDMARK_SCRATCHING_POST',
        [`W_4_ODDFELLOWS_REST`] = 'LANDMARK_ODDFELLOWS_REST',
        [`W_4_RATTLESNAKE_HOLLOW`] = 'LANDMARK_RATTLESNAKE_HOLLOW',
        [`W_4_SILENT_STEAD`] = 'LANDMARK_SILENT_STEAD',
        [`W_4_THE_HANGING_ROCK`] = 'LANDMARK_THE_HANGING_ROCK',
        [`W_4_THE_OLD_BACCHUS_PLACE`] = 'LANDMARK_THE_OLD_BACCHUS_PLACE',
        [`W_4_TWO_CROWS`] = 'LANDMARK_TWO_CROWS',
        [`W_4_REPENTANCE`] = 'LANDMARK_REPENTANCE',
        [`W_4_PIKES_BASIN`] = 'HIDEOUT_PIKES_BASIN',
        [`W_4_EL_NIDO`] = 'SETTLEMENT_EL_NIDO',
        [`W_4_BRITTLEBRUSH_TRAWL`] = 'LANDMARK_BRITTLEBUSH_TRAWL',
        [`W_4_VENTERS_PLACE`] = 'LANDMARK_VENTERS_PLACE',
        [`W_5_CHADWICK_FARM`] = 'HOMESTEAD_CHADWICK_FARM',
        [`W_5_BLACK_BONE_FOREST`] = 'LANDMARK_BLACK_BONE_FOREST',
        [`W_4_CUEVA_SECA`] = 'LANDMARK_CUEVA_SECA',
        [`W_4_SOLOMONS_FOLLY`] = 'HIDEOUT_SOLOMONS_FOLLY',
        [`W_5_FORT_BRENNAND`] = 'LANDMARK_FORT_BRENNAND',
        [`W_4_HORSESHOE_OVERLOOK`] = 'HIDEOUT_HORSESHOE_OVERLOOK',
        [`W_4_RIO_DEL_LOBO_HOUSE`] = 'LANDMARK_RIO_DEL_LOBO_HOUSE',
        [`W_5_BROKEN_TREE`] = 'LANDMARK_BROKEN_TREE',
        [`W_4_FACE_ROCK`] = 'LANDMARK_FACE_ROCK',
        [`W_4_NEKOTI_ROCK`] = 'LANDMARK_NEKOTI_ROCK'
    }

    -- Unwritten rule: Homesteads don't go here (at least from what i've seen?)
    local tReturnsTextPrinted <const> = { -- 11 / printed
        [894611678] = 'SETTLEMENT_LAGRAS',
        [466986025] = 'HIDEOUT_LAKAY',
        [-1225359404] = 'LANDMARK_MONTOS_REST',
        [1573733873] = 'LANDMARK_OWANJILA_DAM',
        [769580703] = 'LANDMARK_RIGGS_STATION',
        [-1532919875] = 'TOWN_MACFARLANES_RANCH',
        [1453682244] = 'LANDMARK_WALLACE_STATION',
        [1106871234] = 'SETTLEMENT_SISIKA_PENITENTIARY',
        [-1988735197] = 'HIDEOUT_TWIN_ROCKS',
        [-99881305] = 'SETTLEMENT_FORT_WALLACE',
        [-864457539] = 'SETTLEMENT_RATHSKELLER_FORK',
        [721024961] = 'LANDMARK_QUAKERS_COVE',
        --[1737121879] = 'LANDMARK_QUAKERS_COVE', -- prolly not correct, this is hash for P_3_SAN_LUIS_RIVER
        [422513214] = 'LANDMARK_CALUMET_RAVINE',
        [-735849380] = 'SETTLEMENT_WAPITI',
        [1246510947] = 'LANDMARK_WINDOW_ROCK',
        [-2038495927] = 'LANDMARK_TEMPEST_RIM',
        [-1288973891] = 'SETTLEMENT_AGUASDULCES',
        [-2028095666] = 'LANDMARK_CINCO_TORRES',
        [1073515151] = 'LANDMARK_LA_CAPILLA',
        [903669278] = 'SETTLEMENT_THIEVES_LANDING',
        [206751400] = 'LANDMARK_BACCHUS_BRIDGE', -- so this IS correct
        [350117545] = 'SETTLEMENT_EMERALD_RANCH',
        [-847222477] = 'LANDMARK_FLATNECK_STATION',
        -- [-2001518509] = 'HIDEOUT_BEAVER_HOLLOW',
        [`P_5_BRANDYWINE_DROP`] = 'LANDMARK_BRANDYWINE_DROP', -- USED TO BE 1595262844, TEST THIS
        [1490773376] = 'LANDMARK_ROANOKE_VALLEY',
        [-745404624] = 'SETTLEMENT_BENEDICT_POINT',
        [-1037423548] = 'HIDEOUT_FORT_MERCER',
        [278622988] = 'SETTLEMENT_PLAINVIEW',
        [-166839571] = 'SETTLEMENT_BRAITHWAITE_MANOR',
        [-67181220] = 'LANDMARK_BOLGER_GLADE',
        [2084778330] = 'SETTLEMENT_CALIGA_HALL',
        -- check these
        [`P_3_MOUNT_HAGEN`] = 'LANDMARK_MOUNT_HAGEN',
        [`P_4_JORGES_GAP`] = 'LANDMARK_JORGES_GAP',
        [`p_4_mercer_station`] = 'LANDMARK_MERCER_STATION',
        [`P_4_BENEDICT_PASS`] = 'LANDMARK_BENEDICT_PASS',
        [`P_4_MANTECA_FALLS`] = 'WATER_MANTECA_FALLS',
        [`P_4_MOUNT_SHANN`] = 'WATER_MOUNT_SHANN',
        [`P_4_THREE_SISTERS`] = 'LANDMARK_THREE_SISTERS',
        [`P_3_ERIS_FIELD`] = 'LANDMARK_ERIS_FIELD',
        [`P_4_GRANITE_PASS`] = 'LANDMARK_GRANITE_PASS',
        [`P_4_CITADEL_ROCK`] = 'LANDMARK_CITADEL_ROCK',
        [`P_3_DEWBERRY_CREEK`] = 'LANDMARK_DEWBERRY_CREEK',
        [`P_4_DIABLO_RIDGE`] = 'LANDMARK_DIABLO_RIDGE',
        [`P_4_DONNER_FALLS`] = 'LANDMARK_DONNER_FALLS',
        [`P_4_CALIBANS_SEAT`] = 'LANDMARK_CALIBANS_SEAT',
        [`P_4_RIO_DEL_LOBO_ROCK`] = 'LANDMARK_RIO_DEL_LOBO_ROCK',
        [`P_4_BARDS_CROSSING`] = 'LANDMARK_BARDS_CROSSING',
        [`P_3_HEARTLAND_OVERFLOW`] = 'LANDMARK_HEARTLAND_OVERFLOW'
    }

    local hTextWritten = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.TEXT_WRITTEN)
    local hTextPrinted = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.TEXT_PRINTED)
    -- bacchus bridge and cumperland falls conflict fix

    -- display "beaver hollow" while in the cave as well
    local iBeaverHollowCave = GetInteriorAtCoords(2318.291, 1448.150, 84.413)
    if iBeaverHollowCave ~= 0 and GetInteriorAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z) == iBeaverHollowCave then
        return 'HIDEOUT_BEAVER_HOLLOW'
    end

    -- Fix conflict between bacchus bridge and cumberland falls
    if hTextPrinted == -138648964 then
        local iRiver = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.RIVER)
        local iDistrict = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.DISTRICT)

        if iDistrict == 1835499550 or iDistrict == -120156735 then
            return 'LANDMARK_BACCHUS_BRIDGE'
        elseif iRiver == 370072007 then
            return 'LANDMARK_CUMBERLAND_FALLS'
        end

        return nil -- god forbid if there's more conflicts with waterfalls lmao
    end

    --print ('hTextWritten 12', hTextWritten, 'hTextPrinted 11', hTextPrinted)

    return tReturnsTextWritten[hTextWritten] or tReturnsTextPrinted[hTextPrinted]
end

local function IsInteriorACave(iInterior)
    local _, hNameHash = GetInteriorLocationAndNamehash(iInterior)
    local tCaveNames <const> = {
        [`Q0304_TUNNEL_ENT`] = true,
        [`J_10P_TUNNEL_1A_INT`] = true,
        [`BAC_TUNNELCURVE_INT`] = true,
        [`L_14_CAVE_INT`] = true,
        [`GAP_MINE_INT`] = true,
        [`MIL_MINE_CAVE_INT`] = true,
        [`M05_BEARCAVE_MAIN`] = true,
        [`Q0304_TUNNEL_INT`] = true,
        [`ELH_SEACAVES_INT`] = true,
        [`L_08_TRAIN_TUNNEL2_INT`] = true,
        [`BAC_TUNNELEXIT_INT`] = true,
        [`BAC_TUNNELENT_INT`] = true,
        [`J_14_TUNNEL01_INT`] = true,
        [653987431] = true,
        [`BEA_01_INT`] = true,
        [`BAC_TUNNEL_INT`] = true,
        [`AGU_FUS_CAVE_INT`] = true,
        [`HEA_TUNNEL_02`] = true,
        [`Q0304_TUNNEL_EXIT`] = true,
        [`ANN_MINE_INT_MAIN`] = true,
        [1633500362] = true,
        [`J_16_TUNNEL_INT`] = true
    }

    return tCaveNames[hNameHash] or false
end

local function LocationUiCheckDistrictFromHash(hDistrict)
    local tReturns <const> = {
        [2025841068] = 'district_bayou_nwa',
        [822658194] = 'district_big_valley',
        [1308232528] = 'district_bluewater_marsh',
        [1835499550] = 'district_cumberland_forest',
        [476637847] = 'DISTRICT_GREAT_PLAINS',
        [1645618177] = 'district_grizzlies', -- grizzlies west
        [-120156735] = 'district_grizzlies', -- grizzlies east
        [-512529193] = 'district_guarma',
        [131399519] = 'district_heartlands',
        [178647645] = 'district_roanoake_ridge',
        [-864275692] = 'district_scarlett_meadows',
        [1684533001] = 'district_tall_Trees',
        [-2066240242] = 'district_gaptooth_ridge',
        [-2145992129] = 'district_rio_bravo',
        [-108848014] = 'district_cholla_springs',
        [892930832] = 'DISTRICT_HENNIGANS_STEAD'
    }

    return tReturns[hDistrict]
end

local function LocationUiCheckDistrict(vPlayerCoords)
    local hDistrict = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, 10)
    return LocationUiCheckDistrictFromHash(hDistrict)
end

local function LocationUiCheckStateFromHash(hState)
    local tReturns <const> = {
        [`Ambarino`] = 'STATE_AMBARINO',
        [`Guarma`] = 'state_guarma',
        [`lemoyne`] = 'state_lemoyne',
        [`LowerWestElizabeth`] = 'state_west_elizabeth',
        [`UpperWestElizabeth`] = 'state_west_elizabeth',
        [`WestElizabeth`] = 'state_west_elizabeth',
        [`NewAustin`] = 'state_new_austin',
        [`NewHanover`] = 'state_new_hanover'
    }

    return tReturns[hState]
end

local function LocationUiCheckState(vPlayerCoords)
    local hState = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, 0)
    return LocationUiCheckStateFromHash(hState)
end

local function GetKamassaRiver(hDistrict)
    if hDistrict == 178647645 then
        return 'WATER_KAMASSA_RIVER_BLUEWATER_MARSH'
    elseif hDistrict == 2025841068 then
        return 'WATER_KAMASSA_RIVER_BAYOU_NWA'
    end

    return 'WATER_KAMASSA_RIVER' -- roanoke ridge
end

local function LocationUiCheckWaters(vPlayerCoords)
    local hLake                    = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.LAKE)
    local hRiver                   = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.RIVER)
    local hOilSpill                = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.OIL_SPILL)
    local hSwamp                   = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.SWAMP)
    local hOcean                   = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.OCEAN)
    local hCreek                   = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.CREEK)
    local hPond                    = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.POND)
    local hDistrict                = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.DISTRICT)

    local tReturnsLake <const>     = {
        [`WATER_AURORA_BASIN`] = 'WATER_AURORA_BASIN',
        [`WATER_BARROW_LAGOON`] = 'WATER_BARROW_LAGOON',
        [`WATER_ELYSIAN_POOL`] = 'WATER_ELYSIAN_POOL',
        [`WATER_FLAT_IRON_LAKE`] = 'WATER_FLAT_IRON_LAKE',
        [`WATER_HEARTLANDS_OVERFLOW`] = 'LANDMARK_HEARTLAND_OVERFLOW',
        [`WATER_LAKE_DON_JULIO`] = 'WATER_LAKE_DON_JULIO',
        [`WATER_LAKE_ISABELLA`] = 'WATER_LAKE_ISABELLA',
        [`WATER_O_CREAGHS_RUN`] = 'WATER_OCREAGHS_RUN',
        [`WATER_OWANJILA`] = 'WATER_OWANJILA',
        [`WATER_SEA_OF_CORONADO`] = 'WATER_SEA_OF_CORONADO'
    }

    local tReturnsRiver <const>    = {
        [`WATER_ARROYO_DE_LA_VIBORA`] = 'WATER_ARROYO_DE_LA_VIBORA',
        [`WATER_DAKOTA_RIVER`] = 'WATER_DAKOTA_RIVER',
        [`WATER_LANNAHECHEE_RIVER`] = 'WATER_LANNAHECHEE_RIVER',
        [`WATER_LITTLE_CREEK_RIVER`] = 'WATER_LITTLE_CREEK_RIVER',
        [`WATER_LOWER_MONTANA_RIVER`] = 'WATER_LOWER_MONTANA_RIVER',
        [`WATER_UPPER_MONTANA_RIVER`] = 'WATER_UPPER_MONTANA_RIVER',
        [`WATER_KAMASSA_RIVER`] = GetKamassaRiver(hDistrict),
        [`WATER_SAN_LUIS_RIVER`] = hDistrict == 426773653 and 'WATER_SAN_LUIS_RIVER_NEW_AUSTIN' or 'water_san_luis_river_west_elizabeth'
    }

    local tReturnsOilSpill <const> = {}

    local tReturnsSwamp <const>    = {
        [`WATER_BAYOU_NWA`] = 'district_bayou_nwa'
    }

    local tReturnsOcean <const>    = {
        [`WATER_BAHIA_DE_LA_PAZ`] = 'WATER_BAHIA_DE_LA_PAZ'
    }

    local tReturnsCreek <const>    = {
        [`WATER_DEADBOOT_CREEK`] = 'WATER_DEADBOOT_CREEK',
        [`WATER_HAWKS_EYE_CREEK`] = 'WATER_HAWKS_EYE_CREEK',
        [`WATER_RINGNECK_CREEK`] = 'WATER_RINGNECK_CREEK',
        [`WATER_SPIDER_GORGE`] = 'WATER_SPIDER_GORGE',
        [`WATER_STILLWATER_CREEK`] = 'WATER_STILLWATER_CREEK',
        [`WATER_WHINYARD_STRAIT`] = 'WATER_WHINYARD_STRAIT'
    }

    local tReturnsPond <const>     = {
        [`WATER_CAIRN_LAKE`] = 'WATER_CAIRN_LAKE',
        [`WATER_CATTIAL_POND`] = 'WATER_CATTAIL_POND',
        [`WATER_HOT_SPRINGS`] = 'WATER_COTORRA_SPRINGS',
        [`WATER_MATTLOCK_POND`] = 'WATER_MATTLOCK_POND',
        [`WATER_MOONSTONE_POND`] = 'WATER_MOONSTONE_POND',
        [`WATER_SOUTHFIELD_FLATS`] = 'WATER_SOUTHFIELD_FLATS'
    }

    return tReturnsLake[hLake] or tReturnsRiver[hRiver] or tReturnsOilSpill[hOilSpill] or tReturnsSwamp[hSwamp] or tReturnsOcean[hOcean] or tReturnsCreek[hCreek] or tReturnsPond[hPond]
end

local function LocationUiGetTopText(vPlayerCoords)
    -- these functions need to return nil if we're not in the vicinity of them so next function can be checked.
    -- basically the return value goes like this
    -- towns > waters (if no town found) > misc locations (if no water found) > district (if no misc location found) > state (if no district found (should be impossible))
    -- > empty string (not ideal) if nothing found
    return (LocationUiCheckTowns(vPlayerCoords)
        or LocationUiCheckWaters(vPlayerCoords)
        or LocationUiCheckMiscLocations(vPlayerCoords)
        or LocationUiCheckDistrict(vPlayerCoords)
        or LocationUiCheckState(vPlayerCoords)) or ''
end

---Updates location display every frame
---@param iGameTimer integer
---@param vPlayerCoords vector3
---@param iPlayerPedId integer
local function ProcessLocations(iGameTimer, vPlayerCoords, iPlayerPedId)
    if iGameTimer - m_StateDisplayData.iCheckLastDone > 500 then -- For optimization we'll check for location changes every 500 ms
        m_StateDisplayData.iCheckLastDone = iGameTimer

        local hCurrentState = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.STATE)
        local hCurrentDistrict = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.DISTRICT)
        local hCurrentTown = GetMapZoneAtCoords(vPlayerCoords.x, vPlayerCoords.y, vPlayerCoords.z, eMAP_ZONE_TYPE.TOWN)

        -- Display the UI with updated location and Time / Temperature Info
        if m_StateDisplayData.hStoredState ~= hCurrentState then
            m_StateDisplayData.hStoredState = hCurrentState

            if hCurrentState ~= 0 then
                local sTopText = LocationUiCheckStateFromHash(hCurrentState)
                if sTopText and UiFeedGetCurrentMessage(2) == 0 then
                    ShowLocationUi(LocationUiGetBottomText(vPlayerCoords), sTopText, LOCATION_UI_TIME)
                end
            end
        elseif m_StateDisplayData.hStoredDistrict ~= hCurrentDistrict then
            m_StateDisplayData.hStoredDistrict = hCurrentDistrict

            if hCurrentDistrict ~= 0 then
                local sTopText = LocationUiCheckDistrictFromHash(hCurrentDistrict)
                if sTopText and UiFeedGetCurrentMessage(2) == 0 then
                    ShowLocationUi(LocationUiGetBottomText(vPlayerCoords), sTopText, LOCATION_UI_TIME)
                end
            end
        elseif m_StateDisplayData.hStoredTown ~= hCurrentTown then
            m_StateDisplayData.hStoredTown = hCurrentTown

            if hCurrentTown ~= 0 then
                local sTopText = LocationUiCheckTownsFromHash(hCurrentTown)
                if sTopText and UiFeedGetCurrentMessage(2) == 0 then
                    ShowLocationUi(LocationUiGetBottomText(vPlayerCoords), sTopText, LOCATION_UI_TIME)
                end
            end
        end
    end
    if Config.EnableKeyCheck then
        if IsControlJustPressed(0, Config.Key) then
            if UiFeedGetCurrentMessage(2) ~= 0 then return end -- Make sure the location ui isnt displaying

            local iInterior = GetInteriorFromEntity(iPlayerPedId)
            if iInterior ~= 0 and not IsInteriorACave(iInterior) then
                return
            end

            local sTopText = LocationUiGetTopText(vPlayerCoords)

            if sTopText == '' or not sTopText then
                print('ProcessLocations: sTopText is nil or empty!')
                return
            end
            ShowLocationUi(LocationUiGetBottomText(vPlayerCoords), sTopText, LOCATION_UI_TIME)
        end
    end
end

CreateThread(function()
repeat Wait(5000) until LocalPlayer.state.IsInSession
		
    while true do
        Wait(0)
        local iPed = PlayerPedId()
        ProcessLocations(GetGameTimer(), GetEntityCoords(iPed), iPed)
    end
end)
