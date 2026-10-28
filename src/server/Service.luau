local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local SS=game:GetService('ServerStorage')
local Http=game:GetService('HttpService')
local Rewards=require(RS.GiftRush.Rewards)
local Data=require(game.ServerScriptService.game.data)
local Stats=require(game.ServerScriptService.game.stats)
local network=require(RS.shared.network)
local Service={}
local profiles,limits={},{ }
local folder=RS.GiftRush
local request=Instance.new('RemoteFunction');request.Name='Request';request.Parent=folder
local changed=Instance.new('RemoteEvent');changed.Name='Changed';changed.Parent=folder
local catalog,models={},{}
for _,m in SS.pets:GetChildren() do
 if m:IsA('Model') and m:GetAttribute('DisplayName') and not models[m.Name] then
  models[m.Name]=m
  table.insert(catalog,{name=m.Name,displayName=m:GetAttribute('DisplayName'),tier=m:GetAttribute('Tier'),image=m:GetAttribute('Image')})
 end
end
table.sort(catalog,function(a,b)return a.displayName<b.displayName end)
local lobby,round=nil,nil
local route={Vector3.new(-132,3,-18),Vector3.new(-155,3,2),Vector3.new(-180,3,17),Vector3.new(-207,3,-3),Vector3.new(-233,3,-24),Vector3.new(-218,3,-49),Vector3.new(-187,3,-62),Vector3.new(-150,3,-50)}
local raceFolder=Instance.new('Folder');raceFolder.Name='GiftRushCourse';raceFolder.Parent=workspace
local raceModels={}
local grantPet
local function state(p) return profiles[p] and profiles[p].giftRush end
local function refresh(p)
 local s=state(p);if not s then return end
 for _,pet in profiles[p].player_pets.owned do
  for _,entry in catalog do if pet.displayName==entry.displayName then s.album[entry.name]=true break end end
 end
 p:SetAttribute('GiftRushCollectionBonus',Rewards.Bonus(s))
 p:SetAttribute('GiftRushOpened',s.opened)
 p:SetAttribute('GiftRushReturnLeft',s.reduced and math.max(0,3-s.returnGifts) or 0)
