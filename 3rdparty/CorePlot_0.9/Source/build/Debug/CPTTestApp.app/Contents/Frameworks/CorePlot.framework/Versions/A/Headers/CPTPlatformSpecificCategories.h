#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import "CPTLayer.h"
#import "CPTColor.h"
#import "CPTPlatformSpecificDefines.h"

/**	@category CPTLayer(CPTPlatformSpecificLayerExtensions)
 *	@brief Platform-specific extensions to CPTLayer.
 **/
@interface CPTLayer(CPTPlatformSpecificLayerExtensions)

/// @name Images
/// @{
-(CPTNativeImage *)imageOfLayer;
///	@}

@end

/**	@category CPTColor(CPTPlatformSpecificColorExtensions)
 *	@brief Platform-specific extensions to CPTColor.
 **/
@interface CPTColor(CPTPlatformSpecificColorExtensions)

@property (nonatomic, readonly, retain) NSColor *nsColor;

@end
