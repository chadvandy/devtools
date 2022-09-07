--- TODO vscode-lua'ify WH3
--- TODO add in "enter" support (not likely)
--- TODO resizable
--- TODO put an info button

--- TODO MP support
--- TODO an "inspector" feature, you press it and it tells you information of the currently selected thing (selected character etc)

out("qa_console.lua loaded");

---@class lua_console
local lua_console = {
	_name = "lua_console",
	_layout_path = "ui/dev_ui/!qa_console",
	_shortcut_to_open = "script_shift_F3", --- TODO expose to MCT
	_shortcut_to_execute = "script_shift_F4", --- TODO expose to MCT

	_uic = nil,

	---@type number The current line selected.
	_current_line = 0,

	---@type number The number of line components currently created
	_num_lines = 0,

	---@type number The last visible line, for when there are more lines created than visible. Only executes code up to this line.
	_last_visible_line = 0,

	---@type number The maximum number of lines. Currently effectively disabled, I don't think it's needed.
	_max_lines = 9000,
}

function lua_console:create()
	self._uic = core:get_or_create_component(self._name, self._layout_path);
	self._uic:SetVisible(false);
	self._uic:AddScriptEventReporter()

	-- local w,h = self._uic:Dimensions()

	-- local listview = find_uicomponent(self._uic, "listview")
	-- listview:Resize(w, 200)

	local listview = find_uicomponent(self._uic, "listview")
	local vslider = find_uicomponent(listview, "vslider")

	vslider:Resize(vslider:Width(), listview:Height()-50)

	local text_popup = core:get_or_create_component("text_popup", "ui/common ui/tooltip_text_only", self._uic)

	local w,h = self._uic:Dimensions()
	text_popup:SetCanResizeWidth(true) text_popup:SetCanResizeHeight(true)
	text_popup:Resize(w + 50, h * 0.8)
	text_popup:SetDockingPoint(8)
	text_popup:SetDockOffset(0, 60)
	text_popup:SetVisible(false)

	text_popup:SetStateText("")

	local bottom_bar = find_uicomponent(self._uic, "bottom_bar_container")
	local container = find_uicomponent(bottom_bar, "button_add_remove_container")

	local add_icon = find_uicomponent(container, "button_add_line")
	local remove_icon = find_uicomponent(container, "button_remove_line")

	add_icon:Destroy()
	remove_icon:Destroy()

	local button_add_line = core:get_or_create_component("button_add_line", "ui/templates/square_small_button", container)
	local button_remove_line = core:get_or_create_component("button_remove_line", "ui/templates/square_small_button", container)

	local button_copy = core:get_or_create_component("button_copy", "ui/templates/square_small_button", container)
	local button_paste = core:get_or_create_component("button_paste", "ui/templates/square_small_button", container)

	find_uicomponent(button_copy, "icon"):SetVisible(false)
	find_uicomponent(button_paste, "icon"):SetVisible(false)
	find_uicomponent(button_add_line, "icon"):SetVisible(false)
	find_uicomponent(button_remove_line, "icon"):SetVisible(false)

	-- find_uicomponent(button_copy, "icon"):SetImagePath(common.get_context_value("AddDefaultSkinPath(\"icon_encyclopedia.png\")"))
	-- find_uicomponent(button_paste, "icon"):SetImagePath(common.get_context_value("AddDefaultSkinPath(\"icon_rename.png\")"))
	button_copy:SetImagePath("ui/skins/default/icon_encyclopedia.png")
	button_paste:SetImagePath("ui/skins/default/icon_rename.png")
	button_add_line:SetImagePath("ui/skins/default/icon_plus_small.png")
	button_remove_line:SetImagePath("ui/skins/default/icon_minus_small.png")

	button_copy:SetTooltipText("Copy the Lua Console to your clipboard.\n[[col:red]]WARNING: There's currently some weird issues with this. If you're having trouble not copying, close and reopen the Lua Console a few times. Your code will remain.[[/col]]", true)
	button_paste:SetTooltipText("Paste the contents of your clipboard to the Lua Console.\nBegins pasting on the first line after your existing code; if there aren't available lines, they will be created.", true)
	button_add_line:SetTooltipText("Add a new line.", true)
	button_remove_line:SetTooltipText("Remvoe the final line (text will be preserved, but not executed).", true)

	button_copy:SetCanResizeWidth(true) button_copy:SetCanResizeHeight(true)
	button_paste:SetCanResizeWidth(true) button_paste:SetCanResizeHeight(true)
	button_add_line:SetCanResizeWidth(true) button_add_line:SetCanResizeHeight(true)
	button_remove_line:SetCanResizeWidth(true) button_remove_line:SetCanResizeHeight(true)

	local w,h = 36,36

	button_copy:Resize(w, h)
	button_paste:Resize(w, h)
	button_add_line:Resize(w, h)
	button_remove_line:Resize(w, h)

	button_copy:SetDockingPoint(4)
	button_copy:SetDockOffset(0, 0)
	button_paste:SetDockingPoint(4)
	button_paste:SetDockOffset(w+4, 0)
	button_add_line:SetDockingPoint(6)
	button_add_line:SetDockOffset(w+4, 0)
	button_remove_line:SetDockingPoint(6)
	button_remove_line:SetDockOffset(0, 0)

	--- TEMP
	button_copy:SetTooltipText("Copy the Lua Console to a local file.\n[[col:red]]There's currently a bug where you can't copy anything with ' or \" in it, making it functionally useless. For now, this prints the Lua Console to a file at Total War WARHAMMER III/lua_console_code.lua[[/col]]", true)

	-- local button_close = find_uicomponent(self._uic, "title_bar", "button_close_container", "button_close")
	-- local button_settings = UIComponent(button_close:CopyComponent("button_settings"))
	-- button_settings:SetDockingPoint(1)
	-- button_settings:SetDockOffset(-button_close:Width() - 10, 0)
	-- button_settings:SetImagePath("ui/skins/warhammer3/icon_options.png", 0)
	-- button_settings:SetTooltipText("Open the Settings panel.", true)

	self:setup_text_input()
	self:init_listeners()
