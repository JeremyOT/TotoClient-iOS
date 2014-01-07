//
//  TCLRUCache.m
//  TotoClient
//
//  Created by Jeremy Olmsted-Thompson on 1/4/14.
//  Copyright (c) 2014 JOT. All rights reserved.
//

#import "TCLRUCache.h"

@interface TCLRUCacheEntry : NSObject

@property (nonatomic, retain) id value;
@property (nonatomic, copy) id<NSCopying> key;
@property (nonatomic) NSTimeInterval timestamp;

-(NSComparisonResult)compare:(TCLRUCacheEntry*)entry;

@end

@implementation TCLRUCacheEntry

-(NSComparisonResult)compare:(TCLRUCacheEntry*)entry {
    if (self->_timestamp == entry->_timestamp) return NSOrderedSame;
    else if (self->_timestamp < entry->_timestamp) return NSOrderedAscending;
    else return NSOrderedDescending;
}

-(void)dealloc {
    self.value = nil;
    self.key = nil;
    [super dealloc];
}

@end

@interface TCLRUCache ()

@property (nonatomic, strong) NSMutableDictionary *cacheDictionary;
@property (nonatomic, strong) NSMutableArray *orderedEntries;

-(void)trimToCapacity;

@end

@implementation TCLRUCache

-(id)initWithCapacity:(NSUInteger)capacity {
    if ((self = [super init])) {
        _capacity = capacity;
        self.cacheDictionary = [NSMutableDictionary dictionaryWithCapacity:_capacity];
        self.orderedEntries = [NSMutableArray arrayWithCapacity:_capacity];
    }
    return self;
}

-(void)dealloc {
    self.cacheDictionary = nil;
    self.orderedEntries = nil;
    [super dealloc];
}

-(void)trimToCapacity {
    if ([_orderedEntries count] <= _capacity) return;
    @synchronized(self) {
        [_orderedEntries sortUsingSelector:@selector(compare:)];
        while ([_orderedEntries count] > _capacity) {
            TCLRUCacheEntry *entry = [_orderedEntries objectAtIndex:0];
            [_orderedEntries removeObjectAtIndex:0];
            [_cacheDictionary removeObjectForKey:entry.key];
        }
    }
}

-(void)setCapacity:(NSUInteger)capacity {
    _capacity = capacity;
    [self trimToCapacity];
}

-(NSUInteger)count {
    return [_cacheDictionary count];
}

-(id)objectForKey:(id)key {
    @synchronized(self) {
        TCLRUCacheEntry *entry = [_cacheDictionary objectForKey:key];
        entry.timestamp = [[NSDate date] timeIntervalSince1970];
        return entry.value;
    }
}

-(void)invalidateObjectForKey:(id)key {
    @synchronized(self) {
        TCLRUCacheEntry *entry = [_cacheDictionary objectForKey:key];
        entry.timestamp = 0;
        entry.value = nil;
    }
}

-(void)setObject:(id)object forKey:(id<NSCopying>)key {
    BOOL newEntry = NO;
    @synchronized(self) {
        TCLRUCacheEntry *entry = [_cacheDictionary objectForKey:key];
        if (!entry) {
            entry = [[[TCLRUCacheEntry alloc] init] autorelease];
            [_cacheDictionary setObject:entry forKey:key];
            [_orderedEntries addObject:entry];
            newEntry = YES;
        }
        entry.key = key;
        entry.value = object;
        entry.timestamp = [[NSDate date] timeIntervalSince1970];
    }
    if (newEntry) [self trimToCapacity];
}

@end
