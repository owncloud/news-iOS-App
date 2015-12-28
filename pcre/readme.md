##Compile libpcre##

####Device####

`$ ./configure --disable-shared --enable-utf8 --host=arm-apple-darwin CFLAGS="-arch armv7 -fembed-bitcode -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.2.sdk" CXXFLAGS="-arch armv7 -fembed-bitcode -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.2.sdk" LDFLAGS="-L." CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc" CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++"`

`$ make`

`$ mv .libs/ libs1`

`$ ./configure --disable-shared --enable-utf8 --host=arm-apple-darwin CFLAGS="-arch armv7s -fembed-bitcode -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.2.sdk" CXXFLAGS="-arch armv7s -fembed-bitcode -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.2.sdk" LDFLAGS="-L." CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc" CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++"`

`$ make`

`$ mv .libs/ libs2`

`$ ./configure --disable-shared --enable-utf8 --host=arm-apple-darwin CFLAGS="-arch arm64 -fembed-bitcode -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.2.sdk" CXXFLAGS="-arch arm64 -fembed-bitcode -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS9.2.sdk" LDFLAGS="-L." CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/cc" CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++"`

`$ make`

`$ mv .libs/ libs3`

####Simulator####

`$ ./configure --disable-shared --enable-utf8 CFLAGS="-miphoneos-version-min=8.0 -arch i386 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" CXXFLAGS="-miphoneos-version-min=8.0 -arch i386 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" LDFLAGS="-L." CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"`

`$ make`

`$ mv .libs/ libs4`

`$ ./configure --disable-shared --enable-utf8 CFLAGS="-miphoneos-version-min=8.0 -arch x86_64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" CXXFLAGS="-miphoneos-version-min=8.0 -arch x86_64 -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk" LDFLAGS="-L." CC="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" CXX="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"`

`$ make`

`$ mv .libs/ libs5`

####Fat libraries####

`$ lipo -create libs1/libpcre.a libs2/libpcre.a libs3/libpcre.a libs4/libpcre.a libs5/libpcre.a -output libs_universal/libpcre.a`

`$ lipo -create libs1/libpcrecpp.a libs2/libpcrecpp.a libs3/libpcrecpp.a libs4/libpcrecpp.a libs5/libpcrecpp.a -output libs_universal/libpcrecpp.a`

`$ lipo -create libs1/libpcreposix.a libs2/libpcreposix.a libs3/libpcreposix.a libs4/libpcreposix.a libs5/libpcreposix.a -output libs_universal/libpcreposix.a`

####Headers#

`$ cp pcre*.h`
