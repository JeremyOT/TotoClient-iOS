//
//  TCDataCache.m
//  TotoClient
//
//  Created by Jeremy Olmsted-Thompson on 1/4/14.
//  Copyright (c) 2014 JOT. All rights reserved.
//

#import "TCDataCache.h"
#import "NSString+TCHash.h"
#import "TCDataService.h"
#import "TCLRUCache.h"

static const NSString *TCDefaultCacheDirectory = @"toto_cache";
static const NSUInteger TCDefaultMemoryCacheCapacity = 0;

@interface TCDataCache ()

@property (nonatomic, copy, readwrite) NSString *cachePath;
@property (nonatomic, retain) TCLRUCache *lruCache;

@end

@implementation TCDataCache

+(NSMutableDictionary*)sharedCaches {
    static NSMutableDictionary *sharedCaches = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCaches = [[NSMutableDictionary alloc] init];
    });
    return sharedCaches;
}

+(TCDataCache *)sharedCache {
    return [self sharedCacheWithName:(NSString*)TCDefaultCacheDirectory];
}

+(TCDataCache *)sharedCacheWithName:(NSString *)name {
    @synchronized(self) {
        TCDataCache *cache = [[self sharedCaches] objectForKey:name];
        if (cache) return cache;
        NSLog(@"Created %@: %@", [self class], name);
        cache = [[[self alloc] initWithPathInCachesDirectory:name] autorelease];
        [[self sharedCaches] setObject:cache forKey:name];
        return cache;
    }
}

-(id)initWithPathInCachesDirectory:(NSString *)path {
    NSString *cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:path];
    self = [self initWithPath:cachePath];
    return self;
}

-(id)initWithPath:(NSString *)path {
    if ((self = [super init])) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        self.cachePath = path;
        self.memoryCacheCapacity = TCDefaultMemoryCacheCapacity;
    }
    return self;
}

-(void)dealloc {
    self.cachePath = nil;
    self.lruCache = nil;
    [super dealloc];
}

-(void)setMemoryCacheCapacity:(NSUInteger)memoryCacheCapacity {
    if (memoryCacheCapacity <= 0) {
        self.lruCache = nil;
        return;
    }
    if (!_lruCache) _lruCache = [[TCLRUCache alloc] initWithCapacity:memoryCacheCapacity];
    else _lruCache.capacity = memoryCacheCapacity;
}

-(NSString*)cachePathForURL:(NSURL *)url {
    return [[self cachePath] stringByAppendingPathComponent:[[url description] stringWithSHA256Hash]];
}

-(void)dataFromURL:(NSURL *)url block:(void (^)(NSData *))block {
    return [self dataFromURL:url ignoreCache:NO block:block];
}

-(void)dataFromURL:(NSURL *)url ignoreCache:(BOOL)ignoreCache block:(void (^)(NSData *))block {
    NSString *cachePath = [self cachePathForURL:url];
    if (!ignoreCache && [[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        block([NSData dataWithContentsOfFile:cachePath]);
        return;
    }
    [[TCDataService service] requestWithURL:url method:@"GET" headers:nil body:nil receiveHandler:^(id response, NSNumber *status, NSDictionary *headers) {
        [(NSData*)response writeToFile:cachePath atomically:YES];
        block(response);
    } errorHandler:^(NSError *error) {
        block(nil);
    }];
}

-(void)imageFromURL:(NSURL *)url block:(void (^)(UIImage *))block {
    [self imageFromURL:url ignoreCache:NO block:block];
}

-(void)imageFromURL:(NSURL *)url ignoreCache:(BOOL)ignoreCache block:(void (^)(UIImage *))block {
    UIImage *memoryCachedImage = [_lruCache objectForKey:url];
    if (memoryCachedImage) {
        NSLog(@"From cache: %@", memoryCachedImage);
        block(memoryCachedImage);
        return;
    }
    [self dataFromURL:url ignoreCache:ignoreCache block:^(NSData *data) {
        if (data) {
            UIImage *image = [self imageFromData:data forSourceURL:url];
            [_lruCache setObject:image forKey:url];
            block(image);
        } else {
            block(nil);
        }
    }];
}

-(UIImage*)imageFromData:(NSData *)data forSourceURL:(NSURL*)url {
    return [UIImage imageWithData:data];
}

@end
