//
//  SearchViewController.m
//  StoreSearch
//
//  Created by Ajay Singh on 10/21/14.
//  Copyright (c) 2014 Ajay Singh. All rights reserved.
//

#import "SearchViewController.h"

#import "SearchResult.h"

#import "SearchResultCell.h"

#import <AFNetworking/AFNetworking.h>

#import "DetailViewController.h"




static NSString * const SearchResultCellIdentifier = @"SearchResultCell";

static NSString * const NothingFoundCellIdentifier = @"NothingFoundCell";

static NSString * const LoadingCellIdentifier = @"LoadingCell";



@interface SearchViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;



@end

@implementation SearchViewController


{
    NSMutableArray *_searchResults;
    
    BOOL _isLoading;
    
    NSOperationQueue *_queue;
}


//Intializing NSOperationQueue
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nil];
    
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}




- (void)viewDidLoad {
    [super viewDidLoad];
    
    // first row will always be visible, and when you scroll the table view the cells still go under the search bar.
    self.tableView.contentInset =  UIEdgeInsetsMake(108, 0, 0, 0);
    
    
    //nib for Search Result cell
    UINib *cellnib = [UINib nibWithNibName:SearchResultCellIdentifier bundle:nil];
    [self.tableView registerNib:cellnib forCellReuseIdentifier:SearchResultCellIdentifier];
    
    self.tableView.rowHeight = 80;
    
    
    //nib for Nothing found Cell
    cellnib = [UINib nibWithNibName:NothingFoundCellIdentifier bundle:nil];
    [self.tableView registerNib:cellnib forCellReuseIdentifier:NothingFoundCellIdentifier];
    
    
    //nib for Activity Indicator
    cellnib = [UINib nibWithNibName:LoadingCellIdentifier bundle:nil];
    [self.tableView registerNib:cellnib forCellReuseIdentifier:LoadingCellIdentifier];
    
    [self.searchBar becomeFirstResponder];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
 
}



#pragma mark - UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    
    if (_isLoading) {
        return 1;
    }
    else if (_searchResults == nil) {
        return 0;
     }
    else if ([_searchResults count] == 0) {
       return 1;
     }
   else {
        return [_searchResults count];
    }
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isLoading) {
        UITableViewCell *cell = [tableView  dequeueReusableCellWithIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
       
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)[cell viewWithTag:100];
        
        [spinner startAnimating];
        
        return cell;
    }
    
    
    else if ([_searchResults count] == 0) {
        return [tableView dequeueReusableCellWithIdentifier:NothingFoundCellIdentifier forIndexPath:indexPath];
    }
    else {
        SearchResultCell *cell = (SearchResultCell *)[tableView dequeueReusableCellWithIdentifier:SearchResultCellIdentifier forIndexPath:indexPath];
        
        SearchResult *searchResult = _searchResults[indexPath.row];
        
        [cell configureForSearchResult:searchResult];

    return cell;
    }
    
}



#pragma mark - UITableViewDelegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [self.searchBar resignFirstResponder];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DetailViewController *controller = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    
    
    // to set the properties of Detail View Controller
    SearchResult *searchResult = _searchResults[indexPath.row];
    controller.searchResult = searchResult;
    
    [controller presentInParentViewController:self];
    
    
//    //Before you add its view to the window,  resize it to the proper dimensions (e.g After you instantiate the DetailViewController it always has a view that is 568 points high, even on a 3.5-inch device.)
//    controller.view.frame = self.view.frame;
//    //Using the view controller containment APIs to embed the DetailViewController “inside” the SearchViewController.
//    [self.view addSubview:controller.view];
//    [self addChildViewController:controller];
//    [controller didMoveToParentViewController:self];
    
    
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_searchResults count] == 0 || _isLoading) {
        return nil;
    }
    else {
        return indexPath;
    }
    
}





#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self performSearch];
}



-(void)performSearch
{
    if ([self.searchBar.text length] > 0) {
    [self.searchBar resignFirstResponder];
        
        //cancelAllOperations you make sure that no old searches can ever get in the way of the new search.
        [_queue cancelAllOperations];
    
        _isLoading = YES;
        [self.tableView reloadData];
        
        _searchResults = [[NSMutableArray alloc] initWithCapacity:10];
        
        
        //To make the web service requests asynchronous, putting the networking part into a block and then place that block on a medium priority queue
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        dispatch_async(queue, ^{
            
            NSURL *url = [self urlWithSearchText:self.searchBar.text category:self.segmentedControl.selectedSegmentIndex];
            
            
            //Implementing AFNetworking Library
            
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            
            AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            
            operation.responseSerializer = [AFJSONResponseSerializer serializer];
            
            [operation setCompletionBlockWithSuccess:^
                  (AFHTTPRequestOperation *operation, id responseObject) {
                      [self parseDictionary:responseObject];
                      [_searchResults sortUsingSelector:@selector(compareName:)];
                      _isLoading = NO;
                      [self.tableView reloadData];
                 //NSLog(@"Success! %@", responseObject);
               }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error){
                      //to prevent the app from showing an error message if user cancel the searching
                     if (operation.isCancelled) {
                         return;
                     }
                     [self showNetworkError];
                     _isLoading = NO;
                     [self.tableView reloadData];
                  NSLog(@"Failure! %@", error);
                 }];
            
            [_queue addOperation:operation];
            
            
            
            
            //NSString *jsonString = [self performStoreRequestWithURL:url];
            
            //If something goes wrong, you call the showNetworkError method to show an alert box
//            if (jsonString == nil) {
//                 // putting Alert message in main tread via main queue since it will be on UI
//                dispatch_async(dispatch_get_main_queue(), ^{
//                
//                [self showNetworkError];
//                });
//                return;
//            }
//        
//            NSDictionary *dictionary = [self parseJSON:jsonString];
//            
//            //If something goes wrong, you call the showNetworkError method to show an alert box
//            if (dictionary == nil) {
//                // putting Alert message in main tread via main queue since it will be on UI
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self showNetworkError];
//                    });
//                return;
//              }
//        
//        
//            [self parseDictionary:dictionary];
            
            //for sorting
//            [_searchResults sortUsingSelector:@selector(compareName:)];
//            
//            NSLog(@"DONE!");

       
//        //Putting reload tableview in main tread via main queue since it will be in UI
//        dispatch_async(dispatch_get_main_queue(), ^{
//            _isLoading = NO;
//            [self.tableView reloadData];
        });
    }
}
    