end

function lua_console:swap_visibility()
	local uic = self:get_uic()
	if uic then
		local b = not uic:Visible()
		uic:SetVisible(b)

		if b then self:set_current_line(1) end
	end
end

function lua_console:setup_text_input()
	for i = 1, 8 do
		self:create_text_line(i)
	end

	self:set_current_line(1)
end

--- TODO dynamically resize the text input so it's always 6px to the right of the :, so it doesn't look weird on different numbers
---@return UIC
function lua_console:create_text_line(i)
	local listview = find_uicomponent(self:get_uic(), "listview")
	local text_box = find_uicomponent(listview, "list_clip", "list_box")

	if not i then i = self._num_lines + 1 end
	if i >= self._max_lines then return find_uicomponent(text_box, "text_input_"..self._max_lines) end

	local extant = find_uicomponent(text_box, "text_input_"..i)
	if is_uicomponent(extant) then
		if extant:Visible() then return extant end
		extant:SetVisible(true)
		self._last_visible_line = i
		return extant
	end

	---@type UIC
	out("Creating text_input_"..i)
	local text_input = core:get_or_create_component("text_input_"..i, "ui/dev_ui/text_box", text_box)
	text_input:SetCanResizeHeight(true) text_input:SetCanResizeWidth(true)

	local w,h = listview:Dimensions()
	local hi = h/8
	h = hi
	
	local line_text = core:get_or_create_component("line_"..i, "ui/dev_ui/text", text_input)
	local tw = line_text:Width()*1.5
	line_text:Resize(tw, h)
	line_text:SetDockingPoint(1)
	line_text:SetDockOffset(-tw, 0)
	line_text:SetStateText(tostring(i)..":")
	
	text_input:Resize(w-tw-20, h)
	text_input:SetDockingPoint(4)
	text_input:SetDockOffset(tw, 0)

	text_input:SetCanResizeHeight(false) text_input:SetCanResizeWidth(false)

	self._num_lines = i
	self:show_line(i)

	text_box:Layout()

	return text_input
end

--- Hide the final line in the block. Keeps the line created, so it can be re-added and 
---@param i any
function lua_console:remove_line(i)
	local i
	if not i then i = self._last_visible_line end

	if i <= 5 then return end

	local input = find_uicomponent(self._uic, "listview", "list_clip", "list_box")
	local line = find_uicomponent(input, "text_input_"..i)
	if is_uicomponent(line) then
		line:SetVisible(false)
		self._last_visible_line = i - 1
		return true
	end

	return false
end

function lua_console:show_line(i)
	if not i then i = self._last_visible_line + 1 end


	local input = find_uicomponent(self._uic, "listview", "list_clip", "list_box")
	local line = find_uicomponent(input, "text_input_"..i)
	if is_uicomponent(line) then
		line:SetVisible(true)
		self._last_visible_line = i
		return true
	end

	return false
end

function lua_console:set_current_line(i)
	if not is_number(i) then
		--- errmsg
		return false
	end
	
	local input = self:get_text_input(i)
	if not input then
		input = self:create_text_line(i)
	end

	self._current_line = i
	input:SimulateLClick()
end

