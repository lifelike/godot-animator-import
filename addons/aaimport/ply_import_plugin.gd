tool
extends "aa_import_plugin.gd"

func get_importer_name():
  return "aaimport.ply"

func get_visible_name():
  return "Animator Polygon or Path"

func get_recognized_extensions():
  return ["ply"]

func get_save_extension():
  return "scn"

func get_resource_type():
  return "PackedScene"
  
func get_preset_count():
  return 1

func get_preset_name(preset):
  return "Default"
  
func get_import_options(preset):
  return []
  
func get_option_visibility(option, options):
  return true

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
  var file = File.new()
  var err = file.open(source_file, File.READ)
  if err != OK:
    return err
  if file.get_len() < 14:
    return ERR_FILE_UNRECOGNIZED
  var nr_points = file.get_16()
  file.get_32() # 4 bytes of zero
  var closed = file.get_8() # 1=closed, otherwise open
  var magic = file.get_8()
  if magic != 0x99:
    print("Expected magic byte at offset 7 to be 0x99, but was: 0x%x"
      % [magic])
    return ERR_FILE_UNRECOGNIZED
  var curve = Curve2D.new()
  var first
  for n in nr_points:
    var x = file.get_16()
    var y = file.get_16()
    var z = file.get_16() # always 0
    var point = Vector2(x, y)
    if !first:
      first = point
    curve.add_point(point)
  if closed == 1:
    curve.add_point(first) 
  var packed_scene = PackedScene.new()
  var path = Path2D.new()
  var name = source_file.get_file()
  path.set_name(name)
  path.set_curve(curve)
  packed_scene.pack(path)
  ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], packed_scene)
  
