-- The reason we're doing this here is because, for a client to load the
-- client side state of an extension, they must allow their extensions to validate,
-- which also requires them to open their E2 editor, or past a E2.

--[[---------------------------------------------------------------------------
Just incase someone wants to spam messages
-----------------------------------------------------------------------------]]
local string_format = string.format
local chat_AddText  = chat.AddText
local unpack        = unpack
local MsgN          = MsgN
local prefix        = Color(180, 180, 180)

net.Receive("wire_expression2_custom_globalprint", function()
  local ret = {}

  for i = 1, net.ReadUInt(8) do
    local type = net.ReadBool()
    local func = type and net.ReadString or net.ReadColor

    ret[i] = func()
  end

  chat_AddText(unpack(ret))

  ret[#ret + 1] = '\n'

  local sender = net.ReadEntity()
  MsgC(prefix, string_format("Player <%s> <%s> said: ", sender:Nick(), sender:SteamID()), unpack(ret))
end)
