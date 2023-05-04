local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi
local widgets = require("ui.widgets")

local action_level = widgets.button.text.normal({
	normal_shape = gears.shape.circle,
	font = beautiful.icon_font .. "Round ",
	size = 17,
	text_normal_bg = beautiful.accent,
	normal_bg = beautiful.one_bg3,
	text = "",
	paddings = dpi(5),
	animate_size = false,
	on_release = function()
		volume_action_jump()
	end,
})

local osd_value = wibox.widget({
	text = "0%",
	font = beautiful.font_name .. "Medium 13",
	align = "center",
	valign = "center",
	widget = wibox.widget.textbox,
})

local slider = wibox.widget({
	nil,
	{
		id = "volume_slider",
		shape = gears.shape.rounded_bar,
		bar_shape = gears.shape.rounded_bar,
		bar_color = beautiful.grey,
		bar_margins = { bottom = dpi(18), top = dpi(18) },
		bar_active_color = beautiful.accent,
		handle_color = beautiful.accent,
		handle_shape = gears.shape.circle,
		handle_width = dpi(15),
		handle_border_width = dpi(3),
		handle_border_color = beautiful.widget_bg,
		maximum = 150,
		widget = wibox.widget.slider,
	},
	nil,
	expand = "none",
	forced_width = dpi(200),
	layout = wibox.layout.align.vertical,
})

local volume_slider = slider.volume_slider

volume_slider:connect_signal("property::value", function()
	local volume_level = volume_slider:get_value()
	awful.spawn("pamixer --set-volume " .. volume_level .. " --allow-boost", false)

	-- Update textbox widget text
	osd_value.text = string.format("%.0f", volume_level / 150 * 100) .. "%"

	-- Update volume osd
	awesome.emit_signal("module::volume_osd", volume_level)
end)

volume_slider:buttons(gears.table.join(
	awful.button({}, 4, nil, function()
		if volume_slider:get_value() > 150 then
			volume_slider:set_value(150)
			return
		end
		volume_slider:set_value(volume_slider:get_value() + 3)
	end),
	awful.button({}, 5, nil, function()
		if volume_slider:get_value() < 0 then
			volume_slider:set_value(0)
			return
		end
		volume_slider:set_value(volume_slider:get_value() - 3)
	end)
))

local update_slider = function()
	awful.spawn.easy_async_with_shell("pamixer --get-volume", function(stdout)
		-- local value = string.gsub(stdout, "^%s*(.-)%s*$", "%1")
		local value = stdout
		volume_slider:set_value(tonumber(value))
		osd_value.text = string.format("%.0f", value / 150 * 100) .. "%"
	end)
end

-- Update on startup
update_slider()

function volume_action_jump()
	local sli_value = volume_slider:get_value()
	local new_value = 0

	if sli_value >= 0 and sli_value < 75 then
		new_value = 75
	elseif sli_value >= 75 and sli_value < 150 then
		new_value = 150
	else
		new_value = 0
	end
	volume_slider:set_value(new_value)
end

-- The emit will come from the global keybind
awesome.connect_signal("widget::volume", function()
	update_slider()
end)

-- The emit will come from the OSD
awesome.connect_signal("widget::volume:update", function(value)
	volume_slider:set_value(tonumber(value))
end)

awesome.connect_signal("widget::volume:mute", function()
	awful.spawn.easy_async_with_shell("pamixer --get-mute", function(isMuted)
		if string.match(isMuted, "true") then
			action_level.text = ""
		else
			action_level.text = ""
		end
	end)
end)

local volume_setting = wibox.widget({
	{
		layout = wibox.layout.fixed.horizontal,
		spacing = dpi(5),
		{
			layout = wibox.layout.align.vertical,
			expand = "none",
			nil,
			action_level,
			nil,
		},
	},
	slider,
	osd_value,
	layout = wibox.layout.fixed.horizontal,
	forced_height = dpi(42),
	spacing = dpi(17),
})

return volume_setting
