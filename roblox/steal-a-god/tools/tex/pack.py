# Empaqueta todas las PNG de una carpeta en un FBX (texturas incrustadas) para subirlas a Roblox.
import bpy, sys, os
D = sys.argv[sys.argv.index("--") + 1]
bpy.ops.wm.read_factory_settings(use_empty=True)
names = sorted(f[:-4] for f in os.listdir(D) if f.endswith(".png"))
for i, name in enumerate(names):
    img = bpy.data.images.load(os.path.join(D, name + ".png"))
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = img
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bpy.ops.mesh.primitive_plane_add(size=2, location=(i * 3, 0, 0))
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
bpy.ops.export_scene.fbx(filepath=os.path.join(D, "tex.fbx"), path_mode='COPY', embed_textures=True, global_scale=0.01, apply_unit_scale=True, object_types={'MESH'})
print("ok", names)
