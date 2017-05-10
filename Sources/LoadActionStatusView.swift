//
//  DisplayStateView.swift
//  StartAppsKitLoadAction
//
//  Created by Gabriel Lanata on 14/11/16.
//
//

#if os(iOS)
    
    import UIKit
    
    public struct DisplayStateViewParams {
        public var activityAnimating: Bool
        public var image: UIImage?
        public var message: String?
        public var messageColor: UIColor?
        public var buttonTitle: String?
        public var buttonColor: UIColor?
        public var buttonAction: ((_ sender: AnyObject) -> Void)?
        public init(activityAnimating: Bool = false, image: UIImage? = nil, message: String? = nil, messageColor: UIColor? = nil,
                    buttonTitle: String? = nil, buttonColor: UIColor? = nil, buttonAction: ((_ sender: AnyObject) -> Void)? = nil) {
            self.activityAnimating = activityAnimating
            self.image = image
            self.message = message
            self.messageColor = messageColor
            self.buttonTitle = buttonTitle
            self.buttonColor = buttonColor
            self.buttonAction = buttonAction
        }
        
        public struct DisplayStateViewParamsDefault {
            public var loadingParams = DisplayStateViewParams(activityAnimating: true)
            public var emptyParams   = DisplayStateViewParams(message: "No data")
            public var errorParams   = DisplayStateViewParams(message: "[Error]")
        }
        public static var defaultParams = DisplayStateViewParamsDefault()
    }
    
    open class DisplayStateView: UIView, LoadActionDelegate {
        
        open var loadingParams = DisplayStateViewParams.defaultParams.loadingParams
        open var emptyParams   = DisplayStateViewParams.defaultParams.emptyParams
        open var errorParams   = DisplayStateViewParams.defaultParams.errorParams
        
        open var activityIndicatorView = UIActivityIndicatorView()
        open var boxView   = UIView()
        open var imageView = UIImageView()
        open var textLabel = UILabel()
        open var button    = UIButton()
        
        open var imageTextConstraint: NSLayoutConstraint!
        open var buttonTextConstraint: NSLayoutConstraint!
        open var imageHeightConstraint: NSLayoutConstraint!
        open var imageWidthConstraint: NSLayoutConstraint!
        
        required public init?(coder aDecoder: NSCoder) {
            // Never initialized by storyboard
            fatalError("init(coder:) has not been implemented")
        }
        
        override public init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.clear
            boxView.backgroundColor = UIColor.clear
            
            textLabel.numberOfLines = 0
            textLabel.textAlignment = .center
            
            activityIndicatorView.activityIndicatorViewStyle = .whiteLarge
            activityIndicatorView.hidesWhenStopped = true
            let color = UITabBar.appearance().barTintColor ?? UINavigationBar.appearance().barTintColor
            activityIndicatorView.color = color ?? UIColor.black
            
            activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            boxView.translatesAutoresizingMaskIntoConstraints = false
            imageView.translatesAutoresizingMaskIntoConstraints = false
            textLabel.translatesAutoresizingMaskIntoConstraints = false
            button.translatesAutoresizingMaskIntoConstraints = false
            addSubview(activityIndicatorView)
            addSubview(boxView)
            boxView.addSubview(imageView)
            boxView.addSubview(textLabel)
            boxView.addSubview(button)
            
            // ActivityIndicator Constraints
            self.addConstraint(
                NSLayoutConstraint(
                    item: activityIndicatorView,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: self, attribute: .centerX,
                    multiplier: 1.0, constant: 0.0
                )
            )
            self.addConstraint(
                NSLayoutConstraint(
                    item: activityIndicatorView,
                    attribute: .centerY,
                    relatedBy: .equal,
                    toItem: self, attribute: .centerY,
                    multiplier: 1.0, constant: 0.0
                )
            )
            
            // BoxView Constraints
            self.addConstraint(
                NSLayoutConstraint(
                    item: boxView, attribute: .top,
                    relatedBy: .greaterThanOrEqual,
                    toItem: self, attribute: .top,
                    multiplier: 1.0, constant: 20.0
                )
            )
            self.addConstraint(
                NSLayoutConstraint(
                    item: boxView, attribute: .leading,
                    relatedBy: .greaterThanOrEqual,
                    toItem: self, attribute: .leading,
                    multiplier: 1.0, constant: 20.0
                )
            )
            self.addConstraint(
                NSLayoutConstraint(
                    item: self, attribute: .bottom,
                    relatedBy: .greaterThanOrEqual,
                    toItem: boxView, attribute: .bottom,
                    multiplier: 1.0, constant: 20.0
                )
            )
            self.addConstraint(
                NSLayoutConstraint(
                    item: self, attribute: .trailing,
                    relatedBy: .greaterThanOrEqual,
                    toItem: boxView, attribute: .trailing,
                    multiplier: 1.0, constant: 20.0
                )
            )
            self.addConstraint(
                NSLayoutConstraint(
                    item: boxView, attribute: .centerX,
                    relatedBy: .equal,
                    toItem: self, attribute: .centerX,
                    multiplier: 1.0, constant: 0.0
                )
            )
            self.addConstraint(
                NSLayoutConstraint(
                    item: boxView, attribute: .centerY,
                    relatedBy: .equal,
                    toItem: self, attribute: .centerY,
                    multiplier: 1.0, constant: 0.0
                )
            )
            
            
            // Add ImageView
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: imageView, attribute: .top,
                    relatedBy: .equal,
                    toItem: boxView, attribute: .top,
                    multiplier: 1.0, constant: 0.0
                )
            )
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: imageView, attribute: .leading,
                    relatedBy: .greaterThanOrEqual,
                    toItem: boxView, attribute: .leading,
                    multiplier: 1.0, constant: 0.0
                )
            )
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: boxView, attribute: .trailing,
                    relatedBy: .greaterThanOrEqual,
                    toItem: imageView, attribute: .trailing,
                    multiplier: 1.0, constant: 0.0
                )
            )
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: imageView, attribute: .centerX,
                    relatedBy: .equal,
                    toItem: boxView, attribute: .centerX,
                    multiplier: 1.0, constant: 0.0
                )
            )
            imageTextConstraint = NSLayoutConstraint(
                item: imageView, attribute: .bottom,
                relatedBy: .equal,
                toItem: textLabel, attribute: .top,
                multiplier: 1.0, constant: 20.0
            )
            boxView.addConstraint(imageTextConstraint)
            imageHeightConstraint = NSLayoutConstraint(
                item: imageView, attribute: .height,
                relatedBy: .equal,
                toItem: nil, attribute: .notAnAttribute,
                multiplier: 1.0, constant: 0.0
            )
            boxView.addConstraint(imageHeightConstraint)
            imageWidthConstraint = NSLayoutConstraint(
                item: imageView, attribute: .width,
                relatedBy: .equal,
                toItem: nil, attribute: .notAnAttribute,
                multiplier: 1.0, constant: 0.0
            )
            boxView.addConstraint(imageWidthConstraint)
            
            
            // Add TextLabel
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: textLabel, attribute: .leading,
                    relatedBy: .equal,
                    toItem: boxView, attribute: .leading,
                    multiplier: 1.0, constant: 0.0
                )
            )
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: boxView, attribute: .trailing,
                    relatedBy: .equal,
                    toItem: textLabel, attribute: .trailing,
                    multiplier: 1.0, constant: 0.0
                )
            )
            let textLabelTopConstraint = NSLayoutConstraint(
                item: boxView, attribute: .top,
                relatedBy: .equal,
                toItem: textLabel, attribute: .top,
                multiplier: 1.0, constant: 0.0
            )
            textLabelTopConstraint.priority = 900
            boxView.addConstraint(textLabelTopConstraint)
            let textLabelBottomConstraint = NSLayoutConstraint(
                item: boxView, attribute: .bottom,
                relatedBy: .equal,
                toItem: textLabel, attribute: .bottom,
                multiplier: 1.0, constant: 0.0
            )
            textLabelBottomConstraint.priority = 900
            boxView.addConstraint(textLabelBottomConstraint)
            
            
            // Add Button
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: boxView, attribute: .bottom,
                    relatedBy: .equal,
                    toItem: button, attribute: .bottom,
                    multiplier: 1.0, constant: 0.0
                )
            )
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: button, attribute: .leading,
                    relatedBy: .greaterThanOrEqual,
                    toItem: boxView, attribute: .leading,
                    multiplier: 1.0, constant: 0.0
                )
            )
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: boxView, attribute: .trailing,
                    relatedBy: .greaterThanOrEqual,
                    toItem: button, attribute: .trailing,
                    multiplier: 1.0, constant: 0.0
                )
            )
            boxView.addConstraint(
                NSLayoutConstraint(
                    item: button, attribute: .centerX,
                    relatedBy: .equal,
                    toItem: boxView, attribute: .centerX,
                    multiplier: 1.0, constant: 0.0
                )
            )
            buttonTextConstraint = NSLayoutConstraint(
                item: textLabel, attribute: .bottom,
                relatedBy: .equal,
                toItem: button, attribute: .top,
                multiplier: 1.0, constant: 20.0
            )
            boxView.addConstraint(buttonTextConstraint)
            
        }
        
        open func loadActionUpdated<L: LoadActionType>(loadAction: L, updatedProperties: Set<LoadActionProperties>) {
            displayState = loadAction.displayState
        }
        
        public var displayState: DisplayState = .none {
            didSet { update() }
        }
        
        open func update() {
            var params: DisplayStateViewParams?
            switch displayState {
            case .none, .loaded:
                params = nil
            case .loading:
                params = loadingParams
            case .empty:
                params = emptyParams
            case .error(let error):
                params = errorParams
                let errorMessage = error.localizedDescription
                params!.message = params!.message?.replacingOccurrences(of: "[Error]", with: errorMessage)
            }
            update(params: params)
        }
        
        open func update(params: DisplayStateViewParams?) {
            isHidden = (params == nil)
            textLabel.text = params?.message
            textLabel.textColor = params?.messageColor ?? UIColor(white: 0.0, alpha: 0.8)
            activityIndicatorView.active = params?.activityAnimating ?? false
            
            imageView.image = params?.image
            let imageSize = params?.image?.size
            imageWidthConstraint.constant = imageSize?.width ?? 0
            imageHeightConstraint.constant = imageSize?.height ?? 0
            imageTextConstraint.isActive = (params?.image != nil)
            
            button.title = (params?.buttonTitle?.clean() != nil ? "   \(params!.buttonTitle!)   " : nil)
            button.backgroundColor = params?.buttonColor ?? UIColor.gray
            button.isHidden = !(params?.buttonTitle?.clean() != nil)
            buttonTextConstraint.isActive = (params?.buttonTitle?.clean() != nil)
        }
        
    }
    
    
    private var _svak: UInt8 = 0
    
    public protocol StatusViewPresentable: class {
        var backgroundView: UIView? { set get }
    }
    
    public extension StatusViewPresentable {
        
        fileprivate func createDisplayStateView() -> DisplayStateView {
            let tempView = DisplayStateView()
            tempView.backgroundColor = UIColor.clear
            backgroundView = tempView
            return tempView
        }
        
        public var displayStateView: DisplayStateView {
            get {
                guard let statusView = objc_getAssociatedObject(self, &_svak) as? DisplayStateView else {
                    let statusView = createDisplayStateView()
                    objc_setAssociatedObject(self, &_svak, statusView, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
                    return statusView
                }
                return statusView
            }
            set {
                objc_setAssociatedObject(self, &_svak, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
        
        public var displayState: DisplayState {
            get { return displayStateView.displayState }
            set { displayStateView.displayState = newValue }
        }
        
    }
    
    extension UICollectionView: StatusViewPresentable { }
    extension UITableView: StatusViewPresentable { }
    
    // MARK: - Legacy Support
    
    public typealias LoadActionStatusView = DisplayStateView
    
    public extension StatusViewPresentable {
        
        // Legacy support
        public var loadActionStatusView: LoadActionStatusView {
            get { return displayStateView }
            set { displayStateView = newValue }
        }
        
    }
    
#endif
