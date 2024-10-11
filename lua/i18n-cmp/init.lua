local M = {}

local function find_i18n_file(file_name)
	local handle = io.popen('find . -name "' .. file_name .. '"')
	if handle then
		local result = handle:read("*a")
		handle:close()
		local file_path = vim.split(result, "\n")[1]
		if file_path and file_path ~= "" then
			return file_path
		end
	end
	return nil
end

local function get_i18n_keys(files)
	local i18n_keys = {}

	for _, file_name in ipairs(files) do
		local filepath = find_i18n_file(file_name)
		if filepath then
			local file = io.open(filepath, "r")
			if file then
				local content = file:read("*a")
				file:close()
				local translations = vim.fn.json_decode(content)
				for key, _ in pairs(translations) do
					table.insert(i18n_keys, key)
				end
			end
		end
	end

	return i18n_keys
end

M.setup = function(opts)
	local i18n_files_exist = false
	for _, file_name in ipairs(opts.files) do
		if find_i18n_file(file_name) then
			i18n_files_exist = true
			break
		end
	end

	if not i18n_files_exist then
		return
	end

	require("cmp").register_source("i18n", {
		complete = function(_, request, callback)
			local i18n_keys = get_i18n_keys(opts.files)
			local items = {}
			for _, key in ipairs(i18n_keys) do
				if string.match(key, request.context.cursor_before_line) then
					table.insert(items, { label = key })
				end
			end
			callback({ items = items })
		end,
	})

	require("cmp").setup.filetype(opts.filetypes, {
		sources = {
			{ name = "i18n" },
		},
	})
end

return M
