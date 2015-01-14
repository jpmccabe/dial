//
//  AppDelegate.m
//  BLETest
//
//  Created by Patrick mccabe on 7/27/14.
//  Copyright (c) 2014 Patrick mccabe. All rights reserved.
//

#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation AppDelegate

@synthesize window;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    //[self startScan];
}



- (void) dealloc{
    [self stopScan];
    [testPeripheral setDelegate:nil];
}


// disconnect peripheral when application terminates
- (void) applicationWillTerminate:(NSNotification *)notification{
    if(testPeripheral){
        [manager cancelPeripheralConnection:testPeripheral];
    }
}


/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error{
    
    if( aPeripheral ){
        [manager cancelPeripheralConnection:aPeripheral];
        [aPeripheral setDelegate:nil];
        aPeripheral = nil;
    }
    NSLog(@"Disconnecting");
    [self startScan];
}




- (void) centralManagerDidUpdateState:(CBCentralManager *)central{
    [self isLECapableHardware];
    
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        NSLog(@"is on");
        [self startScan];
    }
}


/*
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE. An alert is raised if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([manager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:state];
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
    return FALSE;
}


/*
 Request CBCentralManager to scan for peripherals
 */
- (void) startScan
{
    NSLog(@"Start Scan");
    //[manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"80F290C5-278E-41CB-A2F9-6C1CBE18B730"]] options:nil];
    [manager scanForPeripheralsWithServices:nil options:nil];

}


/*
 Request CBCentralManager to stop scanning for peripherals
 */
- (void) stopScan
{
    [manager stopScan];
}



/*
 Invoked when the central discovers a peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Did Discover Peripheral");
    testPeripheral = aPeripheral;
    [self stopScan];
    [manager connectPeripheral:testPeripheral options:nil];
}



/*
 Invoked whenever a connection is succesfully created with the peripheral.
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral
{
    NSLog(@"Did Connect Peripheral");
    [aPeripheral setDelegate:self];
    [aPeripheral discoverServices:nil];
}


/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
        NSLog(@"Service found with UUID: %@", aService.UUID);
        if ([aService.UUID isEqual:[CBUUID UUIDWithString:@"80f290c5-278e-41cb-a2f9-6c1cbe18b730"]])
        {
            [aPeripheral discoverCharacteristics:nil forService:aService];
        }
//        
//        // GAP (Generic Access Profile) for Device Name
//        if ( [aService.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
//        {
//            [aPeripheral discoverCharacteristics:nil forService:aService];
//        }
    }
}


/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"80f290c5-278e-41cb-a2f9-6c1cbe18b730"]])
    {
        for (CBCharacteristic *aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:@"80f290c6-278e-41cb-a2f9-6c1cbe18b730"]])
            {
                [aPeripheral setNotifyValue:YES forCharacteristic:aChar];
            }
        }
    }
    
//    if ( [service.UUID isEqual:[CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]] )
//    {
//        for (CBCharacteristic *aChar in service.characteristics)
//        {
//            /* Read device name */
//            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
//            {
//                [aPeripheral readValueForCharacteristic:aChar];
//               // NSLog(@"Found a Device Name Characteristic");
//            }
//        }
//    }
}


/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"80f290c6-278e-41cb-a2f9-6c1cbe18b730"]])
    {
        if( (characteristic.value)  || !error ){
            [self dataByte:characteristic.value];
        }
    }
    
    /* Value for device Name received */
    else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:CBUUIDDeviceNameString]])
    {
        NSString * deviceName = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        NSLog(@"Device Name = %@", deviceName);
    }
    
}



- (void) dataByte:(NSData *)data
{
    uint8_t *p = (uint8_t*)[data bytes];
    NSUInteger len = [data length];
    
    uint8_t dataAsByte = len ? *p : 0;
    char dataAsChar = (char)dataAsByte;
    NSLog(@"Data: %c", dataAsChar);
    
    if(dataAsChar == 'i'){
        NSString* path = [[NSBundle mainBundle] pathForResource:@"volume_increase" ofType:@"scpt"];
        NSURL* url = [NSURL fileURLWithPath:path];NSDictionary* errors = [NSDictionary dictionary];
        NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
        [appleScript executeAndReturnError:nil];
    }
    
    if(dataAsChar == 'd'){
        NSString* path = [[NSBundle mainBundle] pathForResource:@"volume_decrease" ofType:@"scpt"];
        NSURL* url = [NSURL fileURLWithPath:path];NSDictionary* errors = [NSDictionary dictionary];
        NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
        [appleScript executeAndReturnError:nil];
    }
    
    if(dataAsChar == 'm'){
        NSString* path = [[NSBundle mainBundle] pathForResource:@"mute" ofType:@"scpt"];
        NSURL* url = [NSURL fileURLWithPath:path];NSDictionary* errors = [NSDictionary dictionary];
        NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
        [appleScript executeAndReturnError:nil];
    }
    
    if(dataAsChar == 's'){
        NSString* path = [[NSBundle mainBundle] pathForResource:@"play_pause" ofType:@"scpt"];
        NSURL* url = [NSURL fileURLWithPath:path];NSDictionary* errors = [NSDictionary dictionary];
        NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
        [appleScript executeAndReturnError:nil];
    }
    
    if(dataAsChar == 'w'){
        NSString* path = [[NSBundle mainBundle] pathForResource:@"next" ofType:@"scpt"];
        NSURL* url = [NSURL fileURLWithPath:path];NSDictionary* errors = [NSDictionary dictionary];
        NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
        [appleScript executeAndReturnError:nil];
    }
    
    if(dataAsChar == 'h'){
        NSString* path = [[NSBundle mainBundle] pathForResource:@"back" ofType:@"scpt"];
        NSURL* url = [NSURL fileURLWithPath:path];NSDictionary* errors = [NSDictionary dictionary];
        NSAppleScript* appleScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
        [appleScript executeAndReturnError:nil];
    }
    
}



@end
