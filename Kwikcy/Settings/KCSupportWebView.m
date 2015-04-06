//
//  KCSupportWebView.m
//  Kwikcy
//
//  Created by Hanny Aly on 4/21/14.
//  Copyright (c) 2014 Hanny Aly. All rights reserved.
//

#import "KCSupportWebView.h"
#import "Constants.h"





@interface KCSupportWebView ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webViewScreen;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *topSpinningWheel;

@end

@implementation KCSupportWebView


- (void)viewDidLoad
{
    NSLog(@"KCSupportWebView viewdidload");
    [super viewDidLoad];
    self.webViewScreen.delegate = self;
    if (self.webType == KCWebTypeHelpCenter)
    {
        NSLog(@"KCWebTypeHelpCenter");
        [self getHelpCenterInfo];
    }

    else if (self.webType == KCWebTypePrivacyPolicy)
    {
        NSLog(@"KCWebTypePrivacyPolicy");
        [self getPrivacyPolicy];
    }
    else if (self.webType == KCWebTypeTermsOfService)

    {
        NSLog(@"KCWebTypeTermsOfService");
        [self getTermsOfService];
    }
}



-(void)setWebTypeNumber:(NSNumber *)webType
{
    NSLog(@"setWebTypeNumber");
    self.webType = [webType integerValue];
}



-(void)getHelpCenterInfo
{
    NSLog(@"Support screen getHelpCenterInfo");

    [self.webViewScreen loadRequest:[NSURLRequest requestWithURL:nil]];//[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com/"]]];

}

-(void)getPrivacyPolicy
{
    NSLog(@"Support screen getPrivacyPolicy");
    
    [self.webViewScreen loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.apple.com/"]]];
}

-(void)getTermsOfService
{
    NSLog(@"Support screen TermsOfService");
    

    NSString *termsLink = @"https://s3.amazonaws.com/kwikcy-public/legal/en/terms";
    NSURL *url = [NSURL URLWithString:termsLink];

    
//    [self.webViewScreen loadRequest:[NSURLRequest requestWithURL:url]];

    
    NSError *error;
    NSString *htmlPrivacyPolicyStatement = [NSString stringWithContentsOfURL:url
                                                                    encoding:NSUTF8StringEncoding error:&error];
    NSLog(@"Html sring = %@", htmlPrivacyPolicyStatement);


    if (!error)
    {
        [self.webViewScreen loadHTMLString:htmlPrivacyPolicyStatement baseURL:url];
    }
//    else
    // create html error file
//        [self.webViewScreen loadHTMLString:errorString baseURL:nil];


}



-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"shouldStartLoadWithRequest");

    return YES;
}
-(void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidStartLoad");

    [self.topSpinningWheel startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webViewDidFinishLoad");
    [self finish];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"didFailLoadWithError");

    [self finish];
    
    // report the error inside the webview
    NSString* errorString = [NSString stringWithFormat:
                             @"<html><center><font size=+5 color='red'>    \
                             An error occurred:<br>%@</font></center></html>",
                             error.localizedDescription];
    [self.webViewScreen loadHTMLString:errorString baseURL:nil];
    
}

-(void)finish
{
    [self.topSpinningWheel stopAnimating];
}



@end
