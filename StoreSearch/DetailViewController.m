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

@interface DetailViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView *popupView;

@property (nonatomic, weak) IBOutlet UIImageView *artworkImageView;

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, weak) IBOutlet UILabel *artistNameLabel;

@property (nonatomic, weak) IBOutlet UILabel *kindLabel;

@property (nonatomic, weak) IBOutlet UILabel *genreLabel;

@property (nonatomic, weak) IBOutlet UIButton *priceButton;



@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //stretchable image for Button
    UIImage *image = [[UIImage imageNamed:@"PriceButton"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
    
    //set the “always template” rendering mode on an image, UIKit will remove the original colors from the image and paint the whole thing in the tint color.
    image = [image imageWithRenderingMode: UIImageRenderingModeAlwaysTemplate];
    
    [self.priceButton setBackgroundImage:image forState:UIControlStateNormal];
    
    //can change the tint color on a per-view basis, and if that view has subviews then the new tint color also applies to these subviews
    self.view.tintColor = [UIColor colorWithRed:20/255.0f green:160/255.0f blue:160/255.0f alpha:1.0f];
    
    //to make pop-up view rounded corners
    self.popupView.layer.cornerRadius = 10.0f;
    
    
    //adding Tap gesture recognizer
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:gestureRecognizer];
    
    
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
    
    
   
    
}


//This only returns YES when the touch was on the background view but NO if it was inside the Popup View.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return (touch.view == self.view);
}


- (IBAction)close:(id)sender
{
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];

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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
