//
//  viewIsAppearing.swift
//  
//
//  Created by Apple on 15/12/25.
//

import Foundation

In iOS 17, Apple introduced a new view controller callback named viewIsAppearing(_:), which is poised to become a game-changer for developers. This callback is triggered between viewWillAppear(_:) and viewDidAppear(_:), and it notifies the view controller that the system is adding the view controller's view to a view hierarchy.
                                                                                                                                    
Why viewIsAppearing(_:) is Essential?
                                                                                                                                    
viewIsAppearing(_:) is the ideal place to perform tasks that need to be done each time the view appears. When this method is called, both the view controller and the view have an up-to-date trait collection. Additionally, the view has been added to the hierarchy and has been laid out by its superview. This makes viewIsAppearing(_:) the perfect moment to run code that depends on the view's initial geometry, including its size.

Compatibility:
One of the most impressive aspects of viewIsAppearing(_:) is that it back-deploys all the way to iOS 13. This means you can leverage its benefits even if your app supports older versions of iOS.

Note how viewWillAppear(_:) gets called before the view is added to the hierarchy, and before layout begins. This is why it is too early to use the trait collection, or to do anything that depends on the view’s size or other geometry.
Now, notice how viewDidAppear(_:) is called in a separate CATransaction at the end, after any animations takes place. This means any changes you make in viewWillAppear(_:) don’t become visible until the transition completes. So, it is too late to make changes you want visible during the transition.
On the other hand, viewIsAppearing(_:) is called on the same transaction as viewWillAppear(_:). This means any changes you make in either of those callbacks become visible to the user at the same time, right from the very first frame of the transition.

Though their timing may be similar, there’s a key difference between viewIsAppearing(_:) and layout callbacks like viewWillLayoutSubviews(_:). Layout callbacks are made whenever the view runs layoutSubviews, which can happen multiple times during the transition, or any time later on while the view is visible. But viewIsAppearing(_:) is only called once during the appearance transition, and it still gets called even if the view doesn’t need layout. This is why I like to think of viewIsAppearing(_:) as the Goldilocks callback.

(Goldilocks callback: It’s not called too early, or too late, or too often. It is just right.)

Conclusion:
With viewIsAppearing(_:), iOS 17 provides developers with a powerful new tool to fine-tune the appearance of their views. By understanding its place in the view controller lifecycle and leveraging its unique timing, you can ensure that your view-related code runs at the perfect moment, leading to smoother transitions and a better user experience. So go ahead and integrate viewIsAppearing(_:) into your apps, and enjoy the newfound control it offers.
