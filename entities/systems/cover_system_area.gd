extends Node3D

@onready var cover_marker_3d: Marker3D = $CoverMarker3D
@onready var cover_area: Area3D = $CoverArea
@onready var snap_area: Area3D = $SnapArea

func _on_cover_area_body_entered(body: Node3D) -> void:
	var target = body
	if target.is_in_group("Client"):
		Playerinfo.set_cover_tracker(true)
		Playerinfo.cover_handler(cover_marker_3d,cover_area)
	#signal into somewhere that asks "is the player ready for snapping in ?" and from there teleport the player into $Marker3D

func _on_cover_area_body_exited(body: Node3D) -> void:
	var target = body
	if target.is_in_group("Client"):
		Playerinfo.set_cover_tracker(false)

func _on_snap_area_body_entered(body: Node3D) -> void:
	var target = body
	if target.is_in_group("Client"):
		Playerinfo.cover_handler(cover_marker_3d,snap_area)


func _on_snap_area_body_exited(body: Node3D) -> void:
	var target = body
	if target.is_in_group("Client"):
		pass
