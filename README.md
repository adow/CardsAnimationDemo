# CardsAnimationDemo



## 介绍

CardsAnimationDemo 源于有一天我在网上看到的一篇文章: http://www.cocoachina.com/ios/20151013/13700.html，作者详细的介绍了如何实现这个卡片动画的全部过程。

我写这个 Demo 是同样做了一遍，唯一的不同是，我不是直接操作所有 `UIView` 和 `CALayer` 的 `transform3D` 属性来实现整个效果的，而是使用 `UICollectionView` 来完成所有的视图管理和实现（当然其实内部的实现也不过就是操作了 `transform3D` 属性）。

因此我将使用 `UICollectionView` 来完成整个翻转动画实现，并将做成可以无限轮转的样子。

我想说的是这个项目并不是一个可以直接拿来使用的组件，仅仅是一个作为研究的实验产品，虽然我觉得要并入到现成的项目中应该不算很麻烦。

## 组成

由于使用 `UICollectionView` 来实现所有的卡片视图管理。同其他使用 `UICollectionView` 的代码一样，我们主要的工作都集中在 Layout（我这里定义为 `CardsCollectionViewLayout`），我这里也定义了一个 `CardsCollectionViewCell`, 其中只有一些简单的布局代码（显示那张图片）。

`ViewController` 是整个 App 的 `rootViewController`, 他只做了很少的一部分工作，基本上就是作为 `UICollectionView` 的 `dataSource` 和 `delegate` 存在的。

还有需要说明的是整个项目中的代码中使用了 Autolayout，因此如果把这些代码应用到你的项目中时，需要考虑是不是有布局的兼容性问题。在我的其他项目中，我大范围使用 Cartography 和 SnapKit 作为布局工具，他们让我大大减少了写那些恶心的约束代码的时间。但在这个项目中，我直接写了约束代码而不是使用第三方工具，毕竟我不想在这里依赖任何第三方库。

## UICollectionView

为什么使用 `UICollectionView`? 而不是像那篇文章里的那样直接通过手势来修改所有的卡片View/Layer 的属性？

我曾经也做个类似的项目，通过手势驱动，计算每个屏幕中出现的 UIView, 上下偏移和缩放，我们只需要知道手势移动的距离，知道每个 卡片 View 之间的距离和缩放的关系，就可以计算出每个卡片在配合移动过程中应该有的状态。事实上，使用 `UICollectionView` 中的 layout 部分代码和这个几乎是一样的，但是当你实现完整个项目之后你会突然发现，我通过手势完成的大部分代码居然就是 `UIScrollView` 中同样的功能，我特么居然就自己写了一个 `UIScrollView` 样的东西出来不是吗？既然这样我们为啥就不直接使用 `UIScrollView` 呢？

另一个显而易见的原因是，使用 `UICollectionView` 便于管理各个卡片视图，我们可以在 `UICollectionViewCell` 中完成自己的卡片布局，并且可以重用，这是最重要的。

## 翻转

我们来看看这个卡片翻转动画，其实很简单，卡片从后面往前面移动，当移动到一个位置的时候，他不再继续往前移动了，而是往下完成一个翻转动画，然后就不见了。所以我们很明确的就是需要完成这个翻转的过程。

我们只可以对 `CALayer` 进行翻转，因为只有 `CALayer` 有 `transofrm3D` 属性(`CGTransform3D`), `UIView` 只有一个 `transform` 属性 (`CGAffineTransofrm`)。所以我们要做一个 UIView 的翻转效果就只要直接对这个 UIView 的 layer 属性设置 `transform3D` 就可以了。

需要注意的是，直接使用 x 轴的翻转是看不出透视效果的 （不信你直接用 `CATransform3DMakeRotate` 创建一个 x 变化来看看），我们还得设置一个透视的变化；

创建一个透视的变化:

	func makePerspectiveTransform() -> CATransform3D {
            var transform = CATransform3DIdentity;
            transform.m34 = 1.0 / -2000;
            return transform;
        }
        
现在我们就可以完成一个带透视的 x 轴 翻转效果

	let transform_perctive = self.makePerspectiveTransform()
	let transform_3d = CATransform3DRotate(transform_perctive, radians, 1.0, 0.0, 0.0)
	
然后把这个 transofrm_3d 设置在 layer 的 `transform3D` 属性上就可以了。

## CardsCollectionViewLayout 和 卡片翻转动画

### 先来说说可怕的 UICollectionViewLayout

UICollectionViewLayout 的确才是 UICollectionView 魔术的精髓所在，因为有 layout，才使得他区别于 UITableView，layout 真正控制了 UICollectionView 中所有 cell 的位置。

### CardsCollectionViewLayout
CardsViewControllerViewLayout 继承自 UICollectionFlowLayout, 但其实并没有使用任何 UICollectionFlowLayout 的方法和属性，因为我们的 cell 的坐标都是单独计算出来的。

