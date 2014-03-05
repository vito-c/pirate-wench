#import "AppDelegate.h"

typedef struct
{
    int16_t unused1;      // 0 (not used)
    int16_t lineNum;      // line to select (< 0 to specify range)
    int32_t startRange;   // start of selection range (if line < 0)
    int32_t endRange;     // end of selection range (if line < 0)
    int32_t unused2;      // 0 (not used)
    int32_t theDate;      // modification date/time
    
}__attribute__((packed)) SelectionRange;

NSString *const BUNDLE_ID = @"com.googlecode.iterm2";
@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString* )filename
{
    NSAppleEventDescriptor *desc = [[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] paramDescriptorForKeyword:keyAEPosition];
    NSUInteger line = 0;
    
    NSString *lineString;
    /* This is where I parse the file name and line number from the apple event */
    if(desc != nil) {
        //NSRange range;
        NSData *data = [desc data];
        NSUInteger len = [data length];
        
        if(len == sizeof(SelectionRange)) {
            SelectionRange *sr = (SelectionRange*)[data bytes];
            
            if(sr->lineNum >= 0) {
                line = sr->lineNum + 1;
                lineString = [NSString stringWithFormat:@"+%ld", (unsigned long)line];
                //filename = [NSString stringWithFormat:@"%@ +%ld", filename, (unsigned long)line];
            }
        }

    }
    
    NSLog ( @"filename: |||%@|||", filename );
    NSLog ( @"linestring: |||%@|||", lineString );
    
    /*
    NSString *path = @"/path/to/executable";
    NSArray *args = [NSArray arrayWithObjects:..., nil];
    [[NSTask launchedTaskWithLaunchPath:path arguments:args] waitUntilExit];
    
    NSString *argsServerStrings[4];
    argsServerStrings[0] = @"--servername";
    argsServerStrings[1] = @"UNITY";
    argsServerStrings[2] = @"--remote-send";
    argsServerStrings[3] = @"";
    */
    
    NSPipe *newPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
    NSFileHandle *readHandle = [newPipe fileHandleForReading];
    NSFileHandle *errorHandle = [errPipe fileHandleForReading];
    
    
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/iTerm.app"];
    NSArray* apps = [NSRunningApplication
                     runningApplicationsWithBundleIdentifier:@"com.googlecode.iterm2"];
    [(NSRunningApplication*)[apps objectAtIndex:0]
     activateWithOptions: NSApplicationActivateAllWindows];
    
    /*
    NSTask *unixTask = [[NSTask alloc] init];
    [unixTask setStandardOutput:newPipe];
    [unixTask setStandardInput:[NSPipe pipe]];
    [unixTask setStandardError:errPipe];
    [unixTask setLaunchPath:@"/usr/local/bin/vim"];
    [unixTask setArguments: [ NSArray arrayWithObjects:
                             @"--servername",
                             @"UNITY",
                             @"--remote-silent",
                             lineString,
                             filename,
                             nil]  ];
    */
    
     NSTask *unixTask = [[NSTask alloc] init];
     [unixTask setStandardOutput:newPipe];
     [unixTask setStandardInput:[NSPipe pipe]];
     [unixTask setStandardError:errPipe];
     [unixTask setLaunchPath:@"~/.pirate-setup/pirate-wench/vim-launcher"];
     [unixTask setArguments: [ NSArray arrayWithObjects:
                              lineString,
                              filename, nil] ];
    
    [unixTask launch];
    
    NSString *stdOut = [[NSString alloc] initWithData:[readHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSString *errOut = [[NSString alloc] initWithData:[errorHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSLog(@"Dumping std out: %@", stdOut );
    NSLog(@"Dumping std err: %@", errOut );
    
    
    if( [errOut length] == 0 ){
        NSLog(@"error out is 0");
    } else {
        NSLog(@"OMG there is an error");
    }
    if( [stdOut length] == 0 ){
        NSLog(@"Standard out is 0");
    }

    
    /*
    NSTask *unixTask = [[NSTask alloc] init];
    [unixTask setStandardOutput:newPipe];
    [unixTask setStandardInput:[NSPipe pipe]];
    [unixTask setStandardError:errPipe];
    [unixTask setLaunchPath:@"/usr/local/bin/vim"];
    [unixTask setArguments: [ NSArray arrayWithObjects:
                                @"--servername",
                                @"UNITY",
                                @"--remote-send", @"", nil] ];

    [unixTask launch];
    [unixTask waitUntilExit];
    
    NSString *stdOut = [[NSString alloc] initWithData:[readHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSString *errOut = [[NSString alloc] initWithData:[errorHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    NSLog(@"Dumping std out: %@", stdOut );
    NSLog(@"Dumping std err: %@", errOut );
    
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/iTerm.app"];
    NSArray* apps = [NSRunningApplication
                     runningApplicationsWithBundleIdentifier:@"com.googlecode.iterm2"];
    [(NSRunningApplication*)[apps objectAtIndex:0]
     activateWithOptions: NSApplicationActivateAllWindows];
    
    if( [errOut length] == 0 ){
        NSLog(@"error out is 0");
    } else {
        NSLog(@"OMG there is an error");
    }
    if( [stdOut length] == 0 ){
        NSLog(@"Standard out is 0");
    }
    */
    //~/.pirate-setup/pirate-wench/vim-launcher
    
    /*
    NSString *output = [[NSTask launchedTaskWithLaunchPath:@"/usr/local/bin/vim"
                            arguments: [ NSArray arrayWithObjects:
                                    @"--servername",
                                    @"UNITY",
                                    @"--remote-send", @"", nil] ] waitUntilExit];

     */ 
    /*
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/local/bin/vim"];
    
    NSArray *arguments = [NSArray arrayWithObject:filename];
    [task setArguments:arguments];
    for (id element in arguments) {
        NSLog ( @"Arguments: %@", element );
    }
    
    [task launch];
    */
    [NSApp terminate:nil];
    
    return TRUE;
}

@end
