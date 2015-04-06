//
//  KCSynchronousUploader.m
//  Kwikcy
//
//  Created by Hanny Aly on 8/24/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCSynchronousUploader.h"

#import "AmazonClientManager.h"

#import "Constants.h"
#import "Crypto.h"
#import "MBProgressHUD.h"
#import "Sent_message+methods.h"

#import "QPNetworkActivity.h"
#import "KwikcyClientManager.h"
#import "KCServerResponse.h"

#import <AWSS3/AWSS3.h>
#import <AWSSQS/AWSSQS.h>


@interface KCSynchronousUploader ()

@property (atomic) BOOL dynamoDBUploaded;
@property (atomic) BOOL s3Uploaded;
@property (atomic) BOOL runOnce;

@property (atomic) BOOL dynamoComplete;
@property (atomic) BOOL s3Complete;

@property (nonatomic, strong) NSNumber *progressComplete;

@property (nonatomic, strong) NSTimer *timer;
@end


@implementation KCSynchronousUploader

#pragma mark - Class Lifecycle


-(id)initWithMessageDictionary:(NSDictionary *)theMessageDictionary andProgressView:(UIProgressView *)progressView withManagedObjectContext:(NSManagedObjectContext *)theManagedObjectContext
{
    self = [super init];
    if (self)
    {
        isExecuting = NO;
        isFinished  = NO;
        
        self.messageDictionary    = theMessageDictionary;
        self.managedObjectContext = theManagedObjectContext;
        
        self.timer = [NSTimer timerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(updateTimerArtificially)
                                           userInfo:nil
                                            repeats:YES];
        
        self.progressComplete = [NSNumber numberWithFloat:0];
    }
    
    return self;
}


#pragma mark - Overwriding NSOperation Methods

/*
 * For concurrent operations, you need to override the following methods:
 * start, isConcurrent, isExecuting and isFinished.
 *
 * Please refer to the NSOperation documentation for more details.
 * http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/NSOperation_class/Reference/Reference.html
 */


/*
 * Method determines the size of the data, and begins s3 upload and dynamodb put request
 */

-(void)start
{
    // Makes sure that start method always runs on the main thread.
    if (![NSThread isMainThread])
    {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    
    NSDictionary *info = @{PERCENTAGE_COMPLETE : [NSNumber numberWithFloat:0],
                           FILEPATH            : self.messageDictionary[FILEPATH]
                           };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:KwikcyFileUpload object:self userInfo:info];
    
    
    
    [self willChangeValueForKey:@"isExecuting"];
    isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    NSString *bucket = BUCKET_NAME_TMP;
    
    //on separate thread upload to dynamodb kcOutbox
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addTimer:self.timer forMode:NSRunLoopCommonModes];

        [runLoop run];
        
//        [self uploadDataToDynamoDB];
//        
//        // Regardless if we are successful in uploading to Dynamodb we call sendRequest
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self sendReqestToKwikcyServer:@"dynamodb"];
//        });
    });
    
    
    
    // Upload data to s3
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{

        BOOL success;
        
        if ([self.messageDictionary[MEDIATYPE] isEqualToString:VIDEO])
        {
            NSData* data = [NSData dataWithContentsOfURL:self.messageDictionary[MOVIEURL]];
            int numberOfParts = [self countParts:data];
            
            //Upload data first to s3
            if (numberOfParts > 1)
                success = [self multipartUploadInBucket:bucket];
            else
                success = [self uploadDataInBucket:bucket];
        }
        else //if ([self.messageDictionary[MEDIATYPE] isEqualToString:IMAGE])
        {
            success = [self uploadDataInBucket:bucket];
        }
        
    });
}


-(BOOL)hasRunOnce
{
    @synchronized(self)
    {
        if(!self.runOnce)
        {
            self.runOnce = YES;
            return NO;
        }
        return self.runOnce;
    }
}



