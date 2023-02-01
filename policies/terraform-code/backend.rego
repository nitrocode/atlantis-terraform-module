package backend

import future.keywords

default allow := false

allow if {
	input.terraform[0].backend.s3[0].bucket != ""
	input.terraform[0].backend.s3[0].key != ""
	input.terraform[0].backend.s3[0].region != ""
}

deny contains msg if {
	not allow
	msg := "Invalid backend"
}
