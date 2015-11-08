//
//  ViewController.swift
//  TestCards
//
//  Created by 秦 道平 on 15/10/29.
//  Copyright © 2015年 秦 道平. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var collectionView : UICollectionView!
    private let cellIdentifier = "cell"
    var start_offset_y : CGFloat = 0.0
    /// 轮转中的照片列表
    var carouselImages:[UIImage] = []
    /// 真正的照片列表
    var images : [UIImage] = [] {
        didSet{
            carouselImages.removeAll()
            carouselImages = images + images + images
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.view.backgroundColor = UIColor.whiteColor()
        /// 
        self.prepageImages()
        /// collectionView
        self.collectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: CardsCollectionViewLayout())
        self.collectionView.showsVerticalScrollIndicator = true
        self.collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        self.collectionView.registerClass(CardsCollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        let layout_collectionView = ["collectionView":self.collectionView]
        let collectionView_constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-(-16.0)-[collectionView]-(-16.0)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: layout_collectionView)
        let collectionView_constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|-(-16.0)-[collectionView]-(-16.0)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: layout_collectionView)
        self.view.addConstraints(collectionView_constraintsH)
        self.view.addConstraints(collectionView_constraintsV)
        /// frameView
//        let frameView = UIView()
//        frameView.translatesAutoresizingMaskIntoConstraints = false
//        self.view.addSubview(frameView)
//        frameView.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
//        let layout_frameView = ["frameView":frameView,"superView":self.view]
//        let frameView_constraintsX = NSLayoutConstraint.constraintsWithVisualFormat("H:[frameView(300.)]-(<=0)-[superView]", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: layout_frameView)
//        let frameView_constraintsY = NSLayoutConstraint.constraintsWithVisualFormat("V:[frameView(200.0)]-(<=0)-[superView]", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: layout_frameView)
//        self.view.addConstraints(frameView_constraintsX)
//        self.view.addConstraints(frameView_constraintsY)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView.layoutIfNeeded()
        /// 在开始的时候就滚动到中间一组
        let max_offset_y = self.collectionView.contentSize.height - self.collectionView.bounds.height
//        self.start_offset_y = floor(max_offset_y / 2.0 / 30.0) * 30.0 + 30.0 * CGFloat(self.images.count)
        self.start_offset_y = floor(max_offset_y / 2.0 / 30.0) * 30.0 - 30.0 * CGFloat(self.images.count)
        NSLog("start_offset_y:%f", start_offset_y)
        self.collectionView.setContentOffset(CGPointMake(0.0, start_offset_y), animated: false)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
}
extension ViewController {
    /// 准备轮转的图片
    func prepageImages(){
        var images : [UIImage] = []
        for a in 0..<11 {
            let i = UIImage(named: "\(a)")!
            images.append(i)
        }
        self.images = images
    }
}
extension ViewController:UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return 11
        return self.carouselImages.count
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! CardsCollectionViewCell
//        let image = UIImage(named: "\(indexPath.row)")
//        cell.label.text = "\(indexPath.row)"
        let image = self.carouselImages[indexPath.row]
        cell.contentImageView.image = image
        return cell
    }
}
extension ViewController:UIScrollViewDelegate {
    /// 滚动的时候判断边界距离进行跳转
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let translate = scrollView.contentOffset.y - self.start_offset_y
        NSLog("scroll:%f, %f", scrollView.contentOffset.y, translate)
//        if translate >= 30.0 {
//            scrollView.setContentOffset(CGPointMake(0.0, self.start_offset_y), animated: false)
//        }
        let target_scroll_y : CGFloat = 30.0 * CGFloat(self.images.count)
        if abs(translate) >= target_scroll_y {
            scrollView.setContentOffset(CGPointMake(0.0, self.start_offset_y), animated: false)
        }
    }
}
