//
//  TableViewCell.swift
//  SharingWidget
//
//  Created by Johan Sellström on 2020-03-12.
//  Copyright © 2020 Svipe AB. All rights reserved.
//

import UIKit

public protocol TableDelegate {
    func remove(_ cell: TableViewCell)
}

public class TableViewCell: UITableViewCell {

    public var delegate:TableDelegate?
    
    @IBOutlet weak public var attributeTitle: UILabel!
    @IBOutlet weak public var attributeValue: UILabel!
    @IBOutlet weak public var removeButton: UIButton!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction public func removeAttribute(_ sender: Any) {
        delegate?.remove(self)
    }
    
}