//-(void)sendReqestToKwikcyServer:(NSString*)type
//{
//    if (self.dynamoComplete && self.s3Complete)
//    {
//        if (self.s3Uploaded && self.dynamoDBUploaded)
//        {
//            if([self hasRunOnce])
//                return;
//            
//            NSMutableDictionary *parameters = [NSMutableDictionary new];
//            
//            parameters[COMMAND]   = SEND_PHOTO;
//            parameters[FILEPATH]  = self.messageDictionary[FILEPATH];
//            
//            
//            [KwikcyClientManager sendRequestWithParameters:parameters
//                                     withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
//             {
//                 [[QPNetworkActivity sharedInstance] decreaseActivity];
//
//                 if (error)
//                 {
//                     // Insert into core data failed messages
//                     [self.managedObjectContext performBlock:^{
//                         [Sent_message updateMessageWithStatus:@{SENDER   : self.messageDictionary[SENDER],
//                                                                 FILEPATH : self.messageDictionary[FILEPATH],
//                                                                 STATUS   : FailedToSendDoubleTap
//                                                                 }
//                                        inManagedObjectContext:self.managedObjectContext];
//                     }];
//                     
//                     NSString *message = [NSString stringWithFormat:@"Could not send %@ due to a connection error",
//                                          [parameters[MEDIATYPE] isEqualToString:IMAGE]? @"photo": parameters[MEDIATYPE] ];
//                     
//                     [[Constants alertWithTitle:@"Connection Error"
//                                     andMessage:message] show];
//                 }
//                 else
//                 {
//                     KCServerResponse *serverResponse = (KCServerResponse *)response;
//                     
//                     if (received200Response)
//                     {
//                         if (serverResponse.successful)
//                         {
//                             //                             NSLog(@"serverResponse.successful!");
//                             //Do nothing, it will be updated to pending by function in Sent_message when percent = 100
//                         
////                             NSString *filepath =  serverResponse.info[FILEPATH];
//                         
//                             // Insert into core data failed messages
//                             [self.managedObjectContext performBlock:^{
//                                 [Sent_message updateMessageWithStatus:@{SENDER   : self.messageDictionary[SENDER],
//                                                                         FILEPATH : self.messageDictionary[FILEPATH],
//                                                                         STATUS   : FAILED
//                                                                         }
//                                                inManagedObjectContext:self.managedObjectContext];
//                             }];
//                             
//                             
//                         }
//                         else
//                         {
//                             NSLog(@"serverResponse was unsuccessful!");
//                             
//                             // Insert into core data failed messages
//                             [self.managedObjectContext performBlock:^{
//                                 [Sent_message updateMessageWithStatus:@{SENDER   : self.messageDictionary[SENDER],
//                                                                         FILEPATH : self.messageDictionary[FILEPATH],
//                                                                         STATUS   : FAILED
//                                                                         }
//                                                inManagedObjectContext:self.managedObjectContext];
//                             }];
//                             
//                             
//                         }
//                     }
//                 }
//             }];
//        }
//        // Upload to s3 failed or dynamodb failed?
//        else
//        {
//            [[QPNetworkActivity sharedInstance] decreaseActivity];
//
//            // Insert into core data failed messages
//            [self.managedObjectContext performBlock:^{
//                [Sent_message updateMessageWithStatus:@{SENDER   : self.messageDictionary[SENDER],
//                                                        FILEPATH : self.messageDictionary[FILEPATH],
//                                                        STATUS   : FAILED
//                                                        }
//                               inManagedObjectContext:self.managedObjectContext];
//            }];
//        }
//    }
//}


