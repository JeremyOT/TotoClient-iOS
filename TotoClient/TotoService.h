//
//  Created by Jeremy Olmsted-Thompson on 12/20/11.
//  Copyright (c) 2011 JOT. All rights reserved.
//

#import "DataService.h"

#define TOTO_ERROR_SERVER 1000
#define TOTO_ERROR_MISSING_METHOD 1002
#define TOTO_ERROR_MISSING_PARAMS 1003
#define TOTO_ERROR_NOT_AUTHORIZED 1004
#define TOTO_ERROR_USER_NOT_FOUND 1005
#define TOTO_ERROR_USER_ID_EXISTS 1006
#define TOTO_ERROR_INVALID_SESSION_ID 1007
#define TOTO_ERROR_INVALID_HMAC 1008
#define TOTO_ERROR_INVALID_RESPONSE_HMAC 1009

@class TotoService;

@protocol TotoServiceAuthenticationDelegate

-(void)totoService:(TotoService*)service
requiresAuthenticationForMethodName:(NSString*)methodName
    withParameters:(id)parameters;

@end

@interface TotoService : DataService

@property (readonly) NSURL *serviceURL;
@property (nonatomic,assign) BOOL usesBSON;
@property (nonatomic,assign) id<TotoServiceAuthenticationDelegate> authenticationDelegate;

+(TotoService*)serviceWithURL:(NSURL*)url;
-(TotoService*)initWithURL:(NSURL*)url;
+(TotoService*)serviceWithURL:(NSURL*)url BSON:(BOOL)bson;
-(TotoService*)initWithURL:(NSURL*)url BSON:(BOOL)bson;

-(void)authenticateWithUserID:(NSString*)userID
                     password:(NSString*)password 
         additionalParameters:(NSDictionary *)parameters
               receiveHandler:(void (^)(id))receiveHandler
                 errorHandler:(void (^)(NSError*))errorHandler;

-(void)createAccountWithUserID:(NSString*)userID
                      password:(NSString*)password 
          additionalParameters:(NSDictionary *)parameters
                receiveHandler:(void (^)(id))receiveHandler
                  errorHandler:(void (^)(NSError*))errorHandler;

-(void)totoRequestWithMethodName:(NSString*)method
                      parameters:(id)parameters
                  receiveHandler:(void (^)(id))receiveHandler
                    errorHandler:(void (^)(NSError*))errorHandler;

@end
