VERSION?=3.0.0
BUILD_TS:=$(shell date +%s)

build:
	swift build -c release -Xswiftc -DBRX_BUILD_TS=$(BUILD_TS)

install: build
	install -m 0755 .build/release/BRX /usr/local/bin/brx

test:
	swift test

version:
	@echo $(VERSION) $(BUILD_TS)

clean:
	swift package clean

.PHONY: build install test version clean

