tool
extends EditorPlugin

var cel_import_plugin
var mask_import_plugin
var flic_import_plugin
var ply_import_plugin
var col_import_plugin

func _enter_tree():
  cel_import_plugin = preload("cel_import_plugin.gd").new()
  mask_import_plugin = preload("mask_import_plugin.gd").new()
  flic_import_plugin = preload("flic_import_plugin.gd").new()
  ply_import_plugin = preload("ply_import_plugin.gd").new()
  col_import_plugin = preload("col_import_plugin.gd").new()
  add_import_plugin(cel_import_plugin)
  add_import_plugin(mask_import_plugin)
  add_import_plugin(flic_import_plugin)
  add_import_plugin(ply_import_plugin)
  add_import_plugin(col_import_plugin)

func _exit_tree():
  remove_import_plugin(cel_import_plugin)
  remove_import_plugin(mask_import_plugin)
  remove_import_plugin(flic_import_plugin)
  remove_import_plugin(ply_import_plugin)
  remove_import_plugin(col_import_plugin)
  cel_import_plugin = null
  mask_import_plugin = null
  flic_import_plugin = null
  ply_import_plugin = null
  col_import_plugin = null
