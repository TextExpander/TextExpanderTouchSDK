# Bitcode

The TextExpander.framework in this folder was compiled with Bitcode enabled using Xcode 7.0 beta 4 (7A165t). It cannot be shipped with production apps. It is provided solely for testing purposes.

** DO NOT SHIP THIS FRAMEWORK IN YOUR APP!**

To test for the presence of Bitcode, you should be able to use these commands:

otool -arch armv7 -l TextExpander.framework/Versions/A/TextExpander | grep -i llvm
otool -arch armv7s -l TextExpander.framework/Versions/A/TextExpander | grep -i llvm
otool -arch arm64 -l TextExpander.framework/Versions/A/TextExpander | grep -i llvm

The response for each command should be:
   segname __LLVM

Note: There appears to be a bug in otool such that if you try doing just otool -l on a fat binary which includes x86 code, otool will only return one of the iOS architectures rather than headers for each contained architecture followed by its load commands.

To my surprise and delight, I found that I was able to use this framework to build the TextExpanderDemoApp and run it on both the Simulator and a Device (an iPhone 5s), both running iOS 8.4. Your milage may vary. This appears to suggest that we'll be able to ship a single framework to support both iOS 8 and iOS 9, which includes Bitcode. I expect App Store Bitcode support will be limited to apps which target only iOS 9.

