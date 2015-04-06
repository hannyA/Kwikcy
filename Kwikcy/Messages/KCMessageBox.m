//
//  KCMessageBox.m
//  Kwikcy
//
//  Created by Hanny Aly on 6/1/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCMessageBox.h"
#import "Sent_message.h"

#import "Received_message.h"


@interface KCMessageBox ()
@property (nonatomic, strong) NSMutableArray * messages;
@end



@implementation KCMessageBox


-(id)init
{
    self = [super init];
    if (self)
    {
        self.messages = [[NSMutableArray alloc] init];
    }
    return self;
}


-(NSMutableArray *)getMessages
{
    return self.messages;
}


-(void)insertMessage:(id)message atIndex:(NSUInteger)row
{
    [self.messages insertObject:message atIndex:row];
}

-(id)getMessageAtIndex:(NSUInteger)row
{
    if ([self.messages count] - 1 >= row )
    {
        return self.messages[row];
    }
    return nil;
}

-(void)removeAllMessagesFromBox
{
    [self.messages removeAllObjects];
}

-(void)removeMessageAtIndex:(NSUInteger)row
{
    [self.messages removeObjectAtIndex:row];
}




-(NSInteger)getRowOfMessage:(ReceivedMessage *)receivedMessage
{
    NSUInteger count = [self numberOfMessages];
 
    if ([receivedMessage isKindOfClass:[ReceivedMessage class]])
    {
        for (NSUInteger i = 0; i < count; i++)
        {
            ReceivedMessage *msg = self.messages[i];
            if ([msg isEqualToMessage:receivedMessage])
                return i;
        }

    }
    return -1;
}

-(NSIndexPath*)getIndexPathOfMessage:(id)receivedMessage
{
    NSUInteger count = [self numberOfMessages];
    if ([receivedMessage isKindOfClass:[ReceivedMessage class]])
    {
        
        NSUInteger i;
        for (i = 0; i < count; i++)
        {
            ReceivedMessage *msg = self.messages[i];
            if ([msg isEqualToMessage:receivedMessage]) {
                return [NSIndexPath indexPathForRow:i inSection:0];
            }
        }
    }
    
    return nil;
}





-(NSIndexPath*)getIndexPathOfMessageWithFilePath:(NSString *)filepath
{
    NSUInteger count = [self numberOfMessages];
    
    NSUInteger i;
    for (i = 0; i < count; i++)
    {
        ReceivedMessage *msg = self.messages[i];
        if ([[msg getFilePath] isEqualToString:filepath])
        {
            break;
        }
    }
    return [NSIndexPath indexPathForRow:i inSection:0];
}


