--[=[

    Filename: Entity.lua

    Description: Manages everything related to a player's interactions with any of the
    systems on the server. Also responsible for loading the player, managing any world related
    interactions that need to be processed..you get the fucking point.

]=]

local Entity = {}
Entity.__index = Entity;
Entity._entities = require(script.entities)

-- // Services:

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Modules = ReplicatedStorage.Modules;

local Assets = ReplicatedStorage.Assets;
local UI = Assets.UI;

-- // Imports:

local Systems = script.Parent;

local Area = require(Systems.Areas);
local Loadout = require(Systems.Inventory.Loadout);
local util = require(script.Utilities);
local configs = require(Systems.Areas.CONFIGS);

Entity.util = util;

local replicator = require(Modules.Replicator);
local schema = require(script.Parent.Parent.Data);

function Abbreviate(number)

	local suffixes = { "K", "M", "B", "T", "Qd", "Qt", "Sx", "Sp", "Oc0", "Nl", "Un", "Dd", "Td"}
	local exponent = 0

	if number < 1000 then
		return tostring(number)
	end

	while number >= 1000 and exponent < #suffixes do
		number = number / 1000
		exponent = exponent + 1
	end

	return string.format("%.1f%s", number, suffixes[exponent])

end

--[=[

    @Constrcutor function
    Description: Creates a new Entity object.

]=]

function Entity.Initialize(player : Player, data : {}, profile)

    local self = {};

    self._data = data;
    self._clickDebounce = false;
    self._inventory = Loadout.New(player, self._data.Inventory);
    self._player = player;
    self._area = { _ID = data.Area; _Name = configs[data.Area].Name }
    self._profile = profile;
    self._ENTITY_LOADED = false

    local headGUI : BillboardGui | {PlayerName : TextLabel; Power : TextLabel} = UI.HeadGUI:Clone();
    headGUI.Parent = player.Character.Head;
    headGUI.PlayerName.Text = player.DisplayName;
    headGUI.Power.Text = `{Abbreviate(self._data.KnucklePower)}+ Power`

    Entity._entities[player.UserId] = self;
    return setmetatable(self, Entity);

end

function Entity.GetEntity(userID)
    return Entity._entities[userID]
end

--[=[

    @function Unload()

    Description: Unloads all entity components in an area for the given entity.
    Only called when the player moves to an area.

]=]

function Entity:Unload()

    local Entities : { } = util.GetAllEntitiesInArea(self._area._ID);
    for _, v in Entities do

        if v._player ~= self._player then
            replicator.StreamClient(v._player, "Systems", {

                kwargs = { userID = self._player.Name; };
                Module = "Pets";
                Function = "DumpContainer";
    
            })
        end

        replicator.StreamClient(self._player, "Systems", {

            kwargs = { userID = v._player.Name; };
            Module = "Pets";
            Function = "DumpContainer";

        })

    end
end

--[=[

    @function Load()

    Description: Laods the player's compoenents for all entities in the area
    and the given entity as well.

]=]

function Entity:Load()

    local Entities : { } = util.GetAllEntitiesInArea(self._area._ID)
    Area.Load(self._player, self._data.Area);

    for _, v in Entities do

        if v._player ~= self._player then
            replicator.StreamClient(v._player, "Systems", {

                kwargs = {

                    userID = self._player.Name;
                    pets = self._inventory:GetPets();
                    maxPets = self._data.Inventory.Pets.MaxPets

                };

                Module = "Pets";
                Function = "NewContainer";

            })
        end

        replicator.StreamClient(self._player, "Systems", {

            kwargs = {

                userID = v._player.Name;
                pets = v._inventory:GetPets();
                maxPets = v._data.Inventory.Pets.MaxPets

            };

            Module = "Pets";
            Function = "NewContainer";

        })

    end

    local glove = self._inventory:GetGlove()

    if glove ~= "undefined" then
        Loadout.ClassModules.Gloves.AddGloveOnPlayer(self._player, glove)
    end
end

--[=[

    @function ProcessClientRequest()
    Description: Processes a request given from the client.

]=]

function Entity:ProcessClientRequest(kwargs : {})

    local module = require(Systems:FindFirstChild(kwargs.Module));
    local result = module[kwargs.Function](self, kwargs.kwargs);

end

--[=[

    @function Dump()
    Description: Called when the player leaves the game.

]=]

function Entity:Dump()
    self._entities[self._player.UserId] = nil;
end

return Entity
