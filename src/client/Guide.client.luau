-- One objective, one highlighted destination. All rewards are server-owned.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Input=game:GetService('UserInputService')
local p=Players.LocalPlayer
local rootFolder=RS:WaitForChild('GiftRush')
local request=rootFolder:WaitForChild('Request')
local Rewards=require(rootFolder.Rewards)
local gui=Instance.new('ScreenGui');gui.Name='MysteryPets';gui.ResetOnSpawn=false;gui.DisplayOrder=25;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=p:WaitForChild('PlayerGui')
local purple=Color3.fromRGB(76,38,114)
local orange=Color3.fromRGB(255,176,65)
local ink=Color3.fromRGB(38,27,57)
local function make(class,parent,props)
 local n=Instance.new(class)
 for k,v in props do n[k]=v end
 n.Parent=parent;return n
end
local function round(frame,radius)
 make('UICorner',frame,{CornerRadius=UDim.new(0,radius or 16)})
end
local function label(parent,text,pos,size,fontSize,color)
 return make('TextLabel',parent,{BackgroundTransparency=1,Text=text,Position=pos,Size=size,Font=Enum.Font.GothamBold,TextSize=fontSize or 18,TextColor3=color or ink,TextWrapped=true})
end
local function button(parent,text,pos,size,callback)
 local b=make('TextButton',parent,{Text=text,Position=pos,Size=size,BackgroundColor3=purple,TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBold,TextSize=17,AutoButtonColor=true})
 round(b,12);b.Activated:Connect(callback);return b
