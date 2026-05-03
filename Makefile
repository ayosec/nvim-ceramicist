.PHONY: all
all: doc test lint

.PHONY: doc
doc: doc/ceramicist.txt

doc/ceramicist.txt: doc/generate.sh README.md lua/ceramicist/config.lua
	doc/generate.sh README.md lua/ceramicist/config.lua

.PHONY: test
test:
	tests/run

.PHONY: lint
lint:
	luacheck lua tests --globals a vim