end
function Service.Snapshot(p)
 local s=state(p);if not s then return {ready=false} end
 refresh(p)
 local rows={}
 if round then
  for player,r in round.players do table.insert(rows,{name=player.DisplayName,score=r.score}) end
  table.sort(rows,function(a,b)if a.score==b.score then return a.name<b.name end return a.score>b.score end)
 end
 local r=round and round.players[p]
 local result=p:GetAttribute('GiftRushResult')
 return {ready=true,stage=s.stage,starterPet=s.starterPet,visits=s.visits,nextDay=Rewards.Day(s),canClaim=Rewards.CanClaim(s,os.time()),nextAt=Rewards.NextAt(os.time()),bonus=Rewards.Bonus(s),returnLeft=p:GetAttribute('GiftRushReturnLeft'),opened=s.opened,wins=s.wins,bestRace=s.bestRace,album=s.album,catalog=catalog,
  race={queued=lobby and lobby.players[p]==true or false,countdown=lobby and math.max(0,math.ceil(lobby.at-os.clock())) or 0,active=r~=nil,remaining=round and math.max(0,math.ceil(round.ends-os.clock())) or 0,score=r and r.score or 0,nextTarget=r and (r.score%#route+1) or 0,standings=rows,result=result}}
end
local function push(p) if p.Parent==Players then changed:FireClient(p,Service.Snapshot(p)) end end
function Service.Opened(p)
 local s=state(p);if not s then return end
 Rewards.Opened(s)
 if s.stage==1 then s.stage=2 end
 for _,goal in {{8,'NormalPet2'},{25,'NormalPet3'},{60,'NormalPet4'}} do
  if s.opened>=goal[1] and not s.milestones[tostring(goal[1])] and grantPet(p,goal[2]) then
   s.milestones[tostring(goal[1])]=true
   p:SetAttribute('GiftRushNotice','Nouveau compagnon ! '..goal[1]..' boîtes ouvertes.')
  end
 end
 refresh(p);push(p)
end
grantPet=function(p,modelName)
 local profile=profiles[p];local m=models[modelName]
 if not profile or not m then return false end
 if #profile.player_pets.owned>=profile.petLimit then return false end
 local id=Http:GenerateGUID(false)
 local display=m:GetAttribute('DisplayName')
 table.insert(profile.player_pets.owned,{name=display,displayName=display,image=m:GetAttribute('Image'),tier=m:GetAttribute('Tier'),identifier=id})
 profile.giftRush.album[modelName]=true
 local manager=RS.shared.events:FindFirstChild('petManager')
 if next(profile.player_pets.equipped)==nil and manager and manager.OnServerInvoke then
  manager.OnServerInvoke(p,'equip',{name=display,id=id,slot=1})
 end
 network:fireClient('refreshPets',p)
 return true
end
function Service.Sold(p,coins)
 local s=state(p);if not s or coins<=0 then return end
 if s.stage==2 then
  s.stage=3
  -- The first real sale pays at least the first upgrade, once per profile.
  local balance=tonumber(p.leaderstats.Coins.Real.Value) or 0
  if balance<80 then Stats:add(p,'Coins',80-balance) end
  p:SetAttribute('GiftRushNotice','Première vente réussie ! Ton nouveau sac coûte 80 pièces.')
 end
 push(p)
end
local function completeIntro(p)
 local s=state(p);if not s or s.stage~=3 or p:GetAttribute('SelectedBackpack')~='Backpack2' then return end
 if not s.starterPet then
  if not grantPet(p,'NormalPet1') then return end
  s.starterPet=true
 end
 s.stage=4;p:SetAttribute('GiftRushNotice','Bravo ! Ton premier compagnon te suit. Continue la collection !');push(p)
end
function Service.Upgrade(p)
 local s=state(p)
 if not s or s.stage~=3 then return false,'Termine ta première vente.' end
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 local pos=workspace.areas.area1.shop.ZonePart.Position
 if not root or (root.Position-pos).Magnitude>25 then return false,'Suis la flèche jusqu’à la boutique.' end
 local item
 for _,m in workspace.stores.backpack.models:GetChildren() do
  if m:GetAttribute('ActualObject')=='Backpack2' then item=m break end
 end
 local events=RS.shared.events
 if not item or not events:FindFirstChild('buyBackpack') or not events:FindFirstChild('equipBackpack') then return false,'Boutique en préparation.' end
 local owned=table.find(profiles[p].owned_backpacks,'Backpack2')
 if not owned then
  local ok=events.buyBackpack.OnServerInvoke(p,item)
  if not ok then return false,'Il te faut 80 pièces. Ouvre et vends une autre boîte.' end
 end
 events.equipBackpack.OnServerInvoke(p,item)
 completeIntro(p)
 return true,'Sac amélioré : 200 places !'
end
function Service.Claim(p)
 local s=state(p);if not s or not p:GetAttribute('loaded') then return false,'Chargement en cours' end
 local reward=Rewards.Calendar[Rewards.Day(s)]
 if not Rewards.CanClaim(s,os.time()) then return false,'Cadeau deja recupere aujourd’hui' end
 if reward.pet and (not models[reward.pet] or #profiles[p].player_pets.owned>=profiles[p].petLimit) then return false,'Libere une place pour ton compagnon' end
 Rewards.Claim(s,os.time())
 if reward.coins then Stats:add(p,'Coins',reward.coins) end
 if reward.boost then profiles[p].boosts[reward.boost]+=reward.seconds end
 if reward.pet then grantPet(p,reward.pet) end
 push(p)
 return true,reward.text
end
function Service.Queue(p)
 if not state(p) or not p:GetAttribute('loaded') then return false,'Chargement en cours' end
 if state(p).stage<4 then return false,'Termine ta première amélioration.' end
 if round then return false,'Une course est en cours. Reviens a la fin.' end
 if not lobby then lobby={at=os.clock()+8,players={}} end
 local count=0;for _ in lobby.players do count+=1 end
 if count>=6 and not lobby.players[p] then return false,'Course complete' end
 lobby.players[p]=true;push(p);return true,'Inscrit !'
end
local function stopRound()
 if not round then return end
 local finished=round;round=nil;raceFolder.Parent=SS
 local entries={};for p,r in finished.players do table.insert(entries,{p=p,r=r}) end
 table.sort(entries,function(a,b)if a.r.score==b.r.score then return a.r.lastPoint<b.r.lastPoint end return a.r.score>b.r.score end)
 for rank,item in entries do
  local p,r=item.p,item.r;local s=state(p)
  if s then
   s.bestRace=math.max(s.bestRace,r.score)
   if #entries>1 and rank==1 and r.score>0 then s.wins+=1 end
   Stats:add(p,'Coins',r.score*75+(r.score>0 and rank==1 and #entries>1 and 300 or 0))
   p:SetAttribute('GiftRushRacing',false)
   p:SetAttribute('GiftRushResult',#entries==1 and ('Entrainement : '..r.score..' cadeaux. Record : '..s.bestRace) or ('Place '..rank..' / '..#entries..' — '..r.score..' cadeaux'))
   local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if h then h.WalkSpeed=(p:GetAttribute('DefaultSpeed') or 16)+(p:GetAttribute('AddSpeed') or 0);h.JumpPower=r.jumpPower end
   push(p)
  end
 end
end
local function beginRound()
 local waiting=lobby;lobby=nil;local now=os.clock()
 round={ends=now+120,players={}};raceFolder.Parent=workspace
 for p in waiting.players do
  local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  if state(p) and root and h and h.Health>0 then
   root.CFrame=workspace.areas.Spawn.CFrame+Vector3.new(0,5,0)
   p:SetAttribute('GiftRushRacing',true);p:SetAttribute('GiftRushResult','')
   round.players[p]={score=0,lastPoint=now,checkpoint=root.Position,jumpPower=h.JumpPower,lastPosition=root.Position,lastSample=now}
   h.WalkSpeed=20;h.JumpPower=50
  end
 end
 if next(round.players)==nil then round=nil;raceFolder.Parent=SS end
end
local function collect(p,index)
 local r=round and round.players[p]
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
 if not r or not root or not h or h.Health<=0 or os.clock()>=round.ends then return end
 if index~=r.score%#route+1 or (root.Position-route[index]).Magnitude>10 then return end
 local elapsed=os.clock()-r.lastPoint
 -- Server distance and plausible minimum travel time, never client-declared score.
 if elapsed<math.max(.7,(route[index]-r.checkpoint).Magnitude/32-.4) then return end
 r.score+=1;r.lastPoint=os.clock();r.checkpoint=route[index];push(p)
end
local function buildCourse()
 local template=workspace.gifts:FindFirstChildWhichIsA('Model')
 if not template then return end
 for i,pos in route do
  local model=template:Clone();model.Name='Course'..i
  for _,n in model:GetDescendants() do
   if n:IsA('LuaSourceContainer') or n:IsA('BillboardGui') or n:IsA('SurfaceGui') then n:Destroy()
   elseif n:IsA('BasePart') then n.Anchored=true;n.CanCollide=false end
  end
  local _,size=model:GetBoundingBox();model:ScaleTo(model:GetScale()*4/math.max(1,size.Y))
  model:PivotTo(CFrame.new(pos));model.Parent=raceFolder
  local prompt=Instance.new('ProximityPrompt');prompt.Name='CoursePrompt';prompt.ActionText='Collecter';prompt.ObjectText='Course · '..i..' / 8';prompt.HoldDuration=.15;prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=false;prompt.Parent=model.PrimaryPart
  prompt.Triggered:Connect(function(p)collect(p,i)end)
  model:SetAttribute('CourseIndex',i)
  raceModels[i]=model
 end
end
Data.profileLoaded:Connect(function(profile,p)
 profiles[p]=profile
 local s=profile.giftRush or Rewards.New();profile.giftRush=s
 for k,v in Rewards.New() do if s[k]==nil then s[k]=v end end
 Rewards.Join(s,os.time());refresh(p)
 p:GetAttributeChangedSignal('SelectedBackpack'):Connect(function() completeIntro(p) end)
 task.spawn(function()
  while p.Parent==Players and not p:GetAttribute('loaded') do task.wait(.1) end
  if p.Parent==Players then completeIntro(p);push(p) end
 end)
end)
Players.PlayerRemoving:Connect(function(p)
 local s=state(p);if s then s.lastSeen=os.time() end
 profiles[p]=nil;limits[p]=nil
 if lobby then lobby.players[p]=nil end
 if round then round.players[p]=nil end
end)
request.OnServerInvoke=function(p,action)
 if type(action)~='string' or #action>20 then return false,'Requete invalide' end
 local now=os.clock();local bucket=limits[p] or {at=now,count=0};limits[p]=bucket
 if now-bucket.at>1 then bucket.at=now;bucket.count=0 end
 bucket.count+=1;if bucket.count>6 then return false,'Attends un instant' end
 if action=='snapshot' then return Service.Snapshot(p)
 elseif action=='claim' then return Service.Claim(p)
 elseif action=='queue' then return Service.Queue(p)
 elseif action=='upgrade' then return Service.Upgrade(p)
 elseif action=='leave' then
  if lobby then lobby.players[p]=nil end
  if round and round.players[p] then
   local r=round.players[p];round.players[p]=nil;p:SetAttribute('GiftRushRacing',false)
   local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
   if h then h.WalkSpeed=(p:GetAttribute('DefaultSpeed') or 16)+(p:GetAttribute('AddSpeed') or 0);h.JumpPower=r.jumpPower end
  end
  push(p);return true,'Course quittée.'
 end
 return false,'Action inconnue'
end
raceFolder.Parent=SS
task.spawn(function()
 local deadline=os.clock()+30
 repeat task.wait(.5) until workspace.gifts:FindFirstChildWhichIsA('Model') or os.clock()>deadline
 buildCourse()
end)
game:GetService('RunService').Heartbeat:Connect(function()
 if not round then return end
 for p,r in round.players do
  local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
  local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
  local now=os.clock()
  if not root or not h or h.Health<=0 or (root.Position-r.lastPosition).Magnitude>math.max(12,(now-r.lastSample)*40) then
   round.players[p]=nil;p:SetAttribute('GiftRushRacing',false);p:SetAttribute('GiftRushResult','Course interrompue. Tu peux réessayer.')
   if h then h.WalkSpeed=(p:GetAttribute('DefaultSpeed') or 16)+(p:GetAttribute('AddSpeed') or 0);h.JumpPower=r.jumpPower end
   push(p)
  else r.lastPosition=root.Position;r.lastSample=now end
 end
end)
task.spawn(function()
 while true do
  if lobby and os.clock()>=lobby.at then beginRound() end
  if round and os.clock()>=round.ends then stopRound() end
  for p,profile in profiles do
   profile.giftRush.lastSeen=os.time()
   if round and round.players[p] then local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if h then h.WalkSpeed=20;h.JumpPower=50 end end
   push(p)
  end
  task.wait(1)
 end
end)
return Service
