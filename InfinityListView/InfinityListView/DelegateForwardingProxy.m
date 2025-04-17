//
//  DelegateForwardingProxy.m
//  InfinityListView
//
//  Created by caishilin on 2025/4/16.
//

#import "DelegateForwardingProxy.h"

@implementation DelegateForwardingProxy


// Check if the proxy itself, or either delegate, responds to the selector
- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }
    if (self.internalDelegate && [self.internalDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    if (self.externalDelegate && [self.externalDelegate respondsToSelector:aSelector]) {
        return YES;
    }
    return NO;
}

// Provide the method signature from one of the delegates that implements it
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }

    // Prioritize external delegate's signature
    if (self.externalDelegate && [self.externalDelegate respondsToSelector:aSelector]) {
        // Use NSObject's methodForSelector to get the signature
        return [(NSObject *)self.externalDelegate methodSignatureForSelector:aSelector];
    }
    // Fallback to internal delegate's signature
    if (self.internalDelegate && [self.internalDelegate respondsToSelector:aSelector]) {
         return [(NSObject *)self.internalDelegate methodSignatureForSelector:aSelector];
    }
    // Should not happen if respondsToSelector: is correct, but return nil as fallback
    return nil;
}

// Forward the invocation to the appropriate delegate(s)
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    BOOL internalResponded = NO;
    BOOL externalResponded = NO;

    // Determine if the method has a non-void return type
    // Note: This is a simplified check. C scalars, structs, etc., add complexity.
    // For typical delegate methods returning objects (UIView*) or BOOL, this works.
    BOOL methodReturnsValue = NO;
    NSMethodSignature *sig = [anInvocation methodSignature];
    const char* returnType = [sig methodReturnType];
    // Check if return type is not 'v' (void)
    if (returnType && strcmp(returnType, @encode(void)) != 0) {
        methodReturnsValue = YES;
    }


    // --- Invocation Logic ---

    // 1. Invoke on Internal Delegate?
    if (self.internalDelegate && [self.internalDelegate respondsToSelector:selector]) {
        [anInvocation invokeWithTarget:self.internalDelegate];
        internalResponded = YES;
    }

    // 2. Invoke on External Delegate?
    if (self.externalDelegate && [self.externalDelegate respondsToSelector:selector]) {
        [anInvocation invokeWithTarget:self.externalDelegate];
        externalResponded = YES;
        // If method returns a value, the external delegate's return value
        // will be the one captured by the invocation system, as it was called last.
    }

    // If neither responded (and respondsToSelector: returned YES), something is wrong.
    // Or maybe the selector was for the proxy itself (handled by super).
    if (!internalResponded && !externalResponded) {
        // If the proxy itself might implement methods, call super.
        // Otherwise, log an error or handle appropriately.
        // [super forwardInvocation:anInvocation];
         NSLog(@"Warning: forwardInvocation called for %@ but no delegate responded.", NSStringFromSelector(selector));
    }

    // ** Important Note on Return Values **
    // As implemented above, if both delegates implement a method with a return value,
    // the value returned by the *externalDelegate* (invoked last) will be the
    // effective return value of the proxy's call. Adjust invocation order if
    // internal priority is needed, or add more complex logic if combination is required
    // (rarely possible/meaningful for delegates).
}

@end
