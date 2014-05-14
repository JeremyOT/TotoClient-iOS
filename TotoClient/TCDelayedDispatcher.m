//
//  Created by Jeremy Olmsted-Thompson on 8/21/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "TCDelayedDispatcher.h"

@interface TCDelayedDispatcher ()

@property (nonatomic, assign) NSTimeInterval lastTokenTime;

@end

@implementation TCDelayedDispatcher

#pragma mark - Static Accessors

+(TCDelayedDispatcher*)namedDispatcher:(NSString*)name {
    static NSMutableDictionary *dispatchers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatchers = [[NSMutableDictionary alloc] init];
    });
    TCDelayedDispatcher *dispatcher = [dispatchers objectForKey:name];
    if (dispatcher) {
        return dispatcher;
    }
    dispatcher = [self dispatcher];
    [dispatchers setObject:dispatcher forKey:name];
    return dispatcher;
}

+(TCDelayedDispatcher*)dispatcher {
    return [[self alloc] init];
}

#pragma mark - Scheduling

-(NSTimeInterval)updateToken {
    _lastTokenTime = [[NSDate date] timeIntervalSince1970];
    return _lastTokenTime;
}

-(BOOL)isValidToken:(NSTimeInterval)token {
    return token == _lastTokenTime;
}

-(BOOL)dispatchForToken:(NSTimeInterval)token withBlock:(void (^)())block {
    if ([self isValidToken:token]) {
        block();
        return YES;
    } else {
        return NO;
    }
}

-(void)dispatchAfter:(NSTimeInterval)delay withBlock:(void(^)())block {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC), dispatch_get_main_queue(), [self guardedBlock:block]);
}

-(void (^)())guardedBlock:(void(^)())block {
    NSTimeInterval token = [self updateToken];
    return [^ {
        [self dispatchForToken:token withBlock:block];
    } copy];
}

@end