-(void)sendReqestToKwikcyServer:(NSString*)type
{
    NSLog(@"sendReqestToKwikcyServer");
    if (self.s3Uploaded)
    {
        NSLog(@"sendReqestToKwikcyServer s3Uploaded");

        NSMutableDictionary *parameters = [NSMutableDictionary new];
        
        parameters[COMMAND]    = SEND_PHOTO;
        parameters[FILEPATH]   = self.messageDictionary[FILEPATH];  // range key  , uploaded location
        parameters[FILENAME]   = self.messageDictionary[FILENAME];

        parameters[DATE]       = self.messageDictionary[DATE];
        parameters[MEDIATYPE]  = self.messageDictionary[MEDIATYPE];
        parameters[STATUS]     = PENDING;
        parameters[VIEW]       = NOT_VIEWED;
        parameters[RECEIVERS]  = self.messageDictionary[RECEIVERS_ARRAY];
        
        parameters[SCREENSHOT_SAFE] = [self.messageDictionary[SCREENSHOT_SAFE] boolValue] ? @"y" : @"n";
        
        
        if (self.messageDictionary[MESSAGE] != [NSNull null] && self.messageDictionary[MESSAGE])
        {
            parameters[MESSAGE] = self.messageDictionary[MESSAGE];
        }
        
        
        
        [[QPNetworkActivity sharedInstance] increaseActivity];
        NSLog(@"sendReqestToKwikcyServer s3Uploaded sending");

        [KwikcyClientManager sendRequestWithParameters:parameters
                                 withCompletionHandler:^(BOOL received200Response, Response *response, NSError *error)
         {
             
             NSLog(@"sendReqestToKwikcyServer s3Uploaded sending done");

             [[QPNetworkActivity sharedInstance] decreaseActivity];
             
             if (error)
             {
                 // Insert into core data failed messages
                 [self.managedObjectContext performBlock:^{
                     [Sent_message updateMessageWithStatus:@{SENDER   : self.messageDictionary[SENDER],
                                                             FILEPATH : self.messageDictionary[FILEPATH],
                                                             STATUS   : FailedToSendDoubleTap
                                                             }
                                    inManagedObjectContext:self.managedObjectContext];
                 }];
                 
                 NSString *message = [NSString stringWithFormat:@"Could not send %@ due to a connection error",
                                      [parameters[MEDIATYPE] isEqualToString:IMAGE]? @"photo": parameters[MEDIATYPE] ];
                 
                 [[Constants alertWithTitle:@"Connection Error"
                                 andMessage:message] show];
             }
             else
             {
                 KCServerResponse *serverResponse = (KCServerResponse *)response;
                 
                 if (received200Response)
                 {
                     if (serverResponse.successful)
                     {
                         //                             NSLog(@"serverResponse.successful!");
                         //Do nothing, it will be updated to pending by function in Sent_message when percent = 100
                         
//                         NSString *filepath =  serverResponse.info[FILEPATH];

                         
                         NSString *unsendKey = serverResponse.info[UNSEND_KEY];
                         
                         
                         
                         // Insert into core data failed messages
                         [self.managedObjectContext performBlock:^{
                             [Sent_message updateMessageWithStatus:@{SENDER     : self.messageDictionary[SENDER],
                                                                     FILEPATH   : self.messageDictionary[FILEPATH],
                                                                     UNSEND_KEY : unsendKey
                                                                     }
                                            inManagedObjectContext:self.managedObjectContext];
                         }];
                         
                         
                     }
                     else
                     {
                         NSLog(@"serverResponse was unsuccessful!");
                         
                         // Insert into core data failed messages
                         [self.managedObjectContext performBlock:^{
                             [Sent_message updateMessageWithStatus:@{SENDER   : self.messageDictionary[SENDER],
                                                                     FILEPATH : self.messageDictionary[FILEPATH],
                                                                     STATUS   : FAILED
                                                                     }
                                            inManagedObjectContext:self.managedObjectContext];
                         }];
                         
                         
                     }
                 }
             }
         }];

    }
    // Upload to s3 failed or dynamodb failed?
    else
    {
        // Insert into core data failed messages
        [self.managedObjectContext performBlock:^{
            [Sent_message updateMessageWithStatus:@{SENDER   : self.messageDictionary[SENDER],
                                                    FILEPATH : self.messageDictionary[FILEPATH],
                                                    STATUS   : FAILED
                                                    }
                           inManagedObjectContext:self.managedObjectContext];
        }];
    }
}


