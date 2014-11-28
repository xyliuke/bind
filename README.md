#IOS开发过程中容易出现的问题
##1. 数据同步
在移动端开发过程中，可能会遇到一种情况，即在下一个VC（ViewController）中修改的数据需要在上个VC中体现出来。这种情况下很多人的做法是在两个VC间传递delegate来实现这种需求，但如果需要在其他VC中体现出变化呢？还有种做法是在低层实现一个Manager类来管理数据变化，Manger类中实现一个delegate的弱引用集合，把需要体现数据变化的VC添加到这个delegate的集合中，调用Manager的函数来修改数据，修改完成后再通过delegate全部发出去。这种做法的也是比较好的做法，但缺点是deleagate的协议可能会多一点，毕竟项目中不只是修改一个数据。
##2.异步回调造成的空白页
在移动开发过程中，访问网络是很普遍的事件，这就会出现一个情况：当网络数据还没有返回时，页面一般都会Loading，如果需要的数据不能一次性返回，而是需要多次访问网络后才能得到总的结果，情况可能会麻烦一点，更有可能存在某一次的网络请求失败，造成数据显示存在问题。

##3.多份数据的内存Cache
这种情况可能比较少一点，保证Cache数据只有一份，减少内存使用量，也避免数据更新时出现问题。

##4.控制UI的显示
在正常情况下，如果想改变某个UI的显示效果，如隐藏和显示、背景颜色、显示文字的改变等等，一般的做法是在VC中直接设置相应UI的属性。但在UI的层次比较深时，就需要通过层层调用函数来改变UI，需要改变的方式越多，向外暴露的函数就会越多。

#基于Bind的解决思路
Bind是以KVO为基础，解决多种情况绑定同一份数据的问题，也避免由于绑定而带来的block循环持有问题。Bind的基本思路是在底层构建一份数据Cache，这些Cache以对象的方式存在，为整个App的基础。所有网络请求的数据都转化成Cache对象，所有访问网络请求修改的数据成功后，Cache中相应同步修改。建构好Cache对象后，在页面中的数据显示可以基于Bind来实现。这里举两个例子：
```
1.如果我们想要显示一个人的信息，使用一般的方式是先在内存为找这个人的信息，如果有的话，取数据进行显示；如果没有的话，就需要进行网络请求获取，显示Loading页面，获取数据后再进行显示。
使用Bind的方式的步骤为，首先将需要显示的数据和某一个UI进行绑定，如名字属性和UILabel进行绑定。将所有需要绑定的关系建立完成后，就不需要做其他事件了。
```

```

```