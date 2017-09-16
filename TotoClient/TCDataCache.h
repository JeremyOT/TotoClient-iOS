//
//  TCDataCache.h
//  TotoClient
//
//  Created by Jeremy Olmsted-Thompson on 1/4/14.
//  Copyright (c) 2014 JOT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TCDataService.h"

static const NSUInteger TCDefaultMemoryCacheCapacity;

@interface TCDataCache : NSObject

@property (nonatomic, copy, readonly) NSString *cachePath;
@property (nonatomic) NSUInteger memoryCacheCapacity;
typedef void (^ImageCallback)(UIImage*);

+(TCDataCache*)sharedCache;
+(TCDataCache*)sharedCacheWithName:(NSString*)name;

-(id)initWithPath:(NSString*)path;
-(id)initWithPathInCachesDirectory:(NSString*)path;
-(TCDataService*)dataService;

-(NSData*)cachedDataForURL:(NSURL*)url cachePath:(NSString*)cachePath;
-(NSString*)cachePathForURL:(NSURL*)url;
-(void)dataFromURL:(NSURL*)url block:(void (^)(NSData *data))block;
-(void)dataFromURL:(NSURL*)url ignoreCache:(BOOL)ignoreCache block:(void (^)(NSData *data))block;
-(UIImage*)cachedImageFromURL:(NSURL*)url;
-(void)cacheImage:(UIImage*)image forURL:(NSURL*)url;
-(void)imageFromURL:(NSURL*)url block:(void (^)(UIImage *image))block;
-(void)imageFromURL:(NSURL*)url ignoreCache:(BOOL)ignoreCache block:(void (^)(UIImage *image))block;
-(void)imageFromData:(NSData *)data forSourceURL:(NSURL *)url withCompletionHandler:(void(^)(UIImage *image)) completionHandler;
-(NSUInteger)cacheCostForImage:(UIImage*)image;
-(void)clearCache;

-(BOOL)addImageCallbackBlock:(ImageCallback)block forURL:(NSURL*)url;
-(void)runCallbacksWithImage:(UIImage*)image forUrl:(NSURL*)url;

@end
