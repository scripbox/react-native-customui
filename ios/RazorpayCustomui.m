//
//  RazorpayCheckout.m
//  RazorpayCheckout
//
//  Created by Abhinav Arora on 11/10/17.
//  Copyright © 2016 Razorpay. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "RazorpayCustomui.h"
#import "RazorpayEventEmitter.h"

#import <Razorpay/Razorpay-Swift.h>

@interface RazorpayCustomui () <RazorpayPaymentCompletionProtocol, WKNavigationDelegate>{
    Razorpay *razorpay;
    UIViewController *parentVC;
    WKWebView *webview;
    UINavigationBar *navbar;
    UINavigationItem *navItem;
    UIBarButtonItem *cancelBtn;
    UIWindow *window;
}
@end

@implementation RazorpayCustomui

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(open : (NSDictionary *)options) {
    
    NSString *keyID = (NSString *)[options objectForKey:@"key_id"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRotation) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        //Setting navigation bar
        navbar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.rootViewController.view.frame.size.width, 50)];
        navItem = [[UINavigationItem alloc] initWithTitle:@"Authorize Payment"];
        cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(onTapCancel:)];
        navItem.leftBarButtonItem = cancelBtn;
        [navbar setItems:@[navItem]];
        
        int statusHeight = 22;
        int paddingTop = 20;
        int width = [[UIScreen mainScreen] bounds].size.width;
        int height = [[UIScreen mainScreen] bounds].size.height;
        
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        CGRect frame = CGRectMake(0.0, statusHeight, width, height - statusHeight - paddingTop);
        //Setting web view
        webview = [[WKWebView alloc] initWithFrame: frame configuration:configuration];
        webview.navigationDelegate = self;
        webview.opaque = NO;
        webview.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.4];
        
        [self resizeView];
        
        //setting parent view controller
        parentVC = [UIViewController new];
        [parentVC.view addSubview:webview];
        [parentVC.view addSubview:navbar];
        
        
        parentVC.view.autoresizingMask =
        (UIViewAutoresizingFlexibleLeftMargin |
         UIViewAutoresizingFlexibleRightMargin |
         UIViewAutoresizingFlexibleBottomMargin |
         UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight |
         UIViewAutoresizingFlexibleWidth);
        
        webview.autoresizingMask =
        (UIViewAutoresizingFlexibleLeftMargin |
         UIViewAutoresizingFlexibleRightMargin |
         UIViewAutoresizingFlexibleBottomMargin |
         UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight |
         UIViewAutoresizingFlexibleWidth);
        
        window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        window.windowLevel = UIWindowLevelStatusBar;
        window.backgroundColor = [UIColor clearColor];
        [window makeKeyAndVisible];
        [window setRootViewController:parentVC];
        
        razorpay = [Razorpay initWithKey:keyID andDelegate:self withPaymentWebView:webview];
        
        [razorpay authorize:options];
    });
}


-(void)onTapCancel: (id) sender{
    [razorpay userCancelledPayment];
    [RazorpayEventEmitter onPaymentError:1 description:@"User Cancelled Payment" andData:[NSMutableDictionary dictionary]];
    [razorpay close];
    [self close];
}

- (void)onPaymentSuccess:(nonnull NSString *)payment_id
                 andData:(NSDictionary *)response {
    if (response == nil){
        [RazorpayEventEmitter onPaymentSuccess:payment_id andData:[NSMutableDictionary dictionary]];
    }else{
        [RazorpayEventEmitter onPaymentSuccess:payment_id andData:response];
    }
    [razorpay close];
    [self close];
}

- (void)onPaymentError:(int)code
           description:(nonnull NSString *)str
               andData:(NSDictionary *)response {
    if (response == nil){
        [RazorpayEventEmitter onPaymentError:code description:str andData:[NSMutableDictionary dictionary]];
    }else{
        [RazorpayEventEmitter onPaymentError:code description:str andData:response];
    }
    
    [razorpay close];
    [self close];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [razorpay webView:webview didFail:navigation withError:error];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [razorpay webView:webview didFinish:navigation];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    [razorpay webView:webview didCommit:navigation];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error{
    [razorpay webView:webview didFailProvisionalNavigation:navigation withError:error];
}

- (void)handleRotation {
    [self resizeView];
}

- (void)resizeView{
    CGFloat paddingTop = [UIApplication sharedApplication].statusBarHidden ? 0 : 20;
    CGSize size = [[UIScreen mainScreen] bounds].size;
    CGFloat statusHeight = 44;
    [navbar setFrame:CGRectMake(0, 0, size.width, statusHeight + paddingTop)];
    [webview setFrame:CGRectMake(0, statusHeight + paddingTop, size.width,
                                 size.height - statusHeight - paddingTop)];
}

- (void)close{
    
    
    if (webview != nil){
        [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        webview.backgroundColor = [UIColor clearColor];
        [webview stopLoading];
    }
    
    if (navbar != nil){
        [navbar removeFromSuperview];
    }
    
    razorpay = nil;
    
    webview = nil;
    
    parentVC.view = nil;
    parentVC = nil;
    
    navbar = nil;
    navItem = nil;
    cancelBtn = nil;
    
    window.hidden = YES;
    window = nil;
    
}

@end

