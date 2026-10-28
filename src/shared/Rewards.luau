-- Gift Rush: server clock, cumulative visits, recoverable attendance bonus.
local Rewards = {}
Rewards.Calendar = {
 {day=1,text='Doggy + 150 pieces',icon='rbxassetid://8119685854',pet='NormalPet1',coins=150},
 {day=2,text='500 pieces',icon='rbxassetid://8083205324',coins=500},
 {day=3,text='Collecte x2 · 5 min',icon='rbxassetid://8108338553',boost='2xT',seconds=300},
 {day=4,text='Kitty garanti',icon='rbxassetid://8119693840',pet='NormalPet2'},
 {day=5,text='1 000 pieces',icon='rbxassetid://8086434045',coins=1000},
 {day=6,text='Rayon x2 · 5 min',icon='rbxassetid://8108354884',boost='2xD',seconds=300},
 {day=7,text='Bear legendaire',icon='rbxassetid://8119693437',pet='NormalPet4'},
}
function Rewards.New()
 return {version=2,visits=0,lastClaimDay=-1,lastSeen=0,reduced=false,returnGifts=0,opened=0,wins=0,bestRace=0,album={},stage=1,starterPet=false,milestones={}}
end
function Rewards.Join(state,now)
 if state.lastSeen>0 and now-state.lastSeen>172800 then state.reduced=true state.returnGifts=0 end
 state.lastSeen=now
end
function Rewards.Day(state) return state.visits%7+1 end
function Rewards.CanClaim(state,now) return math.floor(now/86400)>state.lastClaimDay end
function Rewards.Claim(state,now)
 if not Rewards.CanClaim(state,now) then return nil end
 local reward=Rewards.Calendar[Rewards.Day(state)]
 state.lastClaimDay=math.floor(now/86400)
 state.visits+=1
 return reward
end
function Rewards.Opened(state)
 state.opened+=1
 if state.reduced then
  state.returnGifts+=1
  if state.returnGifts>=3 then state.reduced=false end
 end
end
function Rewards.Bonus(state) return state.reduced and 1.05 or 1.10 end
function Rewards.NextAt(now) return (math.floor(now/86400)+1)*86400 end
return Rewards
