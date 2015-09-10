//
//  PPPlugin.h
//
//
//  Created by Ivan Fabijanovic on 08/09/15.
//
//

/**
 
 Notification JSON payload:
 
 {
 "notification": {
 "message": "notification text",
 "extras": {
 any additional payload parameters
 }
 },
 "applicationState": {
 "active": true/false,
 "openedFromNotification": true/false
 }
 }
 
 */

#import <Cordova/CDVPlugin.h>

@interface PPPlugin : CDVPlugin

/**
 Initialize the plugin and Parse SDK.
 
 Expectes two arguments:
 1. Parse applicationId (string)
 2. Parse clientKey (string)
 */
- (void)initialize:(CDVInvokedUrlCommand *)command;

/**
 Registers this device to receive notifications of specified type.
 
 Expects one argument:
 1. UIUserNotificationType bitmask (integer)
 */
- (void)registerForNotificationTypes:(CDVInvokedUrlCommand *)command;

/**
 Gets the notification application was launched with.
 
 Returns a standard notification JSON payload. If app was not launched
 from a notification message and extras will be empty.
 */
- (void)getLaunchNotification:(CDVInvokedUrlCommand *)command;

/**
 Gets a list of channels the current installation is registered to.
 
 Returns an array of strings.
 */
- (void)getChannels:(CDVInvokedUrlCommand *)command;

/**
 Sets the application badge to the specified value.
 
 Expects one argument:
 1. Badge number value (integer)
 */
- (void)setBadgeNumber:(CDVInvokedUrlCommand *)command;

/**
 Sets the alias for this Parse installation.
 
 Expects one argument:
 1. Alias value (string)
 */
- (void)setAlias:(CDVInvokedUrlCommand *)command;

/**
 Sets channels the current installation is registered to.
 
 Expects one argument:
 1. Channels the installation should be subscribed to (array of strings).
 */
- (void)setChannels:(CDVInvokedUrlCommand *)command;

@end