---@return UIC
function lua_console:get_text_input(i)
	if not i then i = 1 end
	local entry_box = find_uicomponent(self:get_uic(), "listview", "list_clip", "list_box")
	local text_input = find_uicomponent(entry_box, "text_input_"..i)

	if not text_input then
		--- TODO error? return 1?
		out("Can't find text input " .. i)
		return
	end

	return text_input
end

--- TODO print out to a logfile as well.

--- TODO trigger errors as you type?
--- TODO stack print results!
--- Make use of the error popup to print return values
function lua_console:print(text)
	local popup,text_uic = self:get_text_popup()

	popup:SetVisible(true)
	local t = text_uic:GetStateText()

	if t ~= "" then t = t .. "\n" end

	text_uic:SetStateText(t .. text)
end

function lua_console:printf(text, ...)
	text = string.format(text, ...)
	self:print(text)
end

---@return UIC
function lua_console:get_uic()
	return self._uic
end

---@return UIC Tooltip
---@return UIC Text
function lua_console:get_text_popup()
	local popup = find_uicomponent(self:get_uic(), "text_popup")
	local text = find_uicomponent(popup, "text")
	return popup, text
end

function lua_console:get_text(visible_only)
	ModLog("Getting text!")
	local num_lines = self._num_lines
	local str = ""

	if visible_only then num_lines = self._last_visible_line end

	for i = 1, num_lines do
		local line = self:get_text_input(i)
		local t = line:GetStateText()
		if t ~= "" then
			if i ~= 1 then str = str .. "\n" end
			str = str .. t
		end
	end

	return str
end

function lua_console:set_visible_up_to_line(i)
	if not i then i = self._num_lines end
	if i < self._last_visible_line then i = self._last_visible_line end

	for j = 1, i do
		self:show_line(j)
	end
end

--- Grab the final line with any user input within.
---@param visible_only boolean? If we should check all lines, or just currently visible ones.
---@return integer
function lua_console:get_last_used_line(visible_only)
	local start = visible_only and self._last_visible_line or self._num_lines
	local last_line

	ModLog("Looping from " .. start .. " to 1.")
	for i = start, 1, -1 do
		ModLog("Checking line #"..i)
		local line = self:get_text_input(i)
		if line then
			local text = line:GetStateText()
			
			if text ~= "" then
				break
			end
			
			last_line = i
		end
	end

	return last_line
end

function lua_console:copy_to_clipboard()
	local text = self:get_text(true)
	ModLog("Copying to Clipboard: \n" .. text)

	common.set_context_value("CcoScriptObject", "LuaConsoleText", text)
	common.call_context_command("CcoScriptObject", "LuaConsoleText", "CopyStringToClipboard(StringValue)")

	-- local file = io.open("lua_console_code.lua", "w+")
	-- file:write(text)
	-- file:close()
end

local function string_split(str, delimiter)
	local result = { }
	local from  = 1
	local delim_from, delim_to = string.find( str, delimiter, from  )
	while delim_from do
		table.insert( result, string.sub( str, from , delim_from-1 ) )
		from  = delim_to + 1
		delim_from, delim_to = string.find( str, delimiter, from  )
	end
	table.insert( result, string.sub( str, from  ) )
	return result
end

