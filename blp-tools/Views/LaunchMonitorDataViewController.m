#import "LaunchMonitorDataViewController.h"
#import "Theme.h"
#import "ScreenDataProcessor.h"
#import "DataModel.h"
#import "MiniGameSettingsViewController.h"
#import "MiniGameEndViewController.h"


NSString *formattedStringFromInteger(NSInteger value) {
    if (value == 0) {
        return @"E";
    } else if (value > 0) {
        return [NSString stringWithFormat:@"+%ld", (long)value];
    } else {
        return [NSString stringWithFormat:@"%ld", (long)value];
    }
}

@interface LaunchMonitorDataViewController ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, UILabel *> *valueLabels;

@property (nonatomic, strong) UIButton *miniGameButton;
@property (nonatomic, strong) UIView *miniGameInfoView;

@end

@implementation LaunchMonitorDataViewController

- (NSMutableAttributedString *)attributedStringWithValue:(NSString *)value
                                                     unit:(NSString *)unit
                                                 fontSize:(CGFloat)fontSize
                                               italicized:(bool)italicized
{
    // Combine the strings
    NSString *fullString = [NSString stringWithFormat:@"%@%@", value, unit];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:fullString];
    
    // Decide on the fonts (italicized or regular)
    UIFont *valueFont;
    UIFont *unitFont;
    
    if (italicized) {
        valueFont = [UIFont italicSystemFontOfSize:fontSize];
        unitFont = [UIFont italicSystemFontOfSize:(fontSize / 2)];
    } else {
        valueFont = [UIFont systemFontOfSize:fontSize];
        unitFont = [UIFont systemFontOfSize:(fontSize / 2)];
    }
    
    // Apply the chosen fonts to the respective ranges
    NSRange valueRange = NSMakeRange(0, [value length]);
    [attributedString addAttribute:NSFontAttributeName value:valueFont range:valueRange];
    
    NSRange unitRange = NSMakeRange([value length], [unit length]);
    [attributedString addAttribute:NSFontAttributeName value:unitFont range:unitRange];
    
    return attributedString;
}

- (NSMutableAttributedString *)attributedStringWithValue:(NSString *)value
                                                     unit:(NSString *)unit
                                                 fontSize:(CGFloat)fontSize
{
    // Default "italicized" to NO
    return [self attributedStringWithValue:value unit:unit fontSize:fontSize italicized:NO];
}

