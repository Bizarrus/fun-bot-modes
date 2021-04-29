class('FunBotModes');

require('Config');

function FunBotModes:__init()
	self.botMod = false;
	Events:Subscribe('Engine:Update', self, self.__update);
	Events:Subscribe('Level:Loaded', self, self.OnLevelLoaded);
	Events:Subscribe('Extension:Unloading', self, self.OnModUnloaded);
	Events:Subscribe('Extension:Loaded', self, self.OnModLoaded);
end

function FunBotModes:__update()
	-- Check if fun-bots available
	local result = RCON:SendCommand('modList.ListRunning');
	
	for _, mod in pairs(result) do
		if mod == 'fun-bots' and self.botMod == false then
			print('[fun-bot Modes] fun-bots now available.');
			self.botMod = true;
			
			-- Re-Fire method when the mod was not available before
			self:OnModLoaded();
		end
	end
end

function FunBotModes:OnModUnloaded()
	self.botMod = false;
end

function FunBotModes:OnModLoaded()
	self:Start(SharedUtils:GetCurrentGameMode());
end

function FunBotModes:OnLevelLoaded(map, mode)
	self:Start(mode);
end

function FunBotModes:Start(mode)
	local players = 6; -- Default Bots
	
	-- Ignore, if fun-bots not available
	if mode == nil then
		print('[fun-bot Modes] No mode is available (Server is currently starting?)');
		return;
	end
	
	if self.botMod == false then
		print('[fun-bot Modes] fun-bot mod is not available!');
		return;
	end
	
	-- Detect custom game modes
	local customMode = ServerUtils:GetCustomGameModeName();
	
	if customMode ~= nil then
		mode = customMode;
	end
	
	-- Get game mode from config
	if Config[mode] ~= nil then
		print('[fun-bot Modes] Found Configuration: ' .. tostring(mode) .. ' = ' .. json.encode(Config[mode]));
		players = Config[mode];
	else
		print('[fun-bot Modes] Game mode "' .. tostring(mode) .. '" doesnt exists in Config.lua.');
		return;
	end
	
	-- Update Bot-Settings
	self:Update(players);
end

function FunBotModes:Update(size)
	local players	= { 3, 3 }; -- Default Bots
	local total		= 6;
	
	-- Calculate Teams
	print('[fun-bot Modes] Size-Value type: ' .. type(size));
	
	if type(size) == 'number' then
		players = { (size / 2), (size / 2) };
		total	= size;
		
	elseif type(size) == 'table' then
		players = size;
		total	= 0;
		
		for team, count in pairs(size) do
			total = total + count
		end
	end
	
	-- Kick all Bots
	print('[fun-bot Modes] Kick all Bots');
	RCON:SendCommand('funbots.kickAll');
	
	-- Change Bot-Configuration
	print('[fun-bot Modes] Update Bots-Configuration (manual, initial Bots: ' .. tostring(total) .. ')');
	RCON:SendCommand('funbots.set.config', { 'spawnMode', tostring('manual') });
	RCON:SendCommand('funbots.set.config', { 'initNumberOfBots', tostring(total) });
	
	-- Respawn Bots
	
	for team, count in pairs(players) do
		print('[fun-bot Modes] Respawn Bots (' .. tostring(count) .. ' on Team' .. tostring(team) .. ')');
		RCON:SendCommand('funbots.spawn', { tostring(count), tostring(team) });
	end
end

-- Singleton.
if g_FunBotModes == nil then
	g_FunBotModes = FunBotModes();
end

return g_FunBotModes;
