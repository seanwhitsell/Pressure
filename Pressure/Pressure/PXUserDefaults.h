//
// This file is part of Pressure.
//
// Pressure is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Pressure is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Pressure.  If not, see <http://www.gnu.org/licenses/>.
//
//  PXUserDefaults.h
//  Created by Ben Shanfelder on 2/4/12.
//

#import <Cocoa/Cocoa.h>

@interface PXUserDefaults : NSObject
{
	@private
}

+ (PXUserDefaults *)sharedDefaults;

// NOTE: These are KVC compliant, so you can use KVO to observe them.
@property (nonatomic, readwrite, assign) BOOL firstLaunch;
@property (nonatomic, readwrite, assign) BOOL noDevice;

@end


@interface NSApplication (PXUserDefaults)

// NOTE: This is a convenience for binding to defaults in XIBs via NSApplication.
// For example, you can bind to Application with key sharedDefaults.noDevice.
- (PXUserDefaults *)sharedDefaults;

@end
