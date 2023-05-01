local awful = require("awful")
local filesystem = require("gears.filesystem")
local config_dir = filesystem.get_configuration_dir()
local helpers = require("helpers")

local function autostart_apps()
	--- Compositor
	helpers.run.check_if_running("picom", nil, function()
		awful.spawn("picom --config " .. config_dir .. "configuration/picom.conf", false)
	end)
	--- Music Server
	helpers.run.run_once_pgrep("mpd")
	helpers.run.run_once_pgrep("mpDris2")
	--- Polkit Agent
	--	helpers.run.run_once_ps(
	--		"polkit-gnome-authentication-agent-1",
	--		"/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
	--	)
	--- System app
	helpers.run.run_once_pgrep("sus.sh")
	helpers.run.run_once_pgrep("bingwall.sh")
	helpers.run.run_once_pgrep("optimus-manager-qt")
	helpers.run.run_once_pgrep("xinput set-prop 'SynPS/2 Synaptics TouchPad' 'libinput Tapping Enabled' 1")
	helpers.run.run_once_pgrep("xinput set-prop 'SynPS/2 Synaptics TouchPad' 'libinput Natural Scrolling Enabled' 1 ")
	helpers.run.run_once_pgrep("xset -dpms")
	helpers.run.run_once_pgrep("xset s off")
	helpers.run.run_once_pgrep("mailspring -b")
	helpers.run.run_once_pgrep("python /home/stefanj/.scripts/toggle.py")
	--	helpers.run.run_once_pgrep("toggle.sh")

	--- Other stuff
	helpers.run.run_once_grep("blueman-applet")
	helpers.run.run_once_grep("nm-applet")
end

autostart_apps()
