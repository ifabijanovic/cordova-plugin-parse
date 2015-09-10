//
//  PPAppDelegateProxy.m
//
//
//  Created by Ivan Fabijanovic on 09/09/15.
//
//

#import "PPAppDelegateProxy.h"

#import <objc/runtime.h>
#import <Parse/Parse.h>

NSString* const PPDidReceiveRemoteNotification = @"PPDidReceiveRemoteNotification";
NSString* const PPDidRegisterForRemoteNotifications = @"PPDidRegisterForRemoteNotifications";
NSString* const PPDidFailToRegisterForRemoteNotifications = @"PPDidFailToRegisterForRemoteNotifications";

static NSDictionary *launchNotification = nil;
static NSMutableDictionary *originalMethods = nil;

@implementation PPAppDelegateProxy

#pragma mark - Init

+ (void)load
{
    // Register this class to get notified when app finishes launching
    [[NSNotificationCenter defaultCenter] addObserver:[PPAppDelegateProxy class] selector:@selector(applicationDidFinishLaunching:) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

+ (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    // Unregister this notification handler
    [[NSNotificationCenter defaultCenter] removeObserver:[PPAppDelegateProxy class] name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    // Get the remote notification (if any) from the launch options
    NSDictionary *remoteNotification = [notification.userInfo objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    
    // Save this notification for later use
    launchNotification = remoteNotification;
}

#pragma mark - Public methods

+ (void)proxyAppDelegate {
    // originalMethods will store original methods before swizzling
    if (!originalMethods) {
        originalMethods = [NSMutableDictionary dictionary];
    }
    
    id delegate = [UIApplication sharedApplication].delegate;
    if (!delegate) {
        return;
    }
    
    Class delegateClass = [delegate class];
    
    // Check to make sure we do not already have entries for the delegate class
    if (originalMethods[NSStringFromClass(delegateClass)]) {
        return;
    }
    
    // application:didReceiveRemoteNotification:
    [PPAppDelegateProxy swizzle:@selector(application:didReceiveRemoteNotification:) implementation:(IMP)PPApplicationDidReceiveRemoteNotification class:delegateClass];
    
    // application:didRegisterForRemoteNotificationsWithDeviceToken:
    [PPAppDelegateProxy swizzle:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:) implementation:(IMP)PPApplicationDidRegisterForRemoteNotificationsWithDeviceToken class:delegateClass];
    
    // application:didFailToRegisterForRemoteNotificationsWithError:
    [PPAppDelegateProxy swizzle:@selector(application:didFailToRegisterForRemoteNotificationsWithError:) implementation:(IMP)PPApplicationDidFailToRegisterForRemoteNotificationsWithError class:delegateClass];
}

+ (NSDictionary *)launchNotification
{
    return launchNotification;
}

#pragma mark - App delegate swizzled methods

void PPApplicationDidReceiveRemoteNotification(id self, SEL _cmd, UIApplication *application, NSDictionary *userInfo) {
    // Post the received remote notification for plugin to handle
    [[NSNotificationCenter defaultCenter] postNotificationName:PPDidReceiveRemoteNotification object:self userInfo:userInfo];
    
    // Call the original method implementation
    IMP original = [PPAppDelegateProxy originalImplementation:_cmd class:[self class]];
    if (original) {
        ((void(*)(id, SEL, UIApplication *, NSDictionary*))original)(self, _cmd, application, userInfo);
    }
}

void PPApplicationDidRegisterForRemoteNotificationsWithDeviceToken(id self, SEL _cmd, UIApplication *application, NSData *deviceToken) {
    // Initialize Parse installation with received device token
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
    
    // Post the deviceToken for plugin to handle
    [[NSNotificationCenter defaultCenter] postNotificationName:PPDidRegisterForRemoteNotifications object:self userInfo:@{@"deviceToken": currentInstallation.deviceToken}];
    
    // Call the original method implementation
    IMP original = [PPAppDelegateProxy originalImplementation:_cmd class:[self class]];
    if (original) {
        ((void(*)(id, SEL, UIApplication*, NSData*))original)(self, _cmd, application, deviceToken);
    }
}

void PPApplicationDidFailToRegisterForRemoteNotificationsWithError(id self, SEL _cmd, UIApplication *application, NSError *error) {
    // Post the error for plugin to handle
    [[NSNotificationCenter defaultCenter] postNotificationName:PPDidFailToRegisterForRemoteNotifications object:self userInfo:@{@"error": error}];
    
    // Call the original method implementation
    IMP original = [PPAppDelegateProxy originalImplementation:_cmd class:[self class]];
    if (original) {
        ((void(*)(id, SEL, UIApplication*, NSError*))original)(self, _cmd, application, error);
    }
}

#pragma mark - Swizzling helper methods

+ (void)swizzle:(SEL)selector implementation:(IMP)implementation class:(Class)class {
    Method method = class_getInstanceMethod(class, selector);
    if (method) {
        IMP existing = method_setImplementation(method, implementation);
        [PPAppDelegateProxy storeOriginalImplementation:existing selector:selector class:class];
    } else {
        struct objc_method_description description = protocol_getMethodDescription(@protocol(UIApplicationDelegate), selector, NO, YES);
        class_addMethod(class, selector, implementation, description.types);
    }
}

+ (IMP)originalImplementation:(SEL)selector class:(Class)class {
    NSString *selectorString = NSStringFromSelector(selector);
    NSString *classString = NSStringFromClass(class);
    
    if (!originalMethods[classString]) {
        return nil;
    }
    
    NSValue *value = originalMethods[classString][selectorString];
    if (!value) {
        return nil;
    }
    
    IMP implementation;
    [value getValue:&implementation];
    return implementation;
}

+ (void)storeOriginalImplementation:(IMP)implementation selector:(SEL)selector class:(Class)class {
    NSString *selectorString = NSStringFromSelector(selector);
    NSString *classString = NSStringFromClass(class);
    
    if (!originalMethods[classString]) {
        originalMethods[classString] = [NSMutableDictionary dictionary];
    }
    
    originalMethods[classString][selectorString] = [NSValue valueWithPointer:implementation];
}

@end
