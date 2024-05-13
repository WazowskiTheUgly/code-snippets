--[=[

    filenmame: Data.lua
    runcontext: module/server
    description: Manages the handling, loading, editing and unloading of data.

    DEFAULT_TEMPLATE - Starting Template
    STACKED_TEMPLATE/1 - Super loaded inventory

]=]

export type DataTemplate = {

    Level : number;
    Experience : number;
    Coins : number;

    LastPetRolled : string;
    LastPetClaimed : boolean;

    Inventory : {

        Current_Pets :{};
        Reserved_Pets : {};
        Items : {};

    };

}

export type DataProfile = {

    Initialize : () -> {};
    _init : () -> nil;

    -- [=[ METHODS ]=] --

    IncrementValue : (index : string, increment : number) -> number;
    DecrementValue : (index : string, decrement : number) -> number;

    SetValue : (index : string, value : any) -> any;
    GetValue : (index : string) -> any;

    GetTableIndex : (tbl : string, value : any) -> number | any?;
    SetTableIndex : (tbl_index : string, value : any?) -> string | any;

    InsertValue : (tbl : string, value : any) -> string;
    RemoveValue : (tbl : string, value : any) -> nil;

}

local DataProfile = {}

DataProfile.__index = DataProfile;
DataProfile.__type = "DataProfile";

--[=[ SERVICES ]=] -- 

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players")

--[=[ PACKAGES ]=] --

local Packages = ReplicatedStorage.Packages

local ProfileService = require(script.ProfileService);
local Template = require(script.Template)
local Profiles = require(script.Profiles)

local Store = ProfileService.GetProfileStore("STACKED_TEMPLATE/2", Template)

--[=[ FUNCTIONS ]=] --

--[=[

    @function DataProfile.Initialize()

        @param           User                Player                  User who's data we must load.
        @return         Profile             DataProfile              The class that manages the data.

    descrption: Loads the player profile and important functions to edit it.

]=]

function DataProfile.Initialize(User : Player) : {}

    local ID = User.UserId;

    local LoadedProfile : {} = Store:LoadProfileAsync("Player_"..ID);
    if LoadedProfile == nil then User:Kick("Data failed to load. Please check your internet connection and try again.") end

    LoadedProfile:AddUserId(ID);
    LoadedProfile:Reconcile();

    LoadedProfile:ListenToRelease(function()
        User:Kick("Profile loaded on another server. Please reconnect.")
    end)

    if User:IsDescendantOf(Players) then

        local self = setmetatable({}, DataProfile)
        
        self.Player = User;
        self.Data = LoadedProfile.Data;
        self.Profile = LoadedProfile;

        Profiles[ID] = self;

        return self.Data;
    
    else

        LoadedProfile:Save()
        LoadedProfile:Release()

        return nil
    
    end
end

--[=[

    @function DataProfile._init()

    descrption: handles any tasks that need to be performed when the module is loaded.
    Sets up connections...etc, starts a process, etc.
    The data module needs no connections to be setup.

]=]

function DataProfile._init()
    print("Data Module Loaded.")
end

--[=[

    @function DataProfile:IncrementValue()

        @param           key           string | any           The key to increment
        @param        increment          +integer             The val to increment by.

        @return         number            number              The new val of the key.

    descrption: Increments a key by + increment

]=]

function DataProfile:Increment(key : string | any, increment : number) : number
    
    local key = self.Data[key];
    key = key + increment;
    self.Data[key] = key;

    return key;

end

--[=[

    @function DataProfile:DecrementValue()

        @param           key           string | any           The key to decrement
        @param        decrement          +integer             The val to decrement by.

        @return         number            number              The new val of the key.

    descrption: decrements a key by + decrement

]=]

function DataProfile:Decrement(key : string | any, decrement : number) : number
    
    local key = self.Data[key];
    key = key + decrement;
    self.Data[key] = key;

    return key;

end

--[=[

    @function DataProfile:GetValue()

        @param          index            string               The index to get.
        @return         value            string               the value found.

    descrption: gets a value from player's data.

]=]

function DataProfile:GetValue(index : string): string
    
    if type(index) ~= "string" then return error("Index must be a string") end
    if not self.Data[index] then return "Undefined" end

    return self.Data[index];

end

--[=[

    @function DataProfile:InsertValue()

        @param           tbl             string               the table to add an element into.
        @return         value             any                 the element to be added into the table.

    descrption: inserts a value into a tbl.

]=]

function DataProfile:InsertValue(tbl : string, value : any)
    
    if not tbl then return error("tbl must be a table") end
    
    local data_array : {} = self:GetValue(tbl);
    table.insert(data_array, value)

    return data_array;
    
end

--[=[

    @function DataProfile:SetValue()

        @param          index            string               the index to set to.
        @return         value             any                 the new value of the index

    descrption: Sets a value to an index.

]=]

function DataProfile:SetValue(index : string, value : any): string
    
    self.Data[index] = value;
    return self.Data[index];

end


return DataProfile