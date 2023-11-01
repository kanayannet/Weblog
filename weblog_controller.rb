class Controller

#*******************    初期設定(yamlファイルのpath)      *******************

#ブラウザで見れない場所に設置することをお勧めします
Yaml = 'weblog.yml'

#*******************     初期設定ここまで          *********************************


	#初期設定ライブラリ
	require 'yaml'
	require 'cgi'
	require './weblog_view.rb'
	require './weblog_logic.rb'
	def initialize(flag)
	  begin
	    #YMLのpathを変えたいときは下記の行を変更する
	    @yaml = YAML.load_file(Yaml)
	  rescue
	    error('YAMLファイルがありません。')
	    
	  end
	  if(flag == 'not_cgi')
	  else
	  	@cgi = CGI.new
	  end
	  
	end
	
	def yaml
	  return @yaml
	end
	
	def Output
	  
	  #TrackBack 受信
	  tr_query = ENV['QUERY_STRING']
	  if(/.*?mode\=TrRes&edit_num\=(\d+)/=~tr_query)
	  	edit_num = $1
	  	WeblogLogic.new.TrackBackWrite(edit_num,@cgi)
	  	
	  	exit
	  end
	  
	  view = WeblogView.new
	  
	  
	  if(@cgi['mode'] == '')
	    #Top Page を出力する
	    return view.TopPageAllView(@cgi)
	  end
	  if(@cgi['mode'] == 'mente_top')
	  	#MenteTopを出す
	  	return view.MenteTop(@cgi)
	  end
	  
	  if(@cgi['mode'] == 'ArticleWriteInput')
	  	#記事入力欄を表示
	  	return view.MenteArticleInput(@cgi)
	  end
	  
	  if(@cgi['mode'] == 'ArticleInputExec')
	  	#記事投稿実行処理
	  	if(@cgi['article_preview'] != "")
	  		return view.ArticlePreview(@cgi)
	  	else
	  		num = WeblogLogic.new.ArticleWrite(@cgi)
	  		puts "location: #{@yaml['Url']}?edit_num=#{num}\n\n"
	  		exit
	  	end
	  end
	  
	  #記事一覧表示
	  if(@cgi['mode'] == 'ArticleList')
	  	return view.ArticleList(@cgi)
	  end
	  
	  #記事編集モード
	  if(@cgi['mode'] == 'ChangeOrDelete')
	  	if(@cgi['change'] != '')
	  		return view.MenteArticleInput(@cgi)
	  	elsif(@cgi['deleted'] != '')
	  		num = WeblogLogic.new.ArticleWrite(@cgi)
	  		puts "location: #{@yaml['Url']}?mode=ArticleList\n\n"
	  		exit
	  	end
	  end
	  
	  #プロフィール設定画面
	  if(@cgi['mode'] == 'ProfileWriteInput')
	  	return view.ProfileInputView(@cgi)
	  end
	  
	  if(/^multipart\/form-data/=~ENV['CONTENT_TYPE'])
		  #プロフィールの設定 or preview
		  mode = @cgi.params['mode'][0].read
		  if(mode == 'ProfileExec')
		  	if(@cgi.params['profile_preview'][0].read == '1')
		  		return view.ProfilePreview(@cgi)
		  	else
		  		WeblogLogic.new.ProfileWrite(@cgi)
		  		puts "location: #{@yaml['Url']}?mode=profile\n\n"
		  		exit
		  	end
		  end
		  #画像管理の設定処理
		  if(mode == 'ImgExec')
			  WeblogLogic.new.ImageWrite(@cgi)
			  winopen_flag = ""
			  if(@cgi.params['winopen_flag'][0])
			  	winopen_flag = @cgi.params['winopen_flag'][0].read
			  end
			  puts "location: #{@yaml['Url']}?mode=ImageWriteInput&winopen_flag=#{winopen_flag}\n\n"
		  	  exit
		  end
		  
	  end
	  
	  #プロフィール画面
	  if(@cgi['mode'] == 'profile')
	  	return view.ProfileView(@cgi)
	  end
	  
	  #返信処理
	  if(@cgi['mode'] == 'Res')
	  	if(@cgi['ResPreviewSubmit'] != '')
	  		return view.ResPreview(@cgi)
	  	else
	  		WeblogLogic.new.ResArticleWrite(@cgi)
			puts "location: #{@yaml['Url']}?edit_num=#{@cgi['edit_num']}\n\n"
		  	exit
	  	end
	  end
	  
	  #お気に入り設定画面
	  if(@cgi['mode'] == 'FavoriteWriteInput')
	  	return view.FavoriteInputView(@cgi)
	  end
	  
	  #お気に入り設定処理
	  if(@cgi['mode'] == 'FavoriteExec')
	  	WeblogLogic.new.FavoriteWrite(@cgi)
	  	puts "location: #{@yaml['Url']}\n\n"
	  	exit
	  end
	  
	  #画像管理画面の設定画面
	  if(@cgi['mode'] == 'ImageWriteInput')
	  	return view.ImageWriteInputView(@cgi)
	  end
	  
	  #祝日休日設定画面
	  if(@cgi['mode'] == 'HolidayWriteInput')
	  	return view.HolidayWriteInputView(@cgi)
	  end
	  
	  #祝日設定処理
	  if(@cgi['mode'] == 'CalExec')
	  	WeblogLogic.new.HolidayWrite(@cgi)
	  	puts "location: #{@yaml['Url']}?mode=HolidayWriteInput\n\n"
	  	exit
	  end
	  
	  #返信一覧から管理画面
	  if(@cgi['mode'] == 'ResArticleList')
	  	return view.ResArticleList(@cgi)
	  end
	  
	  #返信削除処理
	  if(@cgi['mode'] == 'ResArticleDelete')
	  	WeblogLogic.new.ResArticleDelete(@cgi)
	  	puts "location: #{@yaml['Url']}?mode=ResArticleList\n\n"
	  	exit
	  end
	  
	  #TrackBack一覧画面
	  if(@cgi['mode'] == 'TrackBackList')
	  	return view.TrackBackList(@cgi)
	  end
	  
	  #TrackBack削除処理
	  if(@cgi['mode'] == 'TrackBackDelete')
	  	WeblogLogic.new.TrackBackDelete(@cgi)
	  	puts "location: #{@yaml['Url']}?mode=TrackBackList\n\n"
	  	exit
	  end
	  
	  #左サイド自由入力欄編集画面
	  if(@cgi['mode'] == 'LeftSideWriteInput')
	  	return view.LeftSideWriteInput(@cgi)
	  end
	  
	  #左サイド入力実行処理
	  if(@cgi['mode'] == 'LeftFreeExec')
	  	WeblogLogic.new.LeftFreeExec(@cgi)
	  	puts "location: #{@yaml['Url']}?mode=LeftSideWriteInput\n\n"
	  	exit
	  end
	  
	  #右サイド自由入力欄編集画面
	  if(@cgi['mode'] == 'RightSideWriteInput')
	  	return view.RightSideWriteInput(@cgi)
	  end
	  
	  #右サイド入力実行処理
	  if(@cgi['mode'] == 'RightFreeExec')
	  	WeblogLogic.new.RightFreeExec(@cgi)
	  	puts "location: #{@yaml['Url']}?mode=RightSideWriteInput\n\n"
	  	exit
	  end
	  
	  #Rss出力
	  if(@cgi['mode'] == 'Rss')
	  	view.RssView(@cgi)
	  	exit
	  end
	  
	  
	  error("不正な処理です")
	  
	end
	
	#正常処理のエラーメッセージ
	def nomal_error(errstr)
		view = WeblogView.new
		puts "content-type:text/html\n\n"
		puts <<"__END"
		#{view.PageHeadView}
		<div id="pass_input">
		<b><font color="#FF0000">#{errstr}</font></b><br><br>
		<input type="button" onclick="history.back();" value="戻る">
		</div>
		#{view.PageFootView}
__END
		exit
	end

	#テンプレートファイル不正処理の強制エラーメッセージ
	def error(errstr)
	  puts "content-type:text/html\n\n"
	  puts <<"__END"
	  <html>
	  <head> 
	  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"> 
	  <meta http-equiv="paragma" content="no-cache">
	  </head>
	  <body>
	  <center>
	  <br><br>
	  <table border="1"><tr><td>
	  <font size="3" color="#FF0000"><b>
	  #{errstr}
	  </b></font>
	  </td></tr></table>
	  </center>
	  </body>
	  </html>
__END
	  exit
	end
	
	#TrackBack のエラー
	def tr_error
	  	puts "Content-Type: text/xml\n\n"
	  	puts <<"__END"
<?xml version="1.0" encoding="utf-8"?>
<response>
<error>1</error>
<message>Something Bad happened.</message>
</response>
__END
		exit
	end
	
end
