//
//  Created by Jeremy Olmsted-Thompson on 12/20/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import "TotoService.h"
#import "HMAC.h"
#import "BSONSerialization.h"

#define TOTO_USER_ID_KEY @"TOTO_USER_ID"
#define TOTO_SESSION_ID_KEY @"TOTO_SESSION_ID"
#define TOTO_SESSION_EXPIRES_KEY @"TOTO_SESSION_EXPIRES"

@interface TotoService ()

@property (nonatomic, retain) NSMutableDictionary *queuedRequests;

-(void)setUserID:(NSString*)userID SessionID:(NSString*)sessionID expires:(NSTimeInterval)sessionExpires;

@end

@implementation TotoService

@synthesize serviceURL = _serviceURL;
@synthesize authenticationDelegate = _authenticationDelegate;
@synthesize usesBSON = _usesBSON;
@synthesize queuedRequests = _queuedRequests;

#pragma mark - Lifecycle

+(TotoService *)serviceWithURL:(NSURL *)url BSON:(BOOL)bson {
    return [[[self alloc] initWithURL:url BSON:bson] autorelease];
}

+(TotoService *)serviceWithURL:(NSURL *)url {
    return [self serviceWithURL:url BSON:NO];
}

-(TotoService *)initWithURL:(NSURL *)url BSON:(BOOL)bson {
    if ((self = [super init])) {
        _serviceURL = [url copy];
        _usesBSON = bson;
    }
    return self;
}

-(TotoService *)initWithURL:(NSURL *)url {
    return [self initWithURL:url BSON:NO];
}

-(void)dealloc {
    [_serviceURL release];
    [_queuedRequests release];
    [super dealloc];
}

#pragma mark - Properties

-(NSString *)userID {
    if (self.sessionExpires > [[NSDate date] timeIntervalSince1970]) {
        return [[NSUserDefaults standardUserDefaults] stringForKey:[TOTO_USER_ID_KEY stringByAppendingString:[_serviceURL absoluteString]]];
    }
    return nil;
}

-(NSTimeInterval)sessionExpires {
    return [[NSUserDefaults standardUserDefaults] doubleForKey:[TOTO_SESSION_EXPIRES_KEY stringByAppendingString:[_serviceURL absoluteString]]];
}

-(NSString *)sessionID {
    if (self.sessionExpires > [[NSDate date] timeIntervalSince1970]) {
        return [[NSUserDefaults standardUserDefaults] stringForKey:[TOTO_SESSION_ID_KEY stringByAppendingString:[_serviceURL absoluteString]]];
    }
    return nil;
}

-(void)setUserID:(NSString*)userID SessionID:(NSString*)sessionID expires:(NSTimeInterval)sessionExpires {
    [[NSUserDefaults standardUserDefaults] setValue:userID forKey:[TOTO_USER_ID_KEY stringByAppendingString:[_serviceURL absoluteString]]];
    [[NSUserDefaults standardUserDefaults] setValue:sessionID forKey:[TOTO_SESSION_ID_KEY stringByAppendingString:[_serviceURL absoluteString]]];
    [[NSUserDefaults standardUserDefaults] setDouble:sessionExpires forKey:[TOTO_SESSION_EXPIRES_KEY stringByAppendingString:[_serviceURL absoluteString]]];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Authentication

-(void)clearSession {
    [self setUserID:nil SessionID:nil expires:0];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookiesForURL:_serviceURL]) {
        NSLog(@"Clearing Cookie: %@", cookie);
        [cookieStorage deleteCookie:cookie];
    }
}

#pragma mark - Batching

-(NSMutableDictionary *)queuedRequests {
    if (!_queuedRequests) {
        _queuedRequests = [[NSMutableDictionary alloc] init];
    }
    return _queuedRequests;
}

-(NSUInteger)queuedRequestCount {
    return [_queuedRequests count];
}

-(void)clearRequestQueue {
    [_queuedRequests removeAllObjects];
}

-(void)queueRequestWithID:(NSString*)requestID
               methodName:(NSString *)method
               parameters:(id)parameters
           receiveHandler:(void (^)(id))receiveHandler
             errorHandler:(void (^)(NSError *))errorHandler {
    if (!parameters) {
        parameters = [NSDictionary dictionary];
    }
    [self.queuedRequests setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    method, @"method",
                                    parameters, @"parameters",
                                    receiveHandler, @"receiveHandler",
                                    errorHandler, @"errorHandler",
                                    nil] forKey:requestID];
}

