//
//  PPPlugin.m
//
//
//  Created by Ivan Fabijanovic on 08/09/15.
//
//

#import "PPPlugin.h"

#import "PPAppDelegateProxy.h"
#import <Parse/Parse.h>

@implementation PPPlugin

#pragma mark - Plugin methods

- (void)initialize:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *result = nil;
    
    if (command.arguments.count >= 2) {
        NSString *applicationId = [command.arguments objectAtIndex:0];
        NSString *clientKey = [command.arguments objectAtIndex:1];
        
        // Initialize Parse SDK
        [Parse setApplicationId:applicationId clientKey:clientKey];
        
        // Initialize the App Delegate proxy
        [PPAppDelegateProxy proxyAppDelegate];
        
        // Register App Delegate proxy notification handlers
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveRemoteNotification:) name:PPDidReceiveRemoteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRegisterForRemoteNotifications:) name:PPDidRegisterForRemoteNotifications object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToRegisterForRemoteNotifications:) name:PPDidFailToRegisterForRemoteNotifications object:nil];
        
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
        NSNumber *notificationTypesMask = [command.arguments objectAtIndex:0];
        
        [self registerForNotificationsWithMask:[notificationTypesMask intValue]];
        
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Register for notification types expects a types bitmask argument"];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)getLaunchNotification:(CDVInvokedUrlCommand *)command
{
    NSDictionary *launchNotification = [PPAppDelegateProxy launchNotification];
    
    NSString *message = launchNotification ? [self messageForUserInfo:launchNotification] : @"";
    NSDictionary *extras = launchNotification ? [self extrasForUserInfo:launchNotification] : @{};
    
    NSDictionary *data = [self notificationWithMessage:message extras:extras active:NO opened:YES];
    
    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:data];
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)getChannels:(CDVInvokedUrlCommand *)command
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error){
        CDVPluginResult *result = nil;
        
        if (!error) {
            PFInstallation *installation = (PFInstallation *)object;
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:installation.channels];
        } else {
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error description]];
        }
        
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)setBadgeNumber:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *result = nil;
    
    if (command.arguments.count >= 1) {
        NSNumber *value = [command.arguments objectAtIndex:0];
        
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setBadge:[value intValue]];
        [currentInstallation saveInBackground];
        
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Set badge number expectes a badge value argument"];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setAlias:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *result = nil;
    
    if (command.arguments.count >= 1) {
        NSString *value = [command.arguments objectAtIndex:0];
        
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setObject:value forKey:@"alias"];
        [currentInstallation saveInBackground];
        
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Set badge number expectes a badge value argument"];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void)setChannels:(CDVInvokedUrlCommand *)command
{
    CDVPluginResult *result = nil;
    
    if (command.arguments.count >= 1) {
        NSArray *channels = [command.arguments objectAtIndex:0];
        
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setChannels:channels];
        [currentInstallation saveInBackground];
        
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Set channels expects a channels array argument"];
    }
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

#pragma mark - Proxy notification handlers

- (void)didReceiveRemoteNotification:(NSNotification *)notification
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setBadge:0];
    [currentInstallation saveInBackground];
    
    NSString *alert = [self messageForUserInfo:notification.userInfo];
    NSDictionary *extras = [self extrasForUserInfo:notification.userInfo];
    BOOL active = [[UIApplication sharedApplication] applicationState] == UIApplicationStateActive;
    
    [self raisePush:alert withExtras:extras active:active opened:NO];
}

- (void)didRegisterForRemoteNotifications:(NSNotification *)notification
{
    NSString *deviceToken = [notification.userInfo objectForKey:@"deviceToken"];
    [self raiseEvent:@"registration" withData:[NSString stringWithFormat:@"'Registered for remote notifications with device token: %@'", deviceToken]];
}

- (void)didFailToRegisterForRemoteNotifications:(NSNotification *)notification
{
    NSError *error = [notification.userInfo objectForKey:@"error"];
    [self raiseEvent:@"registration" withData:[NSString stringWithFormat:@"'%@'", [error description]]];
}

#pragma mark - Private methods

/**
 Registers this device to receive remote notifications
 */
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

/**
 Converts an NSDictionary into a string JSON representation.
 
 Returns an empty JSON object if serialization fails.
 */
- (NSString *)jsonFromDictionary:(NSDictionary *)dictionary
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    
    if (error) {
        return @"{}";
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

/**
 Retrieves the alert value from aps.
 */
- (NSString *)messageForUserInfo:(NSDictionary *)userInfo
{
    NSString *message = @"";
    
    if ([[userInfo allKeys] containsObject:@"aps"]) {
        NSDictionary *apsDict = [userInfo objectForKey:@"aps"];
        if ([[apsDict objectForKey:@"alert"] isKindOfClass:[NSString class]]) {
            message = [apsDict objectForKey:@"alert"];
        }
    }
    
    return message;
}

/**
 Retrieves all custom properties from the notification payload.
 */
- (NSMutableDictionary *)extrasForUserInfo:(NSDictionary *)userInfo
{
    NSMutableDictionary *extras = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    NSArray *keys = [extras allKeys];
    
    if ([keys containsObject:@"aps"]) {
        [extras removeObjectForKey:@"aps"];
    }
    if ([keys containsObject:@"_uamid"]) {
        [extras removeObjectForKey:@"_uamid"];
    }
    if ([keys containsObject:@"_"]) {
        [extras removeObjectForKey:@"_"];
    }
    
    return extras;
}
/**
 Constructs a payload dictionary from notification user info.
 */
- (NSDictionary *)notificationWithMessage:(NSString *)message extras:(NSDictionary *)extras active:(BOOL)active opened:(BOOL)opened
{
    return @{
             @"notification": @{
                     @"message": message,
                     @"extras": extras
                     },
             @"applicationState": @{
                     @"active": [NSNumber numberWithBool:active],
                     @"openedFromNotification": [NSNumber numberWithBool:opened]
                     }
             };
}

/**
 Raises an event in Javascript.
 */
- (void)raiseEvent:(NSString *)event withData:(NSString *)data
{
    NSString *js = [NSString stringWithFormat:@"plugins.parse.push.raiseEvent('%@', %@);", event, data];
    [self.commandDelegate evalJs:js scheduledOnRunLoop:NO];
}

/**
 Raises a push notification callback in Javascript.
 */
- (void)raisePush:(NSString *)message withExtras:(NSDictionary *)extras active:(BOOL)active opened:(BOOL)opened
{
    if (!message) {
        message = @"";
    }
    if (!extras) {
        extras = @{};
    }
    
    NSDictionary *data = [self notificationWithMessage:message extras:extras active:active opened:opened];
    NSString *json = [self jsonFromDictionary:data];
    
    [self raiseEvent:@"push" withData:json];
}

@end