需要注意的是， layout 并不是直接修改 cell 的 `frame`, `bounds`, `transform` 这些属性来实现 cell 的布局的，而是通过 `UICollectionViewLayoutAttributes` 对象来设置相应的 cell 的位置属性。

像大多数 Layout 的实现那样，我们需要覆盖几个方法：

`func collectionViewContentSize() -> CGSize` 用来告诉 `UICollectionView` 内容区域的大小，因为我们并不是挨着整齐排列的，所以并不能把每个 cell 的大小相加就可以的，如果设置的太小就会让很多 cell 并不能出来，因为滚动区太小了，出不来。如果设置的太大又会拖动了一下就到空的地方去了。还好我们这里并不需要精确的计算整个内容去的大小（其实也可以计算出来），因为我们要做成无限轮转的滚动，他的原理就在于，当我们往上或者往下滚动到一个位置时，会突然跳转到另一个位置，因为我们仔细编排了每个 cell 的位置，所以使得这个跳转的过程看不出来而已。我们将在无限轮转的部分来讨论这个实现。

`override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }`

这个必须要设置为 true，因为我们需要在滚动的时候实时修改 layout。

`override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?` 用来告诉 `UICollectionView` 每个 cell 的 `UICollectionViewLayoutAttributes` 对象，其中可以设置 `frame`, `bounds`, `transform`, `transform3D`, `alpha`, `zIndex` 等属性，他们会在对应的 cell 中被应用到实际的显示中。

`override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]?` 用来告诉 `UICollectionView` 中一个指定区域内的 cell 的 `UICollectionViewLayoutAttributes` 集合，他一般就是当前可见范围内的 cell 的 attributes 集合。

我们简化了上面两个方法的实现，而把主要的工作都放在了  `override func prepareLayout()` 中，在这里，我们会根据 `UIScrollView` 的 `contentOffset.y` 来计算出每个 cell 的位置，缩放，和翻转的关系，为每个 cell 创建 `UICollectionViewLayoutAttributes`,并把他们保存到一个外部的数组中，所以 `layoutAttributesForItemAtIndexPath` 和 `layoutAttributesForElementsInRect` 只是单纯的读取这个数组而已。`UICollectionView` 熟练的你肯定会发现这里其实有很多可以优化性能的地方。

### prepareLayout() 的实现

所有丑陋的代码都在 `prepareLayout()` 中。

每当滚动条拖动并导致更新 layout 时， `prepareLayout()` 会被首先调用，然后会根据位置来调用 `layoutAttributesForItemAtIndexPath` 或者 `layoutAttributesForElementsInRect`。而我把所有的 cell 对应的 attributes 对象的创建都放进了 `prepareLayout` 中。

我们先来讨论下 cell 之间的关系： 屏幕中间的 cell 是第一个，沿着 y 轴往上的时候，一个个 cell 都被放在后面，每个 cell 都沿着 y 轴上移 30 个 位置，并且缩小 0.1, 为了让cell相互遮挡，我们为每个 cell 设置了 `zIndex` ，为了看上去更加舒服点，又为每个 cell 的 layou 设置了 shadow, 这样就伪造出了一个 3D 透视的效果。为了方便计算，我们使用一个变量 (ratio) 来标识每个 cell 之间的关系（前后 ratio 缩小 0.1），ratio 等于 1.0 的时候，cell 在屏幕的中间； ratio 等于 0.0 的时候，就是他看不见了，ratio < 0.0 的时候也是应该看不见的；ratio 是需要大于 1.0 的，感觉他应该是越来越大才对，但是我们这里是需要翻转然后消失的，所以 ratio >1.0 的时候，屏幕中间的这个 cell 开始翻转，当到底 ratio = 1.1 的时候，翻转到另一面并消失了。

由于外部有 `UIScrollView`,当我们滚动的时候，我们不需要让所有的 cell 跟着 `UIScrollView` 直接移动，这样只会让所有的 cell 都上下移动而已。我们只需要记住，确定每个 cell 的位置是依靠 ratio，每个 cell 的 ratio 是相互递减的，所以我们只要在滚动 `UIScrollView` 的时候同时修改 ratio 就可以实现所有的 cell 在跟着滚动条变化。

请原谅我实在没有办法把这里的数学描述的更加清楚了，也许我的代码里写的一样的不清楚。但我们通过 ratio 的修改来设置每个 cell 的位置，ratio 在 0 到 1.0 的时候就是沿着 y 移动并放大缩小，当 ratio 在 1.0 到 1.1 的时候对这个 cell 进行翻转和透明度的变化，仅此而已。

