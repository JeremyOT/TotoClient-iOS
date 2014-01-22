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

static const NSString *TCDefaultCacheDirectory = @"toto_cache";
static const NSUInteger TCDefaultMemoryCacheCapacity = 0;

typedef void (^ImageCallback)(UIImage*);

@interface TCDataCache ()

@property (nonatomic, copy, readwrite) NSString *cachePath;
@property (nonatomic, retain) NSCache *cache;
@property (nonatomic, retain) NSMutableDictionary *imageCallbackBlocks;
@property (nonatomic, assign) dispatch_queue_t lockQueue;
@property (nonatomic, assign) dispatch_queue_t ioQueue;

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
    if ((self = [self init])) {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        self.cachePath = path;
        self.memoryCacheCapacity = TCDefaultMemoryCacheCapacity;
        self.imageCallbackBlocks = [NSMutableDictionary dictionary];
        _lockQueue = dispatch_queue_create("TCDataCache.lock", DISPATCH_QUEUE_SERIAL);
        _ioQueue = dispatch_queue_create("TCDataCache.io", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

-(void)dealloc {
    self.cachePath = nil;
    self.cache = nil;
    self.runLoop = nil;
    dispatch_release(_lockQueue);
    dispatch_release(_ioQueue);
    [super dealloc];
}

-(void)setMemoryCacheCapacity:(NSUInteger)memoryCacheCapacity {
    if (memoryCacheCapacity <= 0) {
        self.cache = nil;
        return;
    }
    if (!_cache) _cache = [[NSCache alloc] init];
    _cache.totalCostLimit = memoryCacheCapacity;
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
    TCDataService *service = [TCDataService service];
    service.runLoop = _runLoop;
    [service requestWithURL:url method:@"GET" headers:nil body:nil receiveHandler:^(id response, NSNumber *status, NSDictionary *headers) {
        [(NSData*)response writeToFile:cachePath atomically:YES];
        block(response);
    } errorHandler:^(NSError *error) {
        block(nil);
    }];
}

-(void)imageFromURL:(NSURL *)url block:(ImageCallback)block {
    [self imageFromURL:url ignoreCache:NO block:block];
}

-(BOOL)addImageCallbackBlock:(ImageCallback)block forUrl:(NSURL*)url {
    __block BOOL first = NO;
    dispatch_sync(_lockQueue, ^{
        NSMutableArray *callbacks = [_imageCallbackBlocks objectForKey:url];
        if (!callbacks) {
            first = YES;
            callbacks = [NSMutableArray array];
            [_imageCallbackBlocks setObject:callbacks forKey:url];
        }
        [callbacks addObject:[[block copy] autorelease]];
    });
    return first;
}

-(void)runCallbacksWithImage:(UIImage*)image forUrl:(NSURL*)url {
    __block NSArray *callbacks = nil;
    dispatch_sync(_lockQueue, ^{
        callbacks = [[_imageCallbackBlocks objectForKey:url] retain];
        [_imageCallbackBlocks removeObjectForKey:url];
    });
    if ([NSThread isMainThread]) {
        for (ImageCallback block in callbacks) {
            block(image);
        }
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            for (ImageCallback block in callbacks) {
                block(image);
            }
        });
    }
    [callbacks release];
}

-(void)imageFromURL:(NSURL *)url ignoreCache:(BOOL)ignoreCache block:(ImageCallback)block {
    UIImage *memoryCachedImage = [_cache objectForKey:url];
    if (memoryCachedImage) {
        block(memoryCachedImage);
        return;
    }
    if (!ignoreCache && ![self addImageCallbackBlock:block forUrl:url]) {
        return;
    }
    dispatch_async(_ioQueue, ^{
        [self dataFromURL:url ignoreCache:ignoreCache block:^(NSData *data) {
            if (data) {
                UIImage *image = [self imageFromData:data forSourceURL:url];
                [_cache setObject:image forKey:url cost:[self cacheCostForImage:image]];
                [self runCallbacksWithImage:image forUrl:url];
            } else {
                [self runCallbacksWithImage:nil forUrl:url];
            }
        }];
    });
}

-(UIImage*)imageFromData:(NSData *)data forSourceURL:(NSURL*)url {
    return [UIImage imageWithData:data];
}

-(NSUInteger)cacheCostForImage:(UIImage*)image {
    return (image.size.height * image.scale) * (image.size.width * image.scale) * 4;
}

@end
