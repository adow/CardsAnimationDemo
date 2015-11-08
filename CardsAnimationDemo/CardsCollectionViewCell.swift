//
//  CardsCollectionViewCell.swift
//  TestCards
//
//  Created by 秦 道平 on 15/10/29.
//  Copyright © 2015年 秦 道平. All rights reserved.
//

import UIKit

class CardsCollectionViewCell: UICollectionViewCell {
    var label:UILabel!
    var contentImageView:UIImageView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.clipsToBounds = true
        /// imageView
        contentImageView = UIImageView(image:UIImage(named: "coffee"))
        contentImageView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(contentImageView)
        let layout_imageView = ["imageView":contentImageView]
        let imageView_constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(-16.0)-[imageView]-(-16.0)-|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: layout_imageView)
        let imageView_constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(-16.0)-[imageView]-(-16.0)-|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: layout_imageView)
        self.contentView.addConstraints(imageView_constraintsH)
        self.contentView.addConstraints(imageView_constraintsV)
        /// label
//        label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        self.contentView.addSubview(label)
//        label.textAlignment = NSTextAlignment.Center
//        label.text = "label"
//        label.backgroundColor = UIColor.grayColor()
//        label.textColor = UIColor.darkGrayColor()
//        let layout_label = ["label":label,"superView":self]
//        let label_constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0.0)-[label]-(0.0)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: layout_label)
//        self.contentView.addConstraints(label_constraintsH)
//        let label_constraintsY = NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
//        self.contentView.addConstraint(label_constraintsY)
        ///
        self.layer.shadowColor = UIColor.darkGrayColor().CGColor
        self.layer.shadowOffset = CGSizeMake(0.0, -1.0)
        self.layer.shadowOpacity = 0.3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
        super.applyLayoutAttributes(layoutAttributes)
        self.layer.anchorPoint = CGPointMake(0.5, 1.0)
    }
    
}
