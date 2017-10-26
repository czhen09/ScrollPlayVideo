# ScrollPlayVideo      
![image](https://github.com/czhen09/ScrollPlayVideo/blob/master/Resource/ScrollPlayVideo.gif)       
## 核心代码     
	- (void)filterShouldPlayCellWithScrollDirection:(BOOL)isScrollDownward
	{
	    //顶部
	    if (self.tableView.contentOffset.y<=0) {
	        //其他的已经暂停播放
	        if (self.lastOrCurrentPlayIndex==-1) {
	            [self playVideoWithShouldToPlayIndex:0];
	        }else{
	            //第一个正在播放
	            if (self.lastOrCurrentPlayIndex==0) {
	                return;
	            }
	            //其他的没有暂停播放,先暂停其他的再播放第一个
	            [self stopVideoWithShouldToStopIndex:self.lastOrCurrentPlayIndex];
	            [self playVideoWithShouldToPlayIndex:0];
	        }
	        return;
	    }
	    
	    //底部
	    if (self.tableView.contentOffset.y+self.tableView.frame.size.height>=self.tableView.contentSize.height) {
	        //其他的已经暂停播放
	        if (self.lastOrCurrentPlayIndex==-1) {
	            [self playVideoWithShouldToPlayIndex:self.dataArray.count-1];
	        }else{
	            //最后一个正在播放
	            if (self.lastOrCurrentPlayIndex==self.dataArray.count-1) {
	                return;
	            }
	            //其他的没有暂停播放,先暂停其他的再播放最后一个
	            [self stopVideoWithShouldToStopIndex:self.lastOrCurrentPlayIndex];
	            [self playVideoWithShouldToPlayIndex:self.dataArray.count-1];
	        }
	        return;
	    }
	    
	    //中部(找出可见cell中最合适的一个进行播放)
	    NSArray *cellsArray = [self.tableView visibleCells];
	    NSArray *newArray = nil;
	    if (!isScrollDownward) {
	        newArray = [cellsArray reverseObjectEnumerator].allObjects;
	    }else{
	        newArray = cellsArray;
	    }
	    [newArray enumerateObjectsUsingBlock:^(ScrollPlayVideoCell *cell, NSUInteger idx, BOOL * _Nonnull stop) {
	        NSLog(@"%ld",(long)cell.row);
	
	        CGRect rect = [cell.videoFirstImageView convertRect:cell.videoFirstImageView.bounds toView:self];
	        CGFloat topSpacing = rect.origin.y;
	        CGFloat bottomSpacing = self.frame.size.height-rect.origin.y-rect.size.height;
	        if (topSpacing>=-rect.size.height/3&&bottomSpacing>=-rect.size.height/3) {
	            if (self.lastOrCurrentPlayIndex==-1) {
	                if (self.lastOrCurrentPlayIndex!=cell.row) {
	                    [cell shouldToPlay];
	                    self.lastOrCurrentPlayIndex = cell.row;
	                }
	            }
	            *stop = YES;
	        }
	    }];
	}



## 调用时机:滚动停止的时候;    
	- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
	{
	    //停止的时候找出最合适的播放
	    [self filterShouldPlayCellWithScrollDirection:self.isScrollDownward];
	}
	
	- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
	{
	     //停止的时候找出最合适的播放
	    [self filterShouldPlayCellWithScrollDirection:self.isScrollDownward];
	}