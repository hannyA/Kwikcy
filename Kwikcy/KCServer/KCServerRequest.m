//
//  KCServerRequest.m
//  Quickpeck
//
//  Created by Hanny Aly on 1/31/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCServerRequest.h"
#import "AmazonKeyChainWrapper.h"
#import "Response.h"
#import "RequestDelegate.h"
#import "Constants.h"

#import "KCServerResponse.h"
//#import "ResponseHandler.h"


#import "KCServerResponse.h"
//#import "KCServerResponseHandler.h"

#import "RequestDelegate.h"

#import "Crypto.h"

//#import "NSData+Base64.h"


#define SERVER_URL            @"http://%@/dynamo"
#define SERVER_URL_SSL        @"https://%@/dynamo"


#define HASH_KEY        @"hashKey"
#define RANGE_KEY       @"rangeKey"


@interface KCServerRequest ()
@property (nonatomic, strong) NSString *url;
@end



@implementation KCServerRequest




/*
 *  username is included in finalData
 */

-(id)initWithParameters:(NSMutableDictionary *)parameters
{
    self = [super init];
    if (self)
    {
        self.command = parameters[COMMAND];

        AmazonCredentials *credentials = [AmazonKeyChainWrapper getCredentialsFromKeyChain];
        
        parameters[ACCESS_KEY]       = credentials.accessKey;
        parameters[SECRET_KEY]       = credentials.secretKey;
        parameters[SECURITY_TOKEN]   = credentials.securityToken;
        parameters[EXPIRATION_DATE]  = [AmazonKeyChainWrapper getExpirationDate];
        
        
        self.decryptionKey = [AmazonKeyChainWrapper getKeyForDevice];
        
        
        NSData *body = [self createJsonBodyFromDictionary:parameters];
        
        NSData *iv = [Crypto blockInitializationVectorOfLength];
    
        NSData *encryptedData = [Crypto encrypt:body
                                              key:self.decryptionKey
                                           withIV:iv];
        
        
        NSDictionary *signature = [self createSignatureWithKey:self.decryptionKey];
        
        NSDictionary *sig = [self createHmacWithData:encryptedData
                                          andWithKey:self.decryptionKey];

        
        NSDictionary *finalData = @{
                                    USERNAME : [AmazonKeyChainWrapper username],
                                    DATA     : [encryptedData base64EncodedString],
                                    IV       : [iv base64EncodedString],
                                    TIMESTAMP: signature[TIMESTAMP],
                                    HMAC     : signature[HEXSIGN],
                                    SIGNATURE: sig[HMAC]
                                  };
    
        
        
        self.finalBody = [self createJsonBodyFromDictionary:finalData];
        
//        NSLog(@"\n\n");
//        
//        
//        NSLog(@"body is %@", [body description]);
//        NSLog(@"body length is %d", [body length]);
//        
//        NSLog(@"\n\n");
//
//        
//        NSLog(@"data is %@", [encryptedData description]);
//        NSLog(@"data length is %d", [encryptedData length]);
//        
//        NSLog(@"\n\n");
//
//        NSLog(@"data is %@", [ [encryptedData base64EncodedString] description]);
//        NSLog(@"data length is %d", [ [encryptedData base64EncodedString] length]);
//        
//
//        NSLog(@"\n\n");
//
//        NSLog(@"iv is %@", [iv description]);
//        NSLog(@"iv length is %d", [iv length]);
//
//
//        
//        NSString *encodedString = [iv base64EncodedString];
//        NSLog(@"iv base64EncodedString is %@", encodedString);
//        NSLog(@"iv base64EncodedString  length is %d", [ encodedString length]);
//
//        NSString *a = [iv base64Encoding];
//        NSLog(@"iv base64EncodedString is %@", a);


//        NSLog(@" hmac = %@", signature[@"hmac"]);
//        NSLog(@" timestamp = %@",signature[@"timestamp"]);

        
    }
    return self;
}





-(NSData *)createJsonBodyFromDictionary:(NSDictionary *)dictionary
{    
    if ([NSJSONSerialization isValidJSONObject:dictionary])
    {
        //Convert to json object from dictionary
        NSError *error;
        NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:&error];
        
        if (!error){
//            NSLog(@"No json error");
            return data;
        }
    }
//    NSLog(@"NSJSONSerialization is not valid");
    return nil;
}





-(NSDictionary *)createSignatureWithKey:(NSString*)key
{
    NSDate   *currentTime = [NSDate date];
    
    NSString *timestamp = [currentTime stringWithISO8601Format];
    NSData   *signature = [Crypto sha256HMac:[timestamp dataUsingEncoding:NSUTF8StringEncoding] withKey:key];
    NSString *rawSig    = [[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding];
    
    NSString *hexSign   = [Crypto hexEncode:rawSig];
  
    return @{TIMESTAMP: timestamp,
             HEXSIGN  : hexSign};
}



-(NSDictionary *)createHmacWithData:(NSData *)data andWithKey:(NSString*)key
{    
    NSData   *signature = [Crypto sha256HMac:data withKey:key];
    
    NSString *rawSig    = [[NSString alloc] initWithData:signature encoding:NSASCIIStringEncoding];
    NSString *hexSign   = [Crypto hexEncode:rawSig];
    
    return @{ HMAC: hexSign};
}



    
-(NSString *)getUrl
{
    return [NSString stringWithFormat:(USE_SSL ? SERVER_URL_SSL: SERVER_URL), KWIKCY_ENDPOINT];
}

@end

