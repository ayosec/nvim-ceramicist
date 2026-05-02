.PHONY: all
all: test lint

.PHONY: test
test:
	tests/run

.PHONY: lint
lint:
	luacheck lua tests --globals a vim
