//
//  Created by Jeremy Olmsted-Thompson on 8/21/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCDelayedDispatcher : NSObject

+(TCDelayedDispatcher*)namedDispatcher:(NSString*)name;
+(TCDelayedDispatcher*)dispatcher;

-(NSTimeInterval)updateToken;
-(BOOL)isValidToken:(NSTimeInterval)token;
-(BOOL)dispatchForToken:(NSTimeInterval)token withBlock:(void (^)())block;
-(void)dispatchAfter:(NSTimeInterval)delay withBlock:(void(^)())block;
-(void (^)())guardedBlock:(void(^)())block;

@end
