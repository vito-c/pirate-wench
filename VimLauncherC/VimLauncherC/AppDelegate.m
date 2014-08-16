#import "AppDelegate.h"
#import "iTerm.h"  
#import <Carbon/Carbon.h>

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
    if( [lineString length] == 0 ){
        NSLog(@"no line");
        lineString = @"-1";
    }
    
    iTermITermApplication *iTerm = [SBApplication applicationWithBundleIdentifier:@"com.googlecode.iterm2"];
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/iTerm.app"];
    
    if ( [self selectSession:@"UNITY (vim)"] ) {
        if([self vimUnityRunning:@"UNITY"] ){
            //send command to go to file and linenumber through vim clientserver terminal
            [self vimOpenFile:filename line:lineString server:@"UNITY"];
        } else {
            //A different vim is currently running and vim unity is not running
            [self backgroundVimProcess];
            [NSThread sleepForTimeInterval:1];
            [self runHacks:filename line:lineString];
        }
        //TODO: edge case missing where your current vim is not vim unity and vim unity is running in the bkg
    } else if( [self selectSession:@"UNITY (bash)"] ){
        [self backgroundProcess];
        [NSThread sleepForTimeInterval:1];
        [self runHacks:filename line:lineString];
    } else {
        //launch new session
        [[iTerm currentTerminal] launchSession:@"Default Session"];
        iTerm.currentTerminal.currentSession.name = @"UNITY";
        [NSThread sleepForTimeInterval:1];
        [self runHacks:filename line:lineString];
    }
    
    [NSApp terminate:nil];
    return TRUE;
 }
- (void)writeToCurrentTerm:(NSString *)text {
     NSTask *unixTask2 = [[NSTask alloc] init];
     [unixTask2 setLaunchPath:@"/usr/bin/osascript"];
     [unixTask2 setArguments: [ NSArray arrayWithObjects:
     @"/Users/vcutten/.pirate-setup/pirate-wench/tellterm.scpt",
     text, nil] ];
     [unixTask2 launch];
}

- (void)backgroundProcess{
    NSTask *unixTask2 = [[NSTask alloc] init];
    [unixTask2 setLaunchPath:@"/usr/bin/osascript"];
    [unixTask2 setArguments: [ NSArray arrayWithObjects:
                              @"/Users/vcutten/.pirate-setup/pirate-wench/sendctrlz.scpt",
                              nil] ];
    [unixTask2 waitUntilExit];
    [unixTask2 launch];
}

- (void)backgroundVimProcess{
    NSTask *unixTask2 = [[NSTask alloc] init];
    [unixTask2 setLaunchPath:@"/usr/bin/osascript"];
    [unixTask2 setArguments: [ NSArray arrayWithObjects:
                              @"/Users/vcutten/.pirate-setup/pirate-wench/sendESCctrlz.scpt",
                              nil] ];
    [unixTask2 waitUntilExit];
    [unixTask2 launch];
}

- (BOOL)vimUnityRunning:(NSString *)serverName {
    return [self vimSendCMD:@"\"\"" server:@"UNITY"];
}

- (void)runHacks:(NSString *) filename
            line: (NSString *) lineNumber
{
    NSString *targetDir = [self getPath:filename ];
    [self writeToCurrentTerm:[NSString stringWithFormat:@"cd %@",targetDir]];
    if( [@"-1" isEqualToString:lineNumber])
        [self writeToCurrentTerm:[NSString stringWithFormat:@"/usr/local/bin/vim --servername UNITY %@",filename]];
    else
        [self writeToCurrentTerm:[NSString stringWithFormat:@"/usr/local/bin/vim --servername UNITY %@ %@",lineNumber,filename]];

}

