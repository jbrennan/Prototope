//
//  AppDelegate.swift
//  Protocaster
//
//  Created by Andy Matuschak on 2/6/15.
//  Copyright (c) 2015 Khan Academy. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var scanner: ProtoscopeScanner!

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		scanner = ProtoscopeScanner(
			serviceDidAppearHandler: { service in
				println(service.name)
			},
			serviceDidDisappearHandler: { service in
				println(service.name)
			}
		)
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}


}

