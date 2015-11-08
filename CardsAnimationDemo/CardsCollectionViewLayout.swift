//
//  CardsCollectionViewLayout.swift
//  TestCards
//
//  Created by 秦 道平 on 15/10/29.
//  Copyright © 2015年 秦 道平. All rights reserved.
//

import UIKit

func divmod(a:CGFloat,b:CGFloat) -> (quotient:CGFloat, remainder:CGFloat){
    return (a / b, a % b)
}
class CardsCollectionViewLayout: UICollectionViewFlowLayout {
    private let cardWidth : CGFloat = 300.0
    private let cardHeight : CGFloat = 200.0
    private var numberOfItems : Int = 0
    private var attributesList : [UICollectionViewLayoutAttributes] = []
    /// 每个 cell 在 y 之间的距离
    private let y_distance_in_cells : CGFloat = 30.0
    var start_offset_y : CGFloat = 0.0
    override init() {
        super.init()
        self.collectionView?.decelerationRate = UIScrollViewDecelerationRateFast
        self.collectionView?.pagingEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func collectionViewContentSize() -> CGSize {
        let height = max(y_distance_in_cells * CGFloat(self.numberOfItems),self.collectionView!.bounds.height + 1.0)
//        let height = self.collectionView!.bounds.height / 2.0 * CGFloat(self.numberOfItems)
//        let height = self.collectionView!.bounds.height * CGFloat(self.numberOfItems)
        return CGSizeMake(self.collectionView!.bounds.width, height * 2.0)
    }
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    func makePerspectiveTransform() -> CATransform3D {
        var transform = CATransform3DIdentity;
        transform.m34 = 1.0 / -2000;
        return transform;
    }
    override func prepareLayout() {
        super.prepareLayout()
        var array : [UICollectionViewLayoutAttributes] = []
        let offset_y : CGFloat = self.collectionView!.contentOffset.y
        let max_offset_y = self.collectionView!.contentSize.height - self.collectionView!.bounds.size.height
//        let (times,_) = divmod(max_offset_y / 2.0, b:30.0)
//        start_offset_y = times * 30.0
        start_offset_y = floor(max_offset_y / 2.0 / 30.0) * 30.0
        let reverse_offset_y : CGFloat = start_offset_y - offset_y
        self.numberOfItems = self.collectionView!.numberOfItemsInSection(0)
        for a in 0..<self.numberOfItems {
            let indexPath = NSIndexPath(forItem: a, inSection: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
            /// 刚开始的时候所有的 cell 都在中间
            let center_x : CGFloat = self.collectionView!.bounds.width / 2.0
            var center_y : CGFloat = self.collectionView!.bounds.height / 2.0 + offset_y + self.cardHeight / 2.0 /// 以中间为固定位置，要加上因为修改 anchor 的 y 偏移
            /// ratio 是每个cell 的比率，控制 y 便宜和 缩放, 0.0 - 1.0 之间是从小到大的变化, 1.0 指的是中间那个位置，1.0 到 1.1 之间不会修改大小和位置，只会进行翻转和透明
            /// 每个 cell 之间的 ratio 相差 0.1 
            /// 每个 cell 之间的 y 距离是 30.0
            var ratio : CGFloat = 1.0 - 0.1 * CGFloat(indexPath.row) /// 间隔 0.1
            /// 再加上滚动的距离(注意滚动方向和实际的表现方向是反的)，除以10是因为每个 cell 之间的 ratio 差是 0.1
            ratio += reverse_offset_y / y_distance_in_cells / 10.0
            /// 最大只会到 1.0，超过 1.0 就不会移动和放大，1.0 到 1.1 之间会进行翻转，然后消失
            if ratio < 1.0 {
                center_y += -(1.0 - ratio) * y_distance_in_cells * 10.0
            }
            attributes.center = CGPointMake(center_x, center_y)
            let scale : CGFloat = min(1.0 * ratio,1.0)
            attributes.transform = CGAffineTransformMakeScale(scale, scale)
            attributes.bounds = CGRectMake(0.0, 0.0, self.cardWidth, self.cardHeight)
            attributes.alpha =  1.0
            /// 设置遮挡关系
            attributes.zIndex = 10000 - indexPath.row
            /// 超过 1.0 之后，在 1.0 - 1.1 之间，会进行翻转和透明度变化
            if ratio > 1.0 {
                /// alpha, 从 1.0 到 0.0
                var alpha = (1.1 - ratio) * 10.0
                alpha = min(alpha, 1.0)
                alpha = max(alpha, 0.0)
                attributes.alpha = alpha
                /// rotate, 翻转角度从 0 到 -180.0 之间, angle_ratio 从 0.0 到 1.0
                var angle_ratio = 1.0 - (1.1 - ratio) * 10.0
                angle_ratio = min(angle_ratio, 1.0)
                angle_ratio = max(angle_ratio , 0.0)
                /// 不使用 180°，因为这样会从反面翻转过来
                let angle : CGFloat = -179.999 * angle_ratio
                /// 转换成弧度
                let radians : CGFloat = angle * CGFloat(M_PI) / 180.0
                /// 实现 3D 翻转
                let transform_perctive = self.makePerspectiveTransform()
                let transform_3d = CATransform3DRotate(transform_perctive, radians, 1.0, 0.0, 0.0)
                attributes.transform3D = transform_3d
//                print("a:\(a),ratio:\(ratio),alpha:\(alpha),angle:\(angle)")
            }
            /// 小于 0 的会反过来，就不用显示了
            if ratio > 0 {
                array.append(attributes)
            }
        }
        self.attributesList = array
    }
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return self.attributesList[indexPath.row]
    }
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.attributesList
    }
    override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
//        print("offset:\(proposedContentOffset)")
        /// 每个 cell 之间的 y 距离是30.0，所以要保证最后停在 30.0 的整数倍上面
        var targetContentOffset = proposedContentOffset
        let (total,more) = divmod(targetContentOffset.y, b: y_distance_in_cells)
        if more > 0.0 {
            if more >= y_distance_in_cells / 2.0 {
                targetContentOffset.y = ceil(total) * y_distance_in_cells
            }
            else {
                targetContentOffset.y = floor(total) * y_distance_in_cells
            }
        }
        
        return targetContentOffset
    }
    
}
