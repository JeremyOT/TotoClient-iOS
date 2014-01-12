//
//  Created by Jeremy Olmsted-Thompson on 12/20/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import "TotoService.h"
#import "TCHMAC.h"
#import "BSONSerialization.h"
#import "TCUUID.h"
#import "NSURL+TCQuery.h"

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
    [_preflightHandler release];
    [super dealloc];
}

#pragma mark - Default Properties

+(NSMutableDictionary*)defaultRequestHeaders {
    static NSMutableDictionary *defaultRequestHeaders = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRequestHeaders = [[NSMutableDictionary alloc] init];
    });
    return defaultRequestHeaders;
}

+(void)setDefaultRequestHeader:(NSString*)value forKey:(NSString*)key {
    [[self defaultRequestHeaders] setObject:value forKey:key];
}

+(NSString*)defaultRequestHeaderForKey:(NSString*)key {
    return [self defaultRequestHeaders][key];
}

+(NSDictionary*)allDefaultRequestHeaders {
    return [NSDictionary dictionaryWithDictionary:[self defaultRequestHeaders]];
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

-(void)setSessionData:(NSDictionary *)sessionData {
    [self setUserID:sessionData[@"user_id"] SessionID:sessionData[@"session_id"] expires:[sessionData[@"expires"] doubleValue]];
}

-(NSDictionary *)sessionData {
    return @{@"user_id": self.userID, @"session_id": self.sessionID, @"expires": [NSNumber numberWithDouble:self.sessionExpires]};
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

-(void)queueRequestWithMethodName:(NSString*)method
                       parameters:(id)parameters
                   receiveHandler:(void (^)(id))receiveHandler
                     errorHandler:(void (^)(NSError *))errorHandler {
    [self queueRequestWithID:[TCUUID generateUUID] methodName:method parameters:parameters receiveHandler:receiveHandler errorHandler:errorHandler];
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
                                    [[method copy] autorelease], @"method",
                                    [[parameters copy] autorelease], @"parameters",
                                    [[receiveHandler copy] autorelease], @"receiveHandler",
                                    [[errorHandler copy] autorelease], @"errorHandler",
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
        if (_signsRequests) {
            [headers setObject:[TCHMAC SHA1Base64DigestWithKey:[self.userID dataUsingEncoding:NSUTF8StringEncoding] data:body] forKey:@"x-toto-hmac"];
        }
        if (_preflightHandler) {
            _preflightHandler(body, headers);
        }
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
                  batchResponse = [NSJSONSerialization JSONObjectWithData:responseData options:_JSONReadingOptions error:NULL];
              }
              NSDictionary *session = [batchResponse objectForKey:@"session"];
              if (session) {
                  self.sessionData = session;
              }
              NSDictionary *responses = [batchResponse objectForKey:@"batch"];
              for (NSString *responseID in [[responses allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]) {
                  NSDictionary *response = [responses objectForKey:responseID];
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
    [self totoRequestWithMethodName:method parameters:parameters headers:nil useQueryParameters:NO receiveHandler:receiveHandler errorHandler:errorHandler];
}

-(void)totoRequestWithMethodName:(NSString *)method
                      parameters:(id)parameters
                         headers:(NSDictionary*)headers
                  receiveHandler:(void (^)(id))receiveHandler
                    errorHandler:(void (^)(NSError *))errorHandler {
    [self totoRequestWithMethodName:method parameters:parameters useQueryParameters:NO receiveHandler:receiveHandler errorHandler:errorHandler];
}
-(void)totoRequestWithMethodName:(NSString *)method
                      parameters:(id)parameters
              useQueryParameters:(BOOL)useQueryParameters
                  receiveHandler:(void (^)(id))receiveHandler
                    errorHandler:(void (^)(NSError *))errorHandler {
    [self totoRequestWithMethodName:method parameters:parameters headers:nil useQueryParameters:useQueryParameters receiveHandler:receiveHandler errorHandler:errorHandler];
}

-(void)totoRequestWithMethodName:(NSString *)method
                      parameters:(id)parameters
                         headers:(NSDictionary*)headers
              useQueryParameters:(BOOL)useQueryParameters
                  receiveHandler:(void (^)(id))receiveHandler
                    errorHandler:(void (^)(NSError *))errorHandler {
    if (!parameters) {
        parameters = [NSDictionary dictionary];
    }
    NSData *body = nil;
    NSMutableDictionary *requestHeaders = [NSMutableDictionary dictionaryWithDictionary:[[self class] defaultRequestHeaders]];
    if (headers) {
        [requestHeaders setValuesForKeysWithDictionary:headers];
    }
    if (_usesBSON) {
        body = [[NSDictionary dictionaryWithObjectsAndKeys:method, @"method", parameters, @"parameters", nil] BSONRepresentation];
        [requestHeaders setObject:@"application/bson" forKey:@"content-type"];
    } else {
        body = [NSJSONSerialization dataWithJSONObject:[NSDictionary dictionaryWithObjectsAndKeys:method, @"method", parameters, @"parameters", nil] options:0 error:NULL];
        [requestHeaders setObject:@"application/json" forKey:@"content-type"];
        
    }
    if (self.sessionID && [self.userID length]) {
        [requestHeaders setObject:self.sessionID forKey:@"x-toto-session-id"];
        if (_signsRequests) {
            [requestHeaders setObject:[TCHMAC SHA1Base64DigestWithKey:[self.userID dataUsingEncoding:NSUTF8StringEncoding] data:body] forKey:@"x-toto-hmac"];
        }
        if (_preflightHandler) {
            _preflightHandler(body, requestHeaders);
        }
    }
    [self requestWithURL:useQueryParameters ? [[_serviceURL URLByAppendingPathComponent:[method stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] URLByAppendingQueryParameters:parameters] : _serviceURL
                  method:useQueryParameters ? @"GET" : @"POST"
                 headers:requestHeaders
                    body:useQueryParameters ? nil : body
          receiveHandler:^(id responseData, NSNumber *status, NSDictionary *headers) {
              NSDictionary *response = nil;
              if ([[headers objectForKey:@"content-type"] hasPrefix:@"application/bson"]) {
                  response = [responseData BSONValue];
              } else {
                  response = [NSJSONSerialization JSONObjectWithData:responseData options:_JSONReadingOptions error:nil];
              }
              NSDictionary *responseError = [response objectForKey:@"error"];
              if (responseError) {
                  NSInteger errorCode = [[responseError objectForKey:@"code"] integerValue];
                  if (self.authenticationDelegate && (errorCode == TOTO_ERROR_INVALID_SESSION_ID || errorCode == TOTO_ERROR_NOT_AUTHORIZED)) {
                      [self clearSession];
                      [self.authenticationDelegate totoService:self requiresAuthenticationForMethodName:method parameters:parameters headers:headers useQueryParameters:useQueryParameters receiveHandler:receiveHandler errorHandler:errorHandler];
                  } else if (errorHandler) {
                      errorHandler([NSError errorWithDomain:@"TotoServiceError"
                                                       code:errorCode
                                                   userInfo:[NSDictionary dictionaryWithObject:[responseError objectForKey:@"value"] forKey:NSLocalizedDescriptionKey]]);
                  }
                  return;
              }
              
              NSDictionary *session = [response objectForKey:@"session"];
              if (session) {
                  self.sessionData = session;
              }
              if (receiveHandler) {
                  receiveHandler([response objectForKey:@"result"]);
              }
          } errorHandler:errorHandler];
}

@end
