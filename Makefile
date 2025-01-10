layouts_dir := ~/Library/Keyboard\ Layouts
keys_bundle := examplekeys.bundle
warn := -Wall -Wextra -Wpedantic
nowarn := -Wno-format-security -Wno-unused-parameter
override CFLAGS := $(warn) $(nowarn) $(CFLAGS)

.PHONY: install uninstall clean

clikeys: clikeys.m
	$(CC) -o $@ $(CFLAGS) -framework Foundation -framework Carbon $<

install: | $(layouts_dir)
	cp -R $(keys_bundle) $(layouts_dir)/$(keys_bundle)

uninstall:
	rm -rf $(layouts_dir)/$(keys_bundle)

$(layouts_dir):
	mkdir -p $(layouts_dir)

clean:
	rm -f clikeys
