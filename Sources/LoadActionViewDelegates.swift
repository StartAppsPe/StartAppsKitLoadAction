//
//  LoadActionViewDelegates.swift
//  Pods
//
//  Created by Gabriel Lanata on 11/30/15.
//
//

#if os(iOS)
    
    import UIKit
    
    extension UIActivityIndicatorView: LoadActionDelegate {
        
        public func loadActionUpdated<L: LoadActionType>(loadAction: L, updatedProperties: Set<LoadActionProperties>) {
            guard updatedProperties.contains(.status) else { return }
            switch loadAction.status {
            case .loading: self.startAnimating()
            case .ready:   self.stopAnimating()
            }
        }
        
    }
    
    extension UIButton: LoadActionDelegate {
        
        public func loadActionUpdated<L: LoadActionType>(loadAction: L, updatedProperties: Set<LoadActionProperties>) {
            guard updatedProperties.contains(.status) || updatedProperties.contains(.error) else { return }
            switch loadAction.status {
            case .loading:
                activityIndicatorView?.startAnimating()
                isUserInteractionEnabled = false
                tempTitle = ""
            case .ready:
                activityIndicatorView?.stopAnimating()
                activityIndicatorView  = nil
                isUserInteractionEnabled = true
                if loadAction.error != nil {
                    tempTitle = errorTitle ?? "Error"
                } else {
                    tempTitle = nil
                }
            }
        }
        
    }
    
    extension UIRefreshControl: LoadActionDelegate {
        
        public func loadActionUpdated<L: LoadActionType>(loadAction: L, updatedProperties: Set<LoadActionProperties>) {
            guard updatedProperties.contains(.status) else { return }
            switch loadAction.status {
            case .loading: active = true
            case .ready:   active = false
            }
        }
        
        public convenience init(loadAction: LoadActionLoadableType) {
            self.init()
            setAction(loadAction: loadAction)
            loadAction.addDelegate(self)
        }
        
        public func setAction(loadAction: LoadActionLoadableType) {
            setAction(controlEvents: .valueChanged, loadAction: loadAction)
        }
        
    }
    
    extension UIControl {
        
        public func setAction(controlEvents: UIControlEvents, loadAction: LoadActionLoadableType) {
            setAction(controlEvents: controlEvents) { (sender) in
                loadAction.loadNew()
            }
        }
        
    }
    
    
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
                tableView.loadActionStatusView.loadActionUpdated(loadAction: loadAction, updatedProperties: updatedProperties)
                tableView.separatorStyle = (loadAction.value != nil ? .singleLine : .none)
                tableView.reloadData()
            }
            if let collectionView = self as? UICollectionView {
                collectionView.loadActionStatusView.loadActionUpdated(loadAction: loadAction, updatedProperties: updatedProperties)
                collectionView.reloadData()
            }
        }
        
    }
    
#endif
