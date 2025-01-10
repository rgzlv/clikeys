#include <stdlib.h>
#include <assert.h>
#include <stdio.h>
#include <string.h>

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

#define ERR(ret, msg) do { \
		NSLog(msg); \
		return ret; \
	} while (0)
#define ERRF(ret, fmt, ...) do { \
		NSLog(fmt, __VA_ARGS__); \
		return ret; \
	} while (0)
#define ERREXIT(msg) do { \
		NSLog(msg); \
		exit(EXIT_FAILURE); \
	} while (0)
#define ERREXITF(fmt, ...) do { \
		NSLog(fmt, __VA_ARGS__); \
		exit(EXIT_FAILURE); \
	} while (0)
#define DECARG(count) do { argc -= count; argv += count; } while (0)
#define CSTR_TO_REF(cstr, ref) \
	( \
	ref = CFStringCreateWithCString(NULL, cstr, kCFStringEncodingASCII), \
	assert(ref), \
	ref \
	)

typedef int (*cmd_func)(int argc, const char **argv);

// Returns the property key constant parsed from a C string name for use in
// TISGetInputSourceProperty.
CFStringRef cstr_to_prop_key(const char *name) {
	if (!name) ERR(NULL, @"empty property name");
	if (!strcmp(name, "src-cat")) return kTISPropertyInputSourceCategory;
	if (!strcmp(name, "src-type")) return kTISPropertyInputSourceType;
	if (!strcmp(name, "is-ascii")) return kTISPropertyInputSourceIsASCIICapable;
	if (!strcmp(name, "can-enable")) return kTISPropertyInputSourceIsEnableCapable;
	if (!strcmp(name, "can-select")) return kTISPropertyInputSourceIsSelectCapable;
	if (!strcmp(name, "is-enabled")) return kTISPropertyInputSourceIsEnabled;
	if (!strcmp(name, "is-selected")) return kTISPropertyInputSourceIsSelected;
	if (!strcmp(name, "src-id")) return kTISPropertyInputSourceID;
	if (!strcmp(name, "bundle-id")) return kTISPropertyBundleID;
	if (!strcmp(name, "mode-id")) return kTISPropertyInputModeID;
	if (!strcmp(name, "name")) return kTISPropertyLocalizedName;
	if (!strcmp(name, "langs")) return kTISPropertyInputSourceLanguages;
	if (!strcmp(name, "unicode-keys")) return kTISPropertyUnicodeKeyLayoutData;
	// kTISPropertyIconRef omitted.
	if (!strcmp(name, "icon-url")) return kTISPropertyIconImageURL;
	ERRF(NULL, @"invalid property key '%s'", name);
}

// Returns whether the property value with key prop in src matched match after
// match is parsed as a property value.
bool cmp_prop_val(CFStringRef prop, TISInputSourceRef src, const char *match) {
	if (prop == kTISPropertyInputSourceCategory || prop == kTISPropertyInputSourceType
		|| prop == kTISPropertyInputSourceID || prop == kTISPropertyBundleID
		|| prop == kTISPropertyInputModeID || prop == kTISPropertyLocalizedName) {
			CFStringRef prop_val = TISGetInputSourceProperty(src, prop);
			if (!prop_val) return false;
			CFStringRef match_val;
			CSTR_TO_REF(match, match_val);
			if (CFStringCompare(prop_val, match_val, 0) == kCFCompareEqualTo) return true;
	} else
		ERREXIT(@"unhandled property");
	return false;
}

// Returns the first TIS source from srcs, which is an array of TIS sources,
// matching a property value with key prop_key and prop_val_str when parsed as a
// property value.
TISInputSourceRef find_src(CFArrayRef srcs, CFStringRef prop_key, const char *prop_val_str) {
	assert(srcs);
	assert(prop_key);
	assert(prop_val_str);
	CFIndex src_count = CFArrayGetCount(srcs);
	TISInputSourceRef matched = NULL;
	for (CFIndex i = 0; i < src_count; i++) {
		TISInputSourceRef src = (TISInputSourceRef)CFArrayGetValueAtIndex(srcs, i);
		if (!src) continue;
		if (cmp_prop_val(prop_key, src, prop_val_str)) {
			matched = src;
			break;
		}
	}
	return matched;
}

