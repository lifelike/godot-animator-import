tool
extends "aa_import_plugin.gd"

const FLC_COLOR_256 = 4
const FLC_DELTA = 7
const FLI_COLOR_64 = 11
const FLI_LC = 12
const FLI_BLACK = 13
const FLI_BRUN = 15
const FLI_COPY = 16
const FLC_PSTAMP = 18

func get_importer_name():
  return "aaimport.fli"

func get_visible_name():
  return "Animator FLIC"

func get_recognized_extensions():
  return ["fli", "flc", "flic"]

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
    {"name": "clip",
    "default_value": Rect2(0, 0, 320, 200)},
    {"name": "max_texture_size",
    "default_value": Vector2(2048, 2048)},
    {"name": "start_frame",
    "default_value": 1},
    {"name": "end_frame",
    "default_value": 60}]

func get_option_visibility(option, options):
  return true

func get_signed_8(file):
  var v = file.get_8()
  if v > 127:
    return v - 256
  else:
    return v

func from_brun_lines(file, image, colors, starty, nrlines, width, brun):
  for y in range(starty, starty + nrlines):
    var x = 0
    var nrpackets = file.get_8()
    for packet in range(nrpackets):
      if not brun:
        var skip_count = file.get_8()
        x += skip_count
      var size_count = get_signed_8(file)
      if brun:
        size_count = -size_count
      if size_count > 0:
        for i in range(size_count):
          if x + i > width:
            return
          image.set_pixel(x + i, y, colors[file.get_8()])
        x += size_count
      else:
        var colorindex = file.get_8()
        var color = colors[colorindex]
        for i in range(-size_count):
          if x + i > width:
            return
          image.set_pixel(x + i, y, color)
        x -= size_count