- (BOOL)vimOpenFile: (NSString *) fileName
               line: (NSString *) lineNumber
             server: (NSString *) serverName
{
    
    NSTask *unixTask = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
//    NSFileHandle *errorHandle = [errPipe fileHandleForReading];
    [unixTask setStandardOutput:newPipe];
    [unixTask setStandardInput:[NSPipe pipe]];
    [unixTask setStandardError:errPipe];
    [unixTask setLaunchPath:@"/usr/local/bin/vim"];
    [unixTask waitUntilExit];
    if( [@"-1" isEqualToString:lineNumber]){
        [unixTask setArguments: [ NSArray arrayWithObjects:
                                 @"--servername",
                                 serverName,
                                 @"--remote-silent",
                                 fileName,
                                 nil] ];
    } else {
        [unixTask setArguments: [ NSArray arrayWithObjects:
                                 @"--servername",
                                 serverName,
                                 @"--remote-silent",
                                 lineNumber,
                                 fileName,
                                 nil] ];
    }
    [unixTask launch];
    
//    NSString *errMsg = @"E247: no registered server named \"UNITY\": Send failed.\n";
//    NSString *errOut = [[NSString alloc] initWithData:[errorHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
//    NSLog(@"Error Msg: %@", errOut);
    NSString *cmd = [NSString stringWithFormat:@"/usr/local/bin/vim --servername %@ --remote-silent %@ %@", serverName, lineNumber, fileName];
    NSLog(@"CMD: %@",cmd);
 //   if( [errMsg isEqualToString:errOut] ) return FALSE ;
    return TRUE;
}


- (BOOL)vimSendCMD: (NSString *) command
            server: (NSString *) serverName
{
    NSTask *unixTask = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
    NSFileHandle *errorHandle = [errPipe fileHandleForReading];
    
    [unixTask setStandardOutput:newPipe];
    [unixTask setStandardInput:[NSPipe pipe]];
    [unixTask setStandardError:errPipe];
    [unixTask setLaunchPath:@"/usr/local/bin/vim"];
    [unixTask waitUntilExit];
    [unixTask setArguments: [ NSArray arrayWithObjects:
                             @"--servername",
                             serverName,
                             @"--remote-send",
                             command, nil] ];
    [unixTask launch];
    
    NSString *errMsg = [NSString stringWithFormat:@"E247: no registered server named \"%@\": Send failed.\n", serverName ];
    NSString *errOut = [[NSString alloc] initWithData:[errorHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    if( [errMsg isEqualToString:errOut] ) return FALSE ;
    return TRUE;
}

- (BOOL)vimSendArgsCMD: (NSArray *) commands
                server: (NSString *) serverName
{
    NSTask *unixTask = [[NSTask alloc] init];
    NSPipe *newPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
//    NSFileHandle *errorHandle = [errPipe fileHandleForReading];
    
    [unixTask setStandardOutput:newPipe];
    [unixTask setStandardInput:[NSPipe pipe]];
    [unixTask setStandardError:errPipe];
    [unixTask setLaunchPath:@"/usr/local/bin/vim"];
    [unixTask waitUntilExit];
    [unixTask setArguments: commands ];
    [unixTask launch];
  //  NSString *errMsg = [NSString stringWithFormat:@"E247: no registered server named \"%@\": Send failed.\n", serverName ];
//    NSString *errOut = [[NSString alloc] initWithData:[errorHandle readDataToEndOfFile] encoding:NSUTF8StringEncoding];
 //   if( [errMsg isEqualToString:errOut] ) return FALSE ;
    return TRUE;
}


- (BOOL)selectSession:(NSString *)name {
    BOOL foundSession = FALSE;
    iTermITermApplication *iTerm = [SBApplication applicationWithBundleIdentifier:@"com.googlecode.iterm2"];
    [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/iTerm.app"];
    for (iTermTerminal *iterminal in iTerm.terminals ){
        for ( iTermSession *tsession in iterminal.sessions ){
            NSLog(@"session: %@", tsession.name);
            if([tsession.name isEqualToString: name] ){
                [iterminal select];
                [tsession select];
                foundSession = TRUE;
                break;
            }
        }
        if( foundSession ) break;
    }
    return foundSession;
}

- (NSString*)getPath:(NSString *) sPath {
    
    BOOL isDir;
    
    [[NSFileManager defaultManager] fileExistsAtPath:sPath isDirectory:&isDir];
    
    if(!isDir)
    {
        sPath = sPath.stringByDeletingLastPathComponent;
    }
    BOOL runwhile = TRUE;
    while (runwhile && ![sPath isEqualToString: NSHomeDirectory()] && ![sPath isEqualToString:@"/"] ) {
        NSArray *contentOfDirectory=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:sPath error:NULL];

        for ( NSString *fname in contentOfDirectory ){
            if( [@"sln" isEqualToString:[fname pathExtension] ] ){
                return sPath;
            }
        }
        sPath = sPath.stringByDeletingLastPathComponent;
        
    }
    return NSHomeDirectory();
}
@end
