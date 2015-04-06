//
//  KCMessageBox.h
//  Kwikcy
//
//  Created by Hanny Aly on 6/1/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AWSDynamoDB/AWSDynamoDB.h>
#import "AmazonKeyChainWrapper.h"
#import "QPNetworkActivity.h"
#import "AmazonClientManager.h"

#import "ReceivedMessageImage.h"

#import "SentMessage.h"

enum MessageBoxType:NSUInteger {
    InboxType,
    OutboxType
};


@interface KCMessageBox : NSObject


/* Server Requests */
+(NSMutableArray *)getNewInboxMessagesFromServer;
+(NSMutableArray *)getOutboxMessagesForPendingMessages:(NSArray *)messages;


-(NSMutableArray *) getMessages;
-(void)             insertAllMessagesFromFetchedController:(NSArray *)messages;


-(void) insertMessage:(id)message atIndex:(NSUInteger)row;

-(NSIndexPath*)getIndexPathOfMessageWithFilePath:(NSString *)filepath;

-(NSIndexPath*)getIndexPathOfMessage:(id)receivedMessage;

-(NSInteger)getRowOfMessage:(ReceivedMessage *)receivedMessage;

-(id)   getMessageAtIndex:(NSUInteger)row;
-(void) removeMessageAtIndex:(NSUInteger)row;
-(void) removeAllMessagesFromBox;


-(NSUInteger)numberOfMessages;
-(BOOL)hasMessages;


-(NSDictionary*)getPendingMessagesinManagedObjectContext:(NSManagedObjectContext*)context;



+(BOOL)deleteInboxMessageFromDynamodbWithRangeKey:(NSString *)rangeKey;
+(BOOL)deleteOutboxMessageFromDynamodbWithRangeKey:(NSString *)rangeKey;



//-(BOOL)contains:(

@end
