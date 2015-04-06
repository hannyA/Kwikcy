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

#import "Response.h"


@implementation Response

@synthesize code = _code;
@synthesize message = _message;


-(id)init
{
    self = [self initWithCode:200 andMessage:nil];    
    return self;
}

-(id)initWithCode:(int)theCode andMessage:(NSString *)theMessage
{
    self = [super init];
    
    if (self) {
        self.code = theCode;
        self.message = theMessage;
    }

    return self;
}



-(bool)wasSuccessful
{
    return self.code == SC_OK;
}
-(bool)wasABadRequest
{
    return self.code == SC_BAD_REQUEST;
}
-(bool)wasUnauthorized
{
    return self.code == SC_UNAUTHORIZED;
}
-(bool)wasServerError
{
    return self.code == SC_INTERNAL_SERVER_ERROR;
}

-(bool)wasRequestTimedOut
{
    return self.code == SC_REQUEST_TIMEOUT;
}

-(bool)wasAnotherError
{
    return self.code == KC_ERROR;
}

-(bool)unknownError
{
    return self.code == KC_ERROR;
}

@end

