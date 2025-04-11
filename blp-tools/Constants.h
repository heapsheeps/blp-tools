// Use this flag to save data out for training models and debugging issues
#define SAVE_DEBUG_DATA 0 // Set to 1 to enable, 0 to disable

#if SAVE_DEBUG_DATA
    #define DEBUG_SAVE_SHOT_DATA(image, data, shotNumber) \
        [self DEBUG_saveShotImage:(image) withData:(data) andShotNumber:(shotNumber)]
#else
    #define DEBUG_SAVE_SHOT_IMAGE(image, data, shotNumber)
#endif

// Number of same detections required in a row to count as a successful/correct result
#define NUM_CONSISTENCY_CHECKS 3

// Time to wait between running OCR on the camera stream
#define OCR_RATE_SECONDS 0.050
