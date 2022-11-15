ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

tests:; godot --path ${ROOT_DIR} -s test/test.gd
profile:; godot --path ${ROOT_DIR} -s test/profile.gd
