extends Node

class_name CertGen

var cert_filename = "certificate.crt"
var key_filename = "key.key"

@onready
var cert_path = "user://Certificate/"+cert_filename

@onready
var key_path = "user://Certificate/"+key_filename

var CN = "srt_server"
var O = "neutalus"
var C = "NL"

var not_before = "20231114000000"
var not_after = "20241113235900"

func _ready():
	if DirAccess.dir_exists_absolute("user://Certificate"):
		pass
	else:
		DirAccess.make_dir_absolute("user://Certificate")
	createCert()
	print("Certificate Created")
func createCert():
	var CNOC = "CN=" + CN + ",O=" + O + ",C=" + C
	var crypto = Crypto.new()
	var key = crypto.generate_rsa(4096)
	var cert = crypto.generate_self_signed_certificate(key, CNOC, not_before, not_after)
	cert.save(cert_path)
	key.save(key_path)