// Wraps find_src by getting the values for it from argc and argv.
// Sets argc and argv to the new values after parsing.
TISInputSourceRef find_src_args(int *argc, const char ***argv) {
	if (!*argc) ERR(NULL, @"missing property key");
	const char *arg_prop_key = **argv; *argc -= 1; *argv += 1;
	CFStringRef prop_key;
	if (!(prop_key = cstr_to_prop_key(arg_prop_key))) return NULL;
	if (!*argc) ERR(NULL, @"missing property value");
	const char *arg_prop_val = **argv; *argc -= 1; *argv += 1;

	CFArrayRef srcs = TISCreateInputSourceList(NULL, true);
	if (!srcs) ERR(NULL, @"couldn't get list of input sources");
	TISInputSourceRef matched = find_src(srcs, prop_key, arg_prop_val);
	if (!matched) ERR(NULL, @"couldn't find input source with matching property and value");
	return matched;
}

// Convenience function that wraps find_src_args and calls either one of the
// 4 Carbon functions that have signatures that match fn's type.
int find_call_src_args(int *argc, const char ***argv, OSStatus (*fn)(TISInputSourceRef src)) {
	TISInputSourceRef matched = find_src_args(argc, argv);
	if (!matched) return 1;
	OSStatus ret;
	if ((ret = fn(matched)) != noErr)
		ERRF(1, @"failed with error code: %d", ret);
	return 0;
}

int list_all_inputs(int argc, const char **argv) {
	#define PROP_KEYS_LEN 16
	CFStringRef prop_keys[PROP_KEYS_LEN] = {0};
	for (int i = 0; argc; i++) {
		prop_keys[i] = cstr_to_prop_key(*argv);
		if (!prop_keys[i]) return 1;
		DECARG(1);
	}

	CFArrayRef srcs = TISCreateInputSourceList(NULL, true);
	if (!srcs) ERR(1, @"NULL input source list");
	CFIndex src_count = CFArrayGetCount(srcs);

	if (prop_keys[0] == NULL) {
		NSLog(@"%@\ncount: %ld\n", srcs, src_count);
		return 0;
	}

	for (CFIndex isrc = 0; isrc < src_count; isrc++) {
		NSString *s = [NSString new];
		bool found = false;
		for (int iprop = 0; iprop < PROP_KEYS_LEN; iprop++) {
			CFStringRef prop_key = prop_keys[iprop];
			if (!prop_key) break;
			TISInputSourceRef src = (TISInputSourceRef)CFArrayGetValueAtIndex(srcs, isrc);
			if (!src) continue;
			id prop_val = TISGetInputSourceProperty(src, prop_key);
			if (!prop_val) continue;
			s = [s stringByAppendingFormat:@(iprop ? ", %@" : "%@"), prop_val];
			found = true;
		}
		if (found) NSLog(@"%@\n", s);
	}
	NSLog(@"count: %ld", src_count);

	return 0;
	#undef PROP_KEYS_LEN
}

int show_current_input(int argc, const char **argv) {
	TISInputSourceRef cur_src = TISCopyCurrentKeyboardInputSource();
	if (!cur_src) ERR(1, @"NULL current input source");
	NSLog(@"%@", cur_src);	
	return 0;
}

int select_input(int argc, const char **argv) {
	return find_call_src_args(&argc, &argv, TISSelectInputSource);
}

int deselect_input(int argc, const char **argv) {
	return find_call_src_args(&argc, &argv, TISDeselectInputSource);
}

int enable_input(int argc, const char **argv) {
	return find_call_src_args(&argc, &argv, TISEnableInputSource);
}

int disable_input(int argc, const char **argv) {
	return find_call_src_args(&argc, &argv, TISDisableInputSource);
}

int main(int argc, const char **argv) {
	@autoreleasepool {
		if (argc < 2) ERR(EXIT_FAILURE, @"expected 1 or more arguments");
		cmd_func fn = NULL;
		DECARG(1);
		if (!strcmp(*argv, "list")) fn = list_all_inputs;
		else if (!strcmp(*argv, "current")) fn = show_current_input;
		else if (!strcmp(*argv, "select")) fn = select_input;
		else if (!strcmp(*argv, "deselect")) fn = deselect_input;
		else if (!strcmp(*argv, "enable")) fn = enable_input;
		else if (!strcmp(*argv, "disable")) fn = disable_input;
		if (!fn) ERR(EXIT_FAILURE, @"invalid command");
		DECARG(1);
		if (fn(argc, argv)) return EXIT_FAILURE;
		return EXIT_SUCCESS;
	}
	return EXIT_SUCCESS;
}
