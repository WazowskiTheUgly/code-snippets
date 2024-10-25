type Pet = {

    _pet : Part;
    _root : Part;
    _owner : Player;
    _ID : number;
    _offset : CFrame;
    ySizeOffset : number;

}

local Pet = {} :: Pet
Pet.__index = Pet;

-- // Services:

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local RunService = game:GetService("RunService");
local TweenService = game:GetService("TweenService");

local Modules = ReplicatedStorage.Modules;

-- // Assets:

local Assets = ReplicatedStorage.Assets;
local PetAssets : Folder = Assets.Pets;

-- // Functions:

--[=[

    @ constructor
    Description: Creates a new instance of the given object

    @ param          Class             string              The class of the pet, essentially just the name of it.
    @ param          Owner             Player              Owner of the object
    @ param           ID               number              position of the pet in the client's equipped array.
    @ param         MaxPets            number              max amount of pets the player owns to compute the offset.

]=]

function Pet.New(Class : string, Owner : Player, ID : number, MaxPets : number, UUID)

    local self = setmetatable({}, Pet);

    self._pet = PetAssets:FindFirstChild(Class):Clone()
    self._uuid = UUID
    self._pet.Parent = Owner.Character
    self._root = Owner.Character.HumanoidRootPart;
    self._owner = Owner;
    self._ID = ID;
    self.maxpets = MaxPets or 3;
    self.active = false;
    self._elevation = 1;
    self._petElevation = self._pet:GetAttribute("ElevationOffset")
    self._params = RaycastParams.new()
    self._params.FilterDescendantsInstances = {self._owner.Character, self._pet}
    self._params.FilterType = Enum.RaycastFilterType.Exclude;
    self._goalReached = false;

    return self

end

--[=[

    @ComputeOffset
    Description: 

]=]

function Pet:ComputeOffset()

    local a = self._ID * (math.pi * 2) / self.maxpets
    self._offset = CFrame.new(math.sin(a) * 6, self._elevation, math.cos(a) * 6);

end

function Pet:Walk()

    local t = 0;

    local callback = function()

        t += 0.001;

        local rootcf = self._root.CFrame;
        local start =  self._pet.CFrame * CFrame.new(0, 15, 0);
        local result = workspace:Raycast(start.Position, -start.UpVector * 69, self._params);

        self:ComputeOffset()

        local elevationOffset = result.Position.Y;
        local transform = CFrame.new(rootcf.X, elevationOffset + self._petElevation, rootcf.Z) * self._offset;

        local animation_angles = CFrame.Angles(math.rad(math.sin(t * 80 / 2) * 25), 0, 0)
        local angles = CFrame.Angles(rootcf:ToOrientation()) * animation_angles;
        local sinewave = CFrame.new(0, 1.5 + math.sin(t * (80)) * 1.75, 0)

        TweenService:Create(self._pet, TweenInfo.new(.1), {CFrame = transform * angles * sinewave}):Play()

    end

    RunService:BindToRenderStep(`Update_Pet_Position ${self._ID}`, Enum.RenderPriority.Camera.Value + 1, callback)

end

function Pet:Readjust()

    local rootcf = self._root.CFrame;
    local start =  self._pet.CFrame * CFrame.new(0, 15, 0);
    local result = workspace:Raycast(start.Position, -start.UpVector * 69, self._params);

    self:ComputeOffset();

    local angles = CFrame.Angles(rootcf:ToOrientation());
    local elevationOffset = result.Position.Y + self._petElevation;
    local transform = CFrame.new(rootcf.X, elevationOffset, rootcf.Z) * self._offset;

    TweenService:Create(self._pet, TweenInfo.new(.15), {CFrame = transform * angles}):Play()
    RunService:UnbindFromRenderStep(`Update_Pet_Position ${self._ID}`)

end

function Pet:Deploy()

    local Humanoid : Humanoid = self._owner.Character.Humanoid;

    local function _run()

        local currentMoveDirection : Vector3 = Humanoid.MoveDirection;
        if currentMoveDirection == Vector3.zero then self:Readjust(); self.active = false return end
        if self.active == true then return end

        self.active = true;
        self:Walk()

    end

    self._mdchanged = Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(_run)
    self:Readjust()

end

function Pet:Terminate()

    if self.active == true then
        RunService:UnbindFromRenderStep(`Update_Pet_Position ${self._ID}`)
    end

    self._mdchanged:Disconnect()
    self._pet:Destroy();
    self._root = nil;
    self._owner = nil;
    self._ID = nil;
    self.maxpets = nil;
    self.active = nil;
    self._elevation = nil;
    self._params = nil

end

return Pet
