//
//  DelegateForwardingProxy.h
//  InfinityListView
//
//  Created by caishilin on 2025/4/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DelegateForwardingProxy: NSObject

// Weak references to avoid retain cycles
@property (nonatomic, weak, nullable) id internalDelegate;
@property (nonatomic, weak, nullable) id externalDelegate;

@end

NS_ASSUME_NONNULL_END
