
#import "AppDelegate.h"
#import "MainContainerViewController.h"
#import "DataModel.h"
#import "LocalHttpServer.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // Create a window the same size as the screen.
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    // Create your ViewController (where your camera code, buttons, etc. live).
    MainContainerViewController *rootVC = [[MainContainerViewController alloc] init];
    
    // Set the root view controller of your app's window.
    self.window.rootViewController = rootVC;
    [self.window makeKeyAndVisible];
    
    // Initialize data model
    [DataModel shared];
    
    // Just for debugging
    [[LocalHttpServer shared] startServer];
    
    return YES;
}

// Optional: If you’re not using SceneDelegate, you can implement 
// the usual application lifecycle methods here if needed.

@end
