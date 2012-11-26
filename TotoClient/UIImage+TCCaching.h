//
//  Created by Jeremy Olmsted-Thompson on 11/25/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (TCCaching)

+(void)imageFromURL:(NSURL*)url block:(void (^)(UIImage *image))block;
+(void)imageFromURL:(NSURL*)url ignoreCache:(BOOL)ignoreCache block:(void (^)(UIImage *image))block;

@end
