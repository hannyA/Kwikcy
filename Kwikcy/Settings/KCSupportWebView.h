//
//  KCSupportWebView.h
//  Kwikcy
//
//  Created by Hanny Aly on 4/21/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import <UIKit/UIKit.h>


enum KCWebType:NSUInteger {
    KCWebTypeHelpCenter,
    KCWebTypePrivacyPolicy,
    KCWebTypeTermsOfService
};



@interface KCSupportWebView : UIViewController

@property (nonatomic,) NSUInteger webType;

-(void)setWebTypeNumber:(NSNumber *)webType;


-(void)getHelpCenterInfo;

-(void)getPrivacyPolicy;

-(void)getTermsOfService;

@end
