//
//  Created by Jeremy Olmsted-Thompson on 11/27/12.
//  Copyright (c) 2012 JOT. All rights reserved.
//

#import "NSURL+TCQuery.h"

@implementation NSURL (TCQuery)

-(NSURL *)URLByAppendingQueryString:(NSString *)query {
    if (![query length]) {
        return self;
    }
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", self, query]];
}

-(NSURL *)URLByAppendingQueryParameters:(NSDictionary *)query {
    NSMutableString *queryString = [NSMutableString string];
    for (NSString *key in query) {
        if ([queryString length]) {
            [queryString appendString:@"&"];
        }
        [queryString appendFormat:@"%@=%@", [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [[[query objectForKey:key] description] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    return [self URLByAppendingQueryString:queryString];
}

@end
