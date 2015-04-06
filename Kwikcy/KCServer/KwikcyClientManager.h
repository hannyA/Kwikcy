//
//  KwikcyClientManager.h
//  Quickpeck
//
//  Created by Hanny Aly on 3/25/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCKwikcyClient.h"


@interface KwikcyClientManager : NSObject

+(void)sendRequestWithParameters:(NSMutableDictionary *)parameters withCompletionHandler:(KCCompletionBlock) handler;

-(void)sendRequestWithParameters:(NSMutableDictionary *)parameters withCompletionHandler:(KCCompletionBlock) handler;

@end
