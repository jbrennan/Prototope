# Prototope

Prototope is a lightweight, high-performance prototyping framework. Its goals are:
 * enabling rapid iteration
 * high performance execution
 * concepts easily mapped onto production implementation
 
This ([jbrennan repo](https://github.com/jbrennan/Prototope)) is an actively maintained fork of the project, which runs with the latest App Store version of Swift on current versions of iOS / OS X. New features are being added, and pull requests are welcome.

Interfaces to the API are available in Swift and JavaScript. The current implementation runs on iOS and OS X.

You can use Protocaster (a Mac app) to broadcast live-reloading JavaScript prototypes to Protoscope (an iOS app). This feature is currently broken, but you can currently still run JS-based prototypes local on the device.

Documentation is available [here](http://khan.github.io/Prototope/).

## Including prototope in your existing project

If you plan to include prototope as a submodule from within your project, you'll likely have to do the following from within your project

### getting it
```
    $ git submodule add https://github.com/jbrennan/Prototope
    $ git submodule update --init --recursive
```

the first adds prototope as a git submodule to your project (and clones it outright), but you need the second command in order to pull in prototope's dependencies (namely pop).

### adding it to xcode

This part is somewhat more involved.

1. under *Embedded Libraries*, add Prototope.framework
2. under *Build Settings -> Other Linker Flags*, add `-Objc -lc++`
3. under *Build Settings -> Header Search Paths*, add 
    * `$(SRCROOT)/Prototope/Prototope/`
    * `$(SRCROOT)/Prototope/ThirdParty/` (set it to be recursive)
4. under Build Settings -> Library Search Paths, add `$(SRCROOT)/Prototope/ThirdParty` (set it to be recursive)

### making sure things work

You should be able to test that you've imported everything if you can type `import Prototope` in your ViewController.swift file and if the project *builds*. Xcode may complain that it can't find the bridging header in the gutter, but it's a lie. It can, and if the project builds, you're in good shape.
