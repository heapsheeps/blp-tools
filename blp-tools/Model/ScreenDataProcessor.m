#import "ScreenDataProcessor.h"
#import "ImageUtilities.h"
#import "SettingsManager.h"
#import "NSubmissionValidator.h"
#import "TrajectoryEstimator.h"
#import "Constants.h"
#import <math.h>

NSString * const ScreenDataProcessorNewCornersNotification = @"ScreenDataProcessorNewCornersNotification";
NSString * const ScreenDataProcessorNewBallDataNotification = @"ScreenDataProcessorNewBallDataNotification";
NSString * const ScreenDataProcessorNewClubDataNotification = @"ScreenDataProcessorNewClubDataNotification";

static double toDouble(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value doubleValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        return [value doubleValue];
    }
    return 0.0;
}

static int toInt(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value intValue];
    }
    if ([value isKindOfClass:[NSString class]]) {
        return [value intValue];
    }
    return 0;
}

static NSString* validateBallData(NSDictionary *data) {
    
    //NSLog(@"Datar: %@", data);
    
    NSSet *validSpeedUnits = [NSSet setWithObjects:@"MPH", @"MPS", @"KMH", nil];
    NSSet *validCarryUnits = [NSSet setWithObjects:@"YDS", @"METERS", nil];
    NSSet *validDirection = [NSSet setWithObjects:@"L", @"R", nil];
    
    double ballSpeed = toDouble(data[@"ball-speed"]);
    NSString *ballSpeedUnits = [validSpeedUnits containsObject:data[@"ball-speed-units"]] ? data[@"ball-speed-units"] : @"";
    double vla = toDouble(data[@"vla"]);
    NSString *hlaDirection = [validDirection containsObject:data[@"hla-direction"]] ? data[@"hla-direction"] : @"";
    double carry = toDouble(data[@"carry"]);
    NSString *carryUnits = [validCarryUnits containsObject:data[@"carry-units"]] ? data[@"carry-units"] : @"";
    int totalSpin = toInt(data[@"total-spin"]);
    int spinAxis = toInt(data[@"spin-axis"]);
    NSString *spinAxisDirection = [validDirection containsObject:data[@"spin-axis-direction"]] ? data[@"spin-axis-direction"] : @"";
    
    // Top level validation logic
    if(ballSpeed == 0)
        return [NSString stringWithFormat:@"invalid: ball-speed = %@", data[@"ball-speed"]];
    if([ballSpeedUnits isEqualToString:@""])
        return [NSString stringWithFormat:@"invalid: ball-speed-units = %@", data[@"ball-speed-units"]];
    if([hlaDirection isEqualToString:@""])
        return [NSString stringWithFormat:@"invalid: hla-direction = %@", data[@"hla-direction"]];
    if([carryUnits isEqualToString:@""])
        return [NSString stringWithFormat:@"invalid: carry-units = %@", data[@"carry-units"]];
    
    if (carry == 0 && totalSpin == 0) {
        return @"putt";
    }
    
    if (carry != 0 || totalSpin != 0 || spinAxis != 0) {
        return @"shot";
    }
    
    return @"invalid: not putt or shot";
}

static NSString* validateClubData(NSDictionary *data) {
    NSSet *validSpeedUnits = [NSSet setWithObjects:@"MPH", @"MPS", @"KMH", nil];
    NSSet *validPathDirection = [NSSet setWithObjects:@"IN-OUT", @"OUT-IN", nil];
    NSSet *validAOADirection = [NSSet setWithObjects:@"UP", @"DOWN", nil];
    
    double clubSpeed = toDouble(data[@"club-speed"]);
    NSString *clubSpeedUnits = [validSpeedUnits containsObject:data[@"club-speed-units"]] ? data[@"club-speed-units"] : @"";
    double efficiency = toDouble(data[@"efficiency"]);
    NSString *pathDirection = [validPathDirection containsObject:data[@"path-direction"]] ? data[@"path-direction"] : @"";
    double path = toDouble(data[@"path"]);
    NSString *aoaDirection = [validAOADirection containsObject:data[@"aoa-direction"]] ? data[@"aoa-direction"] : @"";
    double aoa = toInt(data[@"aoa"]);
    
    // Top level validation logic
//    if (clubSpeed == 0 || [clubSpeedUnits isEqualToString:@"None"] || efficiency == 0 || [pathDirection isEqualToString:@"None"] || path == 0 || [aoaDirection isEqualToString:@"None"] || aoa == 0) {
//        return @"invalid";
//    } else {
//        return @"club";
//    }
    
    return @"club";
}

