#!/usr/bin/env python3
"""Herramientas del catálogo de Roblox para vestir a los dioses con prendas reales.

  python3 tools/catalog.py search consultas.json salida/
      consultas.json: [{"key": "zeus_beard", "keyword": "white beard", "types": ["FaceAccessory"], "limit": 12,
                        "sort": "Relevance"|"MostFavorited"|"Bestselling"|"RecentlyCreated"|"PriceHighToLow"|"PriceLowToHigh"}, ...]
      Busca en el catálogo desde un servidor de Roblox (una sola ejecución para todas las consultas),
      descarga las miniaturas y crea una hoja de contacto por consulta: salida/<key>.jpg (con el ID bajo cada foto)
      y salida/results.json con id, nombre, creador, precio y tipo.
      Tipos válidos (Enum.AvatarAssetType): Hat (sombreros, coronas, cascos), HairAccessory, FaceAccessory, NeckAccessory,
      ShoulderAccessory, FrontAccessory, BackAccessory, WaistAccessory, Shirt, Pants, TShirt,
      ShirtAccessory, PantsAccessory, JacketAccessory, SweaterAccessory, ShortsAccessory, DressSkirtAccessory,
      LeftShoeAccessory, RightShoeAccessory, EyebrowAccessory, EyelashAccessory, Face, DynamicHead.

  python3 tools/catalog.py check outfits.json
      outfits.json: {"zeus": {...conjunto...}, ...} (formato de Config.OUTFITS; ver tools/outfit_format.md)
      Crea cada avatar en un servidor real y dice cuántas prendas se cargaron de las pedidas.

  python3 tools/catalog.py thumbs id1,id2,... salida.jpg
      Hoja de contacto con las miniaturas de esos IDs.
"""
import json, os, sys, time, urllib.request, urllib.error
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import lx  # noqa: E402

def lua_str(s):
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'

SEARCH_LUAU = r'''
local AES = game:GetService("AvatarEditorService")
local HS = game:GetService("HttpService")
local queries = HS:JSONDecode(%s)
local out = {}
for _, q in ipairs(queries) do
	local res = { key = q.key, items = {} }
	local ok, err = pcall(function()
		local p = CatalogSearchParams.new()
		p.SearchKeyword = q.keyword or ""
		local types = {}
		for _, t in ipairs(q.types or {}) do
			table.insert(types, Enum.AvatarAssetType[t])
		end
		if #types > 0 then
			p.AssetTypes = types
		end
		if q.sort then
			p.SortType = Enum.CatalogSortType[q.sort]
		end
		p.IncludeOffSale = q.offsale == true
		local pages = AES:SearchCatalog(p)
		local limit = q.limit or 12
		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				table.insert(res.items, { id = item.Id, name = item.Name, creator = item.CreatorName, price = item.Price, itemType = item.ItemType, assetType = item.AssetType })
				if #res.items >= limit then
					break
				end
			end
			if #res.items >= limit or pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
		end
	end)
	if not ok then
		res.error = tostring(err)
	end
	table.insert(out, res)
end
return HS:JSONEncode(out)
'''

def run_luau(code):
    path = os.path.join(os.environ.get("TMPDIR", "/tmp"), f"cat_{os.getpid()}.luau")
    open(path, "w").write(code)
    lines = lx.run(path)
    os.remove(path)
    for l in lines:
        if l.startswith("[") or l.startswith("{"):
            return json.loads(l), lines
    return None, lines

def thumbs(ids):
    urls = {}
    ids = [str(i) for i in ids]
    for k in range(0, len(ids), 50):
        chunk = ids[k:k + 50]
        for attempt in range(6):
            u = f"https://thumbnails.roblox.com/v1/assets?assetIds={','.join(chunk)}&size=420x420&format=Png"
            data = json.loads(urllib.request.urlopen(u, timeout=30).read())["data"]
            pending = [d for d in data if d.get("state") == "Pending"]
            for d in data:
                if d.get("imageUrl"):
                    urls[str(d["targetId"])] = d["imageUrl"]
            if not pending:
                break
            time.sleep(2)
    return urls

