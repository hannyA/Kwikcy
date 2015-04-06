//
//  QPProfileMethods.m
//  Quickpeck
//
//  Created by Hanny Aly on 1/13/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "AmazonKeyChainWrapper.h"
#import "Constants.h"
#import "QPProfileMethods.h"
#import <AWSDynamoDB/AWSDynamoDB.h>
#import "AmazonClientManager.h"
#import "QPCoreDataManager.h"
#import "User+methods.h"

#import "QPNetworkActivity.h"

@implementation QPProfileMethods





+(int)getPercentage:(float)value
{
    if (value < 0)
        return 0;
    if (value > 100)
        return 100;
    
    
    int n = (int)roundf(value);
    
    return n;
}


+(NSUInteger)getIntegerNumber:(NSString *)value
{
    NSUInteger count = [value integerValue];
    if (count > 0)
        return count;
    
    return 0;
}

+(BOOL)iphoneHasRetinaDisplay{
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
            ([UIScreen mainScreen].scale == 2.0))? YES:NO;
}

















//Either upload data to s3 and then put link in dynamodb search users table
// Or just store binary data in dynamodb search table


+(BOOL)saveImage:(UIImage *)image forProfileUser:(NSString *)username
{

    //    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    
//        NSString *prefix = [Constants getPrefixForUsername:username];
//        
//        
//        // key and range
//        DynamoDBAttributeValue* hashValue = [[DynamoDBAttributeValue alloc] initWithS:prefix];
//        DynamoDBAttributeValue* rangeValue = [[DynamoDBAttributeValue alloc] initWithS:username];
//        
//        
//        // Setup all conditions
//        NSMutableDictionary *key = [[NSMutableDictionary alloc] init];
//        key[PREFIX] = hashValue;
//        key[USERNAME] = rangeValue;
//        
//        
//        DynamoDBUpdateItemRequest *updateItemRequest = [DynamoDBUpdateItemRequest new];
    
        //        CGFloat height = self.view.bounds.size.height;
        //        CGFloat width  = self.view.bounds.size.width;
        
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        CGFloat width  = [UIScreen mainScreen].bounds.size.height;
        
        

        CGFloat square_length = MIN(height, width);
        
        CGFloat difference;
        CGFloat x_position;
        CGFloat y_position;
        
        if (height > width){
            difference = height - width;
            x_position = 0;
            y_position = difference / 2;
        }
        else{
            difference = width - height;
            x_position = difference / 2;
            y_position = 0;
        }
        
        CGRect rect = CGRectMake(x_position, y_position, square_length, square_length);
        
        
        CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
        UIImage *squareImage = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        
        // Create and show the new image from bitmap data
        //  UIImageView *squareImageView = [[UIImageView alloc] initWithImage:squareImage];
        
        
        
        
        
        
        
        
//        //upload to dynamodb and s3
//        NSData *small_data = UIImageJPEGRepresentation(squareImage, 0.4);
//        
//        //upload to s3 only
//        NSData *medium_data = UIImageJPEGRepresentation(squareImage, 0.6);
    
        //upload to s3 only
        NSData *large_data = UIImageJPEGRepresentation(squareImage, 1.0);
        
        
        
        
        //        NSString *largePhotoAsString = [self encodeToBase64String:large_data];
        
        
        
//        NSString *small_key  = [NSString stringWithFormat:@"%@/%@/%@", username, PROFILE_IMAGES, SMALL_IMAGE];
//        NSString *medium_key = [NSString stringWithFormat:@"%@/%@/%@", username, PROFILE_IMAGES, MEDIUM_IMAGE];
        NSString *large_key  = [NSString stringWithFormat:@"%@/%@/%@", username, PROFILE_IMAGES, LARGE_IMAGE];
        
        
//        BOOL smallUpload = [self uploadData:small_data toBucket:BUCKET_NAME_TMP withKeyName:small_key];
//        if (smallUpload)
//            NSLog(@"smallupload success");
//        else
//            NSLog(@"smallupload failed");
//        
//        
//        BOOL mediumUpload = [self uploadData:medium_data toBucket:BUCKET_NAME_TMP withKeyName:medium_key];
//        if (mediumUpload)
//            NSLog(@"mediumUpload success");
//        else
//            NSLog(@"mediumUpload failed");
    
        
        BOOL largeUpload = [self uploadData:large_data toBucket:BUCKET_NAME_TMP withKeyName:large_key];
        if (largeUpload)
            NSLog(@"largeUpload success");
        else
            NSLog(@"largeUpload failed");
        
        
        //        //SET DATA ATTRIBUTE VALUE
        //        DynamoDBAttributeValue *attributeValue = [[DynamoDBAttributeValue alloc] initWithB:small_data];
        //
        //        DynamoDBAttributeValueUpdate *imageAttributeValueUpdate =
        //            [[DynamoDBAttributeValueUpdate alloc] initWithValue:attributeValue
        //                                                      andAction:@"PUT"];
        //
        //        //SET THE TYPE OF DATA ATTRIBUTE VALUE
        //        DynamoDBAttributeValue *typeAttributeValue = [[DynamoDBAttributeValue alloc] initWithS:IMAGE];
        //
        //        DynamoDBAttributeValueUpdate *typeAttributeValueUpdate =
        //            [[DynamoDBAttributeValueUpdate alloc] initWithValue:typeAttributeValue
        //                                                      andAction:@"PUT"];
        //
        //
        //
        //        NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
        //        dictionary[DATA]     = imageAttributeValueUpdate;
        //        dictionary[DATATYPE] = typeAttributeValueUpdate;
        //
        //
        //        updateItemRequest.tableName = QPUSERS_SEARCH_TABLE;
        //        updateItemRequest.attributeUpdates = dictionary;
        //        updateItemRequest.key = key;
        //
        //        [[QPNetworkActivity sharedInstance] increaseActivity];
        //        DynamoDBUpdateItemResponse *updateItemResponse = [[AmazonClientManager ddb] updateItem:updateItemRequest];
        //        [[QPNetworkActivity sharedInstance] decreaseActivity];
        //
        //        if (!updateItemResponse.error)
        //        {
        //            NSDictionary * userInfo = @{USERNAME: self.username, DATA:small_data, ACTION:InsertImage};
        //
        //            dispatch_sync(dispatch_get_main_queue(), ^{
        //
        //                if (self.managedObjectContext)
        //                {
        //                    [self.managedObjectContext performBlockAndWait:^{
        //                        [User updateUserinfo:userInfo inManagedObjectContext:self.managedObjectContext];
        //                    }];
        //                }
        //            });
        //        }
        //        
        
        NSLog(@"Save image in core data and upload to dynamodb with update attribute for user-search");
        
//    });
    
    return largeUpload;
}











+(NSString *)encodeToBase64String:(NSData *)data
{
    return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}






/* Upload data in one part */
+(BOOL)uploadData:(NSData *)data toBucket:(NSString *)bucket withKeyName:(NSString *)key
{
    BOOL success;
    NSLog(@"Key: %@", key);
    S3PutObjectRequest *por = [[S3PutObjectRequest alloc] initWithKey:key
                                                             inBucket:bucket];
    if (USE_SERVER_SIDE_ENCRYPTION){
        //        por.serverSideEncryption = kS3ServerSideEnryptionAES256;
    }
    
    por.contentType   = @"image/jpeg";
    por.data          = data;
    //    por.delegate = self;
    
    [[QPNetworkActivity sharedInstance] increaseActivity];
    S3PutObjectResponse *putObjectResponse = [[AmazonClientManager s3] putObject:por];
    [[QPNetworkActivity sharedInstance] decreaseActivity];
    
    if(putObjectResponse.error)
    {
        NSLog(@"putObjectResponse error: %@", putObjectResponse.error);
        success = NO;
    }
    else
    {
        NSLog(@"putObjectResponse no error");
        success = YES;
    }
    
    return success;
}






@end
