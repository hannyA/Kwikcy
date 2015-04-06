/*
 * Copyright 2010-2013 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "Request.h"
#import "Constants.h"

@implementation Request

-(NSString *)buildRequestUrl
{
    return nil;
}


-(NSString *)getUrl
{
    return nil;
}
-(NSString *)buildRequestPostString
{
    return nil;
}


+(NSString *)getEndpointDomain:(NSString *)originalEndpoint
{
    NSRange endpointRange;
    
    if ( [originalEndpoint hasPrefix:@"http://"] || [originalEndpoint hasPrefix:@"https://"]) {
        NSRange startOfDomain = [originalEndpoint rangeOfString:@"://"];
        endpointRange.location = startOfDomain.location + 3;
    }
    else {
        endpointRange.location = 0;
    }
    
    if ( [originalEndpoint hasSuffix:@"/"]) {
        endpointRange.length = ([originalEndpoint length] - 1) - endpointRange.location;
    }
    else {
        endpointRange.length = [originalEndpoint length] - endpointRange.location;
    }
    
    return [originalEndpoint substringWithRange:endpointRange];
}



+(NSString *)endpoint
{
    return [self getEndpointDomain:[KWIKCY_ENDPOINT lowercaseString]];
}

+(NSString *)appName
{
    return [APP_NAME lowercaseString];
}

+(BOOL)useSSL
{
    return USE_SERVER_SIDE_ENCRYPTION;
}


@end

