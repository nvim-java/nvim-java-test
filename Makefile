SETUP_TEST=tests/setup-test.lua
BEFORE_TEST=tests/before-test.lua
TESTS_DIR=tests/

.PHONY: test

test:
	@nvim \
		--headless \
		-u ${SETUP_TEST} \
		"+PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${BEFORE_TEST}' }"
