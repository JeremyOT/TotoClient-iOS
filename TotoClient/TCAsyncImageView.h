//
//  Created by Jeremy Olmsted-Thompson on 11/25/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TCDataCache;
@class TCAsyncImageView;

@protocol TCAsyncImageViewDelegate <NSObject>

// The image may be the fallback image, so use successfully to check if the remote image was successfully loaded.
-(void)asyncImageView:(TCAsyncImageView*)asyncImageView willDisplayImage:(UIImage*)image successfully:(BOOL)successfully;
-(void)asyncImageView:(TCAsyncImageView*)asyncImageView willLoadImageFromURL:(NSURL*)url;

@end

@interface TCAsyncImageView : UIImageView

@property (nonatomic, assign) UIActivityIndicatorViewStyle indicatorStyle;
@property (nonatomic, retain) TCDataCache *imageCache;
@property (nonatomic) NSUInteger autoRetryCount;

// If YES, the image will not be set to nil before a new one is loaded.
@property (nonatomic) BOOL keepImageWhileLoading;

// The last URL used to load the image, manually setting the image does not affect this property.
@property (nonatomic, readonly) NSURL *imageURL;

// Use the delegate to track when the image is set
@property (nonatomic, assign) IBOutlet NSObject<TCAsyncImageViewDelegate> *delegate;

-(void)setImageWithURL:(NSURL*)url;
-(void)setImageWithURL:(NSURL*)url fallbackImage:(UIImage*)fallbackImage;
-(void)imageFromURL:(NSURL*)url block:(void (^)(UIImage *image))block;
-(void)beginLoadingAnimation;
-(void)endLoadingAnimation;

@end
