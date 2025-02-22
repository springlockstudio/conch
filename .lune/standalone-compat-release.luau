local fs = require "@lune/fs"
local process = require "@lune/process"
local serde = require "@lune/serde"
local testkit = require "../tests/testkit"

type PesdeOverride = { name: string, version: string }
type PesdePatch = { [string]: string }
type PesdeDependency = | {
	name: string,
	wally: nil,
	version: string,
	index: string?,
	target: string?,
	repo: nil,
	rev: nil,
	path: nil,
	workspace: nil,
} | {
	name: nil,
	wally: string,
	version: string,
	index: string?,
	target: nil,
	repo: nil,
	rev: nil,
	path: nil,
	workspace: nil,
} | {
	name: nil,
	wally: nil,
	version: nil,
	index: nil,
	target: nil,
	repo: string,
	rev: string,
	path: string?,
	workspace: nil,
} | {
	name: nil,
	wally: nil,
	version: string,
	index: nil,
	target: nil,
	repo: nil,
	rev: nil,
	path: nil,
	workspace: string,
}

type PesdeToml = {
	name: string,
	version: string,
	description: string?,
	license: string?,
	authors: { string }?,
	repository: string?,
	private: boolean?,
	includes: { string }?,
	pesde_version: string?,
	workspace_members: { string }?,

	target: {
		environment: "roblox" | "roblox_server",
		lib: string?,
		build_files: { string }?,
	} | {
		environment: "luau" | "lune",
		lib: string?,
		bin: string?,
		scripts: { [string]: string }?,
	},

	scripts: {
		roblox_sync_config_generator: string?,
		sourcemap_generator: string?,
		[string]: string,
	}?,

	indices: {
		default: string,
		[string]: string,
	}?,

	wally_indices: {
		default: string,
		[string]: string,
	}?,

	overrides: { [string]: PesdeOverride }?,
	patches: { [string]: PesdePatch }?,

	place: {
		shared: string,
		server: string,
	}?,

	dependencies: { [string]: PesdeDependency }?,
	peer_dependencies: { [string]: PesdeDependency }?,
	dev_dependencies: { [string]: PesdeDependency }?,
}

--[[
needs to bundle the project

]]
local function fix(name: string) return string.gsub(name, "_", "-") end

local function get_types(input: string, into: { string })
	for value in string.gmatch(input, "export type ([%w%.<>=_]-)[ ]-=[ ]-") do
		if string.find(value, "<") and not string.find(value, ">") then
			value ..= ">"
		end
		local export_without_default = string.gsub(value, "=.->", ">")
		table.insert(
			into,
			`export type {value} = main.{export_without_default}`
		)
	end
end

local function get_name(dependency: PesdeDependency)
	if dependency.name then
		return string.split(dependency.name, "/")[2]
	elseif dependency.workspace then
		return string.split(dependency.workspace, "/")[2]
	elseif dependency.wally then
		return string.split(dependency.wally, "/")[2]
	else
		error "cannot get name"
	end
end

