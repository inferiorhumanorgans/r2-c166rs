INST_DIR ?= ~/.config/radare2/plugins/
BIN_FILE ?= /dev/null
BUILD_MODE ?= debug
CARGO_TARGET_DIR?=$(shell pwd)/target
BUILD_DIR=${CARGO_TARGET_DIR}/${BUILD_MODE}
CARGO_FLAGS=
SHARED_EXT?=.so

ifeq ($(BUILD_MODE),release)
  CARGO_FLAGS+=--release
endif

all:
	@echo "Building ${BUILD_MODE}"
	@CARGO_TARGET_DIR=${CARGO_TARGET_DIR} cargo build ${CARGO_FLAGS}
	@echo

# Need to find the proper directory for rasm2 plugins :(
# https://github.com/radare/radare2/issues/4495
	@echo "Installing to ${INST_DIR}"
	@cp -f ${BUILD_DIR}/libc166_asm$(SHARED_EXT) ${BUILD_DIR}/libc166_analysis$(SHARED_EXT) ${BUILD_DIR}/libc166_bin$(SHARED_EXT) ${INST_DIR}/
	@echo

clean:
	@echo "Cleaning"
	@CARGO_TARGET_DIR=${CARGO_TARGET_DIR} cargo clean

run: all
	@echo Running ${TEST_FILE}
	@radare2 -q -i ${TEST_FILE} ${BIN_FILE}
	@echo

interactive: all
	@RUST_BACKTRACE=1 radare2 -a c166 -F c166-rom  ${BIN_FILE}

test-asm:
	@CARGO_TARGET_DIR=${CARGO_TARGET_DIR} cargo test --no-fail-fast -p c166-core c166

test-integration:
	@# Put this in a build target?
	@CARGO_TARGET_DIR=${CARGO_TARGET_DIR} cargo build ${CARGO_FLAGS}

	@# https://github.com/rust-lang/cargo/issues/5364
	@R2_ASM_PLUGIN=${BUILD_DIR}/libc166_asm$(SHARED_EXT) \
	 R2_ANALYSIS_PLUGIN=${BUILD_DIR}/libc166_analysis$(SHARED_EXT) \
	 CARGO_TARGET_DIR=${CARGO_TARGET_DIR} \
	 cargo test --no-fail-fast -Z package-features -p c166-analysis --features integration-tests esil::

test:
	@CARGO_TARGET_DIR=${CARGO_TARGET_DIR} cargo test --all --no-fail-fast -- --skip r2::bindgen_test_layout_max_align_t
