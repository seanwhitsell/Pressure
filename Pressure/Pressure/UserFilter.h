//
//  UserFilter.h
//  Pressure
//
//  Created by Sean Whitsell on 3/19/12.
//  Copyright (c) 2012 Cisco Systems, Inc. All rights reserved.
//

#ifndef Pressure_UserFilter_h
#define Pressure_UserFilter_h

typedef enum _userFilter {
    userAOnly,
    userBOnly,
    userAandB
} UserFilter;

extern NSString * const UserFilterDidChangeNotification;

#endif
