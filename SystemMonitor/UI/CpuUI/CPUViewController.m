//
//  CPUViewController.m
//  System Monitor
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Arvydas Sidorenko
//

#import <GLKit/GLKit.h>
#import "GLLineGraph.h"
#import "AMUtils.h"
#import "AppDelegate.h"
#import "CPUInfoController.h"
#import "CPUViewController.h"

@interface CPUViewController() <CPUInfoControllerDelegate>
@property (strong, nonatomic) GLKView       *cpuUsageGLView;
@property (strong, nonatomic) GLLineGraph   *glGraph;

@property (weak, nonatomic) IBOutlet UILabel *cpuNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *architectureLabel;
@property (weak, nonatomic) IBOutlet UILabel *physicalCoresLabel;
@property (weak, nonatomic) IBOutlet UILabel *logicalCoresLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxLogicalCoresLabel;
@property (weak, nonatomic) IBOutlet UILabel *frequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *l1iCacheLabel;
@property (weak, nonatomic) IBOutlet UILabel *l1dCacheLabel;
@property (weak, nonatomic) IBOutlet UILabel *l2CacheLabel;
@property (weak, nonatomic) IBOutlet UILabel *endianessLabel;
@end

@implementation CPUViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ViewBackground-1496"]]];
    
    AppDelegate *app = [AppDelegate sharedDelegate];
    
    [self.cpuNameLabel setText:app.iDevice.cpuInfo.cpuName];
    [self.architectureLabel setText:app.iDevice.cpuInfo.cpuSubtype];
    [self.physicalCoresLabel setText:[NSString stringWithFormat:@"%lu", (unsigned long)app.iDevice.cpuInfo.physicalCPUCount]];
    [self.logicalCoresLabel setText:[NSString stringWithFormat:@"%lu", (unsigned long)app.iDevice.cpuInfo.logicalCPUCount]];
    [self.maxLogicalCoresLabel setText:[NSString stringWithFormat:@"%lu", (unsigned long)app.iDevice.cpuInfo.logicalCPUMaxCount]];
    [self.frequencyLabel setText:[NSString stringWithFormat:@"%lu MHz", (unsigned long)app.iDevice.cpuInfo.cpuFrequency]];
    [self.l1iCacheLabel setText:(app.iDevice.cpuInfo.l1ICache == 0 ? @"-" : [AMUtils toNearestMetric:(uint64_t)app.iDevice.cpuInfo.l1ICache desiredFraction:0])];
    [self.l1dCacheLabel setText:(app.iDevice.cpuInfo.l1DCache == 0 ? @"-" : [AMUtils toNearestMetric:(uint64_t)app.iDevice.cpuInfo.l1DCache desiredFraction:0])];
    [self.l2CacheLabel setText:(app.iDevice.cpuInfo.l2Cache == 0 ? @"-" : [AMUtils toNearestMetric:(uint64_t)app.iDevice.cpuInfo.l2Cache desiredFraction:0])];
    [self.endianessLabel setText:app.iDevice.cpuInfo.endianess];
    
    self.cpuUsageGLView = [[GLKView alloc] initWithFrame:CGRectMake(0.0f, 30.0f, app.deviceSpecificUI.GLdataLineGraphWidth, 200.0f)];
    self.cpuUsageGLView.opaque = NO;
    self.cpuUsageGLView.backgroundColor = [UIColor clearColor];
    
    self.glGraph = [[GLLineGraph alloc] initWithGLKView:self.cpuUsageGLView
                                          dataLineCount:1
                                              fromValue:0.0f toValue:100.0f
                                                topLegend:@"100%"];
    [self.glGraph setDataLineLegendPostfix:@"%"];
    self.glGraph.preferredFramesPerSecond = kCpuLoadUpdateFrequency;
    
    [app.cpuInfoCtrl setCPULoadHistorySize:[self.glGraph requiredElementToFillGraph]];
}

- (void)viewWillAppear:(BOOL)animated
{
    AppDelegate *app = [AppDelegate sharedDelegate];
    NSArray *cpuLoadArray = [app.cpuInfoCtrl cpuLoadHistory];
    NSMutableArray *graphData = [NSMutableArray arrayWithCapacity:cpuLoadArray.count];
    CGFloat avr;
    
    for (NSUInteger i = 0; i < cpuLoadArray.count; ++i)
    {
        NSArray *data = [cpuLoadArray objectAtIndex:i];
        avr = 0;
        
        for (NSUInteger j = 0; j < data.count; ++j)
        {
            CPULoad *load = [data objectAtIndex:j];
            avr += load.total;
        }
        avr /= data.count;
        
        [graphData addObject:[NSArray arrayWithObject:[NSNumber numberWithDouble:(double)avr]]];
    }
    
    [self.glGraph resetDataArray:graphData];
    app.cpuInfoCtrl.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppDelegate *app = [AppDelegate sharedDelegate];
    app.cpuInfoCtrl.delegate = nil;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 240.0f;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LineGraphBackground-414"]];
    CGRect frame = backgroundView.frame;
    frame.origin.y = 20;
    backgroundView.frame = frame;
    UIView *view = [[UIView alloc] initWithFrame:self.cpuUsageGLView.frame];
    [view addSubview:backgroundView];
    [view sendSubviewToBack:backgroundView];
    [view addSubview:self.cpuUsageGLView];
    return view;
}

#pragma mark - CPUInfoController delegate

- (void)cpuLoadUpdated:(NSArray *)loadArray
{
    CGFloat avr = 0;
    
    for (CPULoad *load in loadArray)
    {
        avr += load.total;
    }
    avr /= loadArray.count;
    
    NSNumber *number = [NSNumber numberWithFloat:avr];
    [self.glGraph addDataValue:[NSArray arrayWithObject:number]];
}

@end