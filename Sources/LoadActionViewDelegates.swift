//
//  LoadActionViewDelegates.swift
//  Pods
//
//  Created by Gabriel Lanata on 11/30/15.
//
//

#if os(iOS)
    
    import UIKit
    import StartAppsKitExtensions
    
    extension UIActivityIndicatorView: LoadActionDelegate {
        
        public func loadActionUpdated<L: LoadActionType>(loadAction: L, updatedProperties: Set<LoadActionProperties>) {
            guard updatedProperties.contains(.status) else { return }
            switch loadAction.status {
            case .loading: self.startAnimating()
            case .ready:   self.stopAnimating()
            }
        }
        
        public var loadingStatus: LoadingStatus {
            get { return (isAnimating ? .loading : .ready) }
            set { self.active = (newValue == .loading) }
        }
        
    }
    
    extension UIRefreshControl {
        
        public convenience init(loadAction: LoadActionLoadableType) {
            self.init()
            setAction(loadAction: loadAction)
            loadAction.addDelegate(self)
        }
        
        public func setAction(loadAction: LoadActionLoadableType) {
            setAction(controlEvents: .valueChanged, loadAction: loadAction)
        }
        
        public var loadingStatus: LoadingStatus {
            get { return (isRefreshing ? .loading : .ready) }
            set { self.active = (newValue == .loading) }
        }
        
    }
    
    extension UIControl {
        
        public func setAction(controlEvents: UIControlEvents, loadAction: LoadActionLoadableType) {
            setAction(controlEvents: controlEvents) { (sender) in
                loadAction.loadNew(completion: nil)
            }
        }
        
    }
    
    extension UIControl: LoadActionDelegate {
        
        public func loadActionUpdated<L: LoadActionType>(loadAction: L, updatedProperties: Set<LoadActionProperties>) {
            guard updatedProperties.contains(.status) || updatedProperties.contains(.error) else { return }
            switch loadAction.status {
            case .loading:
                isEnabled = false
                isUserInteractionEnabled = false
                if let selfButton = self as? UIButton {
                    selfButton.activityIndicatorView?.startAnimating()
                    selfButton.tempTitle = ""
                }
                if let selfRefreshControl = self as? UIRefreshControl {
                    selfRefreshControl.active = true
                }
            case .ready:
                isEnabled = true
                isUserInteractionEnabled = true
                if let selfButton = self as? UIButton {
                    selfButton.activityIndicatorView?.stopAnimating()
                    selfButton.activityIndicatorView  = nil
                    if loadAction.error != nil {
                        selfButton.tempTitle = selfButton.errorTitle
                    } else {
                        selfButton.tempTitle = nil
                    }
                }
                if let selfRefreshControl = self as? UIRefreshControl {
                    selfRefreshControl.active = false
                }
            }
        }
        
    }

    
    private var _rcak: UInt8 = 1
    
    public extension UIScrollView {
        
        public var refreshControlCompat: UIRefreshControl? {
            get {
                if #available(iOS 10.0, *) {
                    return refreshControl
                } else {
                    return objc_getAssociatedObject(self, &_rcak) as? UIRefreshControl
                }
            }
            set {
                if #available(iOS 10.0, *) {
                    refreshControl = newValue
                } else {
                    objc_setAssociatedObject(self, &_rcak, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
                }
                if let newValue = newValue {
                    alwaysBounceVertical = true
                    addSubview(newValue)
                }
            }
        }
        
    }
    
    extension UIScrollView: LoadActionDelegate {
        
        public func loadActionUpdated<L: LoadActionType>(loadAction: L, updatedProperties: Set<LoadActionProperties>) {
            if #available(iOS 10.0, *) {
                refreshControl?.loadActionUpdated(loadAction: loadAction, updatedProperties: updatedProperties)
            } else {
                refreshControlCompat?.loadActionUpdated(loadAction: loadAction, updatedProperties: updatedProperties)
            }
            
            if let tableView = self as? UITableView {
                tableView.displayStateView.loadActionUpdated(loadAction: loadAction, updatedProperties: updatedProperties)
                tableView.separatorStyle = (loadAction.value != nil ? .singleLine : .none)
                tableView.reloadData()
            }
            if let collectionView = self as? UICollectionView {
                collectionView.displayStateView.loadActionUpdated(loadAction: loadAction, updatedProperties: updatedProperties)
                collectionView.reloadData()
            }
        }
        
    }
    
#endif
