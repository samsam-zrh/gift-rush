local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local Rewards=require(RS.GiftRush.Rewards)
local Service=require(game.ServerScriptService.GiftRushService)
local network=require(RS.shared.network)
local subscribed={}
network:createRemoteFunction('nextRewards',function()return Rewards.Calendar end)
network:createRemoteEvent('dailyRewardTransmitter',function(player,action)
 if action=='beginTransmissions' then subscribed[player]=true
 elseif action=='claimDaily' then Service.Claim(player) end
end)
Players.PlayerRemoving:Connect(function(p)subscribed[p]=nil end)
while true do
 for p in subscribed do
  local s=Service.Snapshot(p)
  if s.ready then
   network:fireClient('dailyRewardTransmitter',p,'newStreak',s.visits)
   network:fireClient('dailyRewardTransmitter',p,s.canClaim and 'canClaim' or 'countdown',math.max(0,s.nextAt-os.time()))
  end
 end
 task.wait(1)
end
