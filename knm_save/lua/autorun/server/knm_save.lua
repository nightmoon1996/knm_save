if not SERVER then return end

/* Config Below Here */
/* Config Below Here */
/* Config Below Here */
K.CONFIG = {}
K.CONFIG.saveweapons = true
K.CONFIG.saveteam = true
K.CONFIG.saveposition = true
K.CONFIG.savemodel = true
K.CONFIG.savehealth = true
K.CONFIG.savearmor = true 
K.CONFIG.teams = {TEAM_TROOPER} -- team that doesn't save data
K.CONFIG.auto_save_time = 5*60 --Time between each saves (IN SECONDS)
K.CONFIG.print = true -- Print a message in the console when the server as saved the player's data
K.CONFIG.dontsavedamage = true -- don't save if player being damaged
K.CONFIG.dontsavecooldown = 60 -- time for above (IN SECONDS)
K.CONFIG.cooldownfinish = "Your data have been saved."
K.CONFIG.cooldownstart = "Wait "..K.CONFIG.dontsavecooldown.." before leaving, or you lost your data."


/* Don't Edit Anything Here!!! */
/* Don't Edit Anything Here!!! */
/* Don't Edit Anything Here!!! */
local plyMeta = FindMetaTable("Player")


function plyMeta:KNMLoad()

	local read = file.Read( "knm_save/"..string.lower(game.GetMap()).."/" .. self:SteamID64() .. ".txt", "DATA" )
	if not file.Exists( "knm_save", "DATA" ) then file.CreateDir( "knm_save", "DATA" ) return end
	if not file.Exists("knm_save/"..string.lower(game.GetMap()),"DATA") then file.CreateDir( "knm_save/"..string.lower(game.GetMap()), "DATA" ) end
	if not file.Exists("knm_save/"..string.lower(game.GetMap()).."/"..self:SteamID64()..".txt", "DATA") then 
		local data = {pos = Vector(0,0,0), team = TEAM_MINEUR, weapon = {""}}
			file.Write("knm_save/"..string.lower(game.GetMap()).."/"..self:SteamID64()..".txt", util.TableToJSON(data) )  return 
		end
	
local things = util.JSONToTable(read)

	return things
end 

function plyMeta:KNMSaveThings()
	if not self:Alive() then return end
	if not file.Exists( "knm_save", "DATA" ) then file.CreateDir( "knm_save", "DATA" ) end
	if not file.Exists("knm_save/"..string.lower(game.GetMap()),"DATA") then file.CreateDir( "knm_save/"..string.lower(game.GetMap()), "DATA" ) end
	local weapondata ={}
	local ammodata = {}
	local datapos, datateam, datamodel, dataarmor, datahealth
	if K.CONFIG.saveweapons then 
		for k,v in ipairs(self:GetWeapons()) do
				table.insert(weapondata,k, v:GetClass())

				if v:GetPrimaryAmmoType() != -1 then
					if ammodata[v:GetPrimaryAmmoType()] then 
						if ammodata[v:GetPrimaryAmmoType()].ammotype then
							if ammodata[v:GetPrimaryAmmoType()].ammotype == v:GetPrimaryAmmoType() then continue end
						end
					end
					table.insert(ammodata,v:GetPrimaryAmmoType(), {ammotype = v:GetPrimaryAmmoType(), ammonum = self:GetAmmoCount(v:GetPrimaryAmmoType())})
				end
		end
	end
		if K.CONFIG.saveposition then datapos = self:GetPos() end
		if K.CONFIG.savemodel then datamodel = self:GetModel() end
		if K.CONFIG.saveteam then datateam = self:Team() end
		if K.CONFIG.savehealth then datahealth = {hp = self:Health(),maxhp = self:GetMaxHealth()} end
		if K.CONFIG.savearmor then dataarmor = self:Armor() end
	local data = {pos = datapos, team = datateam, weapon = weapondata, ammo = ammodata, model = datamodel, health = datahealth, armor = dataarmor}

	if self:GetNWBool("savecooldown") then data = {"no"} end

		file.Write("knm_save/"..string.lower(game.GetMap()).."/"..self:SteamID64()..".txt", util.TableToJSON(data) )  
end

hook.Add("PlayerDisconnected", "knmsavethings", function(ply)
	ply:KNMSaveThings()

end)

hook.Add("ShutDown", "ShutDownKNMSaveThings", function()

for k,v in pairs(player.GetAll()) do
	v:KNMSaveThings()
end
if K.CONFIG.print then
	print("[SAVE MODULE]DATA SAVED FOR ALL PLAYERS")
end

end)

hook.Add("PlayerInitialSpawn", "loadthings", function(ply)

		local data = ply:LoadThings()
		if not data then return end
		if data == "no" then return end
	if table.HasValue(K.CONFIG.teams, data.team) then return end

		timer.Simple(1, function()
			if K.CONFIG.saveteam  then
				ply:SetTeam(data.team)
				ply:ConCommand("say /job "..team.GetName(data.team))
				ply:Spawn()
			end

			if K.CONFIG.saveposition  then
				ply:SetPos(data.pos)
			end

			if K.CONFIG.saveweapons  then
				if data.weapon then
				 for k,v in pairs(data.weapon) do
	 				ply:Give(v)
				 end
				 for k,v in pairs(data.ammo) do
				 		ply:SetAmmo(v.ammonum,v.ammotype)		
				 end
				end
			end

			if K.CONFIG.savemodel  then
				ply:SetModel(data.model)
			end

			if K.CONFIG.savehealth  then
				ply:SetMaxHealth(data.health.maxhp)
				ply:SetHealth(data.health.hp)
			end

			if K.CONFIG.savearmor then
				ply:SetArmor(data.armor)
			end
		end)
end)

hook.Add("EntityTakeDamage", "DontSaveWhenDamage", function(target, damage)
	if !K.CONFIG.dontsavedamage then return end
	if !target:IsPlayer() then return end
	if damage:GetAttacker() == target then return end
	if not (damage:GetAttacker():IsNPC() or damage:GetAttacker():IsPlayer()) then return end
		if target:GetNWBool("savecooldown", false) then 
				timer.Adjust("savecooldown"..target:UniqueID(), K.CONFIG.dontsavecooldown, 1, function() if IsValid(target) then target:PrintMessage(HUD_PRINTTALK,K.CONFIG.cooldownfinish) target:SetNWBool("savecooldown", false) end end)
		else
			target:SetNWBool("savecooldown", true)
			target:PrintMessage(HUD_PRINTTALK,K.CONFIG.cooldownstart)
			timer.Create("savecooldown"..target:UniqueID(), K.CONFIG.dontsavecooldown, 1, function() if IsValid(target) then target:PrintMessage(HUD_PRINTTALK,K.CONFIG.cooldownfinish) target:SetNWBool("savecooldown", false) end end)
		end
end)

hook.Add("PlayerDeath", "removecooldowndeath", function(ply)
	if timer.Exists("savecooldown"..ply:UniqueID()) then timer.Destroy("savecooldown"..ply:UniqueID()) target:SetNWBool("savecooldown", false) end

end)

timer.Create("SaveThingsAuto", K.CONFIG.auto_save_time, 0, function() 
local time = 0
	for k,v in pairs(player.GetAll()) do
		timer.Simple(time, function() 
			v:KNMSaveThings()
		end)
		time = time+0.5
	end
if K.CONFIG.print then
	print("[KNM Save]DATA SAVED FOR ALL PLAYERS")
end

end)

print("Kaname Save Module Loaded")