- (NSURL *)urlWithSearchText:(NSString *)searchText category:(NSInteger)category
{
    NSString *categoryName;
    switch (category) {
            case 0: categoryName = @"";
            break;
            case 1: categoryName = @"musicTrack";
            break;
            case 2: categoryName = @"software";
            break;
            case 3: categoryName = @"ebook";
            break;
    }
    
    
    // to handle spaces in URL
    NSString *escapedSearchText = [searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSString *urlString = [NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@&limit=200&entity=%@",escapedSearchText, categoryName];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    return url;
}


//- (NSString *)performStoreRequestWithURL:(NSURL *)url
//{
//    NSError *error;
//    
//    NSString *resultString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
//    
//    if (resultString == nil) {
//        
//        NSLog(@"Download Error: %@", error);
//        
//        return nil;
//    }
//    return resultString;
//}


//- (NSDictionary *)parseJSON:(NSString *)jsonString
//{
//    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
//    
//    NSError *error;
//    
//    id resultObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//    
//
//    // to check that the object returned by NSJSONSerialization is truly an NSDictionary
//        if (![resultObject isKindOfClass:[NSDictionary class]]) {
//            
//            NSLog(@"JSON Error: Expected dictionary");
//            
//            return nil;
//        }
//    return resultObject;
//}


- (void)parseDictionary:(NSDictionary *)dictionary
{
    NSArray *array = dictionary[@"results"];
    
    if (array == nil) {
        
        NSLog(@"Expected 'results' array");
        
        return;
    }
    
    for (NSDictionary *resultDict in array) {
        
        SearchResult *searchResult;
        
        NSString *wrapperType = resultDict[@"wrapperType"];
        NSString *kind = resultDict[@"kind"];
        
        if ([wrapperType isEqualToString:@"track"]) {
            searchResult = [self parseTrack:resultDict];
        }
        else if ([wrapperType isEqualToString:@"audiobook"]) {
            searchResult = [self parseAudioBook:resultDict];
        }
        else if ([wrapperType isEqualToString:@"software"]) {
            searchResult = [self parseSoftware:resultDict];
        }
        else if ([kind isEqualToString:@"ebook"]) {
            searchResult = [self parseEBook:resultDict];
        }
        
        if (searchResult != nil) {
            [_searchResults addObject:searchResult];
        }
        
    }
}


- (SearchResult *)parseTrack:(NSDictionary *)dictionary
{
    SearchResult *searchResult = [[SearchResult alloc] init];
    
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"trackPrice"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    
    return searchResult;
}

- (SearchResult *)parseAudioBook:(NSDictionary *)dictionary
{
    SearchResult *searchResult = [[SearchResult alloc] init];
    
    searchResult.name = dictionary[@"collectionName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"collectionViewUrl"];
    searchResult.kind = @"audiobook";
    searchResult.price = dictionary[@"collectionPrice"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    
    return searchResult;
}


- (SearchResult *)parseSoftware:(NSDictionary *)dictionary
{
    SearchResult *searchResult = [[SearchResult alloc] init];
    
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"price"];
    searchResult.currency = dictionary[@"currency"];
    searchResult.genre = dictionary[@"primaryGenreName"];
    
    return searchResult;
}

- (SearchResult *)parseEBook:(NSDictionary *)dictionary
{
    SearchResult *searchResult = [[SearchResult alloc] init];
    
    searchResult.name = dictionary[@"trackName"];
    searchResult.artistName = dictionary[@"artistName"];
    searchResult.artworkURL60 = dictionary[@"artworkUrl60"];
    searchResult.artworkURL100 = dictionary[@"artworkUrl100"];
    searchResult.storeURL = dictionary[@"trackViewUrl"];
    searchResult.kind = dictionary[@"kind"];
    searchResult.price = dictionary[@"price"];
    searchResult.currency = dictionary[@"currency"];searchResult.genre = [(NSArray *)dictionary[@"genres"] componentsJoinedByString:@", "];
    
    return searchResult;
}





- (void)showNetworkError
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Whoops..."
                              message:@"There was an error reading from the iTunes Store. Please try again."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
}



-(UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    return UIBarPositionTopAttached;
}


- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
   if (_searchResults != nil) {
       [self performSearch];
    }
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
