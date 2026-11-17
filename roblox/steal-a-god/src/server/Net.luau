-- Canales de comunicación servidor <-> cliente
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = {}

local EVENTS = {
	"State", -- servidor -> cliente: estado del jugador
	"Announce", -- servidor -> cliente: aviso en el chat / cartel
	"Toast", -- servidor -> cliente: mensaje corto
	"Reveal", -- servidor -> cliente: animación al abrir un sobre
	"Knock", -- servidor -> cliente: empujón por un golpe
	"Offer", -- servidor -> cliente: ofrecer una compra (p. ej. salvar el sobre)
	"Action", -- cliente -> servidor: comprar, equipar, AFK...
	"Combo", -- cliente -> servidor: acierto en la cinta
}

function Net.init()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	for _, name in ipairs(EVENTS) do
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = folder
		Net[name] = ev
	end
	folder.Parent = ReplicatedStorage
end

function Net.toast(player, key, ...)
	Net.Toast:FireClient(player, key, { ... })
end

-- args: lista; cada elemento puede ser texto/número o {rarity=n}, {zone=n}, {god=id}...
function Net.announce(target, key, args, opts)
	local payload = { key = key, args = args or {}, opts = opts or {} }
	if target == "all" then
		Net.Announce:FireAllClients(payload)
	else
		Net.Announce:FireClient(target, payload)
	end
end

return Net