- (void) addValueLabel:(NSString *) header
                     x:(int) x
                     y:(int) y
                 width:(int) width
                  view:(UIView *)view
{
    const int fontSize = 48;
    const int headerSize = fontSize/2;
    UILabel *fieldLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, headerSize)];
    fieldLabel.text = header;
    fieldLabel.font = [UIFont systemFontOfSize:headerSize];
    fieldLabel.textColor = APP_COLOR_ACCENT;
    [view addSubview:fieldLabel];

    // Value label (bigger, just under the field label)
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y+headerSize, width, fontSize)];
    valueLabel.text = @"--";
    valueLabel.font = [UIFont boldSystemFontOfSize:fontSize];
    valueLabel.textColor = [UIColor whiteColor];
    [view addSubview:valueLabel];
    
    self.valueLabels[header] = valueLabel;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = APP_COLOR_BG;

    self.valueLabels = [NSMutableDictionary dictionary];
    
    // We’ll define a fixed item width and height.
    CGFloat startY = 10;
    CGFloat cellWidth = 240;
    CGFloat y = startY;
    
    [self addValueLabel:@"VLA" x:10 y:10 width:cellWidth view:self.view];
    [self addValueLabel:@"HLA" x:10 y:110 width:cellWidth view:self.view];
    [self addValueLabel:@"Spin" x:10 y:210 width:cellWidth*2 view:self.view];
    
    [self addValueLabel:@"Apex" x:160 y:10 width:cellWidth view:self.view];
    
    [self addValueLabel:@"Carry" x:300 y:10 width:cellWidth view:self.view];
    [self addValueLabel:@"Ball" x:300 y:110 width:cellWidth view:self.view];
    [self addValueLabel:@"Club" x:300 y:210 width:cellWidth view:self.view];
    
    [self addValueLabel:@"Total" x:530 y:10 width:cellWidth view:self.view];
    [self addValueLabel:@"Path" x:530 y:110 width:cellWidth view:self.view];
    [self addValueLabel:@"AOA" x:530 y:210 width:cellWidth view:self.view];
    
    y = 295;
    
    // --- Create "Start mini game" button ---
    self.miniGameButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.miniGameButton setTitle:@"Start mini game" forState:UIControlStateNormal];
    [self.miniGameButton setTitleColor:APP_COLOR_TEXT forState:UIControlStateNormal];
    self.miniGameButton.backgroundColor = APP_COLOR_ACCENT;
    self.miniGameButton.layer.cornerRadius = 4.0;
    self.miniGameButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.miniGameButton addTarget:self action:@selector(startMiniGameTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.miniGameButton];

    // --- Create container view for mini game info row ---
    self.miniGameInfoView = [[UIView alloc] init];
    self.miniGameInfoView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.miniGameInfoView];

    // Set layout constraints for both the button and the info view.
    // They will share the same vertical position (y) so you can easily switch between them.
    [NSLayoutConstraint activateConstraints:@[
        // miniGameButton constraints:
        [self.miniGameButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:-50],
        [self.miniGameButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:y+20],
        [self.miniGameButton.widthAnchor constraintEqualToConstant:160],
        [self.miniGameButton.heightAnchor constraintEqualToConstant:50],
        
        // miniGameInfoView constraints:
        [self.miniGameInfoView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:10],
        [self.miniGameInfoView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
        [self.miniGameInfoView.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:y],
        [self.miniGameInfoView.heightAnchor constraintEqualToConstant:80]
    ]];
    
    // Create a container view for the header and add it to miniGameInfoView
    UIView *headerContainer = [[UIView alloc] init];
    headerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.miniGameInfoView addSubview:headerContainer];

    [NSLayoutConstraint activateConstraints:@[
        [headerContainer.topAnchor constraintEqualToAnchor:self.miniGameInfoView.topAnchor constant:-10],
        [headerContainer.leadingAnchor constraintEqualToAnchor:self.miniGameInfoView.leadingAnchor],
        [headerContainer.trailingAnchor constraintEqualToAnchor:self.miniGameInfoView.trailingAnchor],
        [headerContainer.heightAnchor constraintEqualToConstant:20] // Height for header container
    ]];

    // Add a thin line view to the header container
    UIView *lineView = [[UIView alloc] init];
    lineView.translatesAutoresizingMaskIntoConstraints = NO;
    lineView.backgroundColor = [UIColor whiteColor]; // Change to your desired line color
    [headerContainer addSubview:lineView];

    [NSLayoutConstraint activateConstraints:@[
        // Center vertically within headerContainer, spanning most of the width with side margins
        [lineView.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor],
        [lineView.leadingAnchor constraintEqualToAnchor:headerContainer.leadingAnchor],
        [lineView.trailingAnchor constraintEqualToAnchor:headerContainer.trailingAnchor],
        [lineView.heightAnchor constraintEqualToConstant:2] // 2 pixels tall
    ]];

    // Add a label for "Mini Game" that overlays the line view
    UILabel *headerLabel = [[UILabel alloc] init];
    headerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    headerLabel.text = @"Mini Game";
    headerLabel.font = [UIFont systemFontOfSize:12];
    headerLabel.textColor = [UIColor whiteColor];
    // Set its background to match the miniGameInfoView's background so it appears to "cut" the line
    headerLabel.backgroundColor = self.miniGameInfoView.backgroundColor;
    [headerContainer addSubview:headerLabel];

    [NSLayoutConstraint activateConstraints:@[
        [headerLabel.centerXAnchor constraintEqualToAnchor:headerContainer.centerXAnchor constant:-250],
        [headerLabel.centerYAnchor constraintEqualToAnchor:headerContainer.centerYAnchor]
    ]];
    
    [self addValueLabel:@"Target" x:10 y:5 width:cellWidth view:self.miniGameInfoView];
    [self addValueLabel:@"Last Score" x:160 y:5 width:cellWidth view:self.miniGameInfoView];
    [self addValueLabel:@"Shots Left" x:310 y:5 width:cellWidth view:self.miniGameInfoView];
    [self addValueLabel:@"Total Score" x:460 y:5 width:cellWidth view:self.miniGameInfoView];
    
    // Create the "End game" button, and add it to the same row.
    UIButton *endGameButton = [UIButton buttonWithType:UIButtonTypeSystem];
    endGameButton.frame = CGRectMake(620, 20, 100, 50); // Adjust frame as needed
    [endGameButton setTitle:@"End game" forState:UIControlStateNormal];
    [endGameButton setTitleColor:APP_COLOR_TEXT forState:UIControlStateNormal];
    endGameButton.backgroundColor = APP_COLOR_ACCENT;
    endGameButton.layer.cornerRadius = 4.0;
    [endGameButton addTarget:self action:@selector(endMiniGameTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.miniGameInfoView addSubview:endGameButton];

    // --- Set the initial visibility ---
    // For example, if no mini game exists, show the start button; otherwise show the info row.
    BOOL miniGameExists = NO; // <-- Replace with your own logic
    self.miniGameButton.hidden = miniGameExists;
    self.miniGameInfoView.hidden = !miniGameExists;

    // Set data
    [self setBallData:[DataModel shared].currentShotBallData];
    [self setClubData:[DataModel shared].currentShotClubData];
    
    // Listen for data changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewBallData:)
                                                 name:ScreenDataProcessorNewBallDataNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewClubData:)
                                                 name:ScreenDataProcessorNewClubDataNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMiniGameStatusChanged:)
                                                 name:MiniGameStatusChangedNotification
                                               object:nil];
    
    
    [self updateMiniGameData:[[DataModel shared] getMiniGameManager]];
    
    // DEBUG ONLY
    /*
    self.valueLabels[@"VLA"].attributedText = [self attributedStringWithValue:@"30.2°" unit:@"" fontSize:48];
    self.valueLabels[@"HLA"].attributedText = [self attributedStringWithValue:@"←24°" unit:@"" fontSize:48];
    self.valueLabels[@"Spin"].attributedText = [self attributedStringWithValue:@"24°→ 12789" unit:@"rpm" fontSize:40];
    
    self.valueLabels[@"Apex"].attributedText = [self attributedStringWithValue:@"81" unit:@"ft" fontSize:48 italicized:YES];
    self.valueLabels[@"Carry"].attributedText = [self attributedStringWithValue:@"299" unit:@"yd → 15" fontSize:48];
    self.valueLabels[@"Total"].attributedText = [self attributedStringWithValue:@"399" unit:@"yd ← 29" fontSize:48 italicized:YES];
    
    self.valueLabels[@"Ball"].attributedText = [self attributedStringWithValue:@"185" unit:@"mph" fontSize:48];
    self.valueLabels[@"Club"].attributedText = [self attributedStringWithValue:@"119" unit:@"mph / 1.49x" fontSize:48];
    self.valueLabels[@"Path"].attributedText = [self attributedStringWithValue:@"←17.2°" unit:@"" fontSize:48];
    self.valueLabels[@"AOA"].attributedText = [self attributedStringWithValue:@"17.2° ↑" unit:@"" fontSize:48];
    
    self.valueLabels[@"Target"].attributedText = [self attributedStringWithValue:@"129" unit:@"yd" fontSize:48];
    self.valueLabels[@"Last Score"].attributedText = [self attributedStringWithValue:@"100" unit:@"(+1)" fontSize:48];
    self.valueLabels[@"Shots Left"].attributedText = [self attributedStringWithValue:@"39" unit:@"" fontSize:48];
    self.valueLabels[@"Total Score"].attributedText = [self attributedStringWithValue:@"100" unit:@"(-13)" fontSize:48];
    
    [self showMiniGamePanel:YES];
     */
    // DEBUG ONLY
}

