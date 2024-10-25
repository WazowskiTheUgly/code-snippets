local Tab = {}; local self = Tab

Tab._connections = {};
Tab.temp = {};
Tab._data = {};
Tab.CurrentSelected = nil;

-- // UI Assets

local Player = game.Players.LocalPlayer;
local UI = Player.PlayerGui;

local Root : ScreenGui = UI.Root;
local Frames : Frame = Root.Frames;
local Pets : ImageLabel = Frames.Inventory.Containers.Pets;

local Storage : ImageButton = Pets.Storage;
local Equipped : ImageButton = Pets.Equipped;
local Container : ScrollingFrame = Pets.Container;

local Selected : ImageLabel = Pets.Selected;
local EvolutionStatus : Frame | {Placement : TextLabel} = Selected.Evolution;
local Rarity : Frame | {Placement : TextLabel} = Selected.Rarity;
local Mutation : Frame | {Placement : TextLabel} = Selected.Mutation;

local Evolve : ImageButton = Selected.Evolve;
local Action : ImageButton = Selected.Action;

local Tooltips : Folder = Root.Tooltips;
local PetTooltip = Tooltips.PetTooltip;

-- // Services:

local client = game:GetService("StarterPlayer").StarterPlayerScripts
local TweenService = game:GetService("TweenService");
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MainArray = {Storage, Equipped};
local Template : ImageButton | {Icon : ImageLabel; _Name : TextLabel} = Container.Template;

-- // Imports:

local Modules = ReplicatedStorage.Modules;

local signal = require(Modules.Signal);
local Button = require(script.Parent.Parent.UIManager.Button)
local util = require(script.Parent.Utility);
local effects = require(script.Parent.Parent.Effects);
local configs = require(script.Parent.Configs);
local replicator = require(Modules.Replicator);
local Debug = require(script.Parent.Parent.Debug);

Tab.activated = signal.new()
Tab.deactivated = signal.new()

-- // Loader Functions:

Tab.Activate = {
    args = {
        container = {Storage, Equipped, Container};
        toAnimate = MainArray;
        signal = self.activated
    };
    func = util.Activate
}

Tab.Deactivate = {
    args = {
        container = Pets:GetChildren();
        signal = self.deactivated
    };
    func = util.Deactivate
}

-- // Functions:

--[=[

    @function self.activated
    Description: Called when the tans loaded.

]=]

self.activated:Connect(function()

    local Equip = Button.New(Action)
    Equip:Initialize(self.ConductAction)

    table.insert(self.temp, Equip)
    self.LoadInventory()

    Debug.Log({text = `Loaded subframe [Pets] Of Frame [Inventory].`})

end)

self.deactivated:Connect(function()

    Selected.Visible = false;
    Container.Size = UDim2.new(0.957, 0, 0.856, 0)
    Container.Position = UDim2.fromScale(0.504, 0.522)

    for _, v in self._connections do
        if v then v:Disconnect() end
    end

    for _, v in self.temp do
        if v then v:Dump() end
    end

    for _, v in Container:GetChildren() do
        if v:IsA("ImageButton") and v.Name ~= "Template" then
            v:Destroy()
        end
    end

    self.temp = {}
    self._connections = {}

end)

function Tab.Unequip(args)

    local index = table.find(self._data.Equipped, args.member)

    if Container.Visible == true then

        local Image : ImageButton = Container:FindFirstChild(args.member)
        Image.Equipped:Destroy();

    end

    if Selected.Visible == true then

        Action.ImageColor3 = Color3.new(0, 255, 0);
        Action.ActionText.Text = "EQUIP"

    end

    table.remove(self._data.Equipped, index)
    self.UpdateEquippedCount();

    Action.ImageTransparency = 0;
    Action.Active = true;
    Debug.Log({text = `Succesfully executed server request [Unequip]: [{args.member}]`})

end

function Tab.UpdateHUD(args)

    local action = args.action;

    if Selected.Visible == true then
        if action == "UNEQUIP" then

            Action.ImageColor3 = Color3.new(255, 0, 0);
            Action.ActionText.Text = "UNEQUIP"

        else

            Action.ImageColor3 = Color3.new(0, 255, 0);
            Action.ActionText.Text = "EQUIP"

        end
    end

    Action.ImageTransparency = 0;
    Action.Active = true;

end

function Tab.Equip(args)

    if Container.Visible == true then

        local Image : ImageButton = Container:FindFirstChild(args.member)
        local Tickmark = Frames.Inventory.Equipped:Clone();
        Tickmark.Parent = Image;
        Tickmark.Visible = true;

    end

    if Selected.Visible == true then

        Action.ImageColor3 = Color3.new(255, 0, 0);
        Action.ActionText.Text = "UNEQUIP"

    end

    table.insert(self._data.Equipped, args.member)
    self.UpdateEquippedCount()

    Action.ImageTransparency = 0;
    Action.Active = true;

    Debug.Log({text = `Succesfully executed server request [Equip]: [{args.member}]`})

end

function Tab.GetPets()

    local generatedTable = {}
    local c = 0;

    for _, v in self._data.Equipped do

        c = c + 1
        local morph = self._data.Reserved[v]
        morph.PositionID = c;
        morph.UUID = v;

        table.insert(generatedTable, morph)

    end

    return generatedTable

end

function Tab.AddItemToPlayerInventory(kwargs : {member : string, uuid : string})

    Debug.Log({text = `Added: [{kwargs.member} | {kwargs.uuid}] to [Pets]`})

    self._data.Reserved[kwargs.uuid] = kwargs.memberData;
    self:UpdateReservedCount()

    if Container.Visible == false then return end
    self.CreateButton(kwargs.uuid, kwargs.memberData)