local function generate_standalone_release_files(path: string)
	local file = fs.readFile(path .. "/pesde.toml")
	local pesde_toml: PesdeToml = serde.decode("toml", file)
	if pesde_toml.private then return end

	local lib_file_path = pesde_toml.target.lib

	assert(lib_file_path, "no lib file, cannot make wally release")

	local lib_file = fs.readFile(path .. "/" .. lib_file_path)

	local lib_file_src: string
	do
		local lib_file_path_without = string.gsub(lib_file_path, ".luau", "")
		local init_file = {
			`local main = require("./{lib_file_path_without}")`,
		}

		get_types(lib_file, init_file)

		table.insert(init_file, "return main")
		lib_file_src = table.concat(init_file, "\n")
	end

	local init_file_src: string
	do
		local init_file = {
			`local main = require(script.lib)`,
		}

		get_types(lib_file, init_file)

		table.insert(init_file, "return main")
		init_file_src = table.concat(init_file, "\n")
	end

	local roblox_packages: { [string]: string } = {}
	do
		local dependencies = pesde_toml.dependencies
		if dependencies then
			for name, dependency in dependencies do
				local realm = dependency.target or pesde_toml.target.environment
				if realm ~= "roblox" then continue end
				local set_name_to = get_name(dependency)

				local file =
					fs.readFile(path .. "/roblox_packages/" .. name .. ".luau")
				local package_file = {
					`local main = require(script.Parent.Parent.Parent["{set_name_to}"])`,
				}

				get_types(file, package_file)

				table.insert(package_file, "return main")
				roblox_packages[name] = table.concat(package_file, "\n")
			end
		end
	end

	local luau_packages: { [string]: string } = {}
	do
		local dependencies = pesde_toml.dependencies
		if dependencies then
			for name, dependency in dependencies do
				local realm = dependency.target or pesde_toml.target.environment
				if realm ~= "luau" then continue end
				local set_name_to = get_name(dependency)

				local file =
					fs.readFile(path .. "/luau_packages/" .. name .. ".luau")
				local package_file = {
					`local main = require(script.Parent.Parent.Parent["{set_name_to}"])`,
				}

				get_types(file, package_file)

				table.insert(package_file, "return main")
				luau_packages[name] = table.concat(package_file, "\n")
			end
		end
	end

	-- fs.removeDir(path .. "/dist")
	-- fs.removeFile(path .. "/default.project.json")
	-- fs.removeFile(path .. "/wally.toml")

	fs.writeDir(path .. "/dist")
	fs.writeDir(path .. "/dist/roblox_packages")
	fs.writeDir(path .. "/dist/luau_packages")

	for name, package in roblox_packages do
		fs.writeFile(
			path .. "/dist/roblox_packages/" .. name .. ".luau",
			package
		)
	end

	for name, package in luau_packages do
		fs.writeFile(path .. "/dist/luau_packages/" .. name .. ".luau", package)
	end

	fs.copy(path .. "/src", path .. "/dist/src", true)
	fs.writeFile(path .. "/dist/lib.luau", lib_file_src)
	fs.writeFile(path .. "/dist/init.luau", init_file_src)

	local package_name = string.split(pesde_toml.name, "/")[2]
	fs.writeFile(
		path .. "/default.project.json",
		`\{\n\t"name": "{package_name}",\n\t"tree": \{\n\t\t"$path": "dist"\n\t}\n}`
	)
end

type SortItem = {
	name: string,
	path: string,
	dependencies: { [string]: PesdeDependency }?,
}

local function get_order()
	local packages = fs.readDir "./pkgs"
	local package_dependencies: { SortItem } = {}
	local mapped: { [string]: PesdeToml } = {}

	for index, package in packages do
		local path = "./pkgs/" .. package
		local file = fs.readFile(path .. "/pesde.toml")
		local pesde_toml: PesdeToml = serde.decode("toml", file)

		mapped[pesde_toml.name] = pesde_toml
		package_dependencies[index] = {
			name = pesde_toml.name,
			path = path,
			dependencies = pesde_toml.dependencies,
		}
	end

	-- check if a relies on b
	local function flatten_dependencies(
		dependencies: { [string]: PesdeDependency }
	)
		local flat = {}

		for name, dependency in dependencies do
			if dependency.workspace then
				local toml = mapped[dependency.workspace]
				if toml.dependencies == nil then continue end
				for name in flatten_dependencies(toml.dependencies) do
					flat[name] = true
				end
			elseif not dependency.wally then
				error(`bad dependency {name}`)
			end

			flat[dependency.workspace or dependency.wally] = true
		end

		return flat
	end

	local function relies_on(a: SortItem, b: SortItem)
		if a.dependencies == nil then return false end
		local flattened = flatten_dependencies(a.dependencies)
		return flattened[b.name] or false
	end

	table.sort(package_dependencies, function(a: SortItem, b: SortItem)
		if a.dependencies == nil and b.dependencies == nil then
			return a.name > b.name
		end
		if a.dependencies == nil then return true end
		if b.dependencies == nil then return false end

		if relies_on(a, b) then return false end
		if relies_on(b, a) then return true end

		return a.name > b.name
	end)

	local order = {}

	for index, item in package_dependencies do
		order[index] = item.path
	end

	return order
end

local function cleanup_files(path: string)
	-- fs.removeDir(path .. "/dist")
	fs.removeFile(path .. "/default.project.json")
end

for _, path in get_order() do
	print("Generating release for", path)
	generate_standalone_release_files(path)
	-- cleanup_files(path)
	-- if status.ok == false then error(status.stderr) end
end
