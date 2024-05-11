--[=[

    runcontext: module/server    

]=]

local Quests = {}
Quests.Cache = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage");

-- // Packages:

local Packages = ReplicatedStorage.Packages;

local Net = require(Packages.BridgeNet2);
local Data = require(script.Parent.Parent.Data)
local Configs = require(script.Configs)

local Bridge = Net.ReferenceBridge("Server")
local HUD = Net.ReferenceBridge("HUD")

-------------------------------------------
-- // Quest Generation & Loading Functions:
-------------------------------------------

--[=[

    Function Quests.InitializeQuests()
    Loads all existing quests

]=]

function Quests.InitializeQuests(Player : Player)
    task.spawn(function()

        local PlayerData = Data.Get(Player, "Quests")

        -- // Player does not have quests that are generated.

        if #PlayerData.Quests == 0 then Quests.GenerateQuests(Player, PlayerData) return end
        Quests.Load(Player, PlayerData)

    end)
end

--[=[

    Function Quests.Load()
    Loads the quests from the player's data. Checks to see if the time has passed.

]=]

function Quests.Load(Player, PlayerData)
    
    local TimeAdded : string = PlayerData.TimeAdded;
    local DateAdded : number = PlayerData.DateAdded;

    if os.date("%d") ~= DateAdded then print("Different Date!") return Quests.GenerateQuests(Player, PlayerData) end

    local CurrentHour = os.date("%I");
    local currentMinute = os.date("%M");

    local resetQuota = (1 * 3600)
    local exactTime = (CurrentHour * 3600) + (currentMinute * 60) + os.date("%S");
    local difference = resetQuota - (exactTime - TimeAdded)

    if difference >= resetQuota then return Quests.GenerateQuests(Player, PlayerData) end
    local TimeRemaining = difference;

    HUD:Fire(Net.Players({Player}), {

        Module = "Quests";
        Function = "Load";
        Arguments = {QDATA = PlayerData.Quests; Time = TimeRemaining}

    })

    task.delay(TimeRemaining, function()
        if Player then
            Quests.GenerateQuests(Player, PlayerData)
        end
    end)
end

--[=[

    Function Quests.GenerateQuests()
    Generates 3 new quests for the player.

]=]

function Quests.GenerateQuests(Player, PlayerData)
    
    local CurrentHour = os.date("%I");
    local currentMinute = os.date("%M");

    local exactTime = (CurrentHour * 3600) + (currentMinute * 60) + os.date("%S");
    local exactDate = os.date("%d")

    PlayerData.TimeAdded = exactTime;
    PlayerData.DateAdded = exactDate;

    -- Remove old quests:

    for i = 1, 3 do
        if PlayerData.Quests[i] then table.remove(PlayerData.Quests, i) end
    end

    PlayerData.Quests = {}

    local workerTable = {1, 2, 3, 4, 5, 6}

    for i = 1, 3 do
        
        local rand = math.random(1, #workerTable)
	    local main = workerTable[rand]
        
	    table.remove(workerTable, rand)
        PlayerData.Quests[i] = table.clone(Configs[main])

    end

    HUD:Fire(Net.Players({Player}), {

        Module = "Quests";
        Function = "Load";
        Arguments = {QDATA = PlayerData.Quests; Time = (2 * 3600)}

    })

end

----------------------------
-- // Progression Functions:
----------------------------

function Quests.GetAllRelevantQuests(Gamemode : string, CurrentQuests : {})
    
    local RelevantQuests = {}

    for index : number, Quest in ipairs(CurrentQuests) do

        print(Quest)

        if Quest.Gamemode == Gamemode or Quest.Gamemode == "ALL" then
            table.insert(RelevantQuests, Quest)
        end
    end

    return RelevantQuests

end

function Quests.UpdateQuest(Player : Player, Quest : {}, Adder : number)

    if Quest.Completed == true then return end
    Quest.Progress += Adder;

    HUD:Fire(Net.Players({Player}), {

        Module = "Quests";
        Function = "Update";
        Arguments = {Quest = Quest;};

    })

    if Quest.Progress >= Quest.Completion then
        Quest.Completed = true;
    end
end

function Quests.Claim(Player : Player, Kwargs)
    
    local QuestData = Data.Get(Player, "Quests")
    local QuestName = Kwargs.QuestName;

    local Quest = nil;
    local Index = 0;

    for _, v in ipairs(QuestData.Quests) do Index += 1; if v.Name == QuestName then Quest = v; break end end
    if Quest.Completed == false then print("Quest not completed!") return end
    if Quest.Claimed == true then print("Already calimed!") return end

    local Reward = Quest.RewardData.Amount;
    Quest.Claimed = true;

    Data.GrantCoins(Player, {Coins = Reward})
    HUD:Fire(Net.Players({Player}), {

        Module = "Quests";
        Function = "Claimed";
        Arguments = {Quest = Quest.Name}

    })

end

-- // Refresh Dev product:

function Quests.FulfillRefresh(Player : Player, Kwargs : {})
    
    local PlrData = Data.Get(Player, "Quests")
    Quests.GenerateQuests(Player, PlrData)

    HUD:Fire(Net.Players({Player}), {

        Module = "Quests";
        Function = "DumpTimerThread";
        Arguments = {}

    })

    print("REFRESHED.")

end

return Quests