end

function Tab.ConductAction()

    if self.CurrentSelected == nil then return end

    Action.ImageTransparency = 0.5;
    Action.Active = false;

    local petName = self.CurrentSelected.Name;
    local _action = nil;

    if table.find(self._data.Equipped, self.CurrentSelected.Name) then
        _action = "Unequip"
    else
        _action = "Equip"
    end

    replicator.StreamToServer("Systems", {

        Module = "Inventory";
        Function = "Action";
        kwargs = { member = petName; family = "Pets"; action = _action }

    });

end

function Tab.CloseInformationBar()

    local Tween = TweenService:Create(Selected, TweenInfo.new(0.1), {Size = UDim2.fromScale(0, 0)})
    Tween:Play();

    TweenService:Create(Container, TweenInfo.new(0.1),
        {Size = UDim2.fromScale(0.957, 0.856); Position = UDim2.fromScale(0.504, 0.522)}
    ):Play()

    self.CurrentSelected = nil;

end

--[=[

    @function Tab.OpenInformationBar()
        @param         PetSelected         ImageButton           The pet the player clicked on.

    @description: Opens the information bar related to the pet that the player clicked.

]=]

function Tab.OpenInformationBar(PetSelected : ImageButton)

    self.CurrentSelected = PetSelected;

    if table.find(self._data.Equipped, self.CurrentSelected.Name) then

        Action.ImageColor3 = Color3.new(255, 0, 0);
        Action.ActionText.Text = "UNEQUIP"

    else

        Action.ImageColor3 = Color3.new(0, 255, 0);
        Action.ActionText.Text = "EQUIP"

    end

    if Selected.Visible ~= true then

        Selected.Size = UDim2.new(0, 0, 0 ,0);
        Selected.Visible = true;

        local Tween = TweenService:Create(Selected, TweenInfo.new(0.1), {Size = UDim2.fromScale(0.276, 0.869)})
        Tween:Play();

        local TakeToSide = TweenService:Create(Container, TweenInfo.new(0.1),
            {Size = UDim2.fromScale(0.668, 0.856); Position = UDim2.fromScale(0.36,0.522)}
        )

        TakeToSide:Play();

    end

    for _, v : Frame in {Rarity, Mutation, EvolutionStatus} do

        v.Size = UDim2.new(0, 0, 0, 0);

        local sizeUp = TweenService:Create(v, TweenInfo.new(.25), {Size = UDim2.fromScale(0.422, 0.049)})
        sizeUp:Play()

    end

    local petData = self._data.Reserved[PetSelected.Name]
    local config = configs.Pets[petData.Name];

    Rarity.Placement.Text = config.Rarity;
    Mutation.Placement.Text = petData.Mutation;
    EvolutionStatus.Placement.Text = petData.Evolution;
    Selected.Icon._Name.Text = config.Name;
    Rarity.ColorGiver.Color = configs.RarityColors[config.Rarity];

end

function Tab.CreateButton(index : string, pet_data)

    local Pet = Template:Clone();

    Pet.Parent = Container;
    Pet.Visible = true;
    Pet.Name = tostring(index);

    local config = configs.Pets[pet_data.Name];
    local color = configs.RarityColors[config.Rarity]
    local Btn = Button.New(Pet, {_text = "", _tooltip = true; _base = "PetTooltip"});

    Btn:Initialize(self.OpenInformationBar, Pet);
    Pet._Name.Text = config.Name;
    Pet.Icon.Image = `rbxassetid://{tostring(config.Icon)}`;
    Pet.ColorGiver.Color = color

    if config.Size then Pet.Icon.Size = config.Size; end
    if config.Position then Pet.Icon.Position = config.Position; end

    local Size = Pet.Icon.Size

    self._connections[tostring(index)..`Enter`] = Pet.MouseEnter:Connect(function()

        PetTooltip.PetName.Text = config.Name;
        PetTooltip.Rarity.Text = config.Rarity;
        PetTooltip.ColorGiver.Color = color;
        PetTooltip.Rarity.ColorGiver.Color = color;
        PetTooltip.Multiplier.Text = `x{config.Multiplier} Multiplier`

        effects.ScaledBasedOnPercentage(Pet.Icon, 0.1, 1.15)

    end)

    self._connections[tostring(index)..`Leave`] = Pet.MouseLeave:Connect(function()
        effects.Scale(Pet.Icon, 0.1, Size)
    end)

    table.insert(self.temp, Btn);

end

--[=[

    @function Tab.LoadInventory()
    @description: Loads the inventory. Called everytime the player switches to the pets tab.

]=]

function Tab.LoadInventory()

    if not self._data then return end

    for index : string, pet_data in self._data.Reserved do
        self.CreateButton(index, pet_data)
    end

    for _, pet : string in self._data.Equipped do

        local Image : ImageButton = Container:FindFirstChild(pet)
        local new = Frames.Inventory.Equipped:Clone()
        new.Parent = Image;
        new.Visible = true;

    end

    print(self._data)

end

function Tab.UpdateEquippedCount()
     Equipped.Count.Text = `{tostring(#self._data.Equipped)}/{tostring(self._data.MaxPets)}`
end

function Tab.UpdateReservedCount()

    local c = 0;
    for _, _ in self._data.Reserved do c += 1 end

    Storage.Count.Text = `{tostring(c)}/200`

end

function Tab.Initialize()

    self.UpdateEquippedCount();
    self.UpdateReservedCount();

end

return Tab
