//
//  KwikcyClientManager.m
//  Quickpeck
//
//  Created by Hanny Aly on 3/25/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KwikcyClientManager.h"

//static KCKwikcyClient  *kcc = nil;

@interface KwikcyClientManager()
@property (nonatomic, strong) KCKwikcyClient* kwikcyClient;
@end


@implementation KwikcyClientManager


-(id)init
{
    self = [super init];
    if (self)
    {
        self.kwikcyClient = [[KCKwikcyClient alloc] init];
    }
    return self;
}

-(void)sendRequestWithParameters:(NSMutableDictionary *)parameters withCompletionHandler:(KCCompletionBlock) handler;
{

        [self.kwikcyClient sendRequestWithParameters:parameters
                                   withCompletionHandler:^(BOOL success, Response* response,  NSError *error)
         {
    
             NSLog(@"sendRequestWithParameters command %@", parameters[@"Command"]);
             handler(success, response, error);
         }];
}



+(void)sendRequestWithParameters:(NSMutableDictionary *)parameters withCompletionHandler:(KCCompletionBlock) handler;
{
    NSLog(@"sendRequestWithParameters class method");
    [[KwikcyClientManager kwikcyClient] sendRequestWithParameters:parameters
                                            withCompletionHandler:^(BOOL success, Response* response,  NSError *error)
     {
        handler(success, response, error);
        
    }];
}


+(KCKwikcyClient *)kwikcyClient
{
    return [[KCKwikcyClient alloc] init];
}


//
//-(KCKwikcyClient *)kcc
//{
//    if (kcc == nil) {
//        kcc = [[KCKwikcyClient alloc] init];
//    }
//    
//    return kcc;
//}




@end
