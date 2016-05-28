//
//  MaterialImage.swift
//  going-local
//
//  Created by Dide van Berkel on 29-04-16.
//  Copyright © 2016 Gary Grape Productions. All rights reserved.
//

import UIKit

class MaterialImage: UIImageView {
    
    override func awakeFromNib() {
        layer.cornerRadius = 10.0
        clipsToBounds = true
    }
}
