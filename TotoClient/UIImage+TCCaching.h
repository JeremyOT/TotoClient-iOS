//
//  Created by Jeremy Olmsted-Thompson on 11/25/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *TCImageCacheDirectory = @"toto_images";

@interface UIImage (TCCaching)

+(void)setCacheDirectory:(NSString*)directoryName;
+(void)imageFromURL:(NSURL*)url block:(void (^)(UIImage *image))block;
+(void)imageFromURL:(NSURL*)url ignoreCache:(BOOL)ignoreCache block:(void (^)(UIImage *image))block;

@end
