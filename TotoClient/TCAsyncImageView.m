//
//  Created by Jeremy Olmsted-Thompson on 11/25/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "TCAsyncImageView.h"
#import "TCAsyncImageView_Protected.h"
#import "TCDataCache.h"
#import "TCDelayedDispatcher.h"

@interface TCAsyncImageView ()

@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;
@property (nonatomic, strong) TCDelayedDispatcher *dispatcher;

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


-(void)setImageWithURL:(NSURL*)url {
    [self setImageWithURL:url fallbackImage:nil];
}

-(void)setImageWithURL:(NSURL*)url fallbackImage:(UIImage*)fallbackImage {
    [self setImageWithURL:url fallbackImage:fallbackImage retryCount:_autoRetryCount];
}

-(void)setImageWithURL:(NSURL*)url fallbackImage:(UIImage*)fallbackImage retryCount:(NSUInteger)retryCount {
    NSTimeInterval token = [_dispatcher updateToken];
    if (!url) {
        self.image = nil;
        self.imageURL = nil;
        return;
    }
    if ([_imageURL isEqual:url] && self.image) return;
    self.imageURL = url;
    [_delegate asyncImageView:self willLoadImageFromURL:_imageURL];
    if (!_keepImageWhileLoading) self.image = nil;
    [self beginLoadingAnimation];
    [self imageFromURL:url block:^(UIImage *image) {
        if (![_dispatcher isValidToken:token])
            return;
        [self endLoadingAnimation];
        if (image) {
            [_delegate asyncImageView:self willDisplayImage:image successfully:YES];
            self.image = image;
        } else if (retryCount > 0) {
            dispatch_async(dispatch_get_current_queue(), ^{
                [self setImageWithURL:url fallbackImage:fallbackImage retryCount:retryCount - 1];
            });
        } else {
            self.imageURL = nil;
            [_delegate asyncImageView:self willDisplayImage:fallbackImage successfully:NO];
            self.image = fallbackImage;
        }
    }];
}

-(void)imageFromURL:(NSURL*)url block:(void (^)(UIImage *image))block {
    [_imageCache imageFromURL:url block:block];
}

-(void)beginLoadingAnimation {
    if (!self.indicatorView) {
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.indicatorStyle];
        self.indicatorView = indicatorView;
        self.indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        self.indicatorView.frame = CGRectMake((self.bounds.size.width - self.indicatorView.frame.size.width) / 2.0, (self.bounds.size.height - self.indicatorView.frame.size.height) / 2.0, self.indicatorView.frame.size.width, self.indicatorView.frame.size.height);
        [self.indicatorView startAnimating];
        [self addSubview:self.indicatorView];
    }
}

-(void)endLoadingAnimation {
    [self.indicatorView removeFromSuperview];
    self.indicatorView = nil;
}

@end
