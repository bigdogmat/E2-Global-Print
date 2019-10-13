--[[---------------------------------------------------------------------------
Global color printing!
-----------------------------------------------------------------------------]]
E2Lib.RegisterExtension("globalprint", false, "Allows players to print colored messages to the entire server", "This can be used to impersonate players, and or spam players.")

--[[---------------------------------------------------------------------------
Permissions
0 = everyone,
1 = admins,
2 = superadmins,
Default: 2
-----------------------------------------------------------------------------]]
local permissions = CreateConVar("globalprint_permissions", '2', bit.bor(FCVAR_ARCHIVE, FCVAR_SERVER_CAN_EXECUTE), "Set who can send global messages")

--[[---------------------------------------------------------------------------
Checks players permission
-----------------------------------------------------------------------------]]
local function check_permission(context)
  local ply = context.player

  -- Player left and E2 is still running?
  if not IsValid(ply) then return false end

  local mode = permissions:GetInt()

  if mode == 0 then
    return true
  elseif mode == 1 and ply:IsAdmin() then
    return true
  elseif mode == 2 and ply:IsSuperAdmin() then
    return true
  end

  return false
end

--[[---------------------------------------------------------------------------
Convert E2 types to strings or colors
-----------------------------------------------------------------------------]]
local types_tostring = {
  e = function(ent)
    if not IsValid(ent) then return '' end

    return ent:IsPlayer() and ent:Nick() or tostring(ent)
  end,

  -- Treat vectors as colors unless they're outside the range to be colors
  v = function(vec)
    for k, v in ipairs(vec) do
      if v < 0 or v > 255 then
        return string.format("Vec (%d, %d, %d)", vec[1], vec[2], vec[3])
      end
    end

    return Color(vec[1], vec[2], vec[3])
  end,

  -- Other vector types
  xv2 = function(vec) return string.format("Vec (%d, %d)", vec[1], vec[2]) end,
  xv4 = function(vec) return string.format("Vec (%d, %d, %d, %d)", vec[1], vec[2], vec[3], vec[4]) end,

  n = tostring,
  s = function(str) return str end,
}

--[[---------------------------------------------------------------------------
Build a printable table from varargs
-----------------------------------------------------------------------------]]
local function build_table_from_VarArgs(typeids, ...)
  local ret = {}

  for k, v in ipairs(typeids) do
    if types_tostring[v] then
      ret[#ret + 1] = types_tostring[v](select(k, ...))
    end
  end

  return ret
end

--[[---------------------------------------------------------------------------
When using arrays we have less info about the data types, we have to make
some guesses
-----------------------------------------------------------------------------]]
local realtypes_tostring = {
  number = types_tostring.n,
  string = types_tostring.s,
  entity = types_tostring.e,
  Player = types_tostring.e,

  table  = function(tab)
    for k, v in pairs(tab) do
      if not isnumber(k) then return '' end
      if not isnumber(v) then return '' end

      if k < 1 or k > 4 then return '' end
    end

    if #tab == 2 then
      return types_tostring.xv2(tab)
    elseif #tab == 3 then
      return types_tostring.v(tab)
    elseif #tab == 4 then
      return types_tostring.xv4(tab)
    end

    return ''
  end,
}

--[[---------------------------------------------------------------------------
Build a printable table from an array
-----------------------------------------------------------------------------]]
local function build_table_from_Array(arr)
  local ret = {}

  for k, v in ipairs(arr) do
    local type = type(v)

    if realtypes_tostring[type] then
      ret[#ret + 1] = realtypes_tostring[type](v)
    end
  end

  return ret
end

--[[---------------------------------------------------------------------------
Network the message
-----------------------------------------------------------------------------]]
util.AddNetworkString "wire_expression2_custom_globalprint"

local function write_color_print(context, player, data)
  net.Start "wire_expression2_custom_globalprint"
    net.WriteUInt(#data, 8)

    for k, v in ipairs(data) do
      local type = isstring(v)
      local func = type and net.WriteString or net.WriteColor

      net.WriteBool(type)
      func(v)
    end

    net.WriteEntity(context.player)

  if player then
    net.Send(player)
  else
    net.Broadcast()
  end
end

--[[---------------------------------------------------------------------------
Send a message using an array
-----------------------------------------------------------------------------]]
local function send_color_print_Array(context, ply, arr)
  local data = build_table_from_Array(arr)
  write_color_print(context, ply, data)
end

--[[---------------------------------------------------------------------------
Send a message using varargs
-----------------------------------------------------------------------------]]
local function send_color_print_VarArgs(context, ply, typeids, ...)
  local data = build_table_from_VarArgs(typeids, ...)
  write_color_print(context, ply, data)
end

--[[---------------------------------------------------------------------------
Broadcast messages
-----------------------------------------------------------------------------]]
__e2setcost(50)

e2function void broadcastMessage(...)
  if not check_permission(self) then return end
  if #typeids > 255 then return end

  send_color_print_VarArgs(self, nil, typeids, ...)
end

e2function void broadcastMessage(array args)
  if not check_permission(self) then return end
  if #args > 255 then return end

  send_color_print_Array(self, nil, args)
end

--[[---------------------------------------------------------------------------
Player methods
-----------------------------------------------------------------------------]]
__e2setcost(20)

e2function void entity:printMessage(...)
  if not IsValid(this) then return end
  if not this:IsPlayer() then return end
  if not check_permission(self) then return end
  if #typeids > 255 then return end

  send_color_print_VarArgs(self, this, typeids, ...)
end

e2function void entity:printMessage(array args)
  if not IsValid(this) then return end
  if not this:IsPlayer() then return end
  if not check_permission(self) then return end
  if #args > 255 then return end

  send_color_print_Array(self, this, args)
end
