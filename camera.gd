extends Camera


export var move_cloudplane := false


func _process(_delta: float) -> void:
    var progress := OS.get_ticks_msec() * 0.00005
    var distance := cos(progress + 0.5) * 50.0 + 200.0
    look_at_from_position(
        Vector3(sin(progress) * distance, 10.0, cos(progress) * distance),
        Vector3.UP * 50.0,
        Vector3.UP
    )
    if move_cloudplane:
        $"../Cloudplane".transform.origin.x = transform.origin.x
        $"../Cloudplane".transform.origin.z = transform.origin.z