`prepareLayout()` 的代码: 

    override func prepareLayout() {
            super.prepareLayout()
            var array : [UICollectionViewLayoutAttributes] = []
            let offset_y : CGFloat = self.collectionView!.contentOffset.y
            let max_offset_y = self.collectionView!.contentSize.height - self.collectionView!.bounds.size.height
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

#### 对了还要说一下 anchorPoint

`anchorPoint` 是每个 CALayer 用来确定相互位置关系时的 `锚点`, 问题在于这个点不大好描述，所以我这里就不展开说了，强烈建议大家看一下这个属性的作用。这里需要说明的是， `anchorPoint` 会影响旋转，因为旋转都是绕着 `anchorPoint` 进行的，而默认的 `anchorPoint` 是 (0.5, 0.5) 也就是中间，所以当我们直接做 x 轴翻转的时候会看到的效果其实不是我们想要的，我们需要的是绕着卡片的底部进行翻转。所以需要把 cell 的 `anchorPoint` 设置为底部 (0.5, 1.0), 但是 `anchorPoint` 是用来确定 CALayer 和他父层 CALayer 之间定位关系的点，修改了 `anchorPoint` 会把位置也改了，所以我们还需要同时修改 layer 的 `frame`用来补偿因为修改 `anchorPoint` 而偏移的位置。

在 `CardsCollectionViewCell` 中，`applyLayoutAttributes` 来设置 layer 的 `anchorPoint`，这样保证在每个使用 attributes 时都有一个正确的 `anchorPoint`。

    override func applyLayoutAttributes(layoutAttributes: UICollectionViewLayoutAttributes) {
            super.applyLayoutAttributes(layoutAttributes)
            self.layer.anchorPoint = CGPointMake(0.5, 1.0)
        }
        
同时需要注意在 `prepareLayout` 中对每个 cell 进行位置计算时增加偏移。

	var center_y : CGFloat = self.collectionView!.bounds.height / 2.0 + offset_y + self.cardHeight / 2.0 /// 以中间为固定位置，要加上因为修改 anchor 的 y 偏移

### 改善拖动和吸附位置

因为我们根据 `UIScrollView` 的 滚动位置来确定每个 cell 的位置和翻转状态的，因此如果 `UIScrollView` 滚动到一个不精确的位置，那就可能只看到有个页面翻转了一半就停在那里了。这样实在太奇怪了，所以我们需要让 `UIScrollView` 滚动到一个位置的时候吸附的停在我们需要的位置上。

有的时候我们可以使用 `pagingEnabled` 属性，这里用起来有点麻烦，还好我还发现了另一个方法，`targetContentOffsetForProposedContentOffset`, 可以告诉你预计结束的时候的 `contentOffset` 的位置，你可以根据这个值改一下，并且返回一个修改过的值并让滚动条最后停在这个位置上（太神奇了）。由于我们每个 cell 间的 y 轴距离是 30 个 Point, 所以只需要让滚动条停止在最近的 30 的整数倍上面就可以了。

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


## 无限轮转

轮转图是上古时代企业网站最喜欢的工具，到了 App 中由于屏幕限制依旧随处可见。他们就像单曲循环一样有时让人感到厌烦。

我们这里也使用轮转，这样你无论往上还是往下都可以随意的滚动。

轮转的原理都是一样的，在你滚动到一个边界值的时候（最大或者最小），他就突然跳转到另一边去，这样就重新开始滚动了，我们只是没发现这个过程而已。所以，我们要准备用来轮转的图要比实际使用的多一些。

我们这里有 10 张图做的轮转效果，每张图（cell）之间的  y 轴距离是 30, 所以最大的 y 轴 滚动距离应该是 300, 所以每当超过这个值的时候，就跳转到开始的地方，另一个方向也是一样的。

但是 `UIScrollView` 不可以超出滚动区域很多的地方，所以我们不可以滚动到 `conentOffset.y <0` 很远的距离，一松开就会弹回到 0。

因此我们的 cell 一开始就不是在 `UICollectionView` 顶上开始绘制的，实际是在 `contentSize` 的中间开始绘制，这样你可以往上和往下进行滚动。同时在开始的时候滚动条就应该定位到这个位置。

为了让整个滚动的跳转看不出啥破绽，我准备了足够多的轮转图片，也就是把实际轮转的内容数量乘以 3 倍（其实完全用不着这么多），这样前后都有足够的 cell 做显示。

因此，我原来轮转的图片是 0 - 9 一共 10 张，实际我准备了  0 - 29 一共 30 张，而我在 UIScrollView 中开始时的是 9-18，当滚动到第19张时，会跳转到第 9 张，当滚动到第 8 张时会跳转到第 18 张.

    func scrollViewDidScroll(scrollView: UIScrollView) {
            let translate = scrollView.contentOffset.y - self.start_offset_y
            NSLog("scroll:%f, %f", scrollView.contentOffset.y, translate)
            let target_scroll_y : CGFloat = 30.0 * CGFloat(self.images.count)
            if abs(translate) >= target_scroll_y {
                scrollView.setContentOffset(CGPointMake(0.0, self.start_offset_y), animated: false)
            }
        }

## Demo
        
[CardsAnimationDemo](https://github.com/adow/CardsAnimationDemo/tree/master)
        
## 参考

* [如何实现炫酷的卡片式动画！] (http://www.cocoachina.com/ios/20151013/13700.html)