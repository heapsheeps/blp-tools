#import "ImagesViewController.h"
#import "Theme.h"
#import "ScreenDataProcessor.h"
#import "DataModel.h"

@interface ImagesViewController ()
@property (nonatomic, strong) UIImageView *ballDataImageView;
@property (nonatomic, strong) UIImageView *clubDataImageView;
@end

@implementation ImagesViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = APP_COLOR_BG;
    
    // Initialize image views without setting their frames
    self.ballDataImageView = [[UIImageView alloc] init];
    self.ballDataImageView.backgroundColor = [UIColor blackColor];
    self.ballDataImageView.contentMode = UIViewContentModeScaleToFill;
    self.ballDataImageView.image = [DataModel shared].currentShotBallImage;
    [self.view addSubview:self.ballDataImageView];
    
    self.clubDataImageView = [[UIImageView alloc] init];
    self.clubDataImageView.backgroundColor = [UIColor blackColor];
    self.clubDataImageView.contentMode = UIViewContentModeScaleToFill;
    self.clubDataImageView.image = [DataModel shared].currentShotClubImage;
    [self.view addSubview:self.clubDataImageView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewBallData:)
                                                 name:ScreenDataProcessorNewBallDataNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewClubData:)
                                                 name:ScreenDataProcessorNewClubDataNotification
                                               object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Use safe area insets to adjust for tab bar, etc.
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat margin = 0;
    
    CGFloat availableWidth = self.view.bounds.size.width - safeInsets.left - safeInsets.right - margin * 2;
    CGFloat availableHeight = self.view.bounds.size.height - safeInsets.top - safeInsets.bottom - margin * 2;
    CGFloat leftWidth = availableWidth * 0.6;
    CGFloat rightWidth = availableWidth * 0.4;
    
    // Update frames with the adjusted dimensions
    self.ballDataImageView.frame = CGRectMake(margin + safeInsets.left, margin + safeInsets.top,
                                                leftWidth, availableHeight);
    self.clubDataImageView.frame = CGRectMake(margin + safeInsets.left + leftWidth,
                                                margin + safeInsets.top,
                                                rightWidth, availableHeight);
}

- (void)handleNewBallData:(NSNotification *)notification {
    UIImage *image = notification.userInfo[@"image"];
    if (!image)
        return;
    
    // Update UI on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        self.ballDataImageView.image = image;
        self.clubDataImageView.image = nil;
    });
}

- (void)handleNewClubData:(NSNotification *)notification {
    UIImage *image = notification.userInfo[@"image"];
    if (!image)
        return;
    
    // Update UI on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        self.clubDataImageView.image = image;
    });
}

@end
