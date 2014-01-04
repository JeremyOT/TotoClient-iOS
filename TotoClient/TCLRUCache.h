//
//  TCLRUCache.h
//  TotoClient
//
//  Created by Jeremy Olmsted-Thompson on 1/4/14.
//  Copyright (c) 2014 JOT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCLRUCache : NSObject

@property (nonatomic) NSUInteger capacity;
@property (nonatomic, readonly) NSUInteger count;

-(id)initWithCapacity:(NSUInteger)capacity;
-(void)setObject:(id)object forKey:(id<NSCopying>)key;
-(id)objectForKey:(id)key;
-(void)invalidateObjectForKey:(id)key;

@end