-(BOOL)uploadDataToDynamoDB
{
    BOOL success = NO;
    
    NSString *filepath        = self.messageDictionary[FILEPATH];
    NSString *filename        = self.messageDictionary[FILENAME];
    NSString *mediaType       = self.messageDictionary[MEDIATYPE];
    NSString *username        = self.messageDictionary[SENDER];
    NSString *date            = self.messageDictionary[DATE];
    NSMutableArray *contacts  = self.messageDictionary[RECEIVERS_ARRAY];
    
    NSString *screenShotSafe  = [self.messageDictionary[SCREENSHOT_SAFE] boolValue] ? @"y" : @"n";

    
    NSLog(@"screenShotSafe = %@", screenShotSafe);
    
    NSMutableDictionary *userDic = [NSMutableDictionary dictionary];
    
    
    userDic[SENDER ]    = [[DynamoDBAttributeValue alloc] initWithS:username];
    userDic[FILEPATH]   = [[DynamoDBAttributeValue alloc] initWithS:filepath];

    userDic[FILENAME]   = [[DynamoDBAttributeValue alloc] initWithS:filename];

    userDic[DATE]       = [[DynamoDBAttributeValue alloc] initWithS:date];
    userDic[MEDIATYPE]  = [[DynamoDBAttributeValue alloc] initWithS:mediaType];
    userDic[STATUS]     = [[DynamoDBAttributeValue alloc] initWithS:PENDING];
    userDic[VIEW]       = [[DynamoDBAttributeValue alloc] initWithS:NOT_VIEWED];
    userDic[RECEIVERS]  = [[DynamoDBAttributeValue alloc] initWithSS:contacts];
    
    userDic[SCREENSHOT_SAFE] = [[DynamoDBAttributeValue alloc] initWithS:screenShotSafe];


    
    
    if (self.messageDictionary[MESSAGE] != [NSNull null] && self.messageDictionary[MESSAGE])
    {
        userDic[MESSAGE] = [[DynamoDBAttributeValue alloc] initWithS:self.messageDictionary[MESSAGE]];
    }
    
    DynamoDBPutItemRequest *request = [[DynamoDBPutItemRequest alloc] initWithTableName:OUTBOX_TABLE
                                                                                andItem:userDic];
    
    DynamoDBPutItemResponse *response = [[AmazonClientManager ddb] putItem:request];
    
    if(response.error)
    {
        success = NO;
        //TODO: Store data in core data as failed send
    }
    else
        success = YES;
    
    self.dynamoDBUploaded = success;
    self.dynamoComplete = YES;
    
    return success;
}






#pragma mark - Helper Methods



-(BOOL)isConcurrent
{
    return YES;
}

-(BOOL)isExecuting
{
    return isExecuting;
}

-(BOOL)isFinished
{
    return isFinished;
}


-(void)finish
{
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    isExecuting = NO;
    isFinished  = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
    
    self.s3Complete = YES;
    
    [self sendReqestToKwikcyServer:@"s3"];
}


-(void)updateTimerArtificially
{
    NSLog(@"updateTimerArtificially 1");
    
    if ([ self.progressComplete floatValue] < .8)
    {
        self.progressComplete  = [NSNumber numberWithFloat:[self.progressComplete floatValue] + 0.2];
        
        [self.managedObjectContext performBlock:^{
            [Sent_message updateSentFile:self.messageDictionary[FILEPATH]
                            withProgress:self.progressComplete
                  inManagedObjectContext:self.managedObjectContext];
        }];
        
        
        NSDictionary *info = @{PERCENTAGE_COMPLETE : self.progressComplete,
                               FILEPATH            : self.messageDictionary[FILEPATH]
                               };
        
        [[NSNotificationCenter defaultCenter] postNotificationName:KwikcyFileUpload object:self userInfo:info];
        
        
    }
    else
    {
        if([self.timer isValid])
            [self.timer invalidate];
    }
}

















#pragma mark Methods to deal with uploading data

const int PART_SIZE = (5 * 1024 * 1024); // 5MB is the smallest part size allowed for a multipart upload. (Only the last part can be smaller.)

-(NSData*)getPart:(int)part fromData:(NSData*)fullData
{
    NSRange range;
    range.length = PART_SIZE;
    range.location = part * PART_SIZE;
    
    int maxByte = (part + 1) * PART_SIZE;
    if ( [fullData length] < maxByte ) {
        range.length = [fullData length] - range.location;
    }
    return [fullData subdataWithRange:range];
}



-(int)countParts:(NSData*)fullData
{
    int q = (int)([fullData length] / PART_SIZE);
    int r = (int)([fullData length] % PART_SIZE);
    
    return ( r == 0 ) ? q : q + 1;
}








/* Upload data in one part */
-(BOOL)uploadDataInBucket:(NSString *)bucket
{
    BOOL success = NO;
    NSString *key = self.messageDictionary[FILEPATH];
    
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:key
                                                             inBucket:bucket];
    if (USE_SERVER_SIDE_ENCRYPTION)
    {
        por.serverSideEncryption = kS3ServerSideEnryptionAES256;
    }
    if ([self.messageDictionary[MEDIATYPE] isEqualToString:IMAGE])
    {
        NSData *imageData = self.messageDictionary[DATA];
        por.contentType   = @"image/jpeg";
        por.data          = imageData;
    }
    else
    {
        NSData *data = [NSData dataWithContentsOfURL:self.messageDictionary[MOVIEURL]];
        por.contentType   = @"video/quicktime";
        por.data          = data;
        por.contentLength = [data length];
    }
