//
//  Created by Jeremy Olmsted-Thompson on 11/25/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCDataCache;

@interface TCAsyncImageView : UIImageView

@property (nonatomic, assign) UIActivityIndicatorViewStyle indicatorStyle;
@property (nonatomic, retain) TCDataCache *imageCache;
@property (nonatomic) NSUInteger autoRetryCount;

// If YES, the image will not be set to nil before a new one is loaded.
@property (nonatomic) BOOL keepImageWhileLoading;

// The last URL used to load the image, manually setting the image does not affect this property.
@property (nonatomic, readonly) NSURL *imageURL;

-(void)setImageWithURL:(NSURL*)url;
-(void)setImageWithURL:(NSURL*)url fallbackImage:(UIImage*)fallbackImage;
-(void)imageFromURL:(NSURL*)url block:(void (^)(UIImage *image))block;

@end
