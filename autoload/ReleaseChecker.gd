## Consulta GitHub Releases y compara con la versión empaquetada del juego.
extends Node

signal check_finished(has_update: bool, latest_version: String, download_url: String)

const GITHUB_REPO: String = "kelliru69/boring"
const DOWNLOAD_URL: String = "https://github.com/kelliru69/boring/releases/download/latest/boring.zip"
const RELEASES_API_URL: String = "https://api.github.com/repos/%s/releases?per_page=1" % GITHUB_REPO
const DISMISS_SAVE_PATH: String = "user://dismissed_update_version.txt"
const REQUEST_TIMEOUT_SEC: float = 12.0

var latest_version: String = ""
var has_update: bool = false
var is_checking: bool = false

var _http: HTTPRequest


func get_local_version() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "0.0.0"))


func get_download_url() -> String:
	return DOWNLOAD_URL


func check_for_update() -> void:
	if is_checking:
		return
	is_checking = true
	_ensure_http()
	var err: int = _http.request(RELEASES_API_URL)
	if err != OK:
		is_checking = false
		check_finished.emit(false, "", DOWNLOAD_URL)


func open_download_page() -> void:
	OS.shell_open(DOWNLOAD_URL)


func dismiss_update(version: String) -> void:
	if version.is_empty():
		return
	var file := FileAccess.open(DISMISS_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(version)
		file.close()
	has_update = false
	check_finished.emit(false, version, DOWNLOAD_URL)


func is_update_dismissed(version: String) -> bool:
	if version.is_empty() or not FileAccess.file_exists(DISMISS_SAVE_PATH):
		return false
	var file := FileAccess.open(DISMISS_SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	return file.get_as_text().strip_edges() == version


func _ensure_http() -> void:
	if _http != null:
		return
	_http = HTTPRequest.new()
	_http.timeout = REQUEST_TIMEOUT_SEC
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	is_checking = false
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		check_finished.emit(false, "", DOWNLOAD_URL)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_ARRAY or parsed.is_empty():
		check_finished.emit(false, "", DOWNLOAD_URL)
		return
	var release: Dictionary = parsed[0]
	if release.is_empty() or bool(release.get("draft", true)):
		check_finished.emit(false, "", DOWNLOAD_URL)
		return
	latest_version = _normalize_version(String(release.get("tag_name", "")))
	if latest_version.is_empty():
		check_finished.emit(false, "", DOWNLOAD_URL)
		return
	var local_version: String = _normalize_version(get_local_version())
	has_update = _is_version_newer(latest_version, local_version)
	if has_update and is_update_dismissed(latest_version):
		has_update = false
	check_finished.emit(has_update, latest_version, DOWNLOAD_URL)


func _normalize_version(raw: String) -> String:
	return raw.strip_edges().trim_prefix("v").to_lower()


func _is_version_newer(remote: String, local: String) -> bool:
	if remote == local:
		return false
	var remote_key: Array = _version_tokens(remote)
	var local_key: Array = _version_tokens(local)
	var max_len: int = maxi(remote_key.size(), local_key.size())
	for i: int in max_len:
		var r: Variant = remote_key[i] if i < remote_key.size() else 0
		var l: Variant = local_key[i] if i < local_key.size() else 0
		if r == l:
			continue
		if typeof(r) != typeof(l):
			return str(r) > str(l)
		return r > l
	return false


func _version_tokens(version: String) -> Array:
	var normalized: String = _normalize_version(version)
	var chunks: PackedStringArray = normalized.split("-", false, 1)
	var tokens: Array = []
	for part: String in chunks[0].split(".", false):
		tokens.append(int(part) if part.is_valid_int() else 0)
	if chunks.size() > 1:
		tokens.append(chunks[1])
	return tokens
