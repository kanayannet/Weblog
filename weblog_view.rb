class WeblogView
	#Viewのためのライブラリ
	require 'erb'
	require 'weblog_controller.rb'
	require 'weblog_logic.rb'
	
	include ERB::Util
	def initialize
	 
	  @logic = WeblogLogic.new
	  @cont = Controller.new('not_cgi')
	  @yaml = @cont.yaml
	  
	  begin
	    @head = File.read(@yaml['PageHeadViewFile'])
	  rescue
	    @cont.error('「PageHeadViewFile」がありません。')
	  end
	  #PageHeader
	  erb = ERB.new(@head)
	  url = @yaml['Url']
	  cssurl = @yaml['CssUrl']
	  title = @yaml['Title']
	  description = @yaml['Description']
	  @PageHeadView = erb.result(binding)
	  #PageFooter
	  begin
	    @foot = File.read(@yaml['PageFootViewFile'])
	  rescue
	    @cont.error('「PageFootViewFile」がありません。')
	  end
	  erb = ERB.new(@foot)
	  @PageFootView = erb.result(binding)
	  
	  begin
	    @CenterTop = File.read(@yaml['TopPageCenterTopViewFile'])
	  rescue
	    @cont.error('「TopPageCenterTopViewFile」がありません。')
	  end
	  
	  begin
	    @CenterMiddle = File.read(@yaml['TopPageCenterMiddleViewFile'])
	  rescue
	    @cont.error('「TopPageCenterMiddleViewFile」がありません。')
	  end
	  
	  begin
	    @CalenderView = File.read(@yaml['TopPageCalViewFile'])
	  rescue
	    @cont.error('「TopPageCalViewFile」がありません。')
	  end
	  
	  begin
	    @Favorites = File.read(@yaml['TopPageFavoritesViewFile'])
	  rescue
	    @cont.error('「TopPageFavoritesViewFile」がありません。')
	  end
	  
	  begin
	  	@CenterBottom = File.read(@yaml['TopPageCenterBottomViewFile'])
	  rescue
	  	@cont.error('「TopPageCenterBottomViewFile」がありません。')
	  end
	  
	  begin
	  	@CenterMostBottom = File.read(@yaml['TopPageCenterMostBottomViewFile'])
	  rescue
	  	@cont.error('「TopPageCenterMostBottomViewFile」がありません。')
	  end
	  
	  begin
	  	@RightHeadView = File.read(@yaml['TopPageRightNewParentViewFile'])
	  rescue
	  	@cont.error('「TopPageRightNewParentViewFile」がありません。')
	  end
	  
	  begin
	  	@RightMiddleView = File.read(@yaml['TopPageRightNewChildViewFile'])
	  rescue
	  	@cont.error('「TopPageRightNewChildViewFile」がありません。')
	  end
	  
	  begin
	    @AllView = File.read(@yaml['TopPageAllViewFile'])
	  rescue
	    @cont.error('「TopPageAllViewFile」がありません。')
	  end
	  
	  begin
	  	@PassInputView = File.read(@yaml['PassInputViewFile'])
	  rescue
	  	@cont.error('「PassInputViewFile」がありません。')
	  end
	  
	  begin
	  	@MenteTopView = File.read(@yaml['MenteTopViewFile'])
	  rescue
	  	@cont.error('「MenteTopViewFile」がありません。')
	  end
	  
	  begin
	  	@MenteArticleInutView = File.read(@yaml['MenteArticleInputViewFile'])
	  rescue
	  	@cont.error('「MenteArticleInputViewFile」がありません。')
	  end
	  
	  begin
	  	@ArticlePreview = File.read(@yaml['ArticlePreviewFile'])
	  rescue
	  	@cont.error('「ArticlePreviewFile」がありません。')
	  end
	  
	  begin
	  	@ArticleList = File.read(@yaml['ArticleListFile'])
	  rescue
	  	@cont.error('「ArticleListFile」がありません。')
	  end
	  
	  begin
	  	@ProfileInputView = File.read(@yaml['ProfileInputViewFile'])
	  rescue
	  	@cont.error('「ProfileViewFile」がありません。')
	  end
	  
	  begin
	  	@ProfileView = File.read(@yaml['ProfileViewFile'])
	  rescue
	  	@cont.error('「ProfileInputViewFile」がありません。')
	  end
	  
	  begin
	  	@FavoritesInputView = File.read(@yaml['FavoritesInputViewFile'])
	  rescue
	  	@cont.error('「FavoritesInputViewFile」がありません。')
	  end
	  
	  begin
	  	@ImgInputView = File.read(@yaml['ImgInputViewFile'])
	  rescue
	  	@cont.error('「ImgInputViewFile」がありません。')
	  end
	  begin
	  	@HolidayInputView = File.read(@yaml['HolidayInputViewFile'])
	  rescue
	  	@cont.error('「HolidayInputViewFile」がありません。')
	  end
	  
	  begin
	  	@ResArticleListView = File.read(@yaml['ResArticleListViewFile'])
	  rescue
	  	@cont.error("「ResArticleListViewFile」がありません。")
	  end
	  
	  begin
	  	@TrackBackListView = File.read(@yaml['TrackBackListViewFile'])
	  rescue
	  	@cont.error("「TrackBackListViewFile」がありません。")
	  end
	  
	  begin
	  	@LeftFreeInputView = File.read(@yaml['LeftFreeInputViewFile'])
	  rescue
	  	@cont.error("「LeftFreeInputViewFile」がありません。")
	  end
	  
	  begin
	  	@RightFreeInputView = File.read(@yaml['RightFreeInputViewFile'])
	  rescue
	  	@cont.error("「RightFreeInputViewFile」がありません。")
	  end
	  
	  begin
	  	@ResPreview = File.read(@yaml['ResPreviewFile'])
	  rescue
	  	@cont.error("「ResPreviewFile」がありません。")
	  end
	  
	  @youbi = ['日','月','火','水','木','金','土']
	  
	  @WdayView = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
	  
	  @MonthView = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
	  
	end
	attr_reader :PageHeadView, :PageFootView
	
	#TopPage全体
	def TopPageAllView(cgi)
	    
	    #Calender
	    year = cgi['year'].to_s
	    month = cgi['month'].to_s
	    if(year == '')
	      year = @logic.year.to_s
	    end
	    
	    if(month == '')
	      month = @logic.month.to_s
	    end
	    
	    #親記事の読込
	    erb = ERB.new(@CenterTop)
	    (parent_list,parent_year_month_day,parentid) = @logic.ParentArticleRead(cgi)
	    parent = erb.result(binding)
	    
	    #カレンダー表示
	    (holiday_read,holiday_info) = @logic.HolidayRead(cgi)
	    erb = ERB.new(@CalenderView)
	    cal = @logic.GetCalInfo(year,month)
	    calender = erb.result(binding)
	    
	    
	    #お気に入り表示
	    erb = ERB.new(@Favorites)
	    fav_read = @logic.FavoritesRead(cgi)
	    favorites = erb.result(binding)
	    
	    #左側自由入力欄表示
	    left_free_html = @logic.LeftFreeInputRead
	    
	    #子記事の読み込み + TrackBackの読み込み + comment入力欄読み込み
	    child_list = @logic.ChildArticleRead(cgi)
	    child = ""
	    track = ""
	    commentform = ""
	    if((/^\d+$/=~cgi['edit_num'])&&(parentid[cgi['edit_num'].to_s] == 1))
			erb = ERB.new(@CenterMiddle)
			child = erb.result(binding)
			track_list = @logic.TrackBackRead(cgi)
			erb = ERB.new(@CenterBottom)
			track = erb.result(binding)
			erb = ERB.new(@CenterMostBottom)
			commentform = erb.result(binding)
			
	    end
	    
	    #最近の親記事を表示
	    erb = ERB.new(@RightHeadView)
		newparent = erb.result(binding)
		
		#最近の子記事を表示
		erb = ERB.new(@RightMiddleView)
		newchild = erb.result(binding)
		
		#右側自由入力欄表示
		right_free_html = @logic.RightFreeInputRead
		
	    erb = ERB.new(@AllView)
	    return erb.result(binding)
	end
	
	#パスワード入力画面
	def PassInput(cgi)
		erb = ERB.new(@PassInputView)
		return erb.result(binding)
	end
	
	#メンテナンスTOP画面
	def MenteTop(cgi)
		if((@logic.LoginChk(cgi) == 1)||(@logic.LoginSet(cgi) == 1))
			erb = ERB.new(@MenteTopView)
			return erb.result(binding)
		else
			#パスワード入力ミスの場合
			if(cgi['InputPass'].to_s != "")
				@cont.error('パスワードが間違っています。');
			end
			return PassInput(cgi)
		end
	end
	
	#記事投稿入力画面
	def MenteArticleInput(cgi)
		if(@logic.LoginChk(cgi) == 1)
			subject = ''
			article = ''
			mode = 'ArticleInputExec'
			edit_input = ''
			if(cgi['mode'] == 'ChangeOrDelete')
				edit_num = cgi['edit_num'].to_i
				edit_input = "<input type=\"hidden\" name=\"edit_num\" value=\"#{edit_num}\">"
				(parent_list,parent_year_month_day,parentid) = @logic.ParentArticleRead(cgi)
				parent_list.each_index do |par_key|
					#記事番号指定の表示
					if(cgi['edit_num'] == parent_list[par_key]['id'])
						subject = @logic.SubjectConvert(parent_list[par_key]['subject'])
						article = @logic.FormArticleConvert(parent_list[par_key]['article'])
						break
					else
						next
					end
				end
			end
			erb = ERB.new(@MenteArticleInutView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#記事プレビュー画面
	def ArticlePreview(cgi)
		if(@logic.LoginChk(cgi) == 1)
			erb = ERB.new(@ArticlePreview)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#記事のリスト画面
	def ArticleList(cgi)
		if(@logic.LoginChk(cgi) == 1)
			(parent_list,parent_year_month_day,parentid) = @logic.ParentArticleRead(cgi)
			erb = ERB.new(@ArticleList)
			article_list_html = ""
			
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#プロフィール設定画面
	def ProfileInputView(cgi)
		if(@logic.LoginChk(cgi) == 1)
			(name,url,hobby,profile,image,width,height) = @logic.ProfileGet(cgi)
			erb = ERB.new(@ProfileInputView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#プロフィールプレビュー画面
	def ProfilePreview(cgi)
		if(@logic.LoginChk(cgi) == 1)
			#ここで画像名など得る
			(name,url,hobby,profile,image,width,height) = @logic.ProfilePreviewGet(cgi)
			preview_flag = 1
			erb = ERB.new(@ProfileView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#プロフィール画面
	def ProfileView(cgi)
		(name,url,hobby,profile,image,width,height) = @logic.ProfileGet(cgi)
		preview_flag = 0
		erb = ERB.new(@ProfileView)
		return erb.result(binding)
	end
	
	#お気に入り編集画面
	def FavoriteInputView(cgi)
		if(@logic.LoginChk(cgi) == 1)
			#ここでお気に入りデータ得る
			favorites = @logic.FavoritesRead(cgi)
			erb = ERB.new(@FavoritesInputView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#画像管理の編集画面
	def ImageWriteInputView(cgi)
		if(@logic.LoginChk(cgi) == 1)
			imglist = @logic.ImageListGet(cgi)
			
			erb = ERB.new(@ImgInputView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#休日・祝日設定画面
	def HolidayWriteInputView(cgi)
		if(@logic.LoginChk(cgi) == 1)
			(holiday_read,holiday_info) = @logic.HolidayRead(cgi)
			
			erb = ERB.new(@HolidayInputView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#返信一覧画面
	def ResArticleList(cgi)
		if(@logic.LoginChk(cgi) == 1)
			child_list = @logic.ChildArticleRead(cgi)
			
			erb = ERB.new(@ResArticleListView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#TrackBack 一覧画面
	def TrackBackList(cgi)
		if(@logic.LoginChk(cgi) == 1)
			trackback = @logic.TrackBackRead(cgi)
			
			erb = ERB.new(@TrackBackListView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#左自由入力欄編集画面
	def LeftSideWriteInput(cgi)
		if(@logic.LoginChk(cgi) == 1)
			left = @logic.LeftFreeInputRead
			
			erb = ERB.new(@LeftFreeInputView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#右自由入力欄編集画面
	def RightSideWriteInput(cgi)
		if(@logic.LoginChk(cgi) == 1)
			right = @logic.RightFreeInputRead
			
			erb = ERB.new(@RightFreeInputView)
			return erb.result(binding)
		else
			return PassInput(cgi)
		end
	end
	
	#返信プレビュー
	def ResPreview(cgi)
		erb = ERB.new(@ResPreview)
		return erb.result(binding)
	end
	
	#RSSフィールド
	def RssView(cgi)
		(parent_list,parent_year_month_day,parentid) = @logic.ParentArticleRead(cgi)
		puts "Content-type: text/xml; charset=utf-8\n\n"
		puts <<"__END"
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
<title>#{h @yaml['Title']}</title>
<link>#{h @yaml['Url']}</link>
<language>ja</language>
<description>#{h @yaml['Description']}</description>
__END
		cnt = 0
		parent_list.each_index do |cnt|
			subject = @logic.SubjectConvert(parent_list[cnt]['subject'])
			article = @logic.ParentArticleConvert(parent_list[cnt]['article']).gsub(/\]\]/,"\\]\\]")
			year = parent_list[cnt]['created_at'][0..3]
			month = parent_list[cnt]['created_at'][4..5]
			day = parent_list[cnt]['created_at'][6..7]
			hour = parent_list[cnt]['created_at'][8..9]
			min = parent_list[cnt]['created_at'][10..11]
			sec = parent_list[cnt]['created_at'][12..13]
			#曜日を得る
			wday = @logic.GetWday(year,month,day)
			
			youbi = @WdayView[wday]
			tsuki = @MonthView[month.to_i - 1]
			puts <<"__END"
<item>
<title>#{subject}</title>
<description><![CDATA[#{article}]]></description>
<link><![CDATA[#{@yaml['Url']}?edit_num=#{parent_list[cnt]['id']}]]></link>
<guid><![CDATA[#{@yaml['Url']}?edit_num=#{parent_list[cnt]['id']}]]></guid>
<pubDate>#{youbi}, #{day} #{tsuki} #{year} #{hour}:#{min}:#{sec} +0900</pubDate>
</item>
__END
			cnt = cnt + 1
			if(cnt > 10)
				break
			end
		end
		puts <<"__END"
</channel>
</rss>
__END
	end
end