- (NSString*) getLeftRightArrowFromValue:(float) value {
    return value < 0 ? @"←" : @"→";
}

- (NSString*) getUpDownArrowFromValue:(float) value {
    return value < 0 ? @"↓" : @"↑";
}

- (NSString*) degreesWithLeftRightDirection:(NSString*) degreesValue {
    float degrees = [degreesValue floatValue];
    NSString* maybeLeftArrow = degrees < 0 ? @"←" : @"";
    NSString* maybeRightArrow = degrees > 0 ? @"→" : @"";
    return [NSString stringWithFormat:@"%@%@°%@", maybeLeftArrow, degreesValue, maybeRightArrow];
}

- (void)setBallData:(NSDictionary *)data {
    if(!data)
        return;
    
    bool isPutt = [data[@"IsPutt"] boolValue];
    NSString* distanceUnits = isPutt ? @"ft" : @"yd";
    
    self.valueLabels[@"VLA"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%@°", data[@"VLA"]] unit:@"" fontSize:48];
    self.valueLabels[@"HLA"].attributedText = [self attributedStringWithValue:[self degreesWithLeftRightDirection:data[@"HLA"]] unit:@"" fontSize:48];
    self.valueLabels[@"Spin"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%@ %@", [self degreesWithLeftRightDirection:data[@"SpinAxis"]], data[@"TotalSpin"]] unit:@"rpm" fontSize:40];
    
    self.valueLabels[@"Apex"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%.0f", 3.0f * [data[@"Height"] floatValue]] unit:@"ft" fontSize:48 italicized:YES];
    
    float carryOffline = [data[@"CarryOffline"] floatValue];
    self.valueLabels[@"Carry"].attributedText = [self
                                                 attributedStringWithValue:[NSString stringWithFormat:@"%.0f", [data[@"CarryDistance"] floatValue]]
                                                 unit:[NSString stringWithFormat:@"%@ %@ %.0f", distanceUnits, [self getLeftRightArrowFromValue:carryOffline], carryOffline]
                                                 fontSize:48];
    
    
    float totalOffline = [data[@"TotalOffline"] floatValue];
    self.valueLabels[@"Total"].attributedText = [self
                                                 attributedStringWithValue:[NSString stringWithFormat:@"%.0f", [data[@"TotalDistance"] floatValue]]
                                                 unit:[NSString stringWithFormat:@"%@ %@ %.0f", distanceUnits, [self getLeftRightArrowFromValue:totalOffline], totalOffline]
                                                 fontSize:48 italicized:YES];
                                                 
    self.valueLabels[@"Ball"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%@", data[@"Speed"]] unit:@"mph" fontSize:48];
    
    if([data[@"IsPutt"] boolValue] == YES) {
        self.valueLabels[@"Carry"].attributedText = [[NSAttributedString alloc] initWithString:@"--"];
        self.valueLabels[@"Apex"].attributedText = [[NSAttributedString alloc] initWithString:@"--"];
        self.valueLabels[@"Spin"].attributedText = [[NSAttributedString alloc] initWithString:@"--"];
    }
    
    // Zero out club data until we get new club data
    self.valueLabels[@"Club"].attributedText = [[NSAttributedString alloc] initWithString:@"--"];
    self.valueLabels[@"Path"].attributedText = [[NSAttributedString alloc] initWithString:@"--"];
    self.valueLabels[@"AOA"].attributedText = [[NSAttributedString alloc] initWithString:@"--"];
}

- (void)handleNewBallData:(NSNotification *)notification {
    NSDictionary *data = notification.userInfo[@"data"];
    if (!data)
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setBallData:data];
    });
}

- (void)setClubData:(NSDictionary *)data {
    if(!data)
        return;
    
    self.valueLabels[@"Club"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%@", data[@"Speed"]]
                                                                          unit:[NSString stringWithFormat:@"mph / %.2fx", [data[@"Efficiency"] floatValue]]
                                                                      fontSize:48];

    self.valueLabels[@"Path"].attributedText = [self attributedStringWithValue: [self degreesWithLeftRightDirection:data[@"Path"]] unit:@"" fontSize:48];
    
    float aoa = [data[@"AngleOfAttack"] floatValue];
    self.valueLabels[@"AOA"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%.2f° %@", fabs(aoa), [self getUpDownArrowFromValue:aoa]] unit:@"" fontSize:48];
}

- (void)handleNewClubData:(NSNotification *)notification {
    NSDictionary *data = notification.userInfo[@"data"];
    if (!data)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setClubData:data];
    });
}

