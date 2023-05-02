local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local gears = require("gears")
local icons = require("icons")

---- Cpu popup
local CMD = [[sh -c "grep '^cpu.' /proc/stat; ps -eo '%p|%c|%C|' -o "%mem" -o '|%a' --sort=-%cpu ]]
	.. [[| head -11 | tail -n +2"]]
local is_update = true
local popup_timer = gears.timer({
	timeout = 1,
})
local function split(string_to_split, separator)
	if separator == nil then
		separator = "%s"
	end
	local t = {}

	for str in string.gmatch(string_to_split, "([^" .. separator .. "]+)") do
		table.insert(t, str)
	end

	return t
end
local function starts_with(str, start)
	return str:sub(1, #start) == start
end
local function create_textbox(args)
	return wibox.widget({
		text = args.text,
		align = args.align or "left",
		markup = args.markup,
		forced_width = args.forced_width or 40,
		widget = wibox.widget.textbox,
	})
end
local cpu_rows = {
	spacing = 4,
	layout = wibox.layout.fixed.vertical,
}
local function create_kill_process_button()
	return wibox.widget({
		{
			id = "icon",
			image = icons.kill_process,
			resize = true,
			opacity = 0.1,
			widget = wibox.widget.imagebox,
		},
		widget = wibox.container.background,
	})
end
local function create_process_header(params)
	local res = wibox.widget({
		create_textbox({ markup = "<b>PID</b>" }),
		create_textbox({ markup = "<b>Name</b>" }),
		{
			create_textbox({ markup = "<b>%CPU</b>" }),
			create_textbox({ markup = "<b>%MEM</b>" }),
			params.with_action_column and create_textbox({ forced_width = 20 }) or nil,
			layout = wibox.layout.align.horizontal,
		},
		layout = wibox.layout.ratio.horizontal,
	})
	res:ajust_ratio(2, 0.2, 0.47, 0.33)

	return res
end

return function()
	local popup = awful.popup({
		ontop = true,
		visible = false,
		shape = gears.shape.rounded_rect,
		border_width = 1,
		border_color = beautiful.bg_normal,
		maximum_width = 300,
		offset = { y = 5 },
		widget = {},
	})

	local process_info_max_length = -1
	-- Do not update process rows when mouse cursor is over the widget
	popup:connect_signal("mouse::enter", function()
		is_update = false
	end)
	popup:connect_signal("mouse::leave", function()
		is_update = true
	end)
	local process_rows = {
		layout = wibox.layout.fixed.vertical,
	}
	local cpus = {}
	local enable_kill_button = true
	popup:connect_signal("widget::cpu_popups:show", function()
		if popup.visible then
			popup.visible = not popup.visible
			-- When the popup is not visible, stop the timer
			popup_timer:stop()
		else
			popup:move_next_to(mouse.current_widget_geometry)
			-- Restart the timer, when the popup becomes visible
			-- Emit the signal to start the timer directly and not wait the timeout first
			popup_timer:start()
			popup_timer:emit_signal("timeout")
		end
	end)
	awesome.connect_signal("widget::cpu_popups:hide", function()
		popup.visible = false
		-- When the popup is not visible, stop the timer
		popup_timer:stop()
	end)
	popup_timer:connect_signal("timeout", function()
		awful.spawn.easy_async(CMD, function(stdout, _, _, _)
			local i = 1
			local j = 1
			for line in stdout:gmatch("[^\r\n]+") do
				if starts_with(line, "cpu") then
					if cpus[i] == nil then
						cpus[i] = {}
					end

					local name, user, nice, system, idle, iowait, irq, softirq, steal, _, _ =
						line:match("(%w+)%s+(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)%s(%d+)")

					local total = user + nice + system + idle + iowait + irq + softirq + steal

					local diff_idle = idle - tonumber(cpus[i]["idle_prev"] == nil and 0 or cpus[i]["idle_prev"])
					local diff_total = total - tonumber(cpus[i]["total_prev"] == nil and 0 or cpus[i]["total_prev"])
					local diff_usage = (1000 * (diff_total - diff_idle) / diff_total + 5) / 10

					cpus[i]["total_prev"] = total
					cpus[i]["idle_prev"] = idle

					local row = wibox.widget({
						create_textbox({ text = name }),
						create_textbox({ text = math.floor(diff_usage) .. "%" }),
						{
							max_value = 100,
							value = diff_usage,
							forced_height = 20,
							forced_width = 150,
							paddings = 1,
							margins = 4,
							border_width = 1,
							border_color = beautiful.bg_focus,
							background_color = beautiful.bg_normal,
							bar_border_width = 1,
							bar_border_color = beautiful.bg_focus,
							color = "linear:150,0:0,0:0,#D08770:0.3,#BF616A:0.6," .. beautiful.fg_normal,
							widget = wibox.widget.progressbar,
						},
						layout = wibox.layout.ratio.horizontal,
					})
					row:ajust_ratio(2, 0.15, 0.15, 0.7)
					cpu_rows[i] = row
					i = i + 1
				else
					if is_update == true then
						local columns = split(line, "|")

						local pid = columns[1]
						local comm = columns[2]
						local cpu = columns[3]
						local mem = columns[4]
						local cmd = columns[5]

						local kill_proccess_button = enable_kill_button and create_kill_process_button() or nil

						local pid_name_rest = wibox.widget({
							create_textbox({ text = pid }),
							create_textbox({ text = comm }),
							{
								create_textbox({ text = cpu, align = "center" }),
								create_textbox({ text = mem, align = "center" }),
								kill_proccess_button,
								layout = wibox.layout.fixed.horizontal,
							},
							layout = wibox.layout.ratio.horizontal,
						})
						pid_name_rest:ajust_ratio(2, 0.2, 0.47, 0.33)

						local row = wibox.widget({
							{
								pid_name_rest,
								top = 4,
								bottom = 4,
								widget = wibox.container.margin,
							},
							widget = wibox.container.background,
						})

						row:connect_signal("mouse::enter", function(c)
							c:set_bg(beautiful.bg_focus)
						end)
						row:connect_signal("mouse::leave", function(c)
							c:set_bg(beautiful.bg_normal)
						end)

						if enable_kill_button then
							row:connect_signal("mouse::enter", function()
								kill_proccess_button.icon.opacity = 1
							end)
							row:connect_signal("mouse::leave", function()
								kill_proccess_button.icon.opacity = 0.1
							end)

							kill_proccess_button:buttons(awful.util.table.join(awful.button({}, 1, function()
								row:set_bg("#ff0000")
								awful.spawn.with_shell("kill -9 " .. pid)
							end)))
						end

						awful.tooltip({
							objects = { row },
							mode = "outside",
							preferred_positions = { "bottom" },
							timer_function = function()
								local text = cmd
								if process_info_max_length > 0 and text:len() > process_info_max_length then
									text = text:sub(0, process_info_max_length - 3) .. "..."
								end

								return text
									:gsub("%s%-", "\n\t-") -- put arguments on a new line
									:gsub(":/", "\n\t\t:/") -- java classpath uses : to separate jars
							end,
						})

						process_rows[j] = row

						j = j + 1
					end
				end
			end
			popup:setup({
				{
					cpu_rows,
					{
						orientation = "horizontal",
						forced_height = 15,
						color = beautiful.bg_focus,
						widget = wibox.widget.separator,
					},
					create_process_header({ with_action_column = enable_kill_button }),
					process_rows,
					layout = wibox.layout.fixed.vertical,
				},
				margins = 8,
				widget = wibox.container.margin,
			})
		end)
	end)
	return popup
end
