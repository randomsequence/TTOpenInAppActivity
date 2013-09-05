//
//  TTOpenInAppActivity.m
//
//  Created by Tobias Tiemerding on 12/25/12.
//  Copyright (c) 2012-2013 Tobias Tiemerding
// 
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "TTOpenInAppActivity.h"
#import <MobileCoreServices/MobileCoreServices.h> // For UTI

@interface TTOpenInAppActivity ()
    // Private attributes
    @property (nonatomic, strong) NSURL *fileURL;
    @property (atomic) CGRect rect;
    @property (nonatomic, strong) UIBarButtonItem *barButtonItem;
    @property (nonatomic, strong) UIView *superView;
    @property (nonatomic, strong) UIDocumentInteractionController *docController;

    // Private methods
    - (NSString *)UTIForURL:(NSURL *)url;
    - (void)openDocumentInteractionController;

@end

@implementation TTOpenInAppActivity
@synthesize rect = _rect;
@synthesize superView = _superView;
@synthesize superViewController = _superViewController;

- (id)initWithView:(UIView *)view andRect:(CGRect)rect
{
    if(self =[super init]){
        self.superView = view;
        self.rect = rect;
    }
    return self;
}

- (id)initWithView:(UIView *)view andBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    if(self =[super init]){
        self.superView = view;
        self.barButtonItem = barButtonItem;
    }
    return self;
}

- (NSString *)activityType
{
	return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
	return NSLocalizedString(@"Open in ...", @"Open in ...");
}

- (UIImage *)activityImage
{
	return [UIImage imageNamed:@"TTOpenInAppActivity"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			return YES;
		}
	}
	
	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			self.fileURL = activityItem;
		}
	}
}

- (void)performActivity
{
    if(!self.superViewController){
        [self activityDidFinish:YES];
        return;
    }

    // Dismiss activity view
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        // iPhone dismiss UIActivityViewController
        [self.superViewController dismissViewControllerAnimated:YES completion:^(void){
            // Open UIDocumentInteractionController
            [self openDocumentInteractionController];
        }];
    } else {
        [self.superViewController dismissPopoverAnimated:YES];
        [((UIPopoverController *)self.superViewController).delegate popoverControllerDidDismissPopover:self.superViewController];
        // Open UIDocumentInteractionController
        [self openDocumentInteractionController];
    }
}

#pragma mark - Helper
- (NSString *)UTIForURL:(NSURL *)url
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)url.pathExtension, NULL);
    return (NSString *) CFBridgingRelease(UTI);
}

- (void)openDocumentInteractionController
{
    // Open "Open in"-menu
    self.docController = [UIDocumentInteractionController interactionControllerWithURL:self.fileURL];
    self.docController.delegate = self;
    self.docController.UTI = [self UTIForURL:self.fileURL];
    BOOL sucess;
    
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone){
        sucess = [self.docController presentOpenInMenuFromRect:CGRectZero inView:self.superView animated:YES];
    } else {
        if(self.barButtonItem)
            sucess = [self.docController presentOpenInMenuFromBarButtonItem:self.barButtonItem animated:YES];
        else
            sucess = [self.docController presentOpenInMenuFromRect:self.rect inView:self.superView animated:YES];
    }
    
    if(!sucess){
        // There is no app to handle this file
        NSString* message = NSLocalizedString(@"Your {devicemodel} doesn't have any apps that can open this document",
                                              @"message indicating no apps were found that can open the document. {devicemodel} is replaced by the device name/kind and {devicename} is replaced by the user-specified name of the device, as in Bob's iPad.");
        message = [message stringByReplacingOccurrencesOfString:@"{devicemodel}" withString:[UIDevice currentDevice].localizedModel];
        message = [message stringByReplacingOccurrencesOfString:@"{devicename}" withString:[UIDevice currentDevice].name];
        
        // Display alert
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Suitable Apps Installed", @"title for alert indicating that no apps were found that can open the given document")
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", @"ok")
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void) documentInteractionControllerDidDismissOpenInMenu: (UIDocumentInteractionController *) controller
{
    [self activityDidFinish:YES];
}

@end

