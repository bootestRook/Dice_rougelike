extends Node
class_name AutomationBridge


const DEFAULT_PORT := 24886


var root_view: MainPrototypeView = null
var server := TCPServer.new()
var clients: Array[Dictionary] = []
var port: int = DEFAULT_PORT
var running: bool = false


func setup(new_root_view: MainPrototypeView, requested_port: int = DEFAULT_PORT) -> void:
	root_view = new_root_view
	port = requested_port
	_start_server()


func _exit_tree() -> void:
	for entry in clients:
		var peer := entry.get("peer") as StreamPeerTCP
		if peer != null:
			peer.disconnect_from_host()
	clients.clear()
	server.stop()
	running = false


func _process(_delta: float) -> void:
	if not running:
		return
	_accept_pending_clients()
	_poll_clients()


func _start_server() -> void:
	var error := server.listen(port, "127.0.0.1")
	if error != OK:
		push_warning("自动化接口启动失败：%s" % [error_string(error)])
		return
	running = true
	set_process(true)
	print("自动化接口已启动：127.0.0.1:%d" % [port])


func _accept_pending_clients() -> void:
	while server.is_connection_available():
		var peer := server.take_connection()
		if peer == null:
			return
		peer.set_no_delay(true)
		clients.append({
			"peer": peer,
			"buffer": "",
		})


func _poll_clients() -> void:
	var kept_clients: Array[Dictionary] = []
	for entry in clients:
		var peer := entry.get("peer") as StreamPeerTCP
		if peer == null:
			continue
		var status := peer.get_status()
		if status == StreamPeerTCP.STATUS_NONE or status == StreamPeerTCP.STATUS_ERROR:
			continue
		if peer.get_available_bytes() > 0:
			var chunk := peer.get_utf8_string(peer.get_available_bytes())
			entry["buffer"] = str(entry.get("buffer", "")) + chunk
			_flush_client_lines(entry)
		kept_clients.append(entry)
	clients = kept_clients


func _flush_client_lines(entry: Dictionary) -> void:
	var buffer := str(entry.get("buffer", ""))
	while buffer.contains("\n"):
		var line_end := buffer.find("\n")
		var line := buffer.substr(0, line_end).strip_edges()
		buffer = buffer.substr(line_end + 1)
		if line != "":
			_handle_client_line(entry, line)
	entry["buffer"] = buffer


func _handle_client_line(entry: Dictionary, line: String) -> void:
	var request = JSON.parse_string(line)
	if not request is Dictionary:
		_send_response(entry, {
			"ok": false,
			"error": "请求必须是 JSON 对象。",
		})
		return

	var response := _handle_request(request)
	_send_response(entry, response)


func _send_response(entry: Dictionary, response: Dictionary) -> void:
	var peer := entry.get("peer") as StreamPeerTCP
	if peer == null:
		return
	var text := JSON.stringify(response) + "\n"
	peer.put_data(text.to_utf8_buffer())


func _handle_request(request: Dictionary) -> Dictionary:
	if root_view == null:
		return _error("主视图尚未绑定。")

	var command := StringName(str(request.get("cmd", "")))
	var args = request.get("args", {})
	if not args is Dictionary:
		args = {}

	match command:
		&"ping":
			return _ok({"message": "pong"})
		&"snapshot":
			return _ok({"snapshot": root_view.automation_get_snapshot()})
		&"set_input_lock":
			root_view.automation_set_input_locked(bool(args.get("locked", true)))
			return _ok({"snapshot": root_view.automation_get_snapshot()})
		&"start_run":
			return _ok(root_view.automation_start_run())
		&"select_dice":
			return root_view.automation_select_dice(_int_array(args.get("indices", [])))
		&"preview_selection":
			return root_view.automation_preview_selection(_int_array(args.get("indices", [])))
		&"preview_selections":
			return root_view.automation_preview_selections(_int_array_batch(args.get("selections", [])))
		&"reroll":
			return root_view.automation_reroll()
		&"score":
			return root_view.automation_score()
		&"choose_reward":
			return root_view.automation_choose_reward(int(args.get("index", -1)))
		&"install_piece":
			return root_view.automation_install_piece(
				int(args.get("die_index", -1)),
				int(args.get("face_index", -1))
			)
		_:
			return _error("未知自动化命令：%s" % [str(command)])


func _int_array(value) -> Array[int]:
	var result: Array[int] = []
	if not value is Array:
		return result
	for item in value:
		result.append(int(item))
	return result


func _int_array_batch(value) -> Array:
	var result: Array = []
	if not value is Array:
		return result
	for item in value:
		result.append(_int_array(item))
	return result


func _ok(data: Dictionary = {}) -> Dictionary:
	var response := {"ok": true}
	for key in data.keys():
		response[key] = data[key]
	return response


func _error(message: String) -> Dictionary:
	return {
		"ok": false,
		"error": message,
	}
