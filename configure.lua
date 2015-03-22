function yes_no_to_bool(x)
	if(x == "y") then return true end
	return false
end

function prompt_yes_no(y)
	local x = "n"
	repeat
		 io.write(y)
		 io.flush()
		 x=io.read()
	until x=="y" or x=="n"
	return x
end

function prompt(y,xval)
	local x = xval
	io.write(y)
	io.flush()
	x=io.read()
	if x == "" then
		return xval
	end
	return x
end

local configLines = {}
local configOps = {}

io.write("This is the configure script built for shotodol\n")
configLines["PLATFORM"] = "linux"

-- print("QT_HOME="..."/home/ayaskanti/opt/qt/Desktop/Qt/474/gcc")
-- print("ECHO="..."echo -e")
-- use only echo in mac
configLines["ECHO"] = "echo"
local haslfs,lfs = pcall(require,"lfs")
local phome = "";
if haslfs then
	phome = lfs.currentdir()
end
configLines["PROJECT_HOME"] = prompt("Project path " .. phome .. " > " , phome)
configLines["SHOTODOL_WEB_HOME"] = configLines["PROJECT_HOME"]
-- local ahome = string.gsub(configLines["PROJECT_HOME"],"shotodol_web$","aroop")
-- configLines["VALA_HOME"] = prompt("Aroop path " .. ahome .. " > ", ahome)
local shotohome = string.gsub(configLines["PROJECT_HOME"],"shotodol_web$","shotodol")
configLines["SHOTODOL_HOME"] = prompt("Shotodol path " .. shotohome .. " > ", shotohome)
local shoto_net_home = string.gsub(configLines["PROJECT_HOME"],"shotodol_web$","shotodol_net")
configLines["SHOTODOL_NET_HOME"] = prompt("Shotodol net path " .. shoto_net_home .. " > ", shoto_net_home)
-- local shoto_script_home = string.gsub(configLines["PROJECT_HOME"],"shotodol_web$","shotodol_script")
-- configLines["SHOTODOL_SCRIPT_HOME"] = prompt("Shotodol script path " .. shoto_script_home .. " > ", shoto_script_home)
configLines["CFLAGS+"] = ""
configLines["VALAFLAGS+"] = ""

if yes_no_to_bool(prompt_yes_no("enable debug (-D HTTP_HEADER_DEBUG) ?(y/n) > ")) then
	configLines["VALAFLAGS+"] = configLines["VALAFLAGS+"] .. "-D HTTP_HEADER_DEBUG"
end
local conf = assert(io.open("build/.config.mk", "w"))
-- import shotodol symbols
local infile = assert(io.open(configLines["SHOTODOL_HOME"] .. "/build/.config.mk", "r"))
local shotodol_config = infile:read("*a")
infile:close()
conf:write(shotodol_config);
-- import shotodol_script symbols
-- infile = assert(io.open(configLines["SHOTODOL_SCRIPT_HOME"] .. "/build/.config.mk", "r"))
-- local shotodol_script_config = infile:read("*a")
-- infile:close()
-- conf:write(shotodol_script_config);

for x in pairs(configLines) do
	local op = configOps[x]
	if op == nil then
		op = "="
	end
	conf:write(x .. op .. configLines[x] .. "\n")
end
assert(conf:close())

local shotodol = dofile(configLines["SHOTODOL_HOME"] .. "/build/shotodol.lua")
shotodol.genmake(configLines["PROJECT_HOME"])