-(NSDictionary*)getPendingMessagesinManagedObjectContext:(NSManagedObjectContext*)context
{
//    
//    NSArray * pendingMessages = [Sent_message getMessagesWithPendingStatusinManagedObjectContext:context];
    
    NSMutableArray *pendingMessages = [NSMutableArray new];
    NSMutableArray *indexPaths      = [NSMutableArray new];
    
    NSUInteger count = [self numberOfMessages];

    for (NSUInteger i = 0; i < count; i++)
    {
        NSObject *message = self.messages[i];
        if ([message isKindOfClass:[SentMessage class]])
        {
            SentMessage *sentMesage = (SentMessage *)message;
            
            NSString *status = [sentMesage getStatus];
            NSUInteger statusInt = [status intValue];
            if ([status isEqualToString:PENDING] || (statusInt > 0 && statusInt < 1) )
            {
                [pendingMessages addObject:sentMesage];
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        else
            return nil;
    }
    if ([pendingMessages count])
    {
        return @{ MESSAGE: pendingMessages,
                 @"indexpaths":indexPaths
                 };
    }
    return nil;
}






-(NSUInteger)numberOfMessages
{
    return [self.messages count];
}

-(BOOL)hasMessages
{
    return [self numberOfMessages] ? YES :NO ;
}

-(void)insertAllMessagesFromFetchedController:(NSArray *)fetchedMessages
{
    NSLog(@"insertAllMessagesFromFetchedController fetchedMessages count: %d", [fetchedMessages count]);
    [self.messages removeAllObjects];
    
    if (fetchedMessages && [fetchedMessages count])
    {
        id object = [fetchedMessages firstObject];
        
        if ([object isKindOfClass:[Received_message class]])
        {
            for ( Received_message *message in fetchedMessages)
            {
                if ([message.mediaType isEqualToString:IMAGE])
                {
                    ReceivedMessageImage *timerMessage = [[ReceivedMessageImage alloc] initWithReceived_message:message];
              
                    [self.messages addObject:timerMessage];
                }
            }
        }
        else if ([object isKindOfClass:[Sent_message class]])
        {
            //TODO: incomplete
            for ( Sent_message *message in fetchedMessages)
            {
                if ([message.mediaType isEqualToString:IMAGE])
                {
                    SentMessage *sentMessage = [[SentMessage alloc] initWithSentMessage:message];
                    
                    [self.messages addObject:sentMessage];
                }
            }
        }
    }    
}








+(NSMutableArray *)getNewInboxMessagesFromServer
{
    DynamoDBCondition *condition = [DynamoDBCondition new];
    condition.comparisonOperator = @"EQ";
    
    [condition addAttributeValueList:[[DynamoDBAttributeValue alloc] initWithS:[AmazonKeyChainWrapper username]]];
    
    
    DynamoDBQueryRequest *queryRequest = [DynamoDBQueryRequest new];
    queryRequest.tableName = INBOX_TABLE;
    
    queryRequest.keyConditions = [NSMutableDictionary dictionaryWithObject:condition
                                                                    forKey:RECEIVER];
    queryRequest.limit = [NSNumber numberWithInt:20];
    queryRequest.consistentRead = NO;
    
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    DynamoDBQueryResponse *queryResponse = [[AmazonClientManager ddb] query:queryRequest];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    
    if(!queryResponse.error)
    {
        if ([queryResponse.count integerValue]) {
            NSLog(@"queryResponse count = %@", queryResponse.count);
            
            return [NSMutableArray arrayWithArray:queryResponse.items];
        }
    }
    return nil;
    
}



/* works with function from below */

+(NSMutableDictionary *)getDynamoDBBatchRequestWithArray:(NSArray *)pendingMessages
{
    // Create array to store keys
    NSMutableArray *arrayOfKeys = [[NSMutableArray alloc] init];
    
    // Loop to insert all keys
    for (SentMessage *message in pendingMessages)
    {
        NSDictionary *primaryKeysAndRanges  = @{
                                    SENDER:[[DynamoDBAttributeValue alloc] initWithS:[message getSender]],
                                    FILEPATH:[[DynamoDBAttributeValue alloc] initWithS:[message getFilePath]] };
        // Add keys to array
        [arrayOfKeys addObject:primaryKeysAndRanges];
    }
    
    DynamoDBKeysAndAttributes *keysAndAttr = [[DynamoDBKeysAndAttributes alloc] init];
    
    // Create array of attributes to get
    NSMutableArray * arrayOfAttributes = [NSMutableArray arrayWithObjects:STATUS, SENDER, FILEPATH, nil];
    
    
    keysAndAttr.keys = arrayOfKeys;
    keysAndAttr.attributesToGet = arrayOfAttributes;
    keysAndAttr.consistentRead = NO;
    
    return [NSMutableDictionary dictionaryWithObject:keysAndAttr forKey:OUTBOX_TABLE];
}


//
//+(NSMutableDictionary *)getDynamoDBBatchRequestWithArray:(NSArray *)pendingMessages
//{
//    // Create array to store keys
//    NSMutableArray *arrayOfKeys = [[NSMutableArray alloc] init];
//    
//    // Loop to insert all keys
//    for (Sent_message *message in pendingMessages)
//    {
//        NSDictionary *primaryKeysAndRanges  = @{
//                                                SENDER:[[DynamoDBAttributeValue alloc] initWithS:message.sender],
//                                                FILEPATH:[[DynamoDBAttributeValue alloc] initWithS:message.filepath] };
//        // Add keys to array
//        [arrayOfKeys addObject:primaryKeysAndRanges];
//    }
//    
//    DynamoDBKeysAndAttributes *keysAndAttr = [[DynamoDBKeysAndAttributes alloc] init];
//    
//    // Create array of attributes to get
//    NSMutableArray * arrayOfAttributes = [NSMutableArray arrayWithObjects:STATUS, SENDER, FILEPATH, nil];
//    
//    
//    keysAndAttr.keys = arrayOfKeys;
//    keysAndAttr.attributesToGet = arrayOfAttributes;
//    keysAndAttr.consistentRead = NO;
//    
//    return [NSMutableDictionary dictionaryWithObject:keysAndAttr forKey:OUTBOX_TABLE];
//}



/* used for getting all sent messages with pending requests */


+(NSMutableArray *)getOutboxMessagesForPendingMessages:(NSArray *)pendingMessages
{
    NSLog(@"getOutboxMessagesForPendingMessages called Sent refresh 7");
    
    NSMutableArray * outboxResults = [NSMutableArray array];
    
    
    if ([pendingMessages count])
    {
        DynamoDBBatchGetItemRequest *batchGetItemRequest = [[DynamoDBBatchGetItemRequest alloc] init];
        
        // Send array to getDynamoDBBatchRequestWithArray method to get batch Request
        batchGetItemRequest.requestItems = [self getDynamoDBBatchRequestWithArray:pendingMessages];
        
        [[QPNetworkActivity sharedInstance] increaseActivity];
        DynamoDBBatchGetItemResponse *batchGetItemResponse = [[AmazonClientManager ddb] batchGetItem:batchGetItemRequest];
        [[QPNetworkActivity sharedInstance] decreaseActivity];
       
        if(batchGetItemResponse.error) {
            NSLog(@"Error: %@", batchGetItemResponse.error);
        }
        if(!batchGetItemResponse.error && [batchGetItemResponse.responses count]) {
            
            NSArray *keys = [batchGetItemResponse.responses allKeys];
            for (NSString *tableName in keys)
            {
                NSArray *arrayOfDictionaryResults = [batchGetItemResponse.responses valueForKey:tableName];
                for (NSDictionary *dictionaryResult in arrayOfDictionaryResults)
                {
                    NSString *sender = ((DynamoDBAttributeValue*)[dictionaryResult valueForKey:SENDER]).s;
                    NSString *filepath = ((DynamoDBAttributeValue*)[dictionaryResult valueForKey:FILEPATH]).s;
                    NSString *status = ((DynamoDBAttributeValue*)[dictionaryResult valueForKey:STATUS]).s;
                    
                    if (sender && filepath && status && ![status isEqualToString:PENDING])
                    {
                        NSDictionary * messageResults = @{ SENDER: sender,
                                                           FILEPATH: filepath,
                                                           STATUS: status };
                        
                        [outboxResults addObject:messageResults];
                    }
                }
            }
        }
    }
    return outboxResults;
}




+(BOOL)deleteInboxMessageFromDynamodbWithRangeKey:(NSString *)rangeKey
{
    NSString *hashKey = [AmazonKeyChainWrapper username];
    

    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
    
    attributeDictionary[INBOX_HASH_KEY_RECEIVER] = [[DynamoDBAttributeValue alloc] initWithS:hashKey];
    
    attributeDictionary[INBOX_RANGE_KEY_FILEPATH] = [[DynamoDBAttributeValue alloc] initWithS:rangeKey];
    
    DynamoDBDeleteItemRequest * dynamoDBDeleteRequest = [[DynamoDBDeleteItemRequest alloc] initWithTableName:INBOX_TABLE andKey:attributeDictionary];

    
    DynamoDBDeleteItemResponse * dynamoDBDeleteResponse;
    NSUInteger retry = 3;
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
   
    for(int i = 0; i < retry ; i++)
    {
        dynamoDBDeleteResponse = [[AmazonClientManager ddb] deleteItem:dynamoDBDeleteRequest];
        
        if (!dynamoDBDeleteResponse.error)
        {
            [[QPNetworkActivity sharedInstance] decreaseActivity];
            return YES;
        }
    }
    
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    return NO;
}


+(BOOL)deleteOutboxMessageFromDynamodbWithRangeKey:(NSString *)rangeKey
{
    NSString *hashKey = [AmazonKeyChainWrapper username];
    
    
    NSMutableDictionary *attributeDictionary = [NSMutableDictionary dictionary];
    
    attributeDictionary[OUTBOX_HASH_KEY]  = [[DynamoDBAttributeValue alloc] initWithS:hashKey];
    attributeDictionary[OUTBOX_RANGE_KEY] = [[DynamoDBAttributeValue alloc] initWithS:rangeKey];
    
    DynamoDBDeleteItemRequest * dynamoDBDeleteRequest = [[DynamoDBDeleteItemRequest alloc] initWithTableName:OUTBOX_TABLE andKey:attributeDictionary];
    
    
    DynamoDBDeleteItemResponse * dynamoDBDeleteResponse;
    NSUInteger retry = 3;

    [[QPNetworkActivity sharedInstance] increaseActivity];
    for(int i = 0; i < retry ; i++)
    {
        dynamoDBDeleteResponse = [[AmazonClientManager ddb] deleteItem:dynamoDBDeleteRequest];

        if (!dynamoDBDeleteResponse.error)
        {
            [[QPNetworkActivity sharedInstance] decreaseActivity];
            return YES;
        }
    }
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    return NO;
}





@end
