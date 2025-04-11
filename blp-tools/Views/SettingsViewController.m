//
//  SettingsViewController.m
//  YourAppName
//
//  Created by Your Name on Date.
//

#import "SettingsViewController.h"
#import "Theme.h"
#import "SettingsManager.h"
#import "GSProConnector.h"
#import "DataModel.h"

@interface SettingsViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIPickerView *stimpPicker;
@property (nonatomic, strong) NSArray<NSNumber *> *stimpValues;
@property (nonatomic, assign) NSInteger selectedStimpIndex;

// New: A rounded text field for stimp (instead of placing the picker directly)
@property (nonatomic, strong) UITextField *stimpField;

@property (nonatomic, strong) UISegmentedControl *fairwayControl;
@property (nonatomic, strong) UITextField *ipField;
@property (nonatomic, strong) UILabel *connectionStateLabel;

@property (nonatomic, assign) CGRect originalFrame;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = APP_COLOR_BG;
    
    self.originalFrame = self.view.frame;
    
    // Build stimpValues: values from 5 to 15.
    NSMutableArray<NSNumber *> *values = [NSMutableArray array];
    for (NSInteger i = 5; i <= 15; i++) {
        [values addObject:@(i)];
    }
    self.stimpValues = [values copy];
    
    // Temporarily set selectedStimpIndex; the real value is loaded in viewWillAppear.
    self.selectedStimpIndex = 5; // default (e.g. stimp=10)
    
    CGFloat margin = 20;
    CGFloat labelWidth = 140;
    CGFloat fieldHeight = 30;
    CGFloat x = margin, y = margin + 20;
    
    // 5) Fairway speed
    UILabel *fairwayLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, labelWidth, fieldHeight)];
    fairwayLabel.text = @"Fairway speed:";
    fairwayLabel.textColor = APP_COLOR_TEXT;
    [self.view addSubview:fairwayLabel];
    
    self.fairwayControl = [[UISegmentedControl alloc] initWithItems:@[@"slow", @"medium", @"fast", @"links"]];
    self.fairwayControl.frame = CGRectMake(x + labelWidth + 10, y, 360, fieldHeight);
    self.fairwayControl.selectedSegmentIndex = 1;
    [self.fairwayControl addTarget:self action:@selector(fairwayControlChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.fairwayControl];
    y += fieldHeight + 20;
    
    // 1) Putting stimp label
    UILabel *stimpLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, labelWidth, fieldHeight)];
    stimpLabel.text = @"Putting stimp:";
    stimpLabel.textColor = APP_COLOR_TEXT;
    [self.view addSubview:stimpLabel];
    
    // 2) Create a UITextField for stimp (rounded style)
    self.stimpField = [[UITextField alloc] initWithFrame:CGRectMake(x + labelWidth + 10, y, 100, fieldHeight)];
    self.stimpField.borderStyle = UITextBorderStyleRoundedRect;
    self.stimpField.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.stimpField];
    
    // 3) Create the UIPickerView for stimp
    self.stimpPicker = [[UIPickerView alloc] init];
    self.stimpPicker.backgroundColor = [UIColor clearColor]; // clear or matching color
    self.stimpPicker.dataSource = self;
    self.stimpPicker.delegate = self;
    // Set the stimpField to use the picker as its inputView
    self.stimpField.inputView = self.stimpPicker;
    
    // 4) Add an accessory toolbar with a Done button for stimpField
    UIToolbar *stimpToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    stimpToolbar.barStyle = UIBarStyleBlack;
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                  target:nil
                                  action:nil];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Done"
                                   style:UIBarButtonItemStyleDone
                                   target:self
                                   action:@selector(dismissKeyboard)];
    stimpToolbar.items = @[flexSpace, doneButton];
    [stimpToolbar sizeToFit];
    self.stimpField.inputAccessoryView = stimpToolbar;
    y += fieldHeight + 20;
    
    // 6) GSPro IP label
    UILabel *ipLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, labelWidth, fieldHeight)];
    ipLabel.text = @"GSPro IP:";
    ipLabel.textColor = APP_COLOR_TEXT;
    [self.view addSubview:ipLabel];
    
    // 7) IP text field
    self.ipField = [[UITextField alloc] initWithFrame:CGRectMake(x + labelWidth + 10, y, 160, fieldHeight)];
    self.ipField.borderStyle = UITextBorderStyleRoundedRect;
    self.ipField.placeholder = @"192.168.x.x";
    self.ipField.keyboardType = UIKeyboardTypeDecimalPad;
    self.ipField.delegate = self;
    
    // Add accessory toolbar for IP field
    UIToolbar *ipToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    ipToolbar.barStyle = UIBarStyleBlack;
    UIBarButtonItem *ipFlex = [[UIBarButtonItem alloc]
                               initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                               target:nil
                               action:nil];
    UIBarButtonItem *ipDoneButton = [[UIBarButtonItem alloc]
                                     initWithTitle:@"Done"
                                     style:UIBarButtonItemStyleDone
                                     target:self
                                     action:@selector(dismissKeyboard)];
    ipToolbar.items = @[ipFlex, ipDoneButton];
    [ipToolbar sizeToFit];
    self.ipField.inputAccessoryView = ipToolbar;
    [self.view addSubview:self.ipField];
    
    // 8) Connection state label
    // Assuming self.ipField is already created and added:
    CGFloat connectionStateX = CGRectGetMaxX(self.ipField.frame) + 10; // 10 points of spacing
    self.connectionStateLabel = [[UILabel alloc] initWithFrame:CGRectMake(connectionStateX, y, 250, fieldHeight)];
