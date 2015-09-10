//
//  PPAppDelegateProxy.h
//
//
//  Created by Ivan Fabijanovic on 09/09/15.
//
//

/**
 Notifications posted by the proxy.
 */
extern NSString* const PPDidReceiveRemoteNotification;
extern NSString* const PPDidRegisterForRemoteNotifications;
extern NSString* const PPDidFailToRegisterForRemoteNotifications;

@interface PPAppDelegateProxy : NSObject

/**
 Initializes and attaches the proxy to the AppDelegate.
 */
+ (void)proxyAppDelegate;

/**
 Gets the notification application was launched with. Returns nil
 if app was not launched from notification.
 */
+ (NSDictionary *)launchNotification;

@end
