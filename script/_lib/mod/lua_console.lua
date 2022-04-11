--- TODO vscode-lua'ify WH3
--- TODO add in "enter" support
--- TODO paste functionality (???)
--- TODO resizable
--- TODO put an info button

out("qa_console.lua loaded");

---@class lua_console
local lua_console = {
	_name = "lua_console",
	_layout_path = "ui/dev_ui/!qa_console",
	_shortcut_key = "script_shift_F3", --- TODO expose to MCT

	_uic = nil, --- TODO the UIC itself

	---@type number The current line selected.
	_current_line = 0,

	---@type number The number of line components currently created
	_num_lines = 0,
	_lines = {},
	_max_lines = 90,
	_max_characters = 100, --- TODO demo
}

function lua_console:create()
	self._uic = core:get_or_create_component(self._name, self._layout_path);
	self._uic:SetVisible(false);
	self._uic:AddScriptEventReporter()

	local entry_box = find_uicomponent(self._uic, "entry_box")
	entry_box:SetStateText("")

	local text_popup = core:get_or_create_component("text_popup", "ui/common ui/tooltip_text_only", self._uic)

	local w,h = self._uic:Dimensions()
	text_popup:SetCanResizeWidth(true) text_popup:SetCanResizeHeight(true)
	text_popup:Resize(w + 50, h * 0.8)
	text_popup:SetDockingPoint(8)
	text_popup:SetDockOffset(0, 15)
	text_popup:SetVisible(false)

	self:setup_text_input()
	self:init_listeners()
end

function lua_console:swap_visibility()
	local uic = self:get_uic()
	if uic then
		local b = not uic:Visible()
		uic:SetVisible(b)
		self:set_repeat_callback(b)

		if b then self:set_current_line(1) end
	end
end

--- TODO create each text_input line (start with 8, create more as needed)
--- TODO create the listview
function lua_console:setup_text_input()
	local entry_box = find_uicomponent(self:get_uic(), "entry_box")

	self._num_lines = 8

	for i = 1, self._num_lines do
		---@type UIComponent
		out("Creating text_input_"..i)
		local text_input = core:get_or_create_component("text_input_"..i, "ui/dev_ui/text_box", entry_box)
		text_input:SetCanResizeHeight(true) text_input:SetCanResizeWidth(true)
	
		w,h = entry_box:Dimensions()
		local hi = h/8
		h = hi
		local y = hi * (i-1)
	
		text_input:Resize(w, h)
		text_input:SetDockingPoint(1)
		text_input:SetDockOffset(0, y)

		text_input:SetCanResizeHeight(false) text_input:SetCanResizeWidth(false)

		local line_text = core:get_or_create_component("line_"..i, "ui/dev_ui/text", text_input)
		line_text:SetDockingPoint(4)
		line_text:SetDockOffset(-12, 0)
		line_text:SetStateText(tostring(i)..":")
	end

	self:set_current_line(1)
end

--- TODO if not a valid input then add a new one at the bottom
function lua_console:set_current_line(i)
	if not is_number(i) then
		--- errmsg
		return false
	end

	self._current_line = i
	local input = self:get_text_input(i)
	input:SimulateLClick()
end

---@return UIComponent
function lua_console:get_text_input(i)
	if not i then i = 1 end
	local entry_box = find_uicomponent(self:get_uic(), "entry_box")
	local text_input = find_uicomponent(entry_box, "text_input_"..i)

	if not text_input then
		--- TODO error? return 1?
		out("Can't find text input " .. i)
		return
	end

	return text_input
end

--- TODO make a new line when we're out of room!
function lua_console:set_repeat_callback(b)
	---@type timer_manager
	local tm = core:get_static_object("timer_manager")
	if b == true then
		-- hook up the repeat callback
		out("Setting up repeat callback")
		tm:repeat_real_callback(function()
			local line = self:get_text_input(self._current_line)
			local txt = line:GetStateText()
			local w = line:Width() - 20
			local tw = line:TextDimensionsForText(txt)

			if tw >= w then
				self:set_current_line(self._current_line + 1)
			end
		end, 10, "check_lua_console")
	else
		-- kill it
		out("Removing repeat callback")
		tm:remove_real_callback("check_lua_console")
	end
end

--- TODO print out to a logfile as well.

--- TODO trigger errors as you type?
--- TODO stack print results!
--- Make use of the error popup to print return values
function lua_console:print(text)
	local popup,text_uic = self:get_text_popup()

	popup:SetVisible(true)
	local t = text_uic:GetStateText()

	--- TODO fix newlines on first line
	text_uic:SetStateText(t .. "\n" .. text)
end

function lua_console:printf(text, ...)
	text = string.format(text, ...)
	self:print(text)
end

---@return UIComponent
function lua_console:get_uic()
	return self._uic
end

---@return UIComponent Tooltip
---@return UIComponent Text
function lua_console:get_text_popup()
	local popup = find_uicomponent(self:get_uic(), "text_popup")
	local text = find_uicomponent(popup, "text")
	return popup, text
end

function lua_console:get_text()
	out("Getting text!")
	local num_lines = self._num_lines
	local txt = {}

	for i = 1, num_lines do
		local line = self:get_text_input(i)
		local t = line:GetStateText()
		if t ~= "" then
			txt[#txt+1] = t
		end
	end

	local str = table.concat(txt, "\n")
	return str
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
end

function lua_console:execute()
	out("Executing")
	self:clear_popup()
	local text = self:get_text()

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

function lua_console:init_listeners()
	core:add_listener(
		"qa_console_listener",
		"ShortcutPressed",
		function(context)
			out("ShortcutPressed event occurred, context.string is " .. context.string);
			return context.string == lua_console._shortcut_key
		end,
		function(context)
			lua_console:swap_visibility()
		end,
		true
	);

	core:add_listener(
		"qa_console_lclickup",
		"ComponentLClickUp", 
		function(context)
			local uic = UIComponent(context.component);
			return uic:Id() == "button_run" and uicomponent_descended_from(uic, lua_console._name);
		end,
		function()
			out("Executing")
			local ok, err = pcall(function()
			lua_console:execute();
		end) if not ok then out(err) end
		end,
		true
	);

	core:add_listener(
		"qa_console_lclickup_close",
		"ComponentLClickUp", 
		function(context)
			local uic = UIComponent(context.component);
			return uic:Id() == "button_close" and uicomponent_descended_from(uic, lua_console._name);
		end,
		function()
			lua_console:get_uic():SetVisible(false);
		end,
		true
	);

	core:add_listener(
		"qa_console_lclickup_clear",
		"ComponentLClickUp", 
		function(context)
			local uic = UIComponent(context.component);
			return uic:Id() == "button_clear" and uicomponent_descended_from(uic, lua_console._name);
		end,
		function()
			lua_console:clear_text()
			lua_console:clear_popup()
		end,
		true
	);

	core:add_listener(
		"qa_console_moved",
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