//
//  KCKwikcyClient.h
//  Quickpeck
//
//  Created by Hanny Aly on 3/25/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Response.h"

typedef void (^KCCompletionBlock)(BOOL success,  Response *response, NSError *error);

//functions other classes to implement
//@protocol KCClientProtocolDelegate <NSObject>
//@required
//- (void) kcCallback;
//@end


@interface KCKwikcyClient : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>

// Delegate to respond back
//@property (nonatomic, weak) id <KCClientProtocolDelegate> delegate;

-(void)sendRequestWithParameters:(NSMutableDictionary *)parameters withCompletionHandler:(KCCompletionBlock) handler;
@end
