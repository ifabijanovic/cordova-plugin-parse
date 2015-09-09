//
//  ParsePushPlugin.h
//
//
//  Created by Ivan Fabijanovic on 08/09/15.
//
//

#import <Cordova/CDVPlugin.h>

@interface ParsePushPlugin : CDVPlugin

- (void)initialize:(CDVInvokedUrlCommand *)command;
- (void)registerForNotificationTypes:(CDVInvokedUrlCommand *)command;

@end
