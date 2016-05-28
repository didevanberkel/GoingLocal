//
//  MaterialTextField.swift
//  going-local
//
//  Created by Dide van Berkel on 04-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit

class MaterialTextField: UITextField {

    override func awakeFromNib() {
        layer.cornerRadius = 3.0
        layer.borderColor = UIColor(red: SHADOW_COLOR, green: SHADOW_COLOR, blue: SHADOW_COLOR, alpha: 0.2).CGColor
        layer.borderWidth = 1.0
    }
    
    //For placeholder:
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 10, 0)
    }
    
    //For editable text:
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, 10, 0)
    }

}
