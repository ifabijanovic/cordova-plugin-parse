//
//  ParsePushAppDelegateProxy.m
//  
//
//  Created by Ivan Fabijanovic on 09/09/15.
//
//

#import "ParsePushAppDelegateProxy.h"

#import <objc/runtime.h>

static NSMutableDictionary *originalMethods;

@implementation ParsePushAppDelegateProxy

+ (void)proxyAppDelegate {
    if (!originalMethods) {
        originalMethods = [NSMutableDictionary dictionary];
    }
    
    id delegate = [UIApplication sharedApplication].delegate;
    if (!delegate) {
        NSLog(@"App delegate not set, unable to perform automatic setup.");
        return;
    }
    
    Class delegateClass = [delegate class];
    
    // Check to make sure we do not already have entries for the delegate class
    if (originalMethods[NSStringFromClass(delegateClass)]) {
        NSLog(@"Class %@ already swizzled.", NSStringFromClass(delegateClass));
        return;
    }
}

@end
