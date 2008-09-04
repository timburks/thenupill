#import <CoreLocation/CoreLocation.h>

@interface Locator : NSObject<CLLocationManagerDelegate>
{
    CLLocation *location;
    CLLocationManager *locationManager;
}

@end

@implementation Locator

- (id) init
{
    [super init];
    location = nil;
    locationManager = nil;
    return self;
}

- (void) locate
{
    // Create the location manager if this object does not
    // already have one.
    if (nil == locationManager)
        locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = 1;           // 1 meter
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
    [newLocation retain];
    [location release];
    location = newLocation;
    // Disable future updates to save power.
    [manager stopUpdatingLocation];
}

- (id) latitude
{
    if (location)
        return [NSNumber numberWithFloat:location.coordinate.latitude];
    else
        return [NSNumber numberWithFloat:0.0];
}

- (id) longitude
{
    if (location)
        return [NSNumber numberWithFloat:location.coordinate.longitude];
    else
        return [NSNumber numberWithFloat:0.0];
}

- (id) location
{
	Class NuCell = NSClassFromString(@"NuCell");
	id result = [[[NuCell alloc] init] autorelease];
	[result setCar:[self latitude]];
	[result setCdr:[[[NuCell alloc] init] autorelease]];
	[[result cdr] setCar:[self longitude]];
	return result;
}

@end

