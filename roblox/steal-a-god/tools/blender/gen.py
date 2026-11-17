# Generador de personajes para Steal a God (Blender, sin interfaz)
# Uso: bpyenv/bin/python gen.py -- <salida> <id> [<id> ...]
import bpy, bmesh, math, sys, os, json
from mathutils import Vector, Matrix

OUT = sys.argv[sys.argv.index("--") + 1]
IDS = sys.argv[sys.argv.index("--") + 2:]

def rgb(r, g, b):
    return (r / 255, g / 255, b / 255)

# ---------------------------------------------------------------- utilidades
class Builder:
    def __init__(self):
        bpy.ops.wm.read_factory_settings(use_empty=True)
        self.parts = {}   # grupo -> [objetos]
        self.colors = []  # paleta
        self.objcolor = {}

    def color_index(self, c):
        c = tuple(round(x, 3) for x in c)
        if c not in self.colors:
            self.colors.append(c)
        return self.colors.index(c)

    def _finish(self, o, group, color, smooth=True):
        if smooth:
            for p in o.data.polygons:
                p.use_smooth = True
        self.objcolor[o.name] = self.color_index(color)
        self.parts.setdefault(group, []).append(o)
        return o

    def sphere(self, group, loc, scale, color, seg=20, ring=12, rot=(0, 0, 0)):
        bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=ring, radius=1, location=loc, rotation=rot)
        o = bpy.context.active_object
        o.scale = scale
        return self._finish(o, group, color)

    def limb(self, group, a, b, r1, r2, color, seg=14):
        a, b = Vector(a), Vector(b)
        d = b - a
        bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r1, radius2=r2, depth=d.length, location=(a + b) / 2)
        o = bpy.context.active_object
        o.rotation_mode = 'QUATERNION'
        o.rotation_quaternion = d.to_track_quat('Z', 'Y')
        self._finish(o, group, color)
        self.sphere(group, a, (r1, r1, r1), color, 12, 8)
        self.sphere(group, b, (r2, r2, r2), color, 12, 8)
        return o

    def cone(self, group, a, b, r1, r2, color, seg=16, smooth=True):
        a, b = Vector(a), Vector(b)
        d = b - a
        bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r1, radius2=r2, depth=d.length, location=(a + b) / 2)
        o = bpy.context.active_object
        o.rotation_mode = 'QUATERNION'
        o.rotation_quaternion = d.to_track_quat('Z', 'Y')
        return self._finish(o, group, color, smooth)

    def box(self, group, loc, size, color, rot=(0, 0, 0), bevel=0.08):
        bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
        o = bpy.context.active_object
        o.scale = size
        bpy.ops.object.transform_apply(scale=True)
        if bevel > 0:
            m = o.modifiers.new("b", 'BEVEL')
            m.width = bevel
            m.segments = 2
            bpy.ops.object.modifier_apply(modifier="b")
        return self._finish(o, group, color, smooth=False)

    def torus(self, group, loc, R, r, color, rot=(0, 0, 0)):
        bpy.ops.mesh.primitive_torus_add(major_radius=R, minor_radius=r, major_segments=24, minor_segments=8, location=loc, rotation=rot)
        o = bpy.context.active_object
        return self._finish(o, group, color)

    def cyl(self, group, loc, r, depth, color, rot=(0, 0, 0), seg=20):
        bpy.ops.mesh.primitive_cylinder_add(vertices=seg, radius=r, depth=depth, location=loc, rotation=rot)
        o = bpy.context.active_object
        return self._finish(o, group, color)

    # ------------------------------------------------------------ salida
    def build(self, name, joints):
        n = max(1, len(self.colors))
        cells = 16
        size = 256
        img = bpy.data.images.new(name + "_pal", size, size)
        px = [0.0] * (size * size * 4)
        for i, c in enumerate(self.colors):
            cx, cy = i % cells, i // cells
            for y in range(cy * 16, cy * 16 + 16):
                for x in range(cx * 16, cx * 16 + 16):
                    k = (y * size + x) * 4
                    px[k:k + 4] = [c[0], c[1], c[2], 1.0]
        img.pixels = px
        img.filepath_raw = os.path.join(OUT, name + "_pal.png")
        img.file_format = 'PNG'
        img.save()
        mat = bpy.data.materials.new(name + "_mat")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Roughness"].default_value = 0.55
        tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = img
        tex.interpolation = 'Closest'
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
        # UV de cada pieza al centro de su color
        for group, objs in self.parts.items():
            for o in objs:
                idx = self.objcolor[o.name]
                u = ((idx % cells) * 16 + 8) / size
                v = ((idx // cells) * 16 + 8) / size
                if not o.data.uv_layers:
                    o.data.uv_layers.new()
                for l in o.data.uv_layers.active.data:
                    l.uv = (u, v)
                o.data.materials.clear()
                o.data.materials.append(mat)
        result = []
        for group, objs in self.parts.items():
            bpy.ops.object.select_all(action='DESELECT')
            for o in objs:
                o.select_set(True)
            bpy.context.view_layer.objects.active = objs[0]
            if len(objs) > 1:
                bpy.ops.object.join()
            o = bpy.context.active_object
            o.name = group
            o.data.name = group
            bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
            result.append(o)
        return result, mat


# ---------------------------------------------------------------- humano base
SKIN = rgb(236, 196, 160)

def humanoid(B, L):
    """L: diccionario de aspecto. Coordenadas: Z arriba, -Y es el frente."""
    skin = L.get("skin", SKIN)
    robe = L.get("robe", rgb(245, 244, 238))
    trim = L.get("trim", rgb(232, 186, 60))
    hair = L.get("hair", rgb(90, 60, 35))
    s = L.get("bulk", 1.0)
    # piernas (grupo propio para animarlas)
    for side, g in ((-1, "LegL"), (1, "LegR")):
        B.limb(g, (side * 0.42, 0, 2.3), (side * 0.46, 0, 0.45), 0.36 * s, 0.27 * s, L.get("legs", skin))
        B.sphere(g, (side * 0.46, -0.18, 0.22), (0.3, 0.46, 0.2), L.get("boots", rgb(140, 95, 55)))
    # falda / túnica
    B.cone("Body", (0, 0, 3.0), (0, 0, 1.25), 0.95 * s, 1.2 * s, robe, seg=24)
    # torso
    B.sphere("Body", (0, 0, 3.75), (1.05 * s, 0.68 * s, 1.05), L.get("chest", robe), 24, 16)
    if L.get("muscles") and L.get("chest") == skin:
        for side in (-1, 1):
            B.sphere("Body", (side * 0.42 * s, -0.52 * s, 4.05), (0.42, 0.22, 0.32), skin)
    B.torus("Body", (0, 0, 3.0), 0.98 * s, 0.11, trim)
    if L.get("sash", True):
        B.box("Body", (0.1, -0.66 * s, 3.65), (0.22, 0.06, 1.7), L.get("sash_color", trim), rot=(0, math.radians(30), 0), bevel=0.03)
    # hombreras / mangas
    for side in (-1, 1):
        B.sphere("Body", (side * 1.02 * s, 0, 4.35), (0.42 * s, 0.42 * s, 0.38), L.get("shoulder", robe))
    # cuello y cabeza
    B.cyl("Body", (0, 0, 4.75), 0.28, 0.4, skin)
    hy = 5.35
    head = L.get("head", "human")
    if head == "human":
        B.sphere("Body", (0, 0, hy), (0.62, 0.6, 0.68), skin, 24, 16)
        B.sphere("Body", (0, -0.6, hy - 0.05), (0.11, 0.12, 0.14), tuple(c * 0.92 for c in skin))
        for side in (-1, 1):
            B.sphere("Body", (side * 0.22, -0.52, hy + 0.12), (0.12, 0.06, 0.12), (1, 1, 1))
            B.sphere("Body", (side * 0.22, -0.575, hy + 0.12), (0.065, 0.03, 0.07), rgb(30, 40, 70))
            B.box("Body", (side * 0.23, -0.56, hy + 0.3), (0.26, 0.06, 0.07), hair, rot=(0, math.radians(side * -12), 0), bevel=0.02)
        # pelo
        B.sphere("Body", (0, 0.06, hy + 0.2), (0.66, 0.64, 0.6), hair, 20, 10)
        B.sphere("Body", (0, 0.3, hy - 0.2), (0.6, 0.38, 0.7), hair)
        if L.get("beard"):
            B.sphere("Body", (0, -0.42, hy - 0.5), (0.5, 0.3, 0.55), L.get("beard_color", hair))
            B.sphere("Body", (0, -0.5, hy - 0.95), (0.3, 0.2, 0.35), L.get("beard_color", hair))
        else:
            B.box("Body", (0, -0.6, hy - 0.28), (0.24, 0.04, 0.05), rgb(150, 70, 60), bevel=0.02)
    elif head == "jackal":
        B.sphere("Body", (0, 0, hy), (0.55, 0.6, 0.6), skin, 24, 16)
        B.cone("Body", (0, -0.35, hy - 0.05), (0, -1.25, hy - 0.2), 0.36, 0.14, skin)
        B.sphere("Body", (0, -1.26, hy - 0.2), (0.12, 0.1, 0.1), rgb(20, 20, 20))
        for side in (-1, 1):
            B.cone("Body", (side * 0.3, 0.05, hy + 0.35), (side * 0.42, 0.1, hy + 1.35), 0.2, 0.02, skin, seg=8, smooth=False)
            B.cone("Body", (side * 0.3, 0.0, hy + 0.4), (side * 0.41, 0.04, hy + 1.2), 0.12, 0.01, rgb(200, 120, 120), seg=8, smooth=False)
            B.sphere("Body", (side * 0.24, -0.42, hy + 0.18), (0.11, 0.06, 0.07), rgb(255, 210, 60))
        # tocado
        B.sphere("Body", (0, 0.25, hy - 0.25), (0.75, 0.5, 0.85), L.get("nemes", rgb(40, 80, 190)))
        for k in range(4):
            B.torus("Body", (0, 0.25, hy - 0.6 + k * 0.25), 0.66, 0.05, trim)
    # brazos (grupos propios)
    for side, g in ((-1, "ArmL"), (1, "ArmR")):
        hand = (side * 1.45 * s, -0.25 if side > 0 else 0, 2.85)
        B.limb(g, (side * 1.05 * s, 0, 4.25), hand, 0.3 * s, 0.24 * s, skin)
        B.sphere(g, hand, (0.3, 0.3, 0.3), skin)
        B.torus(g, (side * 1.36 * s, -0.1 if side > 0 else 0, 3.25), 0.27 * s, 0.06, trim, rot=(0, 0, 0))
    joints = {
        "LegL": (-0.42, 0, 2.3), "LegR": (0.42, 0, 2.3),
        "ArmL": (-1.05 * s, 0, 4.25), "ArmR": (1.05 * s, 0, 4.25),
    }
    return joints, (1.45 * s, -0.25, 2.85), hy


# ---------------------------------------------------------------- objetos
def item_bolt(B, hand):
    x, y, z = hand
    pts = [(0, 0, 0), (0.35, 0, 0.9), (-0.1, 0, 1.1), (0.45, 0, 2.2), (0.05, 0, 1.4), (0.5, 0, 1.25), (0.0, 0, 0.0)]
    for i in range(3):
        a = Vector(pts[i * 2]) + Vector((x, y - 0.1, z + 0.1))
        b = Vector(pts[i * 2 + 1]) + Vector((x, y - 0.1, z + 0.1))
        B.cone("ArmR", a, b, 0.17, 0.07, rgb(255, 245, 120), seg=6, smooth=False)
    B.cone("ArmR", (x + 0.45, y - 0.1, z + 2.3), (x - 0.05, y - 0.1, z + 3.4), 0.2, 0.0, rgb(255, 245, 120), seg=6, smooth=False)

def item_hammer(B, hand):
    x, y, z = hand
    B.cyl("ArmR", (x, y - 0.1, z + 0.35), 0.11, 1.5, rgb(110, 70, 40))
    B.box("ArmR", (x, y - 0.1, z + 1.25), (0.95, 0.6, 0.6), rgb(170, 178, 192), bevel=0.12)
    B.torus("ArmR", (x, y - 0.1, z + 1.25), 0.32, 0.06, rgb(255, 200, 60), rot=(0, math.radians(90), 0))
    B.sphere("ArmR", (x, y - 0.1, z - 0.45), (0.14, 0.14, 0.14), rgb(255, 200, 60))

def item_staff(B, hand, top=rgb(240, 190, 50), ankh=False):
    x, y, z = hand
    B.cyl("ArmR", (x, y - 0.1, z + 0.9), 0.08, 4.6, rgb(230, 190, 70))
    if ankh:
        B.torus("ArmR", (x, y - 0.1, z + 3.45), 0.25, 0.07, top, rot=(math.radians(90), 0, 0))
        B.box("ArmR", (x, y - 0.1, z + 3.12), (0.75, 0.14, 0.14), top, bevel=0.03)
    else:
        B.sphere("ArmR", (x, y - 0.1, z + 3.3), (0.26, 0.26, 0.26), top)

def item_axe(B, hand):
    x, y, z = hand
    B.cyl("ArmR", (x, y - 0.15, z + 0.6), 0.14, 3.6, rgb(90, 60, 40))
    for sx in (-1, 1):
        B.sphere("ArmR", (x + sx * 0.75, y - 0.15, z + 2.1), (0.75, 0.12, 0.62), rgb(180, 185, 195))


# ---------------------------------------------------------------- tocados
def crown(B, hy, color=rgb(255, 205, 60)):
    B.cyl("Body", (0, 0.02, hy + 0.55), 0.62, 0.22, color)
    for k in range(7):
        a = k / 7 * math.pi * 2
        B.cone("Body", (math.cos(a) * 0.6, math.sin(a) * 0.6 + 0.02, hy + 0.62), (math.cos(a) * 0.62, math.sin(a) * 0.62 + 0.02, hy + 1.05), 0.12, 0.0, color, seg=6, smooth=False)
    B.sphere("Body", (0, -0.6, hy + 0.58), (0.1, 0.06, 0.1), rgb(80, 180, 255))

def winged_helmet(B, hy):
    B.sphere("Body", (0, 0.02, hy + 0.32), (0.7, 0.68, 0.5), rgb(170, 175, 190))
    B.torus("Body", (0, 0.02, hy + 0.12), 0.66, 0.06, rgb(230, 190, 60))
    for side in (-1, 1):
        for k in range(3):
            B.box("Body", (side * (0.75 + k * 0.12), 0.1, hy + 0.55 + k * 0.18), (0.08, 0.55 - k * 0.1, 0.22), (0.97, 0.97, 0.97), rot=(math.radians(-20), math.radians(side * 30), 0), bevel=0.03)


# ---------------------------------------------------------------- dioses
def god_zeus(B):
    L = {"robe": rgb(246, 244, 236), "trim": rgb(240, 190, 50), "hair": rgb(238, 238, 245), "beard": True, "muscles": True, "bulk": 1.1, "chest": rgb(246, 244, 236), "boots": rgb(200, 160, 80)}
    joints, hand, hy = humanoid(B, L)
    crown(B, hy)
    item_bolt(B, hand)
    # capa azul real
    B.box("Body", (0, 0.62, 3.2), (2.1, 0.12, 3.3), rgb(60, 90, 200), rot=(math.radians(-8), 0, 0), bevel=0.05)
    return joints

def god_thor(B):
    L = {"robe": rgb(90, 95, 110), "chest": rgb(130, 135, 150), "trim": rgb(120, 85, 50), "hair": rgb(205, 85, 35), "beard": True, "muscles": True, "bulk": 1.15, "boots": rgb(90, 60, 40), "sash_color": rgb(110, 75, 45), "legs": rgb(70, 60, 55)}
    joints, hand, hy = humanoid(B, L)
    winged_helmet(B, hy)
    item_hammer(B, hand)
    B.box("Body", (0, 0.66, 3.1), (2.3, 0.12, 3.5), rgb(190, 30, 35), rot=(math.radians(-8), 0, 0), bevel=0.05)
    for side in (-1, 1):
        B.sphere("Body", (side * 0.75, -0.55, 4.3), (0.2, 0.08, 0.2), rgb(220, 200, 120))
    return joints

def god_anubis(B):
    L = {"head": "jackal", "skin": rgb(28, 28, 34), "robe": rgb(248, 244, 230), "chest": rgb(28, 28, 34), "trim": rgb(240, 190, 50), "nemes": rgb(40, 80, 190), "sash": False, "boots": rgb(240, 190, 50)}
    joints, hand, hy = humanoid(B, L)
    # collar ancho egipcio
    B.cyl("Body", (0, 0, 4.55), 0.95, 0.16, rgb(40, 80, 190))
    B.cyl("Body", (0, 0, 4.45), 1.0, 0.1, rgb(240, 190, 50))
    item_staff(B, hand, top=rgb(240, 190, 50), ankh=True)
    return joints


# ---------------------------------------------------------------- guardianes
def guardian_minotaur(B):
    fur = rgb(110, 62, 38)
    dark = rgb(70, 40, 25)
    horn = rgb(238, 228, 205)
    for side, g in ((-1, "LegL"), (1, "LegR")):
        B.limb(g, (side * 0.75, 0, 3.3), (side * 0.85, -0.2, 1.6), 0.62, 0.45, fur)
        B.limb(g, (side * 0.85, -0.2, 1.6), (side * 0.85, 0.15, 0.45), 0.42, 0.32, fur)
        B.sphere(g, (side * 0.85, -0.05, 0.25), (0.42, 0.5, 0.26), rgb(40, 30, 25))
    B.cone("Body", (0, 0, 3.4), (0, 0, 2.4), 1.2, 1.35, rgb(120, 40, 35), seg=20)
    B.torus("Body", (0, 0, 3.35), 1.18, 0.14, rgb(200, 160, 60))
    B.sphere("Body", (0, 0, 4.5), (1.55, 1.0, 1.35), fur, 24, 16)
    for side in (-1, 1):
        B.sphere("Body", (side * 0.62, -0.78, 4.9), (0.62, 0.38, 0.5), rgb(130, 75, 45))
        B.sphere("Body", (side * 1.45, 0, 5.25), (0.75, 0.72, 0.62), fur)
    for k in range(3):
        B.sphere("Body", (0, -0.86, 4.1 - k * 0.42), (0.55, 0.18, 0.17), rgb(130, 75, 45))
    hy = 6.35
    B.sphere("Body", (0, -0.35, hy), (0.85, 0.95, 0.85), fur, 24, 16)
    B.sphere("Body", (0, -1.1, hy - 0.3), (0.62, 0.55, 0.5), rgb(160, 110, 90))
    for side in (-1, 1):
        B.sphere("Body", (side * 0.22, -1.6, hy - 0.3), (0.1, 0.06, 0.1), rgb(30, 20, 15))
        B.sphere("Body", (side * 0.38, -0.95, hy + 0.3), (0.16, 0.08, 0.12), rgb(255, 60, 40))
        B.cone("Body", (side * 0.75, -0.3, hy + 0.35), (side * 1.55, -0.4, hy + 0.75), 0.24, 0.13, horn)
        B.cone("Body", (side * 1.55, -0.4, hy + 0.75), (side * 1.7, -0.65, hy + 1.45), 0.13, 0.0, horn)
        B.sphere("Body", (side * 0.9, -0.1, hy + 0.05), (0.32, 0.12, 0.22), dark)
    B.torus("Body", (0, -1.55, hy - 0.45), 0.2, 0.05, rgb(230, 190, 60), rot=(math.radians(90), 0, 0))
    for side, g in ((-1, "ArmL"), (1, "ArmR")):
        hand = (side * 2.1, -0.4, 3.0)
        B.limb(g, (side * 1.55, 0, 5.1), (side * 1.95, -0.1, 3.9), 0.58, 0.48, fur)
        B.limb(g, (side * 1.95, -0.1, 3.9), hand, 0.46, 0.38, fur)
        B.sphere(g, hand, (0.45, 0.45, 0.45), dark)
        B.torus(g, (side * 2.0, -0.2, 3.45), 0.42, 0.08, rgb(200, 160, 60))
    item_axe(B, (2.1, -0.4, 3.0))
    return {"LegL": (-0.75, 0, 3.3), "LegR": (0.75, 0, 3.3), "ArmL": (-1.55, 0, 5.1), "ArmR": (1.55, 0, 5.1)}


CHARS = {"zeus": god_zeus, "thor": god_thor, "anubis": god_anubis, "minotaur": guardian_minotaur}


# ---------------------------------------------------------------- render de vista previa
def preview(objs, path, height):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 48
    scene.cycles.device = 'CPU'
    scene.render.resolution_x = 700
    scene.render.resolution_y = 900
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("w")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.35, 0.45, 0.65, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 0.6
    bpy.ops.object.light_add(type='SUN', location=(5, -8, 12))
    sun = bpy.context.active_object
    sun.data.energy = 4
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(30))
    bpy.ops.object.light_add(type='AREA', location=(-6, -4, 6))
    fill = bpy.context.active_object
    fill.data.energy = 600
    fill.data.size = 6
    fill.rotation_euler = (math.radians(60), 0, math.radians(-55))
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
    floor = bpy.context.active_object
    fm = bpy.data.materials.new("floor")
    fm.use_nodes = True
    fm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.82, 0.8, 0.75, 1)
    floor.data.materials.append(fm)
    cam_d = height * 1.45
    bpy.ops.object.camera_add(location=(cam_d * 0.45, -cam_d, height * 0.72))
    cam = bpy.context.active_object
    scene.camera = cam
    target = Vector((0, 0, height * 0.52))
    direction = target - cam.location
    cam.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 50
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


for cid in IDS:
    B = Builder()
    joints = CHARS[cid](B)
    objs, mat = B.build(cid, joints)
    height = max((o.matrix_world @ v.co).z for o in objs for v in o.data.vertices)
    # datos para el juego: articulaciones (en studs, Y arriba, -Z al frente)
    meta = {"id": cid, "height": height, "joints": {k: [v[0], v[2], v[1]] for k, v in joints.items()}, "colors": len(B.colors)}
    with open(os.path.join(OUT, cid + ".json"), "w") as f:
        json.dump(meta, f)
    bpy.ops.object.select_all(action='SELECT')
    for o in bpy.context.scene.objects:
        if o.type != 'MESH':
            o.select_set(False)
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, cid + ".fbx"), use_selection=True, path_mode='COPY', embed_textures=True, global_scale=0.01, apply_unit_scale=True, axis_forward='-Z', axis_up='Y', object_types={'MESH'})
    preview(objs, os.path.join(OUT, cid + "_preview.png"), height)
    tris = sum(len(p.vertices) - 2 for o in objs for p in o.data.polygons)
    print("HECHO", cid, "altura", round(height, 2), "triángulos", tris)
