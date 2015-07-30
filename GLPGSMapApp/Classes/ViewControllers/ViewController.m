//
//  ViewController.m
//  GLPGSMapApp
//
//  Created by Preety Pednekar on 7/27/15.
//  Copyright (c) 2015 Preety Pednekar. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import <math.h>
#import "Constants.h"

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (nonatomic, strong) IBOutlet MKMapView    *mapView;
@property (nonatomic, strong) IBOutlet UILabel      *speedLabel;
@property (nonatomic, strong) CLLocationManager     *locationManager;
@property (nonatomic, strong) NSTimer               *speedUpdateTimer;
@property (nonatomic, strong) CLLocation            *previousLocation;
@property (nonatomic, strong) NSDate                *trackingStartDate;
@property (nonatomic, assign) float                 totalDistance;
@property (nonatomic, assign) float                 totalTime;

@end

@implementation ViewController

@synthesize mapView;
@synthesize speedLabel;
@synthesize locationManager;
@synthesize speedUpdateTimer;
@synthesize previousLocation;
@synthesize trackingStartDate;
@synthesize totalDistance;
@synthesize totalTime;

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set map properties
    self.mapView.showsUserLocation  = YES;
    self.mapView.userTrackingMode   = MKUserTrackingModeFollow;
    self.mapView.delegate           = self;
    
    // configure location manager
    [self configureLocationManager];

    // create timer to update the speed info after every 10 seconds
    self.speedUpdateTimer = [NSTimer scheduledTimerWithTimeInterval: SPEED_UPDATE_TIMER
                                                             target: self
                                                           selector: @selector(calculateSpeedTimerFired)
                                                           userInfo: nil
                                                            repeats: YES];
}


#pragma mark - MKMapView Delegate

- (void) mapViewWillStartLocatingUser:(MKMapView *)mapView
{
    // Set tracking date as soon as the locating starts
    self.trackingStartDate = [NSDate date];
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView
{
    // When locating stops, calculate the final average speed and update the label accordingly.
    NSDate *trackingEndDate = [NSDate date];
    self.totalTime          = [trackingEndDate timeIntervalSinceDate: self.trackingStartDate];
    
    [self updateSpeedLabel];
    
    // Reset the distance and time on stopped tracking.
    self.totalDistance  = 0.0f;
    self.totalTime      = 0.0f;
}

- (void)mapView:(MKMapView *) aMapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (self.previousLocation != nil)
    {
        // If previous location is set, calculate the distance between previous and current points and show the path between them on the map.
        CLLocationCoordinate2D locationCoords[2];
        locationCoords[0] = self.previousLocation.coordinate;
        locationCoords[1] = userLocation.coordinate;
        
        // Use previous and current coordinated to draw the path on the map with red line.
        MKPolyline *path = [MKPolyline polylineWithCoordinates: locationCoords count: 2];
        [self.mapView addOverlay: path];
        
        // Calculate the distance.
        CLLocationDistance distance = [self.previousLocation distanceFromLocation: userLocation.location];
        // Uncomment this line to use the Haversine formula to calculate the distance. It is slower than the CLLocation API but more accurate when it comes to long distances
        //float distance = [self calculateDistanceInMetersBetweenPoints: self.previousLocation and: userLocation.location];

        self.totalDistance += distance;
        
#ifdef DEBUG_MODE_ON
        if (userLocation.coordinate.longitude == 139.623581 && userLocation.coordinate.latitude == 35.466046)
        {
            // reached Yokohama - Using GPX file. So stop tracking manually as with GPX file, it restarts tracking automatically.
            self.mapView.showsUserLocation = NO;
            [self.speedUpdateTimer invalidate];
        }
        else if (userLocation.coordinate.longitude == 139.77526746690273 && userLocation.coordinate.latitude == 35.698936457083526)
        {
            // reached Yodobashi camera - Using GPX file. So stop tracking manually as with GPX file, it restarts tracking automatically.
            self.mapView.showsUserLocation = NO;
            [self.speedUpdateTimer invalidate];
        }
#endif
    }
    
    // save current location in previous location variable
    self.previousLocation = userLocation.location;
}

// Show the path with overlay on map
-(MKOverlayRenderer*) mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *pathRenderer = nil;
    
    if ([overlay isKindOfClass: [MKPolyline class]])
    {
        // Set overlay attributes
        pathRenderer                = [[MKPolylineRenderer alloc] initWithPolyline: (MKPolyline *) overlay];
        pathRenderer.lineWidth      = 4.0;
        pathRenderer.strokeColor    = [UIColor redColor];
    }
    
    return pathRenderer;
}

// Show pin at particular geocoordinate
- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *identifier      = ANNOTATION_IDENTIFIER;
    MKAnnotationView *annotationView = (MKAnnotationView *)[aMapView dequeueReusableAnnotationViewWithIdentifier: identifier];
    
    if (!annotationView)
    {
        annotationView = [[MKAnnotationView alloc]  initWithAnnotation: annotation reuseIdentifier: identifier];
    }
    
    // Set custom image for the pin
    annotationView.image = [UIImage imageNamed: ANNOTATION_IMAGE];
    
    return annotationView;
}

#pragma mark - Other Methods

// Calculate speed and update the label
-(void) updateSpeedLabel
{
    float avgSpeed  = self.totalDistance / self.totalTime;
    speedLabel.text = [NSString stringWithFormat: @"%0.2f m/s", avgSpeed];
}

// Invoked on timer expired to update the speed info
-(void) calculateSpeedTimerFired
{
    self.totalTime += SPEED_UPDATE_TIMER;
    
    [self updateSpeedLabel];
}

// Configure location manager to start tracking
-(void) configureLocationManager
{
    self.locationManager            = [[CLLocationManager alloc] init];
    locationManager.delegate        = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // Call the methods - Added in iOS 8.0
    [locationManager requestWhenInUseAuthorization];
    [locationManager requestAlwaysAuthorization];
    [locationManager startUpdatingLocation];
}

// Haversine formula to calculate distance between two geocoordinates
/*-(double) calculateDistanceInMetersBetweenPoints: (CLLocation *) fromPoint and: (CLLocation *) toPoint
{
    // By Haversine formula
    
    double radiusOfEarth    = 6371.0;   // in km
    double diffLatitude     = DEGREE_TO_RADIAN((toPoint.coordinate.latitude - fromPoint.coordinate.latitude));
    double diffLongitude    = DEGREE_TO_RADIAN((toPoint.coordinate.longitude - fromPoint.coordinate.longitude));
    
    double radianFromLatitude = DEGREE_TO_RADIAN(fromPoint.coordinate.latitude);
    double radianToLatitude   = DEGREE_TO_RADIAN(toPoint.coordinate.latitude);
    
    double sqrtCalculation = (pow(sin(diffLatitude / 2), 2)) + cos(radianFromLatitude) * cos(radianToLatitude) * (pow(sin(diffLongitude / 2), 2));

    double calculatedDistance = 2 * radiusOfEarth * asin(sqrt(sqrtCalculation)); // in km
    
    return calculatedDistance * 1000; // convert to meters
}*/

#pragma mark - Memory handling

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    self.locationManager    = nil;
    self.speedUpdateTimer   = nil;
    self.previousLocation   = nil;
    self.trackingStartDate  = nil;
    
}

@end
