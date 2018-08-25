tool
extends EditorImportPlugin

func read_palette(file, alpha=false, nr=256):
  var colors = []
  for c in range(nr):
    var r = file.get_8() * 4
    var g = file.get_8() * 4
    var b = file.get_8() * 4
    colors.push_back(Color8(r, g, b))
  if alpha:
    colors[0] = Color8(0, 0, 0, 0)
  return colors

func save_stex(image, save_path):
  var tmppng = "%s-tmp.png" % [save_path]
  image.save_png(tmppng)
  var pngf = File.new()
  pngf.open(tmppng, File.READ)
  var pnglen = pngf.get_len()
  var pngdata = pngf.get_buffer(pnglen)
  pngf.close()
  Directory.new().remove(tmppng)
  var stexf = File.new()
  stexf.open("%s.stex" % [save_path], File.WRITE)
  stexf.store_8(0x47) # G
  stexf.store_8(0x44) # D
  stexf.store_8(0x53) # S
  stexf.store_8(0x54) # T
  stexf.store_32(image.get_width())
  stexf.store_32(image.get_height())
  stexf.store_32(4) # flags (whatever 4 is)
  stexf.store_32(0x07100000) # data format
  stexf.store_32(1) # nr mipmaps
  stexf.store_32(pnglen + 6)
  stexf.store_8(0x50) # P
  stexf.store_8(0x4e) # N
  stexf.store_8(0x47) # G
  stexf.store_8(0x20) # space
  stexf.store_buffer(pngdata)
  stexf.close()