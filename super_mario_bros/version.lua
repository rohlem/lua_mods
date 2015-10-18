require "base"

smb.versions = {
	{"original (Japan, USA)", "NES"},
	{"USA arcade", "Nintendo PlayChoice-10"}, --arcade
	{"re-release", "FDS"},
	{"Game & Watch port", "G&W"},
	{"Vs. Super Mario Bros.", "arcade"},
	{"All Night Nippon Super Mario Bros.", "FDS"},
	{"2-in-1 Super Mario Bros./Duck Hunt (USA)", "NES"},
	{"Super Mario Bros./Tetris/Nintendo World Cup (EUR)", "NES"}, --also 3-in-1?
	{"3-in-1 Super Mario Bros./Duck Hunt/World Class Track Meet", "NES"},
	{"Nintendo World Championship 1990", "NES"},
	{"Super Mario All-Stars", "SNES"},
	{"Super Mario All-Stars + Super Mario World", "SNES"},
	{"Super Mario Bros. Deluxe", "GBC"},
	{"Animal Crossing in-game NES", "GCN"},
	{"NES Classic", "GBA"},
	{"Virtual Console", "Wii"},
	{"Super Smash Bros. Brawl Demo", "Wii"},
	{"Super Mario All-Stars Limited Edition", "Wii"},
	{"25th Anniversary Remake (Virtual Console)", "Wii"},
	{"Virtual Console", "3DS"},
	{"Virtual Console", "Wii U"},
	{"NES Remix", "Wii U"},
	{"Super Luigi Bros. (NES Remix 2)", "Wii U"},
	{"Ultimate NES Remix", "3DS"},
	{"Speed Mario Bros.", "3DS"}
}
--Planned feature: automatic version detection
--for now simply assume we're getting 00 (Original, NES)
smb.version = 0