-(void)batchRequest:(void(^)())completeHandler {
    NSDictionary *requests = [[_queuedRequests retain] autorelease];
    self.queuedRequests = nil;
    NSMutableDictionary *batch = [NSMutableDictionary dictionaryWithCapacity:[requests count]];
    for (NSString *requestID in requests) {
        [batch setObject:[NSDictionary dictionaryWithObjectsAndKeys:
                          [[requests objectForKey:requestID] objectForKey:@"method"], @"method",
                          [[requests objectForKey:requestID] objectForKey:@"parameters"], @"parameters",
                          nil] forKey:requestID];
    }
    NSDictionary *requestBody = [NSDictionary dictionaryWithObject:batch forKey:@"batch"];
    NSData *body = nil;
    NSMutableDictionary *headers = nil;
    if (_usesBSON) {
        body = [requestBody BSONRepresentation];
        headers = [NSMutableDictionary dictionaryWithObject:@"application/bson" forKey:@"content-type"];
    } else {
        body = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:NULL];
        headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"content-type"];
    }
    if (self.sessionID && [self.userID length]) {
        [headers setObject:self.sessionID forKey:@"x-toto-session-id"];
        [headers setObject:[HMAC SHA1Base64DigestWithKey:[self.userID dataUsingEncoding:NSUTF8StringEncoding] data:body] forKey:@"x-toto-hmac"];
    }
    [self requestWithURL:self.serviceURL
                  method:@"POST"
                 headers:headers
                    body:body
          receiveHandler:^(id responseData, NSNumber *status, NSDictionary *headers) {
              NSDictionary *batchResponse = nil;
              if ([[headers objectForKey:@"content-type"] hasPrefix:@"application/bson"]) {
                  batchResponse = [responseData BSONValue];
              } else {
                  batchResponse = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:NULL];
              }
              if ([headers objectForKey:@"x-toto-hmac"] && self.userID &&
                  ![[HMAC SHA1Base64DigestWithKey:[self.userID dataUsingEncoding:NSUTF8StringEncoding] data:responseData] isEqualToString:[headers objectForKey:@"x-toto-hmac"]]) {
                  NSError *error = [NSError errorWithDomain:@"TotoServiceError"
                                                       code:TOTO_ERROR_INVALID_RESPONSE_HMAC
                                                   userInfo:[NSDictionary dictionaryWithObject:@"Invalid response HMAC" forKey:NSLocalizedDescriptionKey]];
                  for (NSString *requestID in requests) {
                      void (^errorHandler)(NSError *) = [[requests objectForKey:requestID] objectForKey:@"errorHandler"];
                      if (errorHandler) {
                          errorHandler(error);
                      }
                  }
                  if (completeHandler) {
                      completeHandler();
                  }
                  return;
              }
              NSDictionary *session = [batchResponse objectForKey:@"session"];
              [self setUserID:[session objectForKey:@"user_id"] SessionID:[session objectForKey:@"session_id"] expires:[[session objectForKey:@"expires"] doubleValue]];
              for (NSString *responseID in batchResponse) {
                  NSDictionary *response = [batchResponse objectForKey:responseID];
                  NSDictionary *result = [response objectForKey:@"result"];
                  if (result) {
                      void (^receiveHandler)(id, NSNumber*, NSDictionary*) = [[requests objectForKey:responseID] objectForKey:@"receiveHandler"];
                      if (receiveHandler) {
                          receiveHandler(result, status, headers);
                      }
                  } else {
                      NSDictionary *error = [response objectForKey:@"error"];
                      void (^errorHandler)(NSError *) = [[requests objectForKey:responseID] objectForKey:@"errorHandler"];
                      if (errorHandler) {
                          errorHandler([response objectForKey:@"error"] ? [NSError errorWithDomain:@"TotoServiceError"
                                                                                             code:[[error objectForKey:@"code"] integerValue]
                                                                                         userInfo:[NSDictionary dictionaryWithObject:[error objectForKey:@"value"] forKey:NSLocalizedDescriptionKey]] : nil);
                      }
                  }
              }
              if (completeHandler) {
                  completeHandler();
              }
          } errorHandler:^(NSError *error) {
              for (NSString *requestID in requests) {
                  void (^errorHandler)(NSError *) = [[requests objectForKey:requestID] objectForKey:@"errorHandler"];
                  if (errorHandler) {
                      errorHandler(error);
                  }
              }
              if (completeHandler) {
                  completeHandler();
              }
          }];
}

#pragma mark - Requests

