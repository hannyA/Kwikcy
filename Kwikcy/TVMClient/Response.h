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

#import <Foundation/Foundation.h>

#define SC_OK 200
#define SC_BAD_REQUEST 400
#define SC_UNAUTHORIZED 401
#define SC_INTERNAL_SERVER_ERROR 500
#define SC_REQUEST_TIMEOUT 408
#define KC_ERROR 1000



@interface Response:NSObject

@property (nonatomic) int              code;
@property (nonatomic, strong) NSString *message;

-(id)initWithCode:(int)code andMessage:(NSString *)message;
-(bool)wasSuccessful;

-(bool)wasABadRequest;
-(bool)wasUnauthorized;
-(bool)wasServerError;
-(bool)wasRequestTimedOut;

-(bool)unknownError;

@end
