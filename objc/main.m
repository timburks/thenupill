//
//  main.m
//
//  Copyright Neon Design Technology, Inc. 2008. All rights reserved.
//

#import "Nu.h"
extern void NuInit(void);

int main(int argc, char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NuInit();	
	id parser = [Nu parser];
	NSString *main = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"main" ofType:@"nu"]];
    [parser parseEval:main];
    int retVal = UIApplicationMain(argc, argv, nil, @"ApplicationDelegate");
    [pool release];
    return retVal;
}