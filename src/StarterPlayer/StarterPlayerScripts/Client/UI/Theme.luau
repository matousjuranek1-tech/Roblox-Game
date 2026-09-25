--!strict
--[[
	Theme
	"Cinematic minimal" UI palette and typography (see docs/01_KONCEPT.md §10).
	Ivory text on dark translucent panels, ember orange as the only accent. Red, yellow and cyan
	are reserved for danger, parry and weak points / grapple, as in the world itself.
]]

local Theme = {
	Colors = {
		Ivory = Color3.fromRGB(245, 238, 225),
		Muted = Color3.fromRGB(160, 165, 175),
		Ember = Color3.fromRGB(255, 140, 60),
		Danger = Color3.fromRGB(255, 86, 70),
		Cyan = Color3.fromRGB(80, 222, 255),
		Panel = Color3.fromRGB(12, 14, 18),
		Gold = Color3.fromRGB(255, 200, 70),
		Silver = Color3.fromRGB(205, 212, 222),
		Bronze = Color3.fromRGB(205, 135, 80),
	},
	PanelTransparency = 0.35,
	Fonts = {
		Title = Font.fromEnum(Enum.Font.BuilderSansExtraBold),
		Bold = Font.fromEnum(Enum.Font.BuilderSansBold),
		Body = Font.fromEnum(Enum.Font.BuilderSansMedium),
		Mono = Font.fromEnum(Enum.Font.RobotoMono),
	},
}

return Theme
