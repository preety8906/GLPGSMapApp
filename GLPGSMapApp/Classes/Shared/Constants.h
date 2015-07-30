//
//  Constants.h
//  GLPGSMapApp
//
//  Created by Preety Pednekar on 7/27/15.
//  Copyright (c) 2015 Preety Pednekar. All rights reserved.
//

#ifndef GLPGSMapApp_Constants_h
#define GLPGSMapApp_Constants_h

// Comment this variable to run on the device.
// Uncomment to run on simulator using GPS file
#define DEBUG_MODE_ON

// Convert degree to radian
#define DEGREE_TO_RADIAN(degree) (degree * M_PI / 180.0)

// Other constants
#define SPEED_UPDATE_TIMER          10.0

// Image name
#define ANNOTATION_IMAGE            @"red-circle.png"

// Static identifier
#define ANNOTATION_IDENTIFIER       @"annotationIdentifier"

#endif
