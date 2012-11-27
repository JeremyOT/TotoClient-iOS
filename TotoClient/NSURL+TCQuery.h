//
//  Created by Jeremy Olmsted-Thompson on 11/27/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (TCQuery)

-(NSURL*)URLByAppendingQueryString:(NSString*)query;
-(NSURL*)URLByAppendingQueryParameters:(NSDictionary*)query;

@end
