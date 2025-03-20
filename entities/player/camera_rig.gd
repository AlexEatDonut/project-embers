extends Node3D

@onready var background_viewport: SubViewport = $CameraMarker3D/BaseCamera/BackgroundViewportContainer/BackgroundViewport
@onready var foreground_viewport: SubViewport = $CameraMarker3D/BaseCamera/ForegroundViewportContainer/ForegroundViewport
@onready var details_viewport: SubViewport = $CameraMarker3D/BaseCamera/DetailsViewportContainer/DetailsViewport


@onready var camera_marker_3d: Marker3D = $CameraMarker3D

@onready var background_camera: Camera3D = $CameraMarker3D/BaseCamera/BackgroundViewportContainer/BackgroundViewport/BackgroundCamera
@onready var foreground_camera: Camera3D = $CameraMarker3D/BaseCamera/ForegroundViewportContainer/ForegroundViewport/ForegroundCamera
@onready var details_camera: Camera3D = $CameraMarker3D/BaseCamera/DetailsViewportContainer/DetailsViewport/DetailsCamera


func _ready():
	resize();

func resize():
	background_viewport.size = DisplayServer.window_get_size()
	foreground_viewport.size = DisplayServer.window_get_size()
	details_viewport.size = DisplayServer.window_get_size()

func move_to_place():
	background_camera.global_transform = camera_marker_3d.global_transform
	foreground_camera.global_transform = camera_marker_3d.global_transform
	details_camera.global_transform = camera_marker_3d.global_transform

func _process(delta: float) -> void:
	move_to_place()
