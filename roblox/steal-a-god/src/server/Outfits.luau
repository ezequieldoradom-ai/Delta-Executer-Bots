-- Ropa real del catálogo de Roblox para cada personaje (dioses, guardianes y vendedores).
-- Clave = id del personaje (Config.GODS[i].id, "g_<guardián>", "v_<vendedor>").
-- Campos (todos opcionales):
--   hat, hair, face, neck, shoulders, front, back, waist = { ids }   accesorios rígidos
--   layered = { { type = "Jacket", id = ... }, ... }                ropa 3D (Shirt, Pants, Jacket, Sweater, Shorts, DressSkirt, TShirt, LeftShoe, RightShoe)
--   shirt, pants = id                                               ropa clásica 2D
--   keep = { "item", "head", "wings" }                              piezas propias que se conservan (por defecto { "item" })
-- Si un personaje no está aquí, se viste como antes (piezas propias).
return {}