//    self.connectionStateLabel.text = @""; // Text and color updated in setConnectionStateFromGsProConnector
//    self.connectionStateLabel.textColor = APP_COLOR_TEXT;
    [self.view addSubview:self.connectionStateLabel];
    y += fieldHeight + 20;
    
    // 9) Export button
//    UIButton *exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
//    [exportButton setTitle:@"Export shots" forState:UIControlStateNormal];
//    exportButton.frame = CGRectMake(x, y, 180, 40);
//    [exportButton setTitleColor:APP_COLOR_TEXT forState:UIControlStateNormal];
//    exportButton.backgroundColor = APP_COLOR_ACCENT;
//    exportButton.layer.cornerRadius = 4.0;
//    [exportButton addTarget:self action:@selector(exportButtonPressed) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:exportButton];
    y += 60;
    
    // Create the support button.
    UIButton *supportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    supportButton.translatesAutoresizingMaskIntoConstraints = NO;
    [supportButton setTitle:@"Questions & Support" forState:UIControlStateNormal];
    [supportButton setTitleColor:APP_COLOR_ACCENT forState:UIControlStateNormal];
    [supportButton addTarget:self action:@selector(supportButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:supportButton];
    
    // Create the footer label.
    UILabel *footerLabel = [[UILabel alloc] init];
    footerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    footerLabel.text = @"© 2025 Heapsheeps LLC";
    footerLabel.font = [UIFont systemFontOfSize:13.0];
    footerLabel.textColor = APP_COLOR_DARK_TEXT;
    [self.view addSubview:footerLabel];
    
    // Activate constraints pairing the anchors.
    [NSLayoutConstraint activateConstraints:@[
        // Footer label centered horizontally and 10 points above container's safe area bottom.
        [footerLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:-50],
        [footerLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        
        // Support button centered horizontally and 10 points above the footer label.
        [supportButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor constant:-50],
        [supportButton.bottomAnchor constraintEqualToAnchor:footerLabel.topAnchor constant:-10]
    ]];
    
    // Observe keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // Observe GSPro connection state notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleGSProConnectionState:)
                                                 name:GSProConnectionStateNotification
                                               object:nil];
    
    
    [self setConnectionStateFromGsProConnector:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Load settings from SettingsManager
    SettingsManager *mgr = [SettingsManager shared];
    
    // Update stimp field value
    NSInteger stimp = mgr.stimp; // e.g. 10
    NSInteger rowIndex = [self.stimpValues indexOfObject:@(stimp)];
    if (rowIndex == NSNotFound) {
        rowIndex = 5; // default stimp=10
    }
    self.selectedStimpIndex = rowIndex;
    [self.stimpPicker selectRow:rowIndex inComponent:0 animated:NO];
    self.stimpField.text = [NSString stringWithFormat:@"%@", self.stimpValues[rowIndex]];
    
    // Update fairway control
    self.fairwayControl.selectedSegmentIndex = mgr.fairwaySpeedIndex;
    
    // Update IP field
    self.ipField.text = mgr.gsProIP;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect kbFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (CGRectEqualToRect(self.view.frame, self.originalFrame)) {
        CGFloat shift = kbFrame.size.height / 2;
        self.view.frame = CGRectOffset(self.view.frame, 0, -shift);
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.view.frame = self.originalFrame;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - GSPro Connection

- (void)setConnectionStateFromGsProConnector:(NSString *)state {
    // Determine the connection string
    NSString *connectionString = (state != nil) ? state : [[GSProConnector shared] getConnectionState];
    
    // Update the label text
    self.connectionStateLabel.text = connectionString;
    
    // Set the appropriate text color based on connection state
    if ([connectionString isEqualToString:@"Connected"]) {
        self.connectionStateLabel.textColor = APP_COLOR_GREEN;
    } else if ([connectionString isEqualToString:@"Connecting"]) {
        self.connectionStateLabel.textColor = APP_COLOR_YELLOW;
    } else {
        self.connectionStateLabel.textColor = APP_COLOR_DARK_TEXT;
    }
}

- (void)handleGSProConnectionState:(NSNotification *)notification {
    NSString *connectionState = notification.userInfo[@"connectionState"];
    if (!connectionState)
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setConnectionStateFromGsProConnector:connectionState];
    });
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.ipField) {
        SettingsManager *mgr = [SettingsManager shared];
        [mgr setGSProIP:textField.text];
        [mgr saveSettings];
    }
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.stimpValues.count;
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSNumber *value = self.stimpValues[row];
    return [value stringValue];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.selectedStimpIndex = row;
    NSInteger selectedStimp = [self.stimpValues[row] integerValue];
    self.stimpField.text = [NSString stringWithFormat:@"%ld", (long)selectedStimp];
    
    SettingsManager *mgr = [SettingsManager shared];
    mgr.stimp = selectedStimp;
    [mgr saveSettings];
}

#pragma mark - Fairway Control

- (void)fairwayControlChanged:(UISegmentedControl *)sender {
    SettingsManager *mgr = [SettingsManager shared];
    mgr.fairwaySpeedIndex = sender.selectedSegmentIndex;
    [mgr saveSettings];
}

- (void)exportButtonPressed {
    [[DataModel shared] exportShots];
}

- (void)supportButtonPressed {
    NSURL *url = [NSURL URLWithString:@"https://www.heapsheeps.com"]; // TODO
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url
                                           options:@{}
                                 completionHandler:^(BOOL success) {
                NSLog(@"URL opened: %d", success);
            }
        ];
    }

}

@end
