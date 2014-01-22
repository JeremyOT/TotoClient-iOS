//
//  TCDataCache.h
//  TotoClient
//
//  Created by Jeremy Olmsted-Thompson on 1/4/14.
//  Copyright (c) 2014 JOT. All rights reserved.
//

#import <UIKit/UIKit.h>

static const NSUInteger TCDefaultMemoryCacheCapacity;

@interface TCDataCache : NSObject

@property (nonatomic, copy, readonly) NSString *cachePath;
@property (nonatomic, retain) NSRunLoop *runLoop;
@property (nonatomic) NSUInteger memoryCacheCapacity;

+(TCDataCache*)sharedCache;
+(TCDataCache*)sharedCacheWithName:(NSString*)name;

-(id)initWithPath:(NSString*)path;
-(id)initWithPathInCachesDirectory:(NSString*)path;

-(NSString*)cachePathForURL:(NSURL*)url;
-(void)dataFromURL:(NSURL*)url block:(void (^)(NSData *data))block;
-(void)dataFromURL:(NSURL*)url ignoreCache:(BOOL)ignoreCache block:(void (^)(NSData *data))block;
-(void)imageFromURL:(NSURL*)url block:(void (^)(UIImage *image))block;
-(void)imageFromURL:(NSURL*)url ignoreCache:(BOOL)ignoreCache block:(void (^)(UIImage *image))block;
-(UIImage*)imageFromData:(NSData *)data forSourceURL:(NSURL*)url;
-(NSUInteger)cacheCostForImage:(UIImage*)image;

@end