- (void)startMiniGameTapped {
    // Create the modal view controller
    MiniGameSettingsViewController *settingsVC = [[MiniGameSettingsViewController alloc] init];
    settingsVC.modalPresentationStyle = UIModalPresentationFormSheet;
    // or UIModalPresentationOverFullScreen, or UIModalPresentationFullScreen, etc.
    
    // Present it
    [self presentViewController:settingsVC animated:YES completion:nil];
}


- (void)endMiniGameTapped {
    [[DataModel shared] endMiniGameEarly];
    [self updateMiniGameData:nil];
}

- (void)showMiniGamePanel:(bool)visible {
    bool miniGameExists = visible;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.miniGameButton.hidden = miniGameExists;
        self.miniGameInfoView.hidden = !miniGameExists;
    });
}

- (void)updateMiniGameData:(MiniGameManager *)miniGameManager {
    // Mini game not started or over
    if(!miniGameManager || [miniGameManager getShotsRemaining] == 0) {
        [self showMiniGamePanel:NO];
        return;
    }

    [self showMiniGamePanel:YES];

    NSInteger targetDistanceForCurrentShot = [miniGameManager getTargetDistanceForCurrentShot];
    NSInteger mostRecentShotScore = [miniGameManager getMostRecentShotScore];
    NSInteger mostRecentShotToPar = [miniGameManager getMostRecentShotToPar];
    NSInteger shotsRemaining = [miniGameManager getShotsRemaining];
    NSInteger totalScore = [miniGameManager getTotalScore];
    NSInteger totalToPar = [miniGameManager getTotalToPar];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* distanceUnits = [miniGameManager.gameType isEqualToString:@"Putting"] ? @"ft" : @"yd";
        self.valueLabels[@"Target"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%ld", targetDistanceForCurrentShot] unit:distanceUnits fontSize:48];
        self.valueLabels[@"Last Score"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%ld", mostRecentShotScore] unit:[NSString stringWithFormat:@"(%@)", formattedStringFromInteger(mostRecentShotToPar)] fontSize:48];
        self.valueLabels[@"Shots Left"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%ld", shotsRemaining] unit:@"" fontSize:48];
        self.valueLabels[@"Total Score"].attributedText = [self attributedStringWithValue:[NSString stringWithFormat:@"%ld", totalScore] unit:[NSString stringWithFormat:@"(%@)", formattedStringFromInteger(totalToPar)] fontSize:48];
    });
}

- (void)handleMiniGameStatusChanged:(NSNotification *)notification {
    MiniGameManager *miniGameManager = notification.userInfo[@"miniGameManager"];
    if (!miniGameManager)
        return;
    
    [self updateMiniGameData:miniGameManager];
    
    //Handle end of game
    if(miniGameManager && [miniGameManager getShotsRemaining] == 0) {
        NSInteger totalScore = [miniGameManager getTotalScore];
        NSInteger totalToPar = [miniGameManager getTotalToPar];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Create and configure the end-of-game modal
            MiniGameEndViewController *endVC = [[MiniGameEndViewController alloc] init];
            // Pass in the final score from the miniGameManager
            endVC.finalScoreString = [NSString stringWithFormat:@"%ld (%@)", totalScore, formattedStringFromInteger(totalToPar)];
            endVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
            
            // Present the modal view controller
            [self presentViewController:endVC animated:YES completion:nil];
        });
    }
}

@end
