tool
extends "aa_import_plugin.gd"

func get_importer_name():
  return "aaimport.col"

func get_visible_name():
  return "Animator Palette (COL)"
  
func get_recognized_extensions():
  return ["col"]

func get_save_extension():
  return "stex"
  
func get_resource_type():
  return "StreamTexture"

func get_preset_count():
  return 1
  
func get_preset_name(preset):
  return "Default"

func get_import_options(preset):
  return [{"name": "alpha",
          "default_value": true},
          {"name": "columns",
          "default_value": 256}]
          
func get_option_visibility(option, options):
  return true
          
func import(source_file, save_path, options, r_platform_variants, r_gen_files):
  var file = File.new()
  var err = file.open(source_file, File.READ)
  if err != OK:
    return err
  if file.get_len() != 3 * 256:
    print("PAL wrong size, need RGB for 256 colors")
    return ERR_FILE_UNRECOGNIZED
  var colors = read_palette(file, options.alpha)
  var image = Image.new()
  var format = Image.FORMAT_RGBA8 if options.alpha else Image.FORMAT_RGB8
  if options.columns < 1 or options.columns > 256:
    print("Columns must be 1 to 256")
    return ERR_PARAMETER_RANGE_ERROR
  var width = options.columns
  var height = 256 / options.columns
  image.create(width, height, false, format)
  image.lock()
  var i = 0
  for y in range(height):
    for x in range(width):
      image.set_pixel(x, y, colors[i])
      i += 1
  image.unlock()
  save_stex(image, save_path)
  return OK