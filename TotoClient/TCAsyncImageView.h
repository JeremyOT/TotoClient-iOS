//
//  Created by Jeremy Olmsted-Thompson on 11/25/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TCAsyncImageView : UIImageView

@property (nonatomic, assign) UIActivityIndicatorViewStyle indicatorStyle;

-(void)setImageWithURL:(NSURL*)url;
-(void)setImageWithURL:(NSURL*)url fallbackImage:(UIImage*)fallbackImage;

@end
