import Foundation
import UIKit
import LNZTreeView

class CustomUITableViewCell: UITableViewCell
{
    override func layoutSubviews() {
        super.layoutSubviews();
        
        guard var imageFrame = imageView?.frame else { return }
        
        let offset = CGFloat(indentationLevel) * indentationWidth
        imageFrame.origin.x += offset
        imageView?.frame = imageFrame
    }
}




extension UIViewController {
    @objc func dismissVC() {
        if presentingViewController != nil {
            dismiss(animated: true, completion: nil)
        }
        else {
            _ = navigationController?.popViewController(animated: true)
        }
    }
}
