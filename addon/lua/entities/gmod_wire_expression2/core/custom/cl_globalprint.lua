--[[---------------------------------------------------------------------------
Function descriptions
-----------------------------------------------------------------------------]]
E2Helper.Descriptions["broadcastMessage(...)"] = "Broadcasts a message to everyone on the server"
E2Helper.Descriptions["broadcastMessage(r)"]   = "Broadcasts a message to everyone on the server"
E2Helper.Descriptions["printMessage(e:...)"]   = "Prints a message in this players chat"
E2Helper.Descriptions["printMessage(e:r)"]     = "Prints a message in this players chat"

local prefixC = Color(180, 180, 180)

net.Receive("wire_expression2_custom_globalprint", function()
  local ret = {}

  for i = 1, net.ReadUInt(8) do
    local type = net.ReadBool()
    local func = type and net.ReadString or net.ReadColor

    ret[i] = func()
  end

  chat.AddText(unpack(ret))

  -- MsgC below needs a newline
  ret[#ret + 1] = '\n'

  local sender = net.ReadEntity()
  MsgC(prefixC, string.format("Player <%s> <%s> said: ", sender:Nick(), sender:SteamID()), unpack(ret))
end)