func import(source_file, save_path, options, r_platform_variants, r_gen_files):
  if options.start_frame < 1:
    print("FLIC can not import from frame < 1")
    return ERR_PARAMETER_RANGE_ERROR
  if options.end_frame < options.start_frame:
    print("FLIC can not import frame end < frame start")
    return ERR_PARAMETER_RANGE_ERROR
  var file = File.new()
  var err = file.open(source_file, File.READ)
  if err != OK:
    return err
  var filesize = file.get_32() # ignore
  var filemagic = file.get_16()
  var is_flc = false
  if filemagic == 0xAF12:
    is_flc = true
  elif filemagic != 0xAF11:
    print("FLIC file magic number not expected 0xAF11 or 0xAF12")
    return ERR_FILE_CORRUPT
  var nrframes = file.get_16()
  if options.start_frame > nrframes:
    print("FLIC start_frame %d > %d (nr frames in FLI)"
      % [options.start_frame, nrframes])
    return ERR_PARAMETER_RANGE_ERROR
  var width = file.get_16()
  if width != 320 and not is_flc:
    print("FLI width %d is not 320" % [width])
    return ERR_FILE_CORRUPT
  var height = file.get_16()
  if height != 200 and not is_flc:
    print("FLI height %d is not 200" % [height])
    return ERR_FILE_CORRUPT
  var bpp = file.get_16()
  if bpp != 8:
    print("FLIC file with other than 8 bits per pixel not supported")
    return ERR_FILE_CORRUPT
  var flags = file.get_16() # ignored, should be 0 though
  var speed = file.get_16() # ignored?
  var next = file.get_32() # ignored, should be 0
  var frit = file.get_32() # ignored, should be 0, not sure what it does anyway
  for i in range(102):
    file.get_8() # ignored 0, for future expansion of format

  var colsfit = int(options.max_texture_size.x) / int(options.clip.size.x)
  var rowsfit = int(options.max_texture_size.y) / int(options.clip.size.y)
  var texture_size = Vector2(colsfit * options.clip.size.x,
    rowsfit * options.clip.size.y)

  var colors = make_empty_palette()
  var image = Image.new()
  var format = Image.FORMAT_RGBA8 if options.alpha else Image.FORMAT_RGB8
  image.create(texture_size.x, texture_size.y,
    false, format)
  image.lock()
  var frameimage = Image.new()
  frameimage.create(width, height, false, format)
  frameimage.lock()

  var framerect = Rect2(Vector2(0, 0), options.clip.size)

  # Frame numbers in import settings start at 1
  # (because frame numbers in Animator does)
  var firstframe = options.start_frame - 1
  var lastframe = min(options.start_frame + nrframes - 1,
    options.end_frame)

  for frame in range(lastframe) :
    var framestart = file.get_position()
    var framesize = file.get_32() # ignore
    var framemagic = file.get_16()
    if is_flc and framemagic == 0xF100: # prefix frame
      file.seek(framestart + framesize)
      continue
    if framemagic != 0xF1FA:
      print("FLIC file frame magic number not expected 0xF1FA or 0xF100")
      return ERR_FILE_CORRUPT
    var nrchunks = file.get_16()
    for i in range(8):
      file.get_8() # ignore 0, for future expansion of format
    for chunk in range(nrchunks):
      var chunkstart = file.get_position()
      var chunksize = file.get_32()
      var chunktype = file.get_16()

      if chunktype == FLI_BLACK:
        # FIXME there is probably a better way
        for y in range(height):
          for x in range(width):
            frameimage.set_pixel(x, y, colors[0])
      elif chunktype == FLI_LC:
        var skiplines = file.get_16()
        var nrlines = file.get_16()
        from_brun_lines(file, frameimage, colors, skiplines, nrlines, width,
          false)
      elif chunktype == FLI_COPY:
        for y in range(height):
          for x in range(width):
            var i = file.get_8()
            frameimage.set_pixel(x, y, colors[i])
      elif chunktype == FLI_COLOR_64 or chunktype == FLC_COLOR_256:
        var nr_packets = file.get_16()
        var c = 0
        for packet in range(nr_packets):
          c += file.get_8()
          var nr_colors = file.get_8()
          if nr_colors == 0:
            nr_colors = 256
          read_palette_into(file, colors,
            options.alpha, c, nr_colors,
            chunktype == FLC_COLOR_256)
          c += nr_colors
      elif chunktype == FLI_BRUN:
        from_brun_lines(file, frameimage, colors, 0, height, width, true)
      elif chunktype == FLC_DELTA:
        var y = 0
        var nr_lines = file.get_16()
        for line in range(nr_lines):
          var packet_count = 0
          var parsing_opcodes = true
          while parsing_opcodes:
            if y >= height:
              print("y ", y, " >= height ", height)
              return ERR_FILE_CORRUPT
            var opcode = file.get_16()
            var opcode_type = ((opcode & 0xC000) >> 14)
            match opcode_type:
              0:
                packet_count = opcode
                parsing_opcodes = false
              1:
                print("FLIC undefined FLC_DELTA opcode type 1")
                return ERR_FILE_CORRUPT
              2:
                var color = (opcode & 0xff)
                frameimage.set_pixel(width - 1, y, colors[color])
              3:
                var skip_lines = 0x7fff - (opcode & 0x7fff) # abs of two-complement
                y += skip_lines
                if y < 0:
                  print("y < 0")
                  return ERR_FILE_CORRUPT
          var x = 0
          for packet in range(packet_count):
            x += file.get_8() # column skip
            var count = get_signed_8(file)
            if count > 0: # copy count words to image
              if x >= width:
                print("x >= width")
                return ERR_FILE_CORRUPT
              for c in range(count * 2):
                if x >= width:
                  print("x >= width")
                  return ERR_FILE_CORRUPT
                frameimage.set_pixel(x, y, colors[file.get_8()])
                x += 1
            elif count < 0: # copy count copies of color to image
              var color1 = colors[file.get_8()]
              var color2 = colors[file.get_8()]
              for c in range(-count):
                if x >= width:
                  print("x >= width")
                  return ERR_FILE_CORRUPT
                frameimage.set_pixel(x, y, color1)
                x += 1
                if x >= width:
                  print("x >= width")
                  return ERR_FILE_CORRUPT
                frameimage.set_pixel(x, y, color2)
                x += 1
          y += 1
      elif chunktype == FLC_PSTAMP:
          pass # ignore FLC thumbnail
      else:
        print("FLIC unknown chunk type %d" % [chunktype])
      file.seek(chunkstart + chunksize)
    if frame >= firstframe:
      image.blit_rect(frameimage, options.clip, framerect.position)
      framerect.position.x += options.clip.size.x
      if framerect.position.x >= texture_size.x:
        framerect.position.x = 0
        framerect.position.y += options.clip.size.y
        if framerect.position.y + options.clip.size.y >= texture_size.y:
          if frame+1 < lastframe:
            print("warning: FLIC import no more room in texture with ",
              lastframe - frame, " frames remaining to read")
          break
  frameimage.unlock()
  image.unlock()
  save_stex(image, save_path)
  return OK