def contact(items, out_path, cols=6, size=180):
    rows = (len(items) + cols - 1) // cols or 1
    sheet = Image.new("RGB", (cols * size, rows * (size + 34)), (40, 40, 48))
    d = ImageDraw.Draw(sheet)
    urls = thumbs([it["id"] for it in items])
    for i, it in enumerate(items):
        x, y = (i % cols) * size, (i // cols) * (size + 34)
        u = urls.get(str(it["id"]))
        if u:
            try:
                im = Image.open(urllib.request.urlopen(u, timeout=30)).convert("RGBA").resize((size, size))
                bg = Image.new("RGBA", im.size, (200, 200, 210, 255))
                bg.alpha_composite(im)
                sheet.paste(bg.convert("RGB"), (x, y))
            except Exception:
                pass
        d.text((x + 3, y + size + 2), str(it["id"]), fill=(255, 230, 120))
        d.text((x + 3, y + size + 17), str(it.get("name", ""))[:28], fill=(230, 230, 230))
    sheet.save(out_path, quality=86)

def cmd_search(qfile, outdir):
    os.makedirs(outdir, exist_ok=True)
    queries = json.load(open(qfile))
    res, lines = run_luau(SEARCH_LUAU % lua_str(json.dumps(queries)))
    if res is None:
        print("\n".join(lines[:20]))
        sys.exit("ERROR: la búsqueda no devolvió resultados")
    json.dump(res, open(os.path.join(outdir, "results.json"), "w"), ensure_ascii=False, indent=1)
    for r in res:
        if r.get("error"):
            print(f"{r['key']}: ERROR {r['error']}")
            continue
        p = os.path.join(outdir, r["key"] + ".jpg")
        if r["items"]:
            contact(r["items"], p)
        print(f"{r['key']}: {len(r['items'])} resultados -> {p}")

CHECK_LUAU = r'''
local HS = game:GetService("HttpService")
local Players = game:GetService("Players")
local outfits = HS:JSONDecode(%s)
local FIELDS = { hat = "HatAccessory", hair = "HairAccessory", face = "FaceAccessory", neck = "NeckAccessory",
	shoulders = "ShouldersAccessory", front = "FrontAccessory", back = "BackAccessory", waist = "WaistAccessory" }
local out = {}
for id, o in pairs(outfits) do
	local r = { id = id }
	local ok, err = pcall(function()
		local d = Instance.new("HumanoidDescription")
		local want = 0
		for k, f in pairs(FIELDS) do
			if o[k] then
				local list = {}
				for _, v in ipairs(o[k]) do table.insert(list, string.format("%%.0f", v)); want += 1 end
				d[f] = table.concat(list, ",")
			end
		end
		if o.shirt then d.Shirt = o.shirt end
		if o.pants then d.Pants = o.pants end
		if o.faceId then d.Face = o.faceId end
		if o.layered and #o.layered > 0 then
			local acc = {}
			for i, l in ipairs(o.layered) do
				table.insert(acc, { AccessoryType = Enum.AccessoryType[l.type], AssetId = l.id, IsLayered = true, Order = i })
				want += 1
			end
			d:SetAccessories(acc, false) -- false: solo cambia la ropa 3D, no quita pelo/sombreros
		end
		local rig = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
		local got, names = 0, {}
		for _, a in ipairs(rig:GetChildren()) do
			if a:IsA("Accessory") then got += 1; table.insert(names, a.Name) end
		end
		r.want, r.got = want, got
		r.shirt = rig:FindFirstChildOfClass("Shirt") ~= nil
		r.pants = rig:FindFirstChildOfClass("Pants") ~= nil
		r.size = string.format("%%.1f", rig:GetExtentsSize().Y)
		r.names = table.concat(names, ", ")
		rig:Destroy()
	end)
	if not ok then r.error = tostring(err) end
	table.insert(out, r)
end
return HS:JSONEncode(out)
'''

def cmd_check(ofile):
    outfits = json.load(open(ofile))
    res, lines = run_luau(CHECK_LUAU % lua_str(json.dumps(outfits)))
    if res is None:
        print("\n".join(lines[:20]))
        sys.exit("ERROR: la comprobación no devolvió resultados")
    bad = 0
    for r in sorted(res, key=lambda r: r["id"]):
        if r.get("error"):
            bad += 1
            print(f"❌ {r['id']}: {r['error']}")
        else:
            okk = r["got"] >= r["want"]
            bad += 0 if okk else 1
            print(f"{'✅' if okk else '⚠️'} {r['id']}: prendas {r['got']}/{r['want']} · camisa {r['shirt']} · pantalón {r['pants']} · alto {r['size']} · {r['names'][:160]}")
    print("TODO OK" if bad == 0 else f"{bad} con problemas")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    if sys.argv[1] == "search":
        cmd_search(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "check":
        cmd_check(sys.argv[2])
    elif sys.argv[1] == "thumbs":
        contact([{"id": i} for i in sys.argv[2].split(",")], sys.argv[3])
    else:
        sys.exit(__doc__)
