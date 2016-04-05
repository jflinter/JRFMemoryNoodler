//
//  JRFPathUtilities.m
//  JRFMemoryNoodler
//
//  Created by Wendy Lu on 4/5/16.
//  Copyright © 2016 jflinter. All rights reserved.
//

#import "JRFPathUtilities.h"

@implementation JRFPathUtilities


+ (const char *)intentionalQuitPathname
{
    NSString *appSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    if (![[NSFileManager defaultManager] fileExistsAtPath:appSupportDirectory isDirectory:NULL]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:appSupportDirectory withIntermediateDirectories:YES attributes:nil error:nil]) {
            return 0;
        }
    }
    NSString *fileName = [appSupportDirectory stringByAppendingPathComponent:@"intentionalquit"];
    return [fileName UTF8String];
}

@end
