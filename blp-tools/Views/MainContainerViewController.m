#import "MainContainerViewController.h"
#import "LaunchMonitorDataViewController.h"
#import "ImagesViewController.h"
#import "DebugViewController.h"
#import "SettingsViewController.h"
#import "Theme.h"

@interface MainContainerViewController ()
@property (nonatomic, strong) UIView *sideTabBar;
@property (nonatomic, strong) UIView *contentContainer;

@property (nonatomic, strong) NSArray<UIButton *> *tabButtons;
@property (nonatomic, strong) UIButton *dataButton;
@property (nonatomic, strong) UIButton *imagesButton;
@property (nonatomic, strong) UIButton *debugButton;
@property (nonatomic, strong) UIButton *settingsButton;

@property (nonatomic, strong) UIViewController *currentChildVC;
@property (nonatomic, assign) NSInteger selectedTabIndex;
@end

@implementation MainContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = APP_COLOR_BG;
    
    self.selectedTabIndex = -1; // none selected initially
    
    [self setupSideTabBar];
    [self setupContentContainer];
    
    // Load default page (Data tab)
    [self switchToChildViewController:[LaunchMonitorDataViewController new] tabIndex:0];
}

- (void)setupSideTabBar {
    CGFloat tabBarWidth = 100;
    self.sideTabBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tabBarWidth, self.view.bounds.size.height)];
    self.sideTabBar.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.sideTabBar.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.sideTabBar];
    
    // Create tab buttons
    self.dataButton = [self createTabButtonWithTitle:@"Data" action:@selector(tabButtonTapped:)];
    self.imagesButton = [self createTabButtonWithTitle:@"Screens" action:@selector(tabButtonTapped:)];
    self.debugButton = [self createTabButtonWithTitle:@"Camera" action:@selector(tabButtonTapped:)];
    self.settingsButton = [self createTabButtonWithTitle:@"Settings" action:@selector(tabButtonTapped:)];
    
    self.dataButton.tag = 0;
    self.imagesButton.tag = 1;
    self.debugButton.tag = 2;
    self.settingsButton.tag = 3;
    
    // Store them in an array so we can easily loop over them
    self.tabButtons = @[self.dataButton, self.imagesButton, self.debugButton, self.settingsButton];
    
    // Space them out more in a vertical stack
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:self.tabButtons];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.alignment = UIStackViewAlignmentCenter;
    // Increase spacing for a more generous layout
    stackView.spacing = 40;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.sideTabBar addSubview:stackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [stackView.centerXAnchor constraintEqualToAnchor:self.sideTabBar.centerXAnchor],
        [stackView.centerYAnchor constraintEqualToAnchor:self.sideTabBar.centerYAnchor]
    ]];
}

- (UIButton *)createTabButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    // Default is white text
    [btn setTitleColor:APP_COLOR_TEXT forState:UIControlStateNormal];
    btn.backgroundColor = [UIColor clearColor];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)setupContentContainer {
    CGFloat tabBarWidth = 100;
    self.contentContainer = [[UIView alloc] initWithFrame:CGRectMake(tabBarWidth, 0,
                                                                     self.view.bounds.size.width - tabBarWidth,
                                                                     self.view.bounds.size.height)];
    self.contentContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.contentContainer.backgroundColor = APP_COLOR_BG;
    [self.view addSubview:self.contentContainer];
}

- (void)tabButtonTapped:(UIButton *)sender {
    NSInteger tabIndex = sender.tag;
    UIViewController *newVC;
    switch (tabIndex) {
        case 0: newVC = [LaunchMonitorDataViewController new]; break;
        case 1: newVC = [ImagesViewController new]; break;
        case 2: newVC = [DebugViewController new]; break;
        case 3: newVC = [SettingsViewController new]; break;
        default: return;
    }
    [self switchToChildViewController:newVC tabIndex:tabIndex];
}

- (void)switchToChildViewController:(UIViewController *)newVC tabIndex:(NSInteger)tabIndex {
    // Remove old child
    if (self.currentChildVC) {
        [self.currentChildVC willMoveToParentViewController:nil];
        [self.currentChildVC.view removeFromSuperview];
        [self.currentChildVC removeFromParentViewController];
    }
    
    // Add new child
    self.currentChildVC = newVC;
    [self addChildViewController:newVC];
    newVC.view.frame = self.contentContainer.bounds;
    newVC.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentContainer addSubview:newVC.view];
    [newVC didMoveToParentViewController:self];
    
    // Update tab highlight
    self.selectedTabIndex = tabIndex;
    [self updateTabColors];
}

- (void)updateTabColors {
    // For each tab button, if its tag == selectedTabIndex => accent color, else white
    for (UIButton *btn in self.tabButtons) {
        if (btn.tag == self.selectedTabIndex) {
            [btn setTitleColor:APP_COLOR_ACCENT forState:UIControlStateNormal];
        } else {
            [btn setTitleColor:APP_COLOR_TEXT forState:UIControlStateNormal];
        }
    }
}

@end
