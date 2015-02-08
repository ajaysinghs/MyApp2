//
//  DetailViewController.m
//  StoreSearch
//
//  Created by Ajay Singh on 11/2/14.
//  Copyright (c) 2014 Ajay Singh. All rights reserved.
//

#import "DetailViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "SearchResult.h"

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "GradientView.h"

#import "MenuViewController.h"

#import <MessageUI/MessageUI.h>


@interface DetailViewController () <UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIView *popupView;

@property (nonatomic, weak) IBOutlet UIImageView *artworkImageView;

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, weak) IBOutlet UILabel *artistNameLabel;

@property (nonatomic, weak) IBOutlet UILabel *kindLabel;

@property (nonatomic, weak) IBOutlet UILabel *genreLabel;

@property (nonatomic, weak) IBOutlet UIButton *priceButton;

@property (nonatomic, strong) UIPopoverController *masterPopoverController;

@property (nonatomic, strong) UIPopoverController *menuPopoverController;



@end

@implementation DetailViewController

{
    GradientView *_gradientView;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    //for Gradient not to be so dark
    self.view.backgroundColor = [UIColor clearColor];
    
    //stretchable image for Button
    UIImage *image = [[UIImage imageNamed:@"PriceButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    
    //set the “always template” rendering mode on an image, UIKit will remove the original colors from the image and paint the whole thing in the tint color.
    image = [image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    
    [self.priceButton setBackgroundImage:image forState:UIControlStateNormal];
    
    //can change the tint color on a per-view basis, and if that view has subviews then the new tint color also applies to these subviews
    self.view.tintColor = [UIColor colorWithRed:20/255.0f green:160/255.0f blue:160/255.0f alpha:1.0f];
    
    //to make pop-up view rounded corners
    self.popupView.layer.cornerRadius = 10.0f;
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"LandscapeBackground"]];
        self.popupView.hidden = (self.searchResult == nil);
        //self.title = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
        self.title = @"Store Search";
        
        //to add BarButtonItem for email option in ipad
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                                  initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                  target:self
                                                  action:@selector(menuButtonPressed:)];
    }
    else {
    //adding Tap gesture recognizer
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:gestureRecognizer];
        self.view.backgroundColor = [UIColor clearColor];
    
    }
    if (self.searchResult != nil) {
        [self updateUI];
    }
    
}

- (void)updateUI
{
    self.nameLabel.text = self.searchResult.name;
    
    NSString *artistName = self.searchResult.artistName;
    
    if (artistName == nil) {
        artistName = @"Unknown";
    }
    
    self.artistNameLabel.text = artistName;
    self.kindLabel.text = [self.searchResult kindForDisplay];
    self.genreLabel.text = self.searchResult.genre;
    
    //to load image
    [self.artworkImageView setImageWithURL:[NSURL URLWithString:self.searchResult.artworkURL100]];
    
    
    //Show the price, in the proper currency.
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setCurrencyCode:self.searchResult.currency];
    
    NSString *priceText;
    if ([self.searchResult.price floatValue] == 0.0f) {
        priceText = @"Free";
    }   
    else {
        priceText = [formatter stringFromNumber:self.searchResult.price];
    }
    
    [self.priceButton setTitle:priceText forState:UIControlStateNormal];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.popupView.hidden = NO;
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}



//This only returns YES when the touch was on the background view but NO if it was inside the Popup View.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return (touch.view == self.view);
}


- (IBAction)close:(id)sender
{
    
    [self dismissFromParentViewControllerWithAnimationType:DetailViewControllerAnimationTypeSlide];

}