static NSDictionary* translateBallResults(NSDictionary* ballResults, bool isPutt) {
    if (!ballResults) {
        return @{}; // Return an empty dictionary if input is nil
    }

    NSMutableDictionary *processedResults = [NSMutableDictionary dictionary];

    // Data for shots and putts
    float ballSpeed = [ballResults[@"ball-speed"] floatValue];
    processedResults[@"Speed"] = @(ballSpeed);
    
    float vla = [ballResults[@"vla"] floatValue];
    processedResults[@"VLA"] = @(vla);
    
    NSString *hlaDirection = ballResults[@"hla-direction"] ?: @"";
    float hla = [ballResults[@"hla"] floatValue];
    if ([@"L" isEqualToString:hlaDirection]) {
        hla *= -1.0;
    } else if (![@"R" isEqualToString:hlaDirection]) {
        NSLog(@"Warning: Unexpected hla-direction value: '%@'", hlaDirection);
    }
    processedResults[@"HLA"] = @(hla);
    
    float carryDistance = [ballResults[@"carry"] floatValue];
    processedResults[@"CarryDistance"] = @(carryDistance);
    
    float totalSpin = [ballResults[@"total-spin"] floatValue];
    processedResults[@"TotalSpin"] = @(totalSpin);
    
    NSString *spinAxisDirection = ballResults[@"spin-axis-direction"] ?: @"";
    float spinAxis = [ballResults[@"spin-axis"] floatValue];
    if ([@"L" isEqualToString:spinAxisDirection]) {
        spinAxis *= -1.0;
    } else if (![@"R" isEqualToString:spinAxisDirection]) {
        NSLog(@"Warning: Unexpected spin-axis-direction value: '%@'", spinAxisDirection);
    }
    processedResults[@"SpinAxis"] = @(spinAxis);
    
    // Populate total distance and offline amounts
    processedResults[@"IsPutt"] = @(isPutt);
    [[TrajectoryEstimator shared] processBallData:processedResults];
    
    return [processedResults copy]; // Return an immutable dictionary
}

static NSDictionary* translateClubResults(NSDictionary* clubResults) {
    if (!clubResults) {
        return @{}; // Return an empty dictionary if input is nil
    }
    
    NSMutableDictionary *processedResults = [NSMutableDictionary dictionary];

    processedResults[@"Speed"] = @([clubResults[@"club-speed"] floatValue]);
    NSString *clubSpeedUnits = clubResults[@"club-speed-units"] ?: @"";
    //TODO: Handle MPH/KPH/MPS

    NSString *aoaDirection = clubResults[@"aoa-direction"] ?: @"";
    float aoa = [clubResults[@"aoa"] floatValue];
    if ([@"DOWN" isEqualToString:aoaDirection]) {
        aoa *= -1.0;
    } else if (![@"UP" isEqualToString:aoaDirection]) {
        NSLog(@"Warning: Unexpected aoa-direction value: '%@'", aoaDirection);
    }
    processedResults[@"AngleOfAttack"] = @(aoa);

    NSString *pathDirection = clubResults[@"path-direction"] ?: @"";
    float path = [clubResults[@"path"] floatValue];
    if ([@"IN-OUT" isEqualToString:pathDirection]) {
        path *= -1.0;
    } else if (![@"OUT-IN" isEqualToString:pathDirection]) {
        NSLog(@"Warning: Unexpected path-direction value: '%@'", pathDirection);
    }
    processedResults[@"Path"] = @(path);
    
    processedResults[@"Efficiency"] = @([clubResults[@"efficiency"] floatValue]);
    
    processedResults[@"FaceToTarget"] = @0.0;
    processedResults[@"Lie"] = @0.0;
    processedResults[@"Loft"] = @0.0;
    processedResults[@"SpeedAtImpact"] = @0.0;
    processedResults[@"VerticalFaceImpact"] = @0.0;
    processedResults[@"ClosureRate"] = @0.0;
    processedResults[@"HorizontalFaceImpact"] = @0.0;

    return [processedResults copy]; // Return an immutable dictionary
}



@interface ScreenDataProcessor ()

@property (nonatomic, assign) NSTimeInterval lastDetectionTime;
@property (nonatomic, strong) NSArray<NSValue *> *detectedCorners;
@property (nonatomic, strong) NSDictionary* lastBallData;
@property (nonatomic, strong) NSDictionary* lastClubData;

@property (nonatomic, strong) NSubmissionValidator* ballDataValidator;
@property (nonatomic, strong) NSubmissionValidator* clubDataValidator;

@end

@implementation ScreenDataProcessor

- (instancetype)init {
    self = [super init];
    if (self) {
        NSError *error = nil;
        // Load each JSON from the bundle.
        NSString *ballPath = [[NSBundle mainBundle] pathForResource:@"annotations-ball" ofType:@"json"];
        NSString *clubPath = [[NSBundle mainBundle] pathForResource:@"annotations-club" ofType:@"json"];
        NSString *screenPath = [[NSBundle mainBundle] pathForResource:@"annotations-screen" ofType:@"json"];
        
        _ballDataReader = [[ScreenReader alloc] initWithJSONFile:ballPath type:@"ball-data" error:&error];
        if (error) { NSLog(@"Error loading ballDataReader: %@", error); }
        _clubDataReader = [[ScreenReader alloc] initWithJSONFile:clubPath type:@"club-data" error:&error];
        if (error) { NSLog(@"Error loading clubDataReader: %@", error); }
        _screenSelectionReader = [[ScreenReader alloc] initWithJSONFile:screenPath type:@"screen-data" error:&error];
        if (error) { NSLog(@"Error loading screenSelectionReader: %@", error); }
        
        _lastDetectionTime = 0;
        _lastBallData = nil;
        _lastClubData = nil;
        
        _ballDataValidator = [[NSubmissionValidator alloc] initWithRequiredCount:NUM_CONSISTENCY_CHECKS];
        _clubDataValidator = [[NSubmissionValidator alloc] initWithRequiredCount:NUM_CONSISTENCY_CHECKS];
    }
    return self;
}