-(void)authenticateWithUserID:(NSString *)userID
                     password:(NSString *)password
         additionalParameters:(NSDictionary *)parameters
               receiveHandler:(void (^)(id))receiveHandler
                 errorHandler:(void (^)(NSError *))errorHandler {
    userID = [userID lowercaseString];
    NSMutableDictionary *authenticationParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [authenticationParameters setObject:userID forKey:@"user_id"];
    [authenticationParameters setObject:password forKey:@"password"];
    [self setUserID:nil SessionID:nil expires:0];
    [self totoRequestWithMethodName:@"account.login"
                         parameters:authenticationParameters
                     receiveHandler:^(id result) {
                         receiveHandler(result);
             } errorHandler:errorHandler];
}

-(void)createAccountWithUserID:(NSString *)userID
                      password:(NSString *)password
          additionalParameters:(NSDictionary *)parameters
                receiveHandler:(void (^)(id))receiveHandler
                  errorHandler:(void (^)(NSError *))errorHandler {
    userID = [userID lowercaseString];
    NSMutableDictionary *authenticationParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [authenticationParameters setObject:userID forKey:@"user_id"];
    [authenticationParameters setObject:password forKey:@"password"];
    [self setUserID:nil SessionID:nil expires:0];
    [self totoRequestWithMethodName:@"account.create"
                         parameters:authenticationParameters
                     receiveHandler:^(id result) {
                         receiveHandler(result);
                     } errorHandler:errorHandler];
}

-(void)totoRequestWithMethodName:(NSString *)method
                      parameters:(id)parameters
                  receiveHandler:(void (^)(id))receiveHandler
                    errorHandler:(void (^)(NSError *))errorHandler {
    if (!parameters) {
        parameters = [NSDictionary dictionary];
    }
    NSData *body = nil;
    NSMutableDictionary *headers = nil;
    if (_usesBSON) {
        body = [[NSDictionary dictionaryWithObjectsAndKeys:method, @"method", parameters, @"parameters", nil] BSONRepresentation];
        headers = [NSMutableDictionary dictionaryWithObject:@"application/bson" forKey:@"content-type"];
    } else {
        body = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:method, @"method", parameters, @"parameters", nil] options:0 error:NULL];
        headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"content-type"];

    }
    if (self.sessionID && [self.userID length]) {
        [headers setObject:self.sessionID forKey:@"x-toto-session-id"];
        [headers setObject:[HMAC SHA1Base64DigestWithKey:[self.userID dataUsingEncoding:NSUTF8StringEncoding] data:body] forKey:@"x-toto-hmac"];
    }
    [self requestWithURL:self.serviceURL
                  method:@"POST"
                 headers:headers
                    body:body
          receiveHandler:^(id responseData, NSNumber *status, NSDictionary *headers) {
              NSDictionary *response = nil;
              if ([[headers objectForKey:@"content-type"] hasPrefix:@"application/bson"]) {
                  response = [responseData BSONValue];
              } else {
                  response = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:NULL];
              }
              NSDictionary *error = [response objectForKey:@"error"];
              if (error) {
                  NSInteger errorCode = [[error objectForKey:@"code"] integerValue];
                  if (self.authenticationDelegate && (errorCode == TOTO_ERROR_INVALID_SESSION_ID || errorCode == TOTO_ERROR_NOT_AUTHORIZED)) {
                      [self.authenticationDelegate totoService:self requiresAuthenticationForMethodName:method withParameters:parameters];
                  } else {
                      errorHandler([NSError errorWithDomain:@"TotoServiceError"
                                                       code:errorCode
                                                   userInfo:[NSDictionary dictionaryWithObject:[error objectForKey:@"value"] forKey:NSLocalizedDescriptionKey]]);
                  }
                  return;
              }
              if ([headers objectForKey:@"x-toto-hmac"] && self.userID &&
                  ![[HMAC SHA1Base64DigestWithKey:[self.userID dataUsingEncoding:NSUTF8StringEncoding] data:responseData] isEqualToString:[headers objectForKey:@"x-toto-hmac"]]) {
                  errorHandler([NSError errorWithDomain:@"TotoServiceError"
                                                   code:TOTO_ERROR_INVALID_RESPONSE_HMAC
                                               userInfo:[NSDictionary dictionaryWithObject:@"Invalid response HMAC" forKey:NSLocalizedDescriptionKey]]);
                  return;
              }
              NSDictionary *session = [response objectForKey:@"session"];
              [self setUserID:[session objectForKey:@"user_id"] SessionID:[session objectForKey:@"session_id"] expires:[[session objectForKey:@"expires"] doubleValue]];
              if (receiveHandler) {
                  receiveHandler([response objectForKey:@"result"]);
              }
          } errorHandler:errorHandler];
}

@end