end
local card=make('Frame',gui,{Name='Objective',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,8),Size=UDim2.fromOffset(430,104),BackgroundColor3=Color3.fromRGB(255,248,229)})
round(card);make('UIStroke',card,{Color=purple,Thickness=2})
local scale=make('UIScale',card,{Scale=1})
label(card,'MYSTERY PETS  •  BOÎTES HANTÉES',UDim2.fromOffset(14,6),UDim2.new(1,-28,0,20),12,purple)
local title=label(card,'Préparation de ta chasse…',UDim2.fromOffset(12,30),UDim2.new(1,-24,0,29),22)
local subtitle=label(card,'Ton rayon sera équipé automatiquement.',UDim2.fromOffset(15,64),UDim2.new(1,-30,0,32),15)
local notice=label(gui,'',UDim2.new(.5,-210,0,116),UDim2.fromOffset(420,46),16,Color3.new(1,1,1));notice.TextStrokeTransparency=.35
local bar=make('Frame',gui,{Name='Activities',AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,120),Size=UDim2.fromOffset(154,190),BackgroundTransparency=1,Visible=false})
local dailyButton,albumButton,raceButton
local panel=make('Frame',gui,{Name='ActivityPanel',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(560,410),BackgroundColor3=Color3.fromRGB(255,248,229),Visible=false})
round(panel);make('UIStroke',panel,{Color=purple,Thickness=3})
local panelScale=make('UIScale',panel,{Scale=1})
local heading=label(panel,'',UDim2.fromOffset(20,13),UDim2.new(1,-85,0,35),24,purple)
button(panel,'×',UDim2.new(1,-52,0,13),UDim2.fromOffset(36,36),function()panel.Visible=false end)
local body=make('ScrollingFrame',panel,{Position=UDim2.fromOffset(18,58),Size=UDim2.new(1,-36,1,-130),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new()})
local layout=make('UIListLayout',body,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
local footer=label(panel,'',UDim2.new(0,16,1,-67),UDim2.new(1,-192,0,54),13)
local state={ready=false};local page;local busy=false
local renderPanel
local function invoke(action)
 if busy then return end;busy=true
 local ok,a,b=pcall(function()return request:InvokeServer(action)end)
 busy=false
 if ok then
  if action=='snapshot' and type(a)=='table' then state=a
  else notice.Text=b or (a and 'C’est fait !' or 'Réessaie dans un instant.');task.delay(5,function()notice.Text='' end) end
 else notice.Text='Connexion en cours…' end
 if renderPanel then renderPanel() end
end
local actionButton=button(panel,'',UDim2.new(1,-169,1,-58),UDim2.fromOffset(151,43),function()
 if page=='daily' then invoke('claim') elseif page=='race' then invoke(state.race and (state.race.active or state.race.queued) and 'leave' or 'queue') end
end)
local tiers={Common='Commun',Uncommon='Peu commun',Rare='Rare',Epic='Épique',Legendary='Légendaire'}
local colors={Common=Color3.fromRGB(171,180,197),Uncommon=Color3.fromRGB(99,193,136),Rare=Color3.fromRGB(88,156,237),Epic=Color3.fromRGB(184,106,232),Legendary=orange}
renderPanel=function()
 if not panel.Visible or not state.ready then return end
 for _,child in body:GetChildren() do if child~=layout then child:Destroy() end end
 if page=='daily' then
  heading.Text='Un cadeau à chaque retour'
  for i,reward in Rewards.Calendar do
   local row=make('Frame',body,{LayoutOrder=i,Size=UDim2.new(1,-6,0,53),BackgroundColor3=(i==state.nextDay and orange or Color3.fromRGB(237,226,244))});round(row,10)
   make('ImageLabel',row,{Position=UDim2.fromOffset(9,5),Size=UDim2.fromOffset(42,42),BackgroundTransparency=1,Image=reward.icon})
   label(row,'Jour '..i..'  •  '..reward.text,UDim2.fromOffset(58,4),UDim2.new(1,-68,1,-8),16)
  end
  actionButton.Visible=true;actionButton.Text=state.canClaim and 'Récupérer' or 'Déjà reçu'
  footer.Text=state.canClaim and 'Ta progression reste acquise si tu fais une pause.' or 'Prochain cadeau demain (jour UTC).'
 elseif page=='album' then
  heading.Text='Ma collection'
  local count=0
  for i,pet in state.catalog do
   local owned=state.album[pet.name]==true;if owned then count+=1 end
   local row=make('Frame',body,{LayoutOrder=i,Size=UDim2.new(1,-6,0,65),BackgroundColor3=owned and Color3.fromRGB(237,226,244) or Color3.fromRGB(221,221,225)});round(row,10)
   make('ImageLabel',row,{Position=UDim2.fromOffset(8,8),Size=UDim2.fromOffset(48,48),BackgroundTransparency=1,Image=pet.image or '',ImageTransparency=owned and 0 or .65})
   label(row,(owned and '✓  ' or '?  ')..pet.displayName..'  •  '..(tiers[pet.tier] or pet.tier or 'Commun'),UDim2.fromOffset(63,8),UDim2.new(1,-76,1,-16),16,colors[pet.tier] or purple)
  end
  actionButton.Visible=false;footer.Size=UDim2.new(1,-32,0,54)
  footer.Text=count..' / '..#state.catalog..' compagnons. Récompenses garanties à 8, 25 et 60 boîtes. Tes compagnons restent acquis après un prestige.'
 else
  heading.Text='Course aux boîtes • 2 minutes'
  local r=state.race or {}
  label(body,r.active and ('Temps : '..r.remaining..' s  •  '..r.score..' boîtes') or (r.queued and ('Départ dans '..r.countdown..' s') or 'Suis les boîtes numérotées dans l’ordre.'),UDim2.new(),UDim2.new(1,-6,0,55),18)
  for i,row in r.standings or {} do label(body,i..'. '..row.name..'  •  '..row.score,UDim2.new(),UDim2.new(1,-6,0,36),17).LayoutOrder=i end
  footer.Size=UDim2.new(1,-192,0,54);footer.Text=r.result and r.result~='' and r.result or '75 pièces par boîte. Seul : entraînement. Plusieurs : 300 pièces au vainqueur.'
  actionButton.Visible=true;actionButton.Text=(r.active or r.queued) and 'Quitter' or 'Participer'
 end
end
local function open(which)page=which;panel.Visible=true;footer.Size=UDim2.new(1,-192,0,54);renderPanel() end
dailyButton=button(bar,'Cadeau du jour',UDim2.fromOffset(0,0),UDim2.fromOffset(154,44),function()open('daily')end)
albumButton=button(bar,'Ma collection',UDim2.fromOffset(0,51),UDim2.fromOffset(154,44),function()open('album')end)
raceButton=button(bar,'Course · 2 min',UDim2.fromOffset(0,102),UDim2.fromOffset(154,44),function()open('race')end)
button(bar,'Crédits',UDim2.fromOffset(34,155),UDim2.fromOffset(120,30),function()
 page='credits';panel.Visible=true;heading.Text='Créateurs et ressources gratuites'
 for _,child in body:GetChildren() do if child~=layout then child:Destroy() end end
 local credits=rootFolder:FindFirstChild('Credits')
 label(body,credits and credits.Value or 'Base Presents Simulator : Jumpathy / tyler2021.',UDim2.new(),UDim2.new(1,-6,0,245),14)
 footer.Text='Sources et licences complètes dans le dossier Assets.';actionButton.Visible=false
end)
local buy=button(card,'Acheter le sac · 80 pièces',UDim2.fromOffset(16,65),UDim2.new(1,-32,0,32),function()invoke('upgrade')end);buy.Visible=false
local target,point,highlight,beam,a0,a1,hint
local function clearTarget()
 for _,n in {highlight,beam,a0,a1,hint} do if n then n:Destroy() end end
 highlight=nil;beam=nil;a0=nil;a1=nil;hint=nil;target=nil;point=nil
end
local function setTarget(object,part,text)
 if target==object and point==part then if hint then hint.TextLabel.Text=text end return end
 clearTarget();if not part then return end
 target=object;point=part
 highlight=make('Highlight',gui,{Adornee=object,FillColor=orange,OutlineColor=Color3.new(1,1,1),FillTransparency=.65,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})
 hint=make('BillboardGui',part,{Name='MysteryHint',Adornee=part,Size=UDim2.fromOffset(210,48),StudsOffset=Vector3.new(0,4,0),AlwaysOnTop=true})
 local t=label(hint,text,UDim2.new(),UDim2.fromScale(1,1),20,Color3.new(1,1,1));t.Name='TextLabel';t.TextStrokeTransparency=.15
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 if root then
  a0=make('Attachment',root,{});a1=make('Attachment',part,{})
  beam=make('Beam',root,{Attachment0=a0,Attachment1=a1,Width0=.3,Width1=.3,FaceCamera=true,Color=ColorSequence.new(orange),Transparency=NumberSequence.new(.2)})
 end
end
local function nearestGift(root)
 local best,dist=nil,math.huge
 for _,gift in workspace.gifts:GetChildren() do
  if gift:IsA('Model') and gift.PrimaryPart and not gift:GetAttribute('Destroyed') and gift:GetAttribute('Region')=='area1' then
   local d=(gift.PrimaryPart.Position-root.Position).Magnitude
   if d<dist then best=gift;dist=d end
  end
 end
 return best
end
local function equip()
 if p:GetAttribute('GiftRushRacing') then return end
 local char=p.Character;local hum=char and char:FindFirstChildOfClass('Humanoid')
 local bag=p:FindFirstChildOfClass('Backpack')
 if hum and bag and not char:FindFirstChildOfClass('Tool') then
  local tool=bag:FindFirstChildWhichIsA('Tool');if tool then hum:EquipTool(tool) end
 end
end
p.CharacterAdded:Connect(function()clearTarget();task.delay(1,equip)end)
p:GetAttributeChangedSignal('GiftRushNotice'):Connect(function()
 local text=p:GetAttribute('GiftRushNotice');notice.Text=text or '';task.delay(6,function()if notice.Text==text then notice.Text='' end end)
end)
rootFolder.Changed.OnClientEvent:Connect(function(s)if type(s)=='table' then state=s;if page~='credits' then renderPanel() end end end)
task.spawn(function()while not state.ready do invoke('snapshot');task.wait(1) end end)
local native=p.PlayerGui:WaitForChild('UI')
local left=native.Container.LeftContainer
local bottom=native.Container.Bottom.Menu
bottom.Coins.Add.Visible=false
left.Shop.Visible=false
native.Buttons.Visible=false
local nativeWords={Pets='Compagnons',Inventory='Compagnons',Settings='Options',Rebirth='Prestige',Close='Fermer',Equip='Équiper',Unequip='Retirer',Yes='Oui',No='Non',Claim='Récupérer',['Sound effects']='Sons',['Other pets visible']='Compagnons des autres',Music='Musique'}
for _,n in native:GetDescendants() do if n:IsA('TextLabel') or n:IsA('TextButton') then if nativeWords[n.Text] then n.Text=nativeWords[n.Text] end end end
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.3 then return end;elapsed=0
 local camera=workspace.CurrentCamera
 if camera then
  local v=camera.ViewportSize;scale.Scale=math.clamp((v.X-25)/430,.65,1);panelScale.Scale=math.min(1,(v.X-24)/560,(v.Y-80)/410)
 end
 if not state.ready then return end
 equip()
 local stage=state.stage or 1
 local char=p.Character;local root=char and char:FindFirstChild('HumanoidRootPart')
 local toys=p:FindFirstChild('leaderstats') and p.leaderstats:FindFirstChild('Toys')
 local amount=toys and tonumber(toys.Real.Value) or 0
 local limit=tonumber(p:GetAttribute('backpackSize')) or 50
 bottom.Presents.Label.Text='Sac '..amount..' / '..limit
 bottom.Coins.Label.Text='Pièces '..p.leaderstats.Coins.Value
 left.Pets.Visible=stage>=4;left.Rebirth.Visible=stage>=4;bar.Visible=stage>=4
 buy.Visible=false;subtitle.Visible=true
 if state.race and state.race.active then
  title.Text='Boîte '..state.race.nextTarget..' : cours et récupère !'
  subtitle.Text=state.race.remaining..' s restantes • '..state.race.score..' boîtes'
  local folder=workspace:FindFirstChild('GiftRushCourse')
  local model=folder and folder:FindFirstChild('Course'..state.race.nextTarget)
  if model then setTarget(model,model.PrimaryPart,'RÉCUPÈRE CETTE BOÎTE') end
 elseif stage==3 then
  title.Text='3 / 3 • Achète un sac plus grand'
  local pos=workspace.areas.area1.shop.ZonePart
  if root and (root.Position-pos.Position).Magnitude<25 then buy.Visible=true;subtitle.Visible=false
  else subtitle.Text='Suis le trait doré jusqu’à la boutique.' end
  setTarget(workspace.areas.area1.shop.Shop,workspace.areas.area1.shop.ShopPart,'BOUTIQUE • SAC À 80 PIÈCES')
 elseif stage==2 and amount>0 or stage>=4 and amount>=limit then
  title.Text=stage<4 and '2 / 3 • Vends ce que tu as trouvé' or 'Ton sac est plein : va vendre !'
  subtitle.Text='Suis le trait doré. Entre dans le cercle VENDRE.'
  setTarget(workspace.areas.area1.sell,workspace.areas.area1.sell.Zone,'VENDRE • GAGNER DES PIÈCES')
 else
  title.Text=stage==1 and '1 / 3 • Ouvre la boîte dorée' or 'Ouvre des boîtes, collectionne les compagnons'
  local nextGoal=state.opened<8 and 8 or state.opened<25 and 25 or state.opened<60 and 60 or nil
  subtitle.Text=stage<4 and ((Input.TouchEnabled and 'Touche' or 'Clique sur')..' la boîte avec ton rayon équipé.') or (nextGoal and (state.opened..' / '..nextGoal..' boîtes pour le prochain compagnon garanti') or 'Améliore ton équipement et découvre les autres zones.')
  if root then
   local gift=target and target.Parent==workspace.gifts and not target:GetAttribute('Destroyed') and target or nearestGift(root)
   if gift then setTarget(gift,gift.PrimaryPart,'OUVRE CETTE BOÎTE') else clearTarget() end
  end
 end
 local course=workspace:FindFirstChild('GiftRushCourse')
 if course then for _,model in course:GetChildren() do
  local active=state.race and state.race.active and model:GetAttribute('CourseIndex')==state.race.nextTarget
  for _,n in model:GetDescendants() do if n:IsA('ProximityPrompt') then n.Enabled=active==true elseif n:IsA('BasePart') then n.LocalTransparencyModifier=active and 0 or .85 end end
 end end
end)