- (void)presentInParentViewController:(UIViewController *)parentViewController
{
    
    _gradientView = [[GradientView alloc] initWithFrame:parentViewController.view.bounds];
    [parentViewController.view addSubview:_gradientView];
    
    
    
    self.view.frame = parentViewController.view.bounds;
    [parentViewController.view addSubview:self.view];
    [parentViewController addChildViewController:self];
    [self didMoveToParentViewController:parentViewController];
    
    
    //adding Core Animation to Detailview popup, a bounce effect.
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.duration = 0.4;
    bounceAnimation.delegate = self;
    
    bounceAnimation.values = @[ @0.7, @1.2, @0.9, @1.0 ];
    bounceAnimation.keyTimes = @[ @0.0, @0.334, @0.666, @1.0 ];
    
    bounceAnimation.timingFunctions = @[[CAMediaTimingFunction
                                         functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                        [CAMediaTimingFunction
                                         functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                        [CAMediaTimingFunction
                                         functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    [self.view.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
    
    
    //to make the GradientView fade in while the pop-up bounces into view.
    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.fromValue = @0.0f;
    fadeAnimation.toValue = @1.0f;
    fadeAnimation.duration = 0.2;
    [_gradientView.layer addAnimation:fadeAnimation forKey:@"fadeAnimation"];
}



- (void)dismissFromParentViewControllerWithAnimationType: (DetailViewControllerAnimationType)animationType
{
   [self willMoveToParentViewController:nil];
    
    [UIView animateWithDuration:0.4 animations:^{
        if (animationType == DetailViewControllerAnimationTypeSlide) {
            
        CGRect rect = self.view.bounds;
        rect.origin.y += rect.size.height;
        self.view.frame = rect;
        }
        else {
            self.view.alpha = 0.0f;
        }
        _gradientView.alpha = 0.0f;
    }
     completion:^(BOOL finished) {
         [self.view removeFromSuperview];
         [self removeFromParentViewController];
         [_gradientView removeFromSuperview];
        }];
}




//animation’s delegate- By making DetailViewController the delegate of the CAKeyframeAnimation, you will be told when the animation stopped.
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self didMoveToParentViewController:self.parentViewController];
}

//Tapping the button should take the user to the selected product’s page on the iTunes store.
- (IBAction)openInStore:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.searchResult.storeURL]];
}


-(void)dealloc
{
    NSLog(@"dealloc %@", self);
    
    //to cancel the image download if the user closes the pop-up before the image has been downloaded completely.
    [self.artworkImageView cancelImageRequestOperation];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// to update the contents of the labels in DetailViewController (for ipad)
-(void)setSearchResult:(SearchResult *)newSearchResult
{
    if (_searchResult != newSearchResult) {
        _searchResult = newSearchResult;
        
        if ([self isViewLoaded]) {
            [self updateUI];
        }
    }
}


//method to show email button option in ipad
-(void)menuButtonPressed:(UIBarButtonItem *)sender
{
    if ([self.menuPopoverController isPopoverVisible]) {
        [self.menuPopoverController dismissPopoverAnimated:YES];
    }
    else {
    [self.menuPopoverController
          presentPopoverFromBarButtonItem:sender
          permittedArrowDirections:UIPopoverArrowDirectionAny
          animated:YES];
    }
}

-(UIPopoverController *)menuPopoverController
{
    if (_menuPopoverController == nil) {
        MenuViewController *menuViewController = [[MenuViewController alloc] initWithStyle:UITableViewStyleGrouped];
        
        menuViewController.detailViewController = self;
        
        _menuPopoverController = [[UIPopoverController alloc] initWithContentViewController:menuViewController];
    }
    
    return _menuPopoverController;
}

-(void)sendSupportEmail
{
    [self.menuPopoverController dismissPopoverAnimated:YES];
    
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    
    if (controller != nil) {
        [controller setSubject:NSLocalizedString(@"Support Request", @"Email subject")];
        [controller setToRecipients:@[@"ajayxsingh@gmail.com"]];
        [self presentViewController:controller animated:YES completion:nil];
        controller.mailComposeDelegate = self;
        
        controller.modalPresentationStyle = UIModalPresentationFormSheet;
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



#pragma mark - UISplitViewControllerDelegate

-(void)splitViewController:(UISplitViewController *)splitViewController
    willHideViewController:(UIViewController *)viewController
         withBarButtonItem:(UIBarButtonItem *)barButtonItem
      forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Search", @"Split-view master button");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}


-(void)splitViewController:(UISplitViewController *)splitViewController
    willShowViewController:(UIViewController *)viewController
 invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}


-(void)splitViewController:(UISplitViewController *)splitViewController
         popoverController:(UIPopoverController *)popoverController
 willPresentViewController:(UIViewController *)viewController
{
    if ([self.menuPopoverController isPopoverVisible]) {
        [self.menuPopoverController dismissPopoverAnimated:YES];
    }
}



@end












