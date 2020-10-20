PACKAGE_NAME := github.com/dstotijn/hetty
GOLANG_CROSS_VERSION ?= v1.15.2

ifeq ($(OS),Windows_NT)
EXE=extension.exe
LIB_EXT=dll
RM=cmd /c del
LDFLAG=
else
EXE=extension
ifeq ($(shell uname -s),Darwin)
LIB_EXT=dylib
else
LIB_EXT=so
endif
RM=rm -f
LDFLAG=-fPIC
endif
LIB=sqlite3_mod_regexp.$(LIB_EXT)

setup:
	go mod download
	go generate ./...
.PHONY: setup

embed:
	go install github.com/GeertJohan/go.rice/rice
	cd cmd/hetty && rice embed-go
.PHONY: embed

$(LIB): sqlite3_mod_regexp.c
	gcc $(LDFLAG) -shared -o $@ $< -lsqlite3 -lpcre

build: embed $(LIB)
	env CGO_ENABLED=1 go build ./cmd/hetty
.PHONY: build

clean:
	rm -rf cmd/hetty/rice-box.go
.PHONY: clean

release-dry-run:
	@docker run \
		--rm \
		-v `pwd`:/go/src/$(PACKAGE_NAME) \
		-v `pwd`/admin/dist:/go/src/$(PACKAGE_NAME)/admin/dist \
		-w /go/src/$(PACKAGE_NAME) \
		troian/golang-cross:${GOLANG_CROSS_VERSION} \
		--rm-dist --skip-validate --skip-publish
.PHONY: release-dry-run

release:
	@if [ ! -f ".release-env" ]; then \
		echo "\033[91mFile \`.release-env\` is missing.\033[0m";\
		exit 1;\
	fi
	@docker run \
		--rm \
		-v `pwd`:/go/src/$(PACKAGE_NAME) \
		-v `pwd`/admin/dist:/go/src/$(PACKAGE_NAME)/admin/dist \
		-w /go/src/$(PACKAGE_NAME) \
		--env-file .release-env \
		troian/golang-cross:${GOLANG_CROSS_VERSION} \
		release --rm-dist
.PHONY: release