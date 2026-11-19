local fs = require('@lune/fs')
local luau = require('@lune/luau')
local Vector3 = require('@lune/roblox').Vector3
local Rewards = require('../src/shared/Rewards')
local n = 0
local function check(ok, message) assert(ok, message); n += 1 end
local function signal() return {Connect = function() end} end
-- Roblox callbacks can be assigned, but reading OnServerInvoke throws.
local function remote()
 return setmetatable({}, {__index = function(_, key)
  if key == 'OnServerInvoke' then error('OnServerInvoke cannot be read') end
 end})
end
local manager, buyRemote, equipRemote = remote(), remote(), remote()
local events = {petManager=manager,buyBackpack=buyRemote,equipBackpack=equipRemote}
function events:FindFirstChild(name) return self[name] end
local pets = {}
for _,name in {'NormalPet1','NormalPet2','NormalPet3','NormalPet4'} do
 local pet = {Name=name}
 function pet:IsA(class) return class == 'Model' end
 function pet:GetAttribute(key) return ({DisplayName=name,Tier='Common',Image=''})[key] end
 table.insert(pets,pet)
end
local Players = {PlayerRemoving=signal()}
local loaded
local Data = {profileLoaded={Connect=function(_, callback) loaded=callback end}}
local network = {callbacks={},fireClient=function() end}
local Stats = {add=function(_, p, _, amount) p.coins += amount end}
local RS = {GiftRush={Rewards=Rewards},shared={network=network,events=events}}
local SS = {pets={GetChildren=function() return pets end}}
local game = {ServerScriptService={game={data=Data,stats=Stats}}}
function game:GetService(name)
 return ({Players=Players,ReplicatedStorage=RS,ServerStorage=SS,
  HttpService={GenerateGUID=function() return 'test-pet-id' end},
  RunService={Heartbeat=signal()}})[name]
end
local item = {GetAttribute=function(_, key) if key=='ActualObject' then return 'Backpack2' end end}
local workspace = {areas={area1={shop={ZonePart={Position=Vector3.zero}}}},
 stores={backpack={models={GetChildren=function() return {item} end}}}}
local Service = luau.load(fs.readFile('src/server/Service.luau'), {
 debugName='GiftRushService',injectGlobals=true,environment={
  game=game,workspace=workspace,Vector3=Vector3,require=function(module) return module end,
  Instance={new=function(class)
   if class=='RemoteFunction' then return remote() end
   return {FireClient=function() end}
  end},task={spawn=function() end},
 }})()
local p = {Parent=Players,coins=0,Character={FindFirstChild=function() return {Position=Vector3.zero} end}}
local attrs={loaded=true}
function p:GetAttribute(key) return attrs[key] end
function p:SetAttribute(key,value) attrs[key]=value end
function p:GetAttributeChangedSignal() return signal() end
local profile = {player_pets={owned={},equipped={}},petLimit=100,owned_backpacks={},boosts={}}
loaded(profile,p)
local equipped, bought, worn = 0,0,0
network.callbacks.petManager=function(player, action, details)
 check(player==p and action=='equip' and details.slot==1,'Equip callback arguments')
 check(details.id==profile.player_pets.owned[1].identifier,'Equip granted pet')
 equipped+=1
end
local ok = Service.Claim(p)
check(ok and #profile.player_pets.owned==1 and equipped==1,'Claim and equip through server handler')
check(p.coins==150 and profile.giftRush.visits==1,'Claim rewards granted once')
check(not Service.Claim(p) and p.coins==150,'Duplicate claim rejected')
profile.giftRush.stage=3
check(not Service.Upgrade(p),'Missing shop handlers fail without callback read')
network.callbacks.buyBackpack=function(player, object)
 check(player==p and object==item,'Buy callback arguments');bought+=1
 table.insert(profile.owned_backpacks,'Backpack2');return true
end
network.callbacks.equipBackpack=function(player, object)
 check(player==p and object==item,'Backpack equip callback arguments');worn+=1
end
check(Service.Upgrade(p) and bought==1 and worn==1,'Buy and equip through server handlers')
check(Service.Upgrade(p) and bought==1 and worn==2,'Owned backpack is not bought twice')
profile.owned_backpacks={}
network.callbacks.buyBackpack=function() return false end
check(not Service.Upgrade(p) and worn==2,'Rejected purchase does not equip backpack')
network.callbacks=nil
profile.giftRush.visits=0;profile.giftRush.lastClaimDay=-1
check(Service.Claim(p) and #profile.player_pets.owned==2,'Pet grant works without optional auto-equip')
check(not Service.Upgrade(p),'Missing handler registry fails safely')
print(n..' service checks passed')
