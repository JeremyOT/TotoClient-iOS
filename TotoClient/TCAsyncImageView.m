//
//  Created by Jeremy Olmsted-Thompson on 11/25/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "TCAsyncImageView.h"
#import "TCDataCache.h"
#import "TCDelayedDispatcher.h"

@interface TCAsyncImageView ()

@property (nonatomic, assign) UIActivityIndicatorView *indicatorView;
@property (nonatomic, retain) TCDelayedDispatcher *dispatcher;

@end

@implementation TCAsyncImageView

-(void)initialize {
    self.indicatorStyle = UIActivityIndicatorViewStyleGray;
    self.dispatcher = [TCDelayedDispatcher dispatcher];
    self.imageCache = [TCDataCache sharedCache];
}

-(id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self initialize];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initialize];
    }
    return self;
}

-(id)initWithImage:(UIImage *)image {
    if ((self = [super initWithImage:image])) {
        [self initialize];
    }
    return self;
}

-(id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    if ((self = [super initWithImage:image highlightedImage:highlightedImage])) {
        [self initialize];
    }
    return self;
}

-(void)dealloc {
    [_dispatcher release];
    [_imageCache release];
    [super dealloc];
}

-(void)setImageWithURL:(NSURL*)url {
    [self setImageWithURL:url fallbackImage:nil];
}

-(void)setImageWithURL:(NSURL*)url fallbackImage:(UIImage*)fallbackImage {
    [self setImageWithURL:url fallbackImage:fallbackImage retryCount:_autoRetryCount];
}

-(void)setImageWithURL:(NSURL*)url fallbackImage:(UIImage*)fallbackImage retryCount:(NSUInteger)retryCount {
    if (!url) return;
    if (!self.indicatorView) {
        self.indicatorView = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.indicatorStyle] autorelease];
        self.indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.indicatorView.frame = CGRectMake((self.bounds.size.width - self.indicatorView.frame.size.width) / 2.0, (self.bounds.size.height - self.indicatorView.frame.size.height) / 2.0, self.indicatorView.frame.size.width, self.indicatorView.frame.size.height);
        [self.indicatorView startAnimating];
        [self addSubview:self.indicatorView];
    }
    NSTimeInterval token = [_dispatcher updateToken];
    [self imageFromURL:url block:^(UIImage *image) {
        if (![_dispatcher isValidToken:token])
            return;
        [self.indicatorView removeFromSuperview];
        self.indicatorView = nil;
        if (image) {
            self.image = image;
        } else if (retryCount > 0) {
            dispatch_async(dispatch_get_current_queue(), ^{
                [self setImageWithURL:url fallbackImage:fallbackImage retryCount:retryCount - 1];
            });
        } else {
            self.image = fallbackImage;
        }
    }];
}

-(void)imageFromURL:(NSURL*)url block:(void (^)(UIImage *image))block {
    [_imageCache imageFromURL:url block:block];
}

@end