--- TODO issue if you have 10 lines written, hide the last 2, and then try to paste - it will paste at 11, but will still have 9-10 hidden.
function lua_console:paste_from_clipboard()
	ModLog("Pasting from clipboard!")

	--- get the last line that is untouched
	local last_line = self:get_last_used_line()
	if not last_line then
		self:create_text_line()
		last_line = self._num_lines
	end

	self:set_visible_up_to_line(last_line)

	ModLog("Pasting from clipboard - last line with stuff is " .. last_line)

	-- starting from the last untouched line, loop and paste.
	local clipboard = common.get_context_value("PasteStringFromClipboard")
	local tab = string_split(clipboard, "\n")
	
	ModLog("Clipboard text is " .. clipboard)
	ModLog("Number of lines: "..#tab)

	for i = 1, #tab do
		local this_line = last_line + (i-1)
		ModLog("Pasting on line " .. this_line)
		self:create_text_line(this_line)
		local line = self:get_text_input(this_line)
		line:SetStateText(tab[i])
	end
end

function lua_console:clear_popup()
	local popup = self:get_text_popup()
	popup:SetVisible(false)

	local text = find_uicomponent(popup, "text")
	text:SetStateText("")
end

function lua_console:clear_text()
	for i = 1, self._num_lines do 
		local line = self:get_text_input(i)
		line:SetStateText("")
	end
	
	self:set_current_line(1)
end

function lua_console:execute()
	out("Executing")
	self:clear_popup()
	local text = self:get_text(true)

	out("Executing text: " .. text)

    local func, err = loadstring(text);
    
    if not func then 
		script_error("ERROR: qa console attempted to run a script command but an error was reported when loading the command string into a function. Command and error will follow this message.");
		out("Command:");
		out(text);
		out("Error:");
		out(err);
		self:printf("[[col:red]] Error: %s[[/col]]", err)
		return;
	end

	local env = core:get_env()
    setfenv(func, env);
    
    local ok, result = pcall(func);

	if not ok then 
		script_error("ERROR: qa console attempted to run a script command but an error was reported when executing the function. Command and error will follow this message.");
		out("Command:");
		out(text);
		out("Error:");
		out(result);
		self:printf("[[col:red]] Error: %s[[/col]]", result)
		return
	else
		if result then
			self:print(tostring(result))
		end
	end;
end

--- TODO do I even want to do this when I can really just MCT?
function lua_console:open_settings_panel()
	local panel = core:get_or_create_component("settings_panel", "ui/templates/panel_frame", self._uic)
	
	local w,h = self._uic:Dimensions()
	panel:Resize(w*1.5, h*1.3) 
	panel:SetDockingPoint(5) panel:SetDockOffset(0, 0)

	local title = core:get_or_create_component("title", "ui/templates/panel_title", panel)
	title:SetDockingPoint(2) title:SetDockOffset(0, 20)

	local text = core:get_or_create_component("text", "ui/dev_ui/text", title)
	text:SetDockingPoint(5) text:SetDockOffset(0, 0)
	text:SetStateText("Lua Console Settings") --- TODO font change

	
end

function lua_console:init_listeners()
	core:add_listener(
		"lua_console_listener",
		"ShortcutPressed",
		function(context)
			return context.string == lua_console._shortcut_to_open or context.string == lua_console._shortcut_to_execute
		end,
		function(context)
			if context.string == self._shortcut_to_open then
				lua_console:swap_visibility()
			elseif context.string == self._shortcut_to_execute then
				if lua_console:get_uic():Visible() then
					lua_console:execute()
				end
			end
		end,
		true
	);

	core:add_listener(
		"lua_console_lclickup",
		"ComponentLClickUp",
		function(context)
			return uicomponent_descended_from(UIComponent(context.component), lua_console._name)
		end,
		function(context)
			local id = context.string

			--- TODO I'm too old to do an if/else string like this, clean up pls
			if id == "button_run" then
				lua_console:execute()
			elseif id == "button_close" then
				lua_console:swap_visibility()
			elseif id == "button_clear" then 
				lua_console:clear_text()
				lua_console:clear_popup()
			elseif id == "button_add_line" then
				if not lua_console:show_line() then
					lua_console:create_text_line()
				end
			elseif id == "button_remove_line" then
				lua_console:remove_line()
			elseif id == "button_copy" then
				local ok, err = pcall(function()
					lua_console:copy_to_clipboard()
				end) if not ok then ModLog(err) end
			elseif id == "button_paste" then
				local ok, err = pcall(function()
					lua_console:paste_from_clipboard()
				end) if not ok then ModLog(err) end
			elseif id == "button_settings" then
				lua_console:open_settings_panel()
			end
		end,
		true
	)


	core:add_listener(
		"lua_console_moved",
		"ComponentMoved",
		function(context)
			return context.string == lua_console._name
		end,
		function(context)
			local uic = UIComponent(context.component)
			local x,y = uic:Position()

			local function f() uic:MoveTo(x, y) end
			local i = 5
			local k = "refresh_lua_console"
			
			---@type timer_manager
			local tm = core:get_static_object("timer_manager")
			tm:real_callback(f, i, k)
		end,
		true
	)
end

function console_print(t)
	lua_console:print(t)
end

function console_printf(t, ...)
	lua_console:printf(t, ...)
end

c_print = console_print 
c_printf = console_printf

function t_get(t, i)
	if not is_table(t) then return end
	if not is_number(i) and not is_string(i) then return end

	return t[i]
end

function t_set(t, i, v)
	if not is_table(t) then return end
	if not is_number(i) and not is_string(i) then return end
	
	t[i] = v
end

if not core:is_battle() then
	core:add_ui_created_callback(
		function()
			-- create the console uicomponent
			-- local ok, err = pcall(function()
			if core:is_campaign() then 
				cm:add_post_first_tick_callback(function()
					lua_console:create()
				end)
			elseif core:is_frontend() then
				lua_console:create()
			end
			-- end) if not ok then out(err) end
	
			out("Created")
		end
	);
else
	bm:register_phase_change_callback("Deployment", function() lua_console:create() end)
end