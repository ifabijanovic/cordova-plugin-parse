//
//  CDVParsePlugin.m
//
//
//  Created by Ivan Fabijanovic on 08/09/15.
//
//

#import "CDVParsePlugin.h"
#import <Parse/Parse.h>

@implementation CDVParsePlugin

#pragma mark - Plugin methods

- (void)initialize:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *result = nil;
    
    if (command.arguments.count >= 2) {
        NSString *applicationId = [command.arguments objectAtIndex:0];
        NSString *clientKey = [command.arguments objectAtIndex:1];
        
        [Parse setApplicationId:applicationId clientKey:clientKey];
        
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Parse plugin must be initialized with applicationId and clientKey arguments"];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)registerForNotificationTypes:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *result = nil;
    
    if (command.arguments.count >= 1) {
        id notificationTypesMask = [command.arguments objectAtIndex:0];
        
        if ([notificationTypesMask isKindOfClass:[NSNumber class]]) {
            [self registerForNotificationsWithMask:[notificationTypesMask intValue]];
        }
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Register for notification types expects a types bitmask argument"];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

#pragma mark - Private methods

- (void)registerForNotificationsWithMask:(int)mask
{
    UIApplication *app = [UIApplication sharedApplication];
    
    if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        // iOS >= 8
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:mask categories:nil];
        [app registerUserNotificationSettings:settings];
        [app registerForRemoteNotifications];
    } else {
        // iOS < 8
        [app registerForRemoteNotificationTypes:mask];
    }
}

@end
