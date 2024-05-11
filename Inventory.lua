--!nocheck

--[=[

    filenmame: Inventory.lua
    runcontext: module/server
    description: Manages the Inventory System. Handles the claiming and selling of pets.

]=]

local Inventory = {}

-- [=[ SERVICES ]=]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- [=[ PACKAGES ]=]

local Packages = ReplicatedStorage.Packages;
local Configs = script.Parent.Configs;

local network = require(Packages.ByteNet);
local profiles = require(script.Parent.Data.Profiles)

-- [=[ ASSETS ]=]

local Assets = ServerStorage.Assets;
local PetAssets = Assets.PetAssets;

--[=[ PACKETS ]=]

local namespace = network.defineNamespace("Inventory", function()
    return {
        _updateInventory = network.definePacket({
            value = network.struct({

                _pet = network.string;
                _count = network.float64;

            })
        });

        _equipPet = network.definePacket({
            value = network.struct({

                _class = network.string;
                _identification = network.string;

            })
        });
    }
end)

--[=[ FUNCTIONS ]=]

function Inventory._init()

    print("Initialized Inventory")

    namespace._equipPet.listen(function(data, Player)
        Inventory.EquipPet(data, Player)
    end)
end

--[=[

    @function Inventory.UpdatePetInventory()
        
        @param           player            Player                The player who's inventory to update.
        @param         operation           string                either +, or -, to remove or add a pet.
        @param            pet              string                The pet to update the inventory with.

    description: Called when the player accepts a pet, or sells a pet. Updates the reserve inventory.

]=]

function Inventory.UpdatePetInventory(player : Player, operation : string, pet : string): string
    
    local profile : profiles.DataProfile = profiles[player.UserId]
    if not profile then return end

    local ReservedPets = profile.Data.Inventory.Reserved_Pets
    local PlayerPet = ReservedPets[pet]

    if operation == "+" then

        if not PlayerPet then
            ReservedPets[pet] = 1;
        else
            ReservedPets[pet] += 1;
        end

    elseif operation == "-" then

        ReservedPets[pet] -= 1;

        if PlayerPet == 0 then
            ReservedPets[pet] = nil;
        end
    end

    namespace._updateInventory.sendTo({

        _pet = pet;
        _count = ReservedPets[pet];

    }, player)

    print("Player Chose: ", pet, " Operation: ", operation)

end

--[=[

    @function Inventory.EquipPet()
        
        @param           player            Player                The player who wants to equip a pet.
        @param           _class            string                The class of the pet to equip.
        @param      _identification        string                Identifier of the pet, like PetName_69.

    description: Called when the player wants to equip a pet.

]=]

function Inventory.EquipPet(data: {_class : string; _identification : string}, player : Player)
    
    local Character = player.Character
    local Folder = Character.Pets;

    local profile : profiles.DataProfile = profiles[player.UserId]
    if not profile then return end

    if not profile.Data.Inventory.Reserved_Pets[data._class] then
        player:Kick("pls no hack 😔")
    end

    local Pet : Part = PetAssets:FindFirstChild(data._class):Clone()
    Pet.Parent = Folder
    Pet.Name = data._identification

    namespace._equipPet.sendTo({

        _class = data._class;
        _identification = data._identification

    }, player)

end

return Inventory;