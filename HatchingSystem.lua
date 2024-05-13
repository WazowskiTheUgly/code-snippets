--!nocheck

--[=[

    filenmame: Hatch.lua
    runcontext: module/server
    description: Manages the Hatching system in the game.

]=]

local Hatch = {}
Hatch.Debounces = {}

-- [=[ SERVICES ]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- [=[ PACKAGES ]=]

local Packages = ReplicatedStorage.Packages;
local Configs = script.Parent.Configs;

local network = require(Packages.ByteNet);
local profiles = require(script.Parent.Data.Profiles)
local chances = require(Configs.Chances);
local inventory = require(script.Parent.Inventory)

--[=[ PACKETS ]=]

local server_namespace = network.defineNamespace("Hatch", function()
    return {

        _post = network.definePacket({
            value = network.nothing
        });

        _result = network.definePacket({
            value = network.struct({

                _result = network.string;
                _reserve = network.array(network.string)

            })
        });

        _determineRollResult = network.definePacket({
            value = network.string -- either "claim" or "sell"
        });

    }
end)

--[=[

    @function Hatch._init()
    description: Only called once. sets up all of the connections.

]=]

function Hatch._init()
    server_namespace._post.listen(function(kwargs : {}, player : Player)
        Hatch.Hatch(player);
    end)

    server_namespace._determineRollResult.listen(function(option : string, player : Player)

        local profile : profiles.DataProfile = profiles[player.UserId]

        if option ~= "Claim" and option ~= "Sell" then player:Kick("pls no hack uwu") end
        if profile.Data.LastPetClaimed == true then player:Kick("Pls no hack uwu") end

        Hatch.DetermineRollResult(player, option, profile:GetValue("LastPetRolled"))
        profile:SetValue("LastPetClaimed", false)
        
        task.delay(1, function()
            Hatch.Debounces[player.UserId] = nil
        end)
    end)
end

--[=[

    @function Hatch.DetermineRollResult()
        
        @param           player            Player                The player who called the function.
        @param           option            string                The option chosen by the player.
        @param            pet              string                The pet to be claimed or sold.

    description: Either sells or claims the pet.

]=]

function Hatch.DetermineRollResult(player : Player, option : string, pet : string)
    if option == "Claim" then
        inventory.UpdatePetInventory(player, "+", pet)
    else
        print("selling")
    end
end

--[=[

    @function Hatch.Hatch()
        
        @param           player            Player                The player who called the function.

    description: Called when the player clicks on roll.

]=]

function Hatch.Hatch(player : Player)
    
    if Hatch.Debounces[player.UserId] then return end
    Hatch.Debounces[player.UserId] = true;

    local player_profile : profiles.DataProfile = profiles[player.UserId]
    local Chosen = Hatch.Roll();
    
    local _reserve = {}
    for i = 1, 7 do table.insert(_reserve, Hatch.Roll()) end

    server_namespace._result.sendTo({

        _result = Chosen,
        _reserve = _reserve

    }, player);

    task.delay(.35 * 8, function()

        player_profile:SetValue("LastPetRolled", Chosen)
        player_profile:SetValue("LastPetClaimed", false)

    end)
end

--[=[

    @function Hatch.Roll()
    description: Gets the pet chosen based on the weights.

]=]

function Hatch.Roll()

    local RNG = Random.new();
	local Counter = 0;

	for k, v in pairs(chances) do
		Counter += v
	end

	local Chosen = RNG:NextInteger(0, Counter);

	for i, v in pairs(chances) do
		Counter -= v
		if Chosen > Counter then return i end
	end
end

return Hatch