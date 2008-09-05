;; It seems that there's no BridgeSupport for the iPhone (yet).
;; These constants are defined in the UIKit framework headers.
(global NSUTF8StringEncoding 4)
(global UIControlStateNormal 0)
(global UIControlContentHorizontalAlignmentCenter 0)
(global UIControlContentVerticalAlignmentCenter 0)
(global UIControlEventTouchUpInside (<< 1 6))
(global UITextFieldBorderStyleRounded 3)
(global UIKeyboardTypeAlphabet 1)
(global UITextAlignmentCenter 1)
(global NSTerminateNow 1)

(global NSURLRequestUseProtocolCachePolicy 0)
(global NSURLCredentialPersistenceForSession 1)
(global UIImagePickerControllerSourceTypePhotoLibrary 0)
(global UIImagePickerControllerSourceTypeCamera 1)
(global UIImagePickerControllerSourceTypeSavedPhotosAlbum 2)
(global UITextAutocorrectionTypeDefault 0)
(global UITextAutocorrectionTypeNo 1)
(global UITextAutocorrectionTypeYes 2)
(global UITableViewStylePlain 0)
(global UITableViewStyleGrouped 1)
(global UIViewAutoresizingFlexibleHeight (<< 1 4))
(global UIViewAutoresizingFlexibleWidth (<< 1 1))

(set TEXT_FIELD_FONT_SIZE 15.0)
(set BUTTON_FONT_SIZE 16.0)
(set TEXT_LABEL_FONT_SIZE 30.0)
(set TEXT_FIELD_HEIGHT_MULTIPLIER 2.0)

(set $host "169.254.84.157")

(class Handler is NSObject
     (ivars)
     (- init is
        (super init)
        (set @context (((context) "parent") "parent"))
        self)
     
     (- (void)socketConnected:(id)sock is
        (set $socket sock)
        (puts "handler connected")
        (set @data (NSMutableData data)))
     
     (- (void)socketConnectFailed:(id)sock is
        (puts "handler connect failed")
        (puts "error is #{(self error)}"))
     
     (- (void)socketBecameReadable:(id)sock is
        (set data (sock readData))
        (set string ((NSString alloc) initWithData:data encoding:NSUTF8StringEncoding))
        (puts (+ "evaluating >> " string))
        (if (/^quit/ findInString:string)
            (then (sock close))
            (else (try
                      (set code (parse string))
                      (if code
                          (then
                               (puts (+ "code is >> " (code stringValue)))
                               (set result (code evalWithContext:@context))
                               (puts (+ "result is >> " (send result stringValue)))
                               (self writeString:(send result stringValue) toSocket:sock))
                          (else
                               (self writeString:"parse error" toSocket:sock)))
                      (catch (exception)
                             (self writeString:(+ "error! " (exception description)) toSocket:sock)))))
        
        (if (eq (data length) 0)
            (sock close)))
     
     (- (void) writeString:(id) string toSocket:(id) socket is
        (@data appendData:(string dataUsingEncoding:NSUTF8StringEncoding))
        (if (socket isWritable)
            (self socketBecameWritable:socket)))
     
     (- (void)socketBecameWritable:(id)sock is
        (unless (eq (@data length) 0)
                (try
                    (set @data (NSMutableData dataWithData:(sock writeData:@data)))
                    (catch (exception)
                           (puts (exception description))
                           (sock close))))))

(class RemoteNuServer is NSObject
     (ivars) (ivar-accessors)
     
     ; When this object is the delegate of the NSApplication instance, we can get notifications about various states.
     ; Here, the NSApplication shared instance is asking if and when we should terminate. By listening for this
     ; message, we can stop the service cleanly, and then indicate to the NSApplication instance that it's all right
     ; to quit immediately.
     (- (int) applicationShouldTerminate:(id)sender is
        (if @netService (@netService stop))
        NSTerminateNow)
     
     (- initWithName:name is
        (super init)
        (set @serviceName name)
        (self startSharing)
        self)
     
     (- (void)startSharing is
        (set localIPAddress (NuSocketAddress localIPAddress))
        (unless localIPAddress
                (puts "unable to get local ip address, server not started")
                (return))
        (unless (and @netService @listeningSocket)
                (set @listeningSocket (AGSocket tcpSocket))
                (@listeningSocket setDelegate:self)
                (set @address (AGInetSocketAddress addressWithHostname:localIPAddress port:4040))
                (puts (+ "local address is " (NuSocketAddress localIPAddress)))
                ;; lazily instantiate the NSNetService object that will advertise on our behalf.
                ;; Passing in "" for the domain causes the service to be registered in the
                ;; default registration domain, which will currently always be "local"
                (set @netService ((NSNetService alloc) initWithDomain:""
                                  type:"_nuserve._tcp."
                                  name:@serviceName
                                  port:(@address port)))
                (@netService setDelegate:self))
        
        (if (and @netService @listeningSocket)
            (@listeningSocket listenOnAddress:@address)
            (@netService publish)))
     
     (- (void)socket:(id)sock acceptedChild:(id)child is
        (puts "connection received, creating handler")
        (set $child child)
        (child setDelegate:(set @h ((Handler alloc) init))))
     
     ;; This object is the delegate of its NSNetService. It should implement the NSNetServiceDelegateMethods that
     ;; are relevant for publication (see NSNetServices.h).
     (- (void)netServiceWillPublish:(id)sender is
        (puts "publishing"))
     
     (- (void)netServiceDidStop:(id)sender is
        (puts "stopping")
        ;; We'll need to release the NSNetService sending this, since we want to recreate it in sync with the socket
        ;; at the other end. Since there's only the one NSNetService in this application, we can just release it.
        (set @netService nil))
     
     (- (void)netService:(id)sender didNotPublish:(id)errorDict is
        (puts "did not publish")
        ;; Display some meaningful error message here, using the longerStatusText as the explanation.
        ;(if (eq (errorDict objectForKey:NSNetServicesErrorCode) NSNetServicesCollisionError)
        ;    (then (puts "A name collision occurred. A service is already running with that name someplace else."))
        ;    (else (puts "Some unknown error occurred.")))
        (set @listeningSocket nil)
        (set @netService nil)))

