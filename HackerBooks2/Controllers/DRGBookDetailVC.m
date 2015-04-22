//
//  DRGBookDetailVC.m
//  HackerBooks2
//
//  Created by David Regatos on 15/04/15.
//  Copyright (c) 2015 DRG. All rights reserved.
//

@import QuartzCore;

#import "DRGBookDetailVC.h"
#import "DRGAnnotationVC.h"
// models
#import "DRGBook.h"
#import "DRGWriter.h"
#import "DRGCover.h"
#import "DRGPdf.h"
#import "DRGAnnotation.h"
// others
#import "NotificationKeys.h"
#import "UIViewController+Navigation.h"

#define KVO_tags @"tags"

@interface DRGBookDetailVC ()

@property (nonatomic, readwrite) DRGBook *book;

@end

@implementation DRGBookDetailVC

#pragma mark - Init

- (instancetype)initWithBook:(DRGBook *)aBook {
    
    if (self = [super initWithNibName:nil bundle:nil]) {
        _book = aBook;
    }
    
    return self;
}

#pragma mark - View events

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Hacker Books 2.0";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    // cover container appearance
    self.coverContainer.layer.borderWidth = 2.;
    self.coverContainer.layer.borderColor = [UIColor darkGrayColor].CGColor;
    self.coverContainer.clipsToBounds = YES;
    self.coverImView.image = [UIImage imageNamed:@"book-placeholder.jpg"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateViewContent];
    
    // Notifications **********************
    [self registerForNotifications];
    
    // KVOs **********************
    [self registerForKVOs];   
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self unregisterForNotifications];
    [self unregisterForKVOs];
}

#pragma mark - Sync view <-> model

- (void)updateViewContent {
    
    self.tagsLbl.text = [[self.book tagListExceptFavorite] componentsJoinedByString:@", "];
    self.favoriteBtn.selected = [self.book isFavoriteBook];
    self.readBtn.selected = [self.book isPDFAvailable];

    // cover
    [self performSelector:@selector(loadCoverImage) withObject:nil afterDelay:0.3];
    
    NSLog(@"Book annotation count: %lu", [self.book.annotations count]);
}

#pragma mark - NSNotification

- (void)dealloc {
    [self unregisterForNotifications];
    [self unregisterForKVOs];
}

- (void)registerForNotifications {
    // Add your notification observer here
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notifyNewBookWasSelected:)
                                                 name:DID_SELECT_BOOK_NOTIFICATION
                                               object:nil];
}

- (void)unregisterForNotifications {
    // Clear out _all_ observations that this object was making
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// DID_SELECT_BOOK_NOTIFICATION
- (void)notifyNewBookWasSelected:(NSNotification *)notification {
    
    DRGBook *book = [notification.userInfo objectForKey:BOOK_KEY];
    self.book = book;

    [self updateViewContent];
}

#pragma mark - KVOs

- (void)setBook:(DRGBook *)book {
    
    // KVOs **********************
    [self unregisterForKVOs];  // unregister for previous book
    _book = book;
    [self registerForKVOs];    // register for new one
}

- (void)registerForKVOs {
    [self.book addObserver:self forKeyPath:KVO_tags options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)unregisterForKVOs {
    [self.book removeObserver:self forKeyPath:KVO_tags];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:KVO_tags]) {
        // Do something after observed_obj's observed_property was changed
        [self updateViewContent];
    }
}

#pragma mark - IBActions

- (IBAction)favoriteBtnPressed:(UIButton *)sender {
    
    // Talk with the delegate, if it implements the method
    if ([self.delegate respondsToSelector:@selector(bookDetailVC:didMarkBookAsFavorite:)]) {
        [self.delegate bookDetailVC:self didMarkBookAsFavorite:self.book];
    }
}

- (IBAction)readBtnPressed:(UIButton *)sender {
    
    if (!sender.selected) {
        // Download pdf file
        NSLog(@"Download PDF file");
        [self loadPDFFile];
    }
    
    // Show pdf file
}

- (IBAction)newAnnotationBtnPressed:(UIButton *)sender {
    
    DRGAnnotationVC *annVC = [[DRGAnnotationVC alloc] initAnnotationForBook:self.book];
    [self presentViewController:[annVC wrappedInNavigationController] animated:YES completion:nil];
}

- (IBAction)showAnnotationsBtnPressed:(UIButton *)sender {
    
}

#pragma mark - Utils

- (void)loadCoverImage {
    //self.coverImView.image = nil;
    if (!self.book.cover.data) {
        [self.coverActivityIndicator startAnimating];
    }
    [self.book.cover fetchCoverImageWithCompletion:^(UIImage *image) {
        UIImage *newImage = image ? image : [UIImage imageNamed:@"book-placeholder.jpg"];
        [UIView transitionWithView:self.coverImView
                          duration:0.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.coverImView.image = newImage;
                        } completion:^(BOOL finished) {
                            [self.coverActivityIndicator stopAnimating];
                        }];
    }];
}

- (void)loadPDFFile {
    [self.book.pdf fetchPDFDataWithCompletion:^(NSData *pdfData) {
        NSLog(@"PDF file is ready");
        self.readBtn.selected = [self.book isPDFAvailable];
    }];
}

#pragma mark - UISplitViewControllerDelegate

- (void)splitViewController:(UISplitViewController *)svc willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    
    // Is splitVC's table visible?
    if (displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
        self.navigationItem.leftBarButtonItem = svc.displayModeButtonItem;
        // NOTE: BarBtn item is provided by the splitVC
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

@end
