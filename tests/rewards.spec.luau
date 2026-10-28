local R=require('../src/shared/Rewards')
local n=0
local function check(v,label)assert(v,label);n+=1 end
local s=R.New();local now=20000*86400+500
R.Join(s,now);check(R.CanClaim(s,now),'First claim')
check(R.Claim(s,now).pet=='NormalPet1','Guaranteed starting pet')
check(R.Claim(s,now)==nil,'No double daily claim')
check(s.visits==1,'Idempotent visit count')
R.Join(s,now+3*86400);check(R.Bonus(s)==1.05,'Absence reduces temporary bonus')
check(s.visits==1,'Absence keeps calendar progress')
R.Opened(s);R.Opened(s);check(s.reduced,'Return challenge needs three gifts')
R.Opened(s);check(R.Bonus(s)==1.10,'Bonus restored')
for i=1,6 do R.Claim(s,now+i*86400) end
check(s.visits==7,'Seven cumulative claims');check(R.Day(s)==1,'Calendar loops')
check(R.Calendar[7].pet=='NormalPet4','Guaranteed legendary at seventh visit')
local boundary=R.New();R.Claim(boundary,now)
check(R.CanClaim(boundary,R.NextAt(now)),'Claim becomes available at server day boundary')
check(s.opened==3,'Recorded actual opens')
print(n..' reward scenarios passed')