- (void)processScreenDataFromImage:(UIImage *)rawImage error:(NSError **)error {
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    
    // Rate-limit screen detection to once every 5 seconds.
    if (!self.detectedCorners || (currentTime - self.lastDetectionTime) >= 5.0) {
        NSArray<NSValue *> *foundCorners = [ImageUtilities detectScreenInImage:rawImage];
        if (!foundCorners || foundCorners.count != 4) {
            if (error) {
                *error = [NSError errorWithDomain:@"ScreenDataProcessorErrorDomain"
                                             code:100
                                         userInfo:@{NSLocalizedDescriptionKey: @"Screen corner detection failed"}];
            }
            return;
        }
        
        self.detectedCorners = [foundCorners copy];
        self.lastDetectionTime = currentTime;
        
        // Notify that new corners were detected
        NSDictionary *userInfo = @{@"corners": self.detectedCorners};
        [[NSNotificationCenter defaultCenter] postNotificationName:ScreenDataProcessorNewCornersNotification
                                                            object:nil
                                                          userInfo:userInfo];
    }
    
    // Warp the raw image using the detected corners.
    UIImage *warpedImage = [ImageUtilities warpPerspective:rawImage withPoints:self.detectedCorners];
    if (!warpedImage) {
        if (error) {
            *error = [NSError errorWithDomain:@"ScreenDataProcessorErrorDomain"
                                         code:101
                                     userInfo:@{NSLocalizedDescriptionKey: @"Warping image failed"}];
        }
        return;
    }
    
    // Use the screenSelectionReader to determine which screen is active.
    NSDictionary *selectionResults = [self.screenSelectionReader runOCROnImage:warpedImage error:error];
    if (*error)
        return;
    
    // Expected keys (per your design) might be "ball-screen-pattern" and "club-screen-pattern".
    NSString *ballPattern = selectionResults[@"ball-screen-pattern"] ?: @"";
    NSString *clubPattern = selectionResults[@"club-screen-pattern"] ?: @"";
    
    bool ballScreenDetected = [ballPattern isEqualToString:@"SPEED"];
    bool clubScreenDetected = [clubPattern isEqualToString:@"SPEED"];
    
    // Process with the corresponding OCR.
    NSDictionary *result = nil;
    if (ballScreenDetected && !clubScreenDetected) {
        result = [self.ballDataReader runOCROnImage:warpedImage error:error];
        if (*error)
            return;
        
        NSString* kind = validateBallData(result);
        
        if(![kind isEqualToString:@"shot"] && ![kind isEqualToString:@"putt"] ) {
            NSLog(@"Invaid shot detected: %@ \n %@", kind, result);
            return;
        }
        
        bool isPutt = [kind isEqualToString:@"putt"];
        NSDictionary* translatedResults = translateBallResults(result, isPutt);
        
        if([self.ballDataValidator validateDictionary:translatedResults]) {
            // Notify of new ball results
            NSDictionary *userInfo = @{@"image": warpedImage, @"data": translatedResults};
            [[NSNotificationCenter defaultCenter] postNotificationName:ScreenDataProcessorNewBallDataNotification
                                                                object:nil
                                                              userInfo:userInfo];
            self.lastBallData = [translatedResults copy];
        }
    } else if (!ballScreenDetected && clubScreenDetected) {
        result = [self.clubDataReader runOCROnImage:warpedImage error:error];
        if (*error)
            return;
        
        NSString* kind = validateClubData(result);
        if([kind isEqualToString:@"invalid"]) {
            NSLog(@"Invaid club data detected: %@ \n %@", kind, result);
            return;
        }
        
        NSDictionary* translatedResults = translateClubResults(result);
    
        if([self.clubDataValidator validateDictionary:translatedResults]) {
            // Notify of new club results
            NSDictionary *userInfo = @{@"image": warpedImage, @"data": translatedResults};
            [[NSNotificationCenter defaultCenter] postNotificationName:ScreenDataProcessorNewClubDataNotification
                                                                object:nil
                                                              userInfo:userInfo];
            self.lastClubData = [translatedResults copy];
        }
    } else {
        //NSLog(@"Neither screen detected");
        // Nothing to do, not a screen we are interested in
    }
}

@end
