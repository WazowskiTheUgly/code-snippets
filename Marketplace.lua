local Deals = {};
Deals.Sessions = {};

-- // Services:

local ReplicatedStorage = game:GetService("ReplicatedStorage");

-- // Imports:

local Packages = ReplicatedStorage.Packages;

local ProductIDs = require(script.ProductIDs)
local Fulfillment = require(script.Fulfillment);
local Signal = require(Packages.GoodSignal);

Deals.PromptGamepassPurchase = Signal.new();
Deals.PromptDeveloperProductPurchase = Signal.new();

-- // Functions:

function Deals.ProcessLimitedEggPurchaseRequest(player : Player, times : number, egg : string)

    local product_name = egg.."_x"..tostring(times)
    if not ProductIDs.ShopEggs[product_name] then player:Kick("Stop messing with headers") return end

    local Config = ProductIDs.ShopEggs[product_name];
    local ID = Config.ID
    local session = Deals.CreateSessionLock(player, ID, {Fulfillment = "GiveLimitedEgg"; kwargs = {times; egg}})

    Deals.PromptDeveloperProductPurchase:Fire(player, ID, session)
    return product_name

end

function Deals.CreateSessionLock(player : Player, ID : number, OnPurchased : {})

    local session = setmetatable({player = player; ID = ID;}, {
        __newindex = function(self, k, v)

            if v == false then
                Deals.Sessions[player.UserId] = nil;
            end

            if v ~= true then return end

            Fulfillment[OnPurchased.Fulfillment](player, table.unpack(OnPurchased.kwargs));
            Deals.Sessions[player.UserId] = nil;

        end
    })

    Deals.Sessions[player.UserId] = session;
    return session;

end


return Deals
