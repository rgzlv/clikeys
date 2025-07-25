# clikeys

clikeys is a small program to interact with the macOS Text Input Sources (TIS)
part of Carbon using Objective-C.
TIS itself seems to be deprecated but I was unable to find any other library or
framework available on macOS that allows you to interact with the system
keyboard layouts in a similar way.
With clikeys you can query, select, deselect, enable and disable keyboard input
layouts, similar to how you'd do it through System Settings.
Registering inputs is also possible but there seems to be no API exposed to
deregister the inputs.
AFAIK the only way to register an input without clikeys is to logout and log
back in, which is kind of inconvenient.

## Useful links

- [Bundles](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/AboutBundles/AboutBundles.html)
- [Bundle structure](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html#//apple_ref/doc/uid/10000123i-CH101-SW1)
- [Application bundles (bundle structure)](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html#//apple_ref/doc/uid/10000123i-CH101-SW13)
- [Resources (bundle structure)](https://developer.apple.com/library/archive/documentation/CoreFoundation/Conceptual/CFBundles/BundleTypes/BundleTypes.html#//apple_ref/doc/uid/20001119-110730)
- [Keylayout](https://developer.apple.com/library/archive/technotes/tn2056/_index.html)
