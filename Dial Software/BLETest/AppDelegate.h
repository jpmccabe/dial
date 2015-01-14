//
//  AppDelegate.h
//  BLETest
//
//  Created by Patrick mccabe on 7/27/14.
//  Copyright (c) 2014 Patrick mccabe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, CBCentralManagerDelegate, CBPeripheralDelegate>{
    CBCentralManager *manager;
    CBPeripheral *testPeripheral;
}

@property (assign) IBOutlet NSWindow *window;

- (void) startScan;
- (void) stopScan;
@end