(class HelloViewController is UIViewController
     (ivars)
     (ivar-accessors)
     
     (- (void) loadView is
        (set viewFrame '(0 0 320 416))
        (set @contentView ((UIView alloc) initWithFrame:viewFrame))
        (@contentView setBackgroundColor:(UIColor yellowColor))
        (self setView:@contentView)
        
        ;; Add the image as the background view
        (set @imageView ((UIImageView alloc) initWithFrame:(@contentView bounds)))
        (@imageView setImage:(UIImage imageNamed:"Background.png"))
        (@contentView addSubview:@imageView)
        
        (set contentFrame (@contentView frame))
        
        ;; Create a button using an image as the background.
        ;; Use the desired background image's size as the button's size
        (set buttonBackground (UIImage imageNamed:"Button.png"))
        (set buttonFrame (list 0.0 0.0 ((buttonBackground size) first) ((buttonBackground size) second)))
        (set @button ((UIButton alloc) initWithFrame:buttonFrame))
        
        (@button setTitle:"Hello" forStates:UIControlStateNormal)
        (@button setFont:(UIFont boldSystemFontOfSize:BUTTON_FONT_SIZE))
        
        ;; Center the text on the button, considering the button's shadow
        (@button setContentHorizontalAlignment: UIControlContentHorizontalAlignmentCenter)
        (@button setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter)
        
        ;; Set the background image on the button
        (@button setBackgroundImage:buttonBackground forStates:UIControlStateNormal)
        (@button addTarget:self action:"hello:" forControlEvents:UIControlEventTouchUpInside)  ;; hello: is sent when the button is touched
        
        ;; Position the button centered horizontally in the contentView
        (@button setCenter: (list ((@contentView center) first) (- ((@contentView center) second) 30)))
        (@contentView addSubview:@button)
        
        ;; Create a text field to type into
        (set textFieldWidth (* (contentFrame third) 0.72))
        ;; and set the origin based on centering the view
        (set textFieldOriginX (/ (- (contentFrame third) textFieldWidth) 2.0))
        (set leftMargin 20.0)
        (set textFieldFrame (list textFieldOriginX leftMargin textFieldWidth (* TEXT_FIELD_FONT_SIZE TEXT_FIELD_HEIGHT_MULTIPLIER)))
        (set aTextField ((UITextField alloc) initWithFrame:textFieldFrame))
        (aTextField setBorderStyle: UITextFieldBorderStyleRounded)
        (aTextField setFont:(UIFont systemFontOfSize:TEXT_FIELD_FONT_SIZE))
        (aTextField setContentVerticalAlignment: UIControlContentVerticalAlignmentCenter)
        (aTextField setPlaceholder:"Your name")
        (aTextField setKeyboardType: UIKeyboardTypeAlphabet)
        (set @textField aTextField)
        (@contentView addSubview:@textField)
        
        ;; Create a label for greeting output. Dimensions are based on the input field sizing
        (set leftMargin 90.0)
        (set labelFrame (list textFieldOriginX leftMargin textFieldWidth (* TEXT_LABEL_FONT_SIZE TEXT_FIELD_HEIGHT_MULTIPLIER)))
        (set aLabel ((UILabel alloc) initWithFrame:labelFrame))
        (aLabel setFont:(UIFont systemFontOfSize:TEXT_LABEL_FONT_SIZE))
        
        ;; Create a slightly muted green color
        (aLabel setTextColor:(UIColor colorWithRed:0.22 green:0.54 blue:0.41 alpha:1.0))
        (aLabel setTextAlignment:UITextAlignmentCenter)
        (set @label aLabel)
        (@contentView addSubview:@label))
     
     ;; This method is invoked when the Hello button is touched
     (- (void)hello:(id)sender is
        (@textField resignFirstResponder)
        (set nameString (@textField text))
        (if (eq (nameString length) 0)
            (set nameString "Nubie"))
        (@label setText:(+ "Hello, " nameString "!"))))

(class ApplicationDelegate is NSObject
     (ivars)
     (ivar-accessors)
     
     (- (void)applicationDidFinishLaunching:(id)application is
        ;; Set up the window and content view
        (set screenRect ((UIScreen mainScreen) bounds))
        (set @window ((UIWindow alloc) initWithFrame:screenRect))
        (set @helloViewController ((HelloViewController alloc) init))
        (set @navigationController ((UINavigationController alloc) initWithRootViewController:@helloViewController))
        (@window setContentView:(@navigationController view))
        
        ;; start the server
        (set $server ((RemoteNuServer alloc) initWithName:"Nu Server"))
        
        ;; Show the window
        (@window makeKeyAndVisible))
     
     (- (int) _dontbother_applicationShouldTerminate:(id)sender is
        ($server applicationShouldTerminate:sender)))

(puts "Nu code loaded")




