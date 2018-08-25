tool
extends "aa_import_plugin.gd"

func get_importer_name():
  return "aaimport.mask"

func get_visible_name():
  return "Animator Mask"

func get_recognized_extensions():
  return ["msk"]

func get_save_extension():
  return "tres"

func get_resource_type():
  return "BitMap"
  
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
  if file.get_len() != 8000:
    return ERR_FILE_UNRECOGNIZED
  var bitmap = BitMap.new()
  bitmap.create(Vector2(320, 200))
  for y in range(200):
    for x in range(320 / 8):
      var b = file.get_8()
      for d in range(8):
        bitmap.set_bit(Vector2(x * 8 + d, y), (b & 128) == 128)
        b <<= 1
  ResourceSaver.save("%s.%s" % [save_path, get_save_extension()], bitmap)
  