//    por.delegate = self;
    
    
    //This is an asynch call. This gets called first and continues, then totalBytes:writtenBytes function is called
    NSLog(@"KWIKCY PUTING OBJECT BEGIN");

    [[QPNetworkActivity sharedInstance] increaseActivity];

    S3PutObjectResponse *putObjectResponse = [[AmazonClientManager s3] putObject:por];
    
    [[QPNetworkActivity sharedInstance] decreaseActivity];

    NSLog(@"KWIKCY PUTOBJECT COMPLETE");
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        if([self.timer isValid])
            [self.timer invalidate];
        
        
        NSMutableDictionary *info = [NSMutableDictionary new];
      
        info[PERCENTAGE_COMPLETE] = [NSNumber numberWithFloat:1];
        info[FILEPATH] = self.messageDictionary[FILEPATH];
        
        if(putObjectResponse.error)
        {
            NSLog(@"KWIKCY PUTOBJECT COMPLETE %@", putObjectResponse.error);
            
            self.s3Uploaded = NO;
            
            self.progressComplete  = [NSNumber numberWithFloat:1];

          
            // Insert into core data failed messages
            [self.managedObjectContext performBlock:^{
                [Sent_message updateMessageWithStatus:@{SENDER   : self.messageDictionary[SENDER],
                                                        FILEPATH : self.messageDictionary[FILEPATH],
                                                        STATUS   : FAILED
                                                        }
                               inManagedObjectContext:self.managedObjectContext];
            }];
            
            info[STATUS] = FAILED;
        }
        else
        {
            self.s3Uploaded = YES;
        
            self.progressComplete  = [NSNumber numberWithFloat:1];
            
            
            [self.managedObjectContext performBlock:^{
                [Sent_message updateSentFile:self.messageDictionary[FILEPATH]
                                withProgress:self.progressComplete
                      inManagedObjectContext:self.managedObjectContext];
            }];
    
            
            info[STATUS] = PENDING;
        }
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:KwikcyFileUpload
                                                            object:self
                                                          userInfo:info];
        
        [self finish];
    });


    return success;
}



-(void)finalUpdate
{
    [self.managedObjectContext performBlock:^{
        [Sent_message updateSentFile:self.messageDictionary[FILEPATH]
                        withProgress:self.progressComplete
              inManagedObjectContext:self.managedObjectContext];
    }];
    
//    
//    NSDictionary *info = @{PERCENTAGE_COMPLETE : [NSNumber numberWithFloat:0],
//                           FILEPATH            : self.messageDictionary[FILEPATH]
//                           };
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:KwikcyFileUpload object:self userInfo:info];

}


/* Multipart Upload */
-(BOOL)multipartUploadInBucket:(NSString *)bucket
{
    BOOL success = NO;
    
    AmazonS3Client *s3 = [AmazonClientManager s3];
    NSString *key = self.messageDictionary[FILEPATH];
    NSData* data = [NSData dataWithContentsOfURL:self.messageDictionary[MOVIEURL]];
    
    
    S3InitiateMultipartUploadRequest *initReq = [[S3InitiateMultipartUploadRequest alloc] initWithKey:key inBucket:bucket];
    S3MultipartUpload *upload = [s3 initiateMultipartUpload:initReq].multipartUpload;
    S3CompleteMultipartUploadRequest *compReq = [[S3CompleteMultipartUploadRequest alloc] initWithMultipartUpload:upload];
    
    int numberOfParts = [self countParts:data];
    for ( int part = 0; part < numberOfParts; part++ ) {
        NSData *dataForPart = [self getPart:part fromData:data];
        
        S3UploadPartRequest *upReq = [[S3UploadPartRequest alloc] initWithMultipartUpload:upload];
        upReq.partNumber = ( part + 1 );
        upReq.contentLength = [dataForPart length];
        
//        upReq.delegate = self;
        
        S3UploadPartResponse *response = [s3 uploadPart:upReq];
        if (response.error)
        {
            success = NO;
            return success;
        }
        
        [compReq addPartWithPartNumber:( part + 1 ) withETag:response.etag];
    }
    
    S3CompleteMultipartUploadResponse  *response = [s3 completeMultipartUpload:compReq];
    
    if (response.error)
        success = NO;
    else
        success = YES;
    
    return success;
}

@end
