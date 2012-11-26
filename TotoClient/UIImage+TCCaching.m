//
//  Created by Jeremy Olmsted-Thompson on 11/25/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "UIImage+TCCaching.h"
#import "NSString+TCHash.h"
#import "TCDataService.h"

@implementation UIImage (TCCaching)

+(void)setCacheDirectory:(NSString *)directoryName {
    [TCImageCacheDirectory release];
    TCImageCacheDirectory = [directoryName copy];
}

+(NSString*)cachePath {
    static NSString *cachePath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:TCImageCacheDirectory] retain];
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    });
    return cachePath;
}

+(void)imageFromURL:(NSURL *)url block:(void (^)(UIImage *))block {
    [self imageFromURL:url ignoreCache:NO block:block];
}

+(void)imageFromURL:(NSURL *)url ignoreCache:(BOOL)ignoreCache block:(void (^)(UIImage *))block {
    NSString *imagePath = [[self cachePath] stringByAppendingPathComponent:[[url description] stringWithSHA256Hash]];
    if (!ignoreCache && [[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        block([UIImage imageWithContentsOfFile:imagePath]);
        return;
    }
    [[TCDataService service] requestWithURL:url method:@"GET" headers:nil body:nil receiveHandler:^(id response, NSNumber *status, NSDictionary *headers) {
        [(NSData*)response writeToFile:imagePath atomically:YES];
        block([UIImage imageWithContentsOfFile:imagePath]);
    } errorHandler:^(NSError *error) {
        block(nil);
    }];
}

@end
