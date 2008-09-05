(class NuDrawPlugin is NSObject
     (ivars) (ivar-accessors)
     
     (+ (id) plugin is ((self alloc) init))
     
     (- (id) init is
        (super init)
        self)
     
     (- (void) willRegister:(id)pluginManager is
        (pluginManager addBitmapTool:self))
     
     (- (void) didRegister is nil)
     
     (- (id) worksOnShapeLayers:(id) userObject is NO)
     
     (- (id) toolName is "NuDraw")
     
     (- (id) bezierCircleAroundPoint:(NSPoint) p radius:(float) radius is
        (NSBezierPath bezierPathWithOvalInRect:
             (list (- (p first) radius)
                   (- (p second) radius)
                   (* 2 radius)
                   (* 2 radius))))
     
     ;(- (id) toolCursorAtScale:(float) scale is nil)
     
     ;(- (id) toolPaletteView is nil)
     
     (- (void) mouseDown:(id) event onCanvas:(id) canvas toLayer:(id) layer is
        (puts "mouse down #{(event description)}")
        
        )
     )
