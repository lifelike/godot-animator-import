tool
extends "aa_import_plugin.gd"

func get_importer_name():
  return "aaimport.celpic"

func get_visible_name():
  return "Animator CEL/PIC"
  
func get_recognized_extensions():
  return ["cel", "pic"]

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
          "default_value": true}]
          
func get_option_visibility(option, options):
  return true
          
func import(source_file, save_path, options, r_platform_variants, r_gen_files):
  var file = File.new()
  var err = file.open(source_file, File.READ)
  if err != OK:
    return err
  if file.get_16() != 0x9119:
    print("CEL/PIC file did not begin with expected magic 0x9119")
    return ERR_FILE_CORRUPT
  var width = file.get_16()
  var height = file.get_16()
  var x = file.get_16() # screen x of CEL; ignore?
  var y = file.get_16() # screen y of CEL; ignore?
  var bpp = file.get_8()
  if bpp != 8:
    print("CEL/PIC file with other than 8 bits per pixel not supported")
    return ERR_FILE_CORRUPT
  var compression_type = file.get_8()
  if compression_type != 0:
    print("CEL/PIC file with unsupported compression type %d"
      % compression_type)
    return ERR_FILE_CORRUPT
  var size = file.get_32()
  var expected_size = width * height
  if size != expected_size:
    print("CEL/PIC size %d not expected size %d (width x height)"
      % [size, expected_size])
    return ERR_FILE_CORRUPT
  for i in range(16):
    if file.get_8() != 0:
      print("CEL/PIC got != 0 header reserved byte %d" % i)
      return ERR_FILE_CORRUPT
  var colors = read_palette(file, options.alpha)
  var image = Image.new()
  var format = Image.FORMAT_RGBA8 if options.alpha else Image.FORMAT_RGB8
  image.create(width, height, false, format)
  image.lock()
  for y in range(height):
    for x in range(width):
      var i = file.get_8()
      image.set_pixel(x, y, colors[i])
  image.unlock()
  save_stex(image, save_path)
  return OK