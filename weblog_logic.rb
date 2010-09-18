class WeblogLogic
	#Weblog用のロジックのライブラリ
	require 'weblog_controller.rb'
	require 'erb'
	include ERB::Util
	def initialize
	  #現在の時刻をクラス変数に入れる
	  
	  ltime = Time.now.to_a
	  @year = ltime[5].to_s
	  @month = sprintf("%02d",ltime[4].to_s)
	  @day = sprintf("%02d",ltime[3].to_s)
	  @hour = sprintf("%02d",ltime[2].to_s)
	  @min = sprintf("%02d",ltime[1].to_s)
	  @sec = sprintf("%02d",ltime[0].to_s)
	  @now = "#{@year}#{@month}#{@day}#{@hour}#{@min}#{@sec}"
	  
	  @cont = Controller.new('not_cgi')
	  @yaml = @cont.yaml
	  
	end
	attr_reader :year, :month, :day, :hour, :min, :sec
	
	#**********************************************************************
	#
	#	休日データの読み込み
	#	(holiday_read,holiday_info) = @logic.HolidayRead(cgi)
	#	holiday_read[0]['id'] = ID
	#	holiday_read[0]['year'] = '年'
	#	holiday_read[0]['month'] = '月'
	#	holiday_read[0]['day'] = 日
	#	holiday_info["年_月_日"] = 1
	#**********************************************************************
	def HolidayRead(cgi)
		holiday_read = Array.new
		holiday_info = Hash.new
		begin
			file = File.open(@yaml['HolidayFile'],"r")
			file.flock(File::LOCK_SH)
			cnt = 0
			while rec = file.gets
				(id,year,month,day) = rec.split(/\t/)
				holiday_read[cnt] = Hash.new
				holiday_read[cnt]['id'] = id
				holiday_read[cnt]['year'] = year
				holiday_read[cnt]['month'] = month
				holiday_read[cnt]['day'] = day
				holiday_info["#{year}_#{month}_#{day}"] = 1
				cnt = cnt + 1
			end
			file.flock(File::LOCK_UN)
			file.close
		rescue
		end
		return holiday_read,holiday_info
	end
	#**********************************************************************
	#
	#	休日設定の書き込み
	#	@logic.HolidayWrite(cgi)
	#
	#**********************************************************************
	def HolidayWrite(cgi)
		
		#引数チェック
		if(LoginChk(cgi) == 0)
			@cont.nomal_error('ログインして下さい。');
		end
		
		if((cgi['year'] != "")||(cgi['month'] != "")||(cgi['day'] != ""))
			if(/^\d+$/=~cgi['year'])
			else
				@cont.nomal_error('年が間違っています。')
			end
			if(/^\d+$/=~cgi['month'])
			else
				@cont.nomal_error('月が間違っています。')
			end
			if(/^\d+$/=~cgi['day'])
			else
				@cont.nomal_error('日が間違っています。')
			end
		end
		
		#新規書き込みフラグ
		rec_flag = 0
		if((cgi['year'] != "")&&(cgi['month'] != "")&&(cgi['day'] != ""))
			cal_info = GetCalInfo(cgi['year'],cgi['month'])
			if(cal_info['EndMonthDay'].to_i < cgi['day'].to_i)
				@cont.nomal_error("#{cgi['year']}年#{cgi['month']}月は#{cal_info['EndMonthDay']}日までです。")
			end
			rec_flag = 1
		end
		begin 
			if(File.exist?(@yaml['HolidayFile']))
				file = File.open(@yaml['HolidayFile'],"r+")
				file.flock(File::LOCK_EX)
				file_read = Array.new
				#1レコード目を拾う
				one_rec = file.gets
				file.rewind
				#新しいIDを拾う
				num = 0
				new_rec = ""
				if(rec_flag == 1)
					if(one_rec != nil)
						num = one_rec.split(/\t/)[0].to_i + 1
					else
						num = 1
					end
					new_rec = "#{num}\t#{cgi['year']}\t#{cgi['month']}\t#{cgi['day']}\t\n"
					
				end
				cnt = 0
				while rec = file.gets
					(id,year,month,day) = rec.split(/\t/)
					if(cgi["cal_#{id}"] == '1')
						next
					end
					file_read[cnt] = rec
					cnt = cnt + 1
				end
				
				data = file_read.join("")
				if(rec_flag == 1)
					data = "#{new_rec}#{data}"
				end
				file.rewind
				file.truncate( 0 )
				if(data != "")
					file.puts data
				end
				file.flock(File::LOCK_UN)
				file.close
			else
				file = File.open(@yaml['HolidayFile'],"w")
				file.flock(File::LOCK_EX)
				if(rec_flag == 1)
					file.puts "1\t#{cgi['year']}\t#{cgi['month']}\t#{cgi['day']}\t\n"
				end
				file.flock(File::LOCK_UN)
				file.close
				File.chmod(0666,@yaml['HolidayFile'])
			end
		rescue
			@cont.nomal_error('休日ファイルの書き込みに失敗しました。')
		end
	end
	#**********************************************************************
	#
	#	プロフィール書き込み処理
	#	@logic.ProfileWrite(cgi)
	#
	#
	#**********************************************************************
	def ProfileWrite(cgi)
		
		#引数チェック
		if(LoginChk(cgi) == 0)
			@cont.nomal_error('ログインして下さい。');
		end
		
		name = TabCrlfEscape(cgi.params['name'][0].read)
		if(!name)
			@cont.nomal_error('お名前がありません。')
		end
		url = TabCrlfEscape(cgi.params['url'][0].read)
		if(url != '')
			if(/^(http[s]?\:\/\/[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)$/=~url)
			else
				@cont.nomal_error('URLが正しくありません。');
			end
		end
		hobby = TabCrlfEscape(cgi.params['hobby'][0].read)
		profile = TabCrlfConvert(cgi.params['profile_text'][0].read)
		img = cgi.params['image'][0]
		width = TabCrlfEscape(cgi.params['width'][0].read)
		height = TabCrlfEscape(cgi.params['height'][0].read)
		#textDBに保存する画像ファイル名
		db_image_file = ''
		if(img.original_filename != "")
			element = img.content_type
			#画像ファイル名
			image_file = ''
			if(/jpeg/=~element)
				image_file = "#{@yaml['ImageFileDir']}profile.jpg"
				db_image_file = "profile.jpg"
			elsif(/gif/=~element)
				image_file = "#{@yaml['ImageFileDir']}profile.gif"
				db_image_file = "profile.gif"
			elsif(/png/=~element)
				image_file = "#{@yaml['ImageFileDir']}profile.png"
				db_image_file = "profile.png"
			else
				@cont.nomal_error('画像のファイルではありません。')
			end
			begin
				file = File.open("#{image_file}",'w')
				file.flock(File::LOCK_EX)
				file.puts img.read
				file.flock(File::LOCK_UN)
				file.close
				File.chmod(0666,image_file)
			rescue
				@cont.nomal_error('画像のファイルが作成できませんでした。')
			end
		end
		#ここで書き込み
		begin
			file = File.open("#{@yaml['ProfileFile']}",'w')
			file.flock(File::LOCK_EX)
			file.puts <<"__END"
#{name}
#{url}
#{hobby}
#{profile}
#{db_image_file}
#{width}
#{height}
__END
			file.flock(File::LOCK_UN)
			file.close
			File.chmod(0666,@yaml['ProfileFile'])
		rescue
			@cont.nomal_error('プロフィールファイルが作成できませんでした。')
		end
	end
	
	#**********************************************************************
	#
	#	プロフィールのデータを取得する
	#	(name,url,hobby,profile,image,width,height) = @logic.ProfileGet(cgi)
	#	name :名前
	#	url :URL
	#	hobby :趣味
	#	profile :一言メモ
	#	image :画像URL
	#	width :画像の横幅
	#	height :画像の縦幅
	#**********************************************************************
	def ProfileGet(cgi)
		name = ""
		url = ""
		hobby = ""
		profile = ""
		image = ""
		width = ""
		height = ""
		begin
			open(@yaml['ProfileFile']) do |file|
				file.flock(File::LOCK_SH)
		      	name = file.gets.to_s.gsub(/\r\n|\r|\n/, "")
		      	url = file.gets.to_s.gsub(/\r\n|\r|\n/, "")
		      	hobby = file.gets.to_s.gsub(/\r\n|\r|\n/, "")
		      	profile = file.gets.to_s.gsub(/\r\n|\r|\n/, "")
		      	if(profile != "")
		      		profile = profile.gsub(/<br>/, "\n")
		      	end
		      	image = file.gets.to_s.gsub(/\r\n|\r|\n/, "")
		      	if(image != "")
		      		image = "#{@yaml['ImageFileUrl']}#{image}"
		      	end
		      	width = file.gets.to_s.gsub(/\r\n|\r|\n/, "")
		      	height = file.gets.to_s.gsub(/\r\n|\r|\n/, "")
		      	file.flock(File::LOCK_UN)
				file.close
			end
		rescue
		end
		return name,url,hobby,profile,image,width,height
	end
	
	#**********************************************************************
	#
	#	imglist = @logic.ImageListGet(cgi)
	#	imglist[0]['id'] = ID
	#	imglist[0]['imgname'] = 画像名
	#	
	#**********************************************************************
	def ImageListGet(cgi)
		imglist = Array.new
		if(File.exist?(@yaml['ImgListFile']))
			begin
				file = File.open(@yaml['ImgListFile'],'r')
				file.flock(File::LOCK_SH)
				cnt = 0
				while rec = file.gets
					rec = rec.gsub(/\n|\r/,"");
					if(rec == '')
						next
					end
					(id,imgfile) = rec.split(/\t/)
					imglist[cnt] = Hash.new
					imglist[cnt]['id'] = id
					imglist[cnt]['imgname'] = imgfile
					cnt = cnt + 1
				end
				file.flock(File::LOCK_UN)
				file.close
			rescue
				@cont.nomal_error('画像管理ファイルが開けませんでした。')
			end
		end
		return imglist
	end
	#**********************************************************************
	#
	#	@logic.ImageWrite(cgi)
	#	画像管理画面からのアップ処理
	#	
	#**********************************************************************
	def ImageWrite(cgi)
		#引数チェック
		if(LoginChk(cgi) == 0)
			@cont.nomal_error('ログインして下さい。');
		end
		num = 0
		begin
			#ファイルが無ければ生成する + ID を得る
			if(File.exist?(@yaml['ImgListFile']))
				file = File.open(@yaml['ImgListFile'],'r')
				file.flock(File::LOCK_SH)
				get = file.gets
				if(get != nil)
					num = get.split(/\t/)[0].to_i + 1
				end
				file.flock(File::LOCK_UN)
				file.close
			else
				num = 1
				file = File.open(@yaml['ImgListFile'],'w')
				file.flock(File::LOCK_SH)
				file.flock(File::LOCK_UN)
				file.close
				File.chmod(0666,@yaml['ImgListFile'])
			end
		rescue
			@cont.nomal_error('画像管理ファイルが処理出来ませんでした。')
		end
		img = cgi.params['image'][0]
		#textDBに保存する画像ファイル名
		db_image_file = ''
		if(img.original_filename != "")
			element = img.content_type
			#画像ファイル名
			image_file = ''
			if(/jpeg/=~element)
				image_file = "#{@yaml['ImageFileDir']}#{num}.jpg"
				db_image_file = "#{num}.jpg"
			elsif(/gif/=~element)
				image_file = "#{@yaml['ImageFileDir']}#{num}.gif"
				db_image_file = "#{num}.gif"
			elsif(/png/=~element)
				image_file = "#{@yaml['ImageFileDir']}#{num}.png"
				db_image_file = "#{num}.png"
			else
				@cont.nomal_error('画像のファイルではありません。')
			end
			begin
				if(File.exist?(@yaml['ImageFileDir']))
				else
					Dir::mkdir(@yaml['ImageFileDir'],0777)
					File.chmod(0777,@yaml['ImageFileDir'])
				end
				file = File.open("#{image_file}",'w')
				file.flock(File::LOCK_EX)
				file.puts img.read
				file.flock(File::LOCK_UN)
				file.close
				File.chmod(0666,image_file)
			rescue
				@cont.nomal_error('画像のファイルが作成できませんでした。')
			end
		end
		begin
			
			file = File.open(@yaml['ImgListFile'],'r+')
			file.flock(File::LOCK_EX)
			data_list = Array.new
			i = 0
			edit_num = ""
			while rec = file.gets
				(imgnum,img) = rec.split(/\t/)
				if(cgi.params["#{imgnum}"][0] != nil)
					edit_num = cgi.params["#{imgnum}"][0].read
					if(edit_num == '1')
						#削除
						if(File.exist?("#{@yaml['ImageFileDir']}#{img}"))
							File.unlink("#{@yaml['ImageFileDir']}#{img}")
						end
						next
					end
				end
				data_list[i] = rec
				i = i + 1
			end
			data = data_list.join("")
			
			if(db_image_file != "")
				data = "#{num}\t#{db_image_file}\t\n#{data}"
			end
			
			file.rewind
			file.truncate( 0 )
			file.puts data
			file.flock(File::LOCK_UN)
			file.close

		rescue
			@cont.nomal_error('画像管理ファイルが処理出来ませんでした。')
		end
	end
	#**********************************************************************
	#
	#	プロフィールのプレビューのための引数Get
	#	(name,url,hobby,profile,image,width,height) = @logic.ProfilePreviewGet(cgi)
	#	name :名前
	#	url :URL
	#	hobby :趣味
	#	profile :一言メモ
	#	image :画像URL
	#	width :画像の横幅
	#	height :画像の縦幅
	#**********************************************************************
	def ProfilePreviewGet(cgi)
		name = cgi.params['name'][0].read
		if(!name)
			@cont.nomal_error('お名前がありません。')
		end
		url = cgi.params['url'][0].read
		if(url != "")
			if(/^(http[s]?\:\/\/[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)$/=~url)
			else
				@cont.nomal_error('URLが正しくありません。');
			end
		end
		hobby = cgi.params['hobby'][0].read
		profile = cgi.params['profile_text'][0].read
		img = cgi.params['image'][0]
		image = ''
		width = cgi.params['width'][0].read
		height = cgi.params['height'][0].read
		if(img.original_filename != "")
			element = img.content_type
			#画像ファイル名
			image_file = ''
			if(/jpeg/=~element)
				image_file = "#{@yaml['ImageFileDir']}preview_image.jpg"
				image = "#{@yaml['ImageFileUrl']}preview_image.jpg"
			elsif(/gif/=~element)
				image_file = "#{@yaml['ImageFileDir']}preview_image.gif"
				image = "#{@yaml['ImageFileUrl']}preview_image.gif"
			elsif(/png/=~element)
				image_file = "#{@yaml['ImageFileDir']}preview_image.png"
				image = "#{@yaml['ImageFileUrl']}preview_image.png"
			else
				@cont.nomal_error('画像のファイルではありません。')
			end
			
			begin
				if(File.exist?(@yaml['ImageFileDir']))
				else
					Dir::mkdir(@yaml['ImageFileDir'],0777)
					File.chmod(0777,@yaml['ImageFileDir'])
				end
				file = File.open("#{image_file}",'w')
				file.flock(File::LOCK_EX)
				file.puts img.read
				file.flock(File::LOCK_UN)
				file.close
				File.chmod(0666,image_file)
			rescue
				@cont.nomal_error('画像のファイルが作成できませんでした。')
			end
		end
		return name,url,hobby,profile,image,width,height
	end
	
	#**********************************************************************
	#
	#	記事の書き込み
	#	num = ArticleWrite(cgi)
	#	num: 記事Num
	#**********************************************************************
	def ArticleWrite(cgi)
		#引数チェック(削除モード以外)
		if(LoginChk(cgi) == 0)
			@cont.nomal_error('ログインして下さい。');
		end
		if(cgi['deleted'] != '')
		else
			ParamCheck(cgi)
		end
		subject = TabCrlfEscape(cgi['subject'])
		article = TabCrlfConvert(cgi['article'])
		num = 0
		begin
			
			if(File.exist?(@yaml['ParentArticleFile']))
	    	else
	    		file = File.open(@yaml['ParentArticleFile'],"w")
	    		file.flock(File::LOCK_EX)
	    		file.flock(File::LOCK_UN)
	    		file.close
	    		File.chmod(0666,@yaml['ParentArticleFile'])
	    	end
			file = File.open("#{@yaml['ParentArticleFile']}", "r+")
			file.flock(File::LOCK_EX)
			data = file.read
			if(cgi['edit_num'] != '')
				#記事編集 or delete
				edit_num = cgi['edit_num'].to_s
				data_list = data.split(/\n/)
				i = 0
				data_list.each do |rec|
					num = rec.split(/\t/)[0]
					if(num == edit_num)
						created_at = rec.split(/\t/)[1]
						if(cgi['deleted'] != '')
							#記事delete
							data_list.delete_at(i)
						else
							#記事編集
							data_list[i] = "#{num}\t#{created_at}\t#{@now}\t#{subject}\t#{article}\t#{ENV['REMOTE_ADDR']}\t"
						end
						break
					end
					i = i + 1
				end
				file.rewind
				file.truncate( 0 )
				file.puts data_list.join("\n")
			else
				#新規書き込み
				if(data.split(/\n/)[0] != nil)
					num = data.split(/\n/)[0].split(/\t/)[0].to_i + 1
				else
					num = 1
				end
				data = data.split(/\n/)[0..@yaml['LimitParRec'] - 2].join("\n")
				rec = "#{num}\t#{@now}\t#{@now}\t#{subject}\t#{article}\t#{ENV['REMOTE_ADDR']}\t\n"
				file.rewind
				file.truncate( 0 )
				file.puts rec
				file.puts data
			end
			file.flock(File::LOCK_UN)
			file.close
			File.chmod(0666,@yaml['ParentArticleFile'])
		rescue
			@cont.nomal_error('記事のファイルに書き込みが出来ませんでした。');
		end
		return num
	end
	
	#**********************************************************************
	#
	#	書き込み時の引数のチェック
	#	ParamCheck(cgi)
	#
	#
	#**********************************************************************
	def ParamCheck(cgi)
		if(cgi['subject'] == '')
			@cont.nomal_error('タイトルが未入力です。');
		end
		if(cgi['article'] == '')
			@cont.nomal_error('記事が未入力です。');
		end
		
	end
	#**********************************************************************
	#
	#	ログインしたかどうかのチェック
	#	ret = LoginChk(cgi)
	#	ret = 1(ok) 0(ng)
	#
	#
	#
	#**********************************************************************
	def LoginChk(cgi)
	  	pass = cgi.cookies[@yaml['CookieIdName']][0]
	  	if(pass.to_s == @yaml['PassWord'].to_s)
	  		return 1
	  	else
	  		return 0
	  	end
	end
	
	#**********************************************************************
	#
	#	ログインをセットする
	#	ret = LoginSet(cgi)
	#	ret = 1(ok) 0(ng)
	#
	#**********************************************************************
	def LoginSet(cgi)
		if(@yaml['PassWord'].to_s == cgi['InputPass'].to_s)
			puts "Set-Cookie: #{@yaml['CookieIdName']}=#{@yaml['PassWord']};Path=/;\n"
			return 1
		else
			return 0
		end
	end
	
	#**********************************************************************
	#
	#	@logic.TrackBackDelete(cgi)
	#	トラックバック削除
	#
	#**********************************************************************
	def TrackBackDelete(cgi)

		if(LoginChk(cgi) == 0)
			@cont.nomal_error('ログインして下さい。');
		end

		begin
	    	file = File.open(@yaml['TrackBackFile'],"r+")
	    	file.flock(File::LOCK_EX)
			data_list = Array.new
			cnt = 0
			while rec = file.gets
				num = rec.split(/\t/)[0]
				if(cgi["#{num}"] == '1')
					#削除
					next
				end
				data_list[cnt] = rec
				cnt = cnt + 1
			end
			data = data_list.join("\n")
			file.rewind
			file.truncate( 0 )
			file.puts data
			file.flock(File::LOCK_UN)
	    	file.close
	    rescue
	    	@cont.nomal_error('TrackBackのファイルに書き込みが出来ませんでした。');
	    end
	end
	
	#**********************************************************************
	#
	#	TrackBack書き込み
	#	TrackBackWrite(edit_num,@cgi)
	#	edit_num : 記事ID
	#
	#**********************************************************************
	def TrackBackWrite(edit_num,cgi)
		
		#引数チェック
		if((cgi['blog_name'] == '')||(cgi['blog_name'].split(//u).length > @yaml['LimitTrackBackStr'].to_i))
	  		@cont.tr_error()
	  	end
	  	
	  	if((cgi['title'] == '')||(cgi['title'].split(//u).length > @yaml['LimitTrackBackStr'].to_i))
	  		@cont.tr_error()
	  	end
	  	
	  	if((/^(http[s]?\:\/\/[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)$/=~cgi['url'])||(cgi['url'].split(//u).length > @yaml['LimitTrackBackStr'].to_i))
	  	else
	  		@cont.tr_error()
	  	end
	  	
	  	if((cgi['excerpt'] == '')||(cgi['excerpt'].split(//u).length > @yaml['LimitTrackBackStr'].to_i))
	  		@cont.tr_error()
	  	end
	  	
	  	name = TabCrlfEscape(cgi['blog_name'])
	  	title = TabCrlfEscape(cgi['title'])
	  	url = TabCrlfEscape(cgi['url'])
	  	excerpt = TabCrlfConvert(cgi['excerpt'])
	  	
	  	begin
	    	if(File.exist?(@yaml['TrackBackFile']))
	    		file = File.open(@yaml['TrackBackFile'],'r+')
	    		file.flock(File::LOCK_EX)
	    		rec = file.gets
	    		file.rewind
	    		num = 1
	    		if(rec != "")
	    			num = rec.split(/\t/)[0].to_i + 1
	    		end
	    		
	    		data = file.read.split(/\n/)[0..@yaml['LimitTrRecord'].to_i - 2].join("\n")
	    		data = "#{num}\t#{edit_num}\t#{@now}\t#{@now}\t#{name}\t#{title}\t#{excerpt}\t#{url}\t#{ENV['REMOTE_ADDR']}\t\n#{data}"
	    		file.rewind
	    		file.truncate(0)
	    		file.puts data
	    		file.flock(File::LOCK_UN)
	    		file.close
	    	else
	  			file = File.open(@yaml['TrackBackFile'],'w')
	  			file.flock(File::LOCK_EX)
	  			file.puts "1\t#{edit_num}\t#{@now}\t#{@now}\t#{name}\t#{title}\t#{excerpt}\t#{url}\t#{ENV['REMOTE_ADDR']}\t\n"
	  			file.flock(File::LOCK_UN)
	  			file.close
	  		end
	  		
	  		puts "Content-Type: text/xml\n\n"
	  		puts <<"__END"
<?xml version="1.0" encoding="utf-8"?>
<response>
<error>0</error>
<message>Ping saved successfully.</message>
</response>
__END
	  		exit
	  	rescue
	  		@cont.tr_error()
	  	end
	end
	#**********************************************************************
	# 
	# TrackBackファイルの読み込み
	# 呼び方: trackback = TrackBackRead(cgi)
	# trackback[0]['id'] = 記事ID
	# trackback[0]['parid'] = 親記事ID
	# trackback[0]['created_at'] = 投稿日時
	# trackback[0]['updated_at'] = 更新日時
	# trackback[0]['name'] = 名前
	# trackback[0]['subject'] = 記事タイトル
	# trackback[0]['article'] = 記事
	# ......
	#
	#**********************************************************************
	def TrackBackRead(cgi)
	  trackback = Array.new
	  cnt = 0
	  begin
	    File.open(@yaml['TrackBackFile']) do |tra|
	      tra.flock(File::LOCK_SH)
	      while rec = tra.gets
	       if(/^\D/=~rec)
	          next
	        end
	        (id,parid,created_at,updated_at,name,subject,article,url) = rec.split(/\t/)
	        trackback[cnt] = Hash.new
	        trackback[cnt]['id'] = id
	        trackback[cnt]['parid'] = parid
	        trackback[cnt]['created_at'] = created_at
	        trackback[cnt]['updated_at'] = updated_at
	        trackback[cnt]['name'] = name
	        trackback[cnt]['subject'] = subject
	        trackback[cnt]['article'] = article
	        trackback[cnt]['url'] = url
	        cnt = cnt + 1
	      end
	      tra.flock(File::LOCK_UN)
	      tra.close
	    end
	  rescue
	  end
	  return trackback
	end
	
	#**********************************************************************
	#
	#	子記事の書き込み
	#	@logic.ResArticleWrite(cgi)
	#
	#**********************************************************************
	def ResArticleWrite(cgi)
		
		if(/^\d+$/=~cgi['edit_num'])
		else
			@cont.nomal_error('不正なアクセスです。');
		end
		subject = TabCrlfEscape(cgi['subject'])
		name = TabCrlfEscape(cgi['name'])
		comment = TabCrlfConvert(cgi['comment'])
		
		#引数チェック
		if((cgi['subject'] == "")||(cgi['subject'].split(//u).length > @yaml['LimitResStr'].to_i))
			@cont.nomal_error('「Subject」の文字数が多いか、入力されていません。')
		end
		
		if((cgi['name'] == "")||(cgi['name'].split(//u).length > @yaml['LimitResStr'].to_i))
			@cont.nomal_error('「Name」の文字数が多いか、入力されていません。')
		end
		
		if((cgi['comment'] == "")||(cgi['comment'].split(//u).length > @yaml['LimitResStr'].to_i))
			@cont.nomal_error('「Comment」の文字数が多いか、入力されていません。')
		end
		
		
		begin
	    	if(File.exist?(@yaml['ChildArticleFile']))
	    	else
	    		file = File.open(@yaml['ChildArticleFile'],"w")
	    		file.flock(File::LOCK_EX)
	    		file.flock(File::LOCK_UN)
	    		file.close
	    		File.chmod(0666,@yaml['ChildArticleFile'])
	    	end
	    	file = File.open(@yaml['ChildArticleFile'],"r+")
	    	file.flock(File::LOCK_EX)
			num = 1
			rec = file.gets
			file.rewind
			if(rec != nil)
				num = rec.split(/\t/)[0].to_i + 1
			end
			data = file.read.split(/\n/)[0..@yaml['LimitResRecord'].to_i - 2].join("\n")
			
			data = "#{num}\t#{cgi['edit_num']}\t#{@now}\t#{@now}\t#{name}\t#{subject}\t#{comment}\t#{ENV['REMOTE_ADDR']}\t\n#{data}"
			file.rewind
			file.truncate( 0 )
			file.puts data
			file.flock(File::LOCK_UN)
	    	file.close
	    	File.chmod(0666,@yaml['ChildArticleFile'])
	    rescue
	    	@cont.nomal_error('返信記事のファイルに書き込みが出来ませんでした。');
	    end
	end
	
	
	#**********************************************************************
	#
	#	子記事の削除
	#	@logic.ResArticleDelete(cgi)
	#
	#**********************************************************************
	def ResArticleDelete(cgi)
		
		if(LoginChk(cgi) == 0)
			@cont.nomal_error('ログインして下さい。');
		end
		
		begin
	    	file = File.open(@yaml['ChildArticleFile'],"r+")
	    	file.flock(File::LOCK_EX)
			data_list = Array.new
			cnt = 0
			while rec = file.gets
				num = rec.split(/\t/)[0]
				if(cgi["#{num}"] == '1')
					#削除
					next
				end
				data_list[cnt] = rec
				cnt = cnt + 1
			end
			data = data_list.join("")
			file.rewind
			file.truncate( 0 )
			file.puts data
			file.flock(File::LOCK_UN)
	    	file.close
	    rescue
	    	@cont.nomal_error('返信記事のファイルに書き込みが出来ませんでした。');
	    end
	end
	#**********************************************************************
	# 
	# 子供記事の読み込み
	# 呼び方: child = ChildArticleRead(cgi)
	# child[0]['id'] = 記事ID
	# child[0]['parid'] = 親記事ID
	# child[0]['created_at'] = 投稿日時
	# child[0]['updated_at'] = 更新日時
	# child[0]['name'] = 名前
	# child[0]['subject'] = 記事タイトル
	# child[0]['article'] = 記事
	# ......
	#
	#**********************************************************************
	def ChildArticleRead(cgi)
	  child = Array.new
	  cnt = 0
	  begin
	    File.open(@yaml['ChildArticleFile']) do |chi|
	      chi.flock(File::LOCK_SH)
	      while rec = chi.gets
	       if(/^\D/=~rec)
	          next
	        end
	        (id,parid,created_at,updated_at,name,subject,article) = rec.split(/\t/)
	        child[cnt] = Hash.new
	        child[cnt]['id'] = id
	        child[cnt]['parid'] = parid
	        child[cnt]['created_at'] = created_at
	        child[cnt]['updated_at'] = updated_at
	        child[cnt]['name'] = name
	        child[cnt]['subject'] = subject
	        child[cnt]['article'] = article
	        cnt = cnt + 1
	      end
	      chi.flock(File::LOCK_UN)
	      chi.close
	    end
	  rescue
	  end
	  return child
	end
	
	#**********************************************************************
	# 
	# 親記事の読み込み
	# 呼び方: (parent,parent_year_month_day,parentid) = ParentArticleRead(cgi)
	# parent[0]['id'] = 記事ID
	# parent[0]['created_at'] = 投稿日時
	# parent[0]['updated_at'] = 更新日時
	# parent[0]['subject'] = 記事タイトル
	# parent[0]['article'] = 記事
	# ......
	# parent_year_month_day[YYYY][MM][DD] = 1(#記事を投稿した日)
	# parentid['id'] = 1 (投稿されている親記事のID)
	#**********************************************************************
	def ParentArticleRead(cgi)
	  parent = Array.new
	  parentid = Hash.new
	  cnt = 0
	  parent_year_month_day = Hash.new
	  begin
	    File.open(@yaml['ParentArticleFile']) do |par|
			par.flock(File::LOCK_SH)
			while rec = par.gets
				if(/^\D/=~rec)
					next
				end
				(id,created_at,updated_at,subject,article) = rec.split(/\t/)
				parent[cnt] = Hash.new
				parent[cnt]['id'] = id
				parentid[id.to_s] = 1
				parent[cnt]['created_at'] = created_at
				parent[cnt]['updated_at'] = updated_at
				parent[cnt]['subject'] = subject
				parent[cnt]['article'] = article
				pyear = created_at[0..3].to_s
				pmonth = created_at[4..5].to_s
				pday = created_at[6..7].to_s
				parent_year_month_day["#{pyear}#{pmonth}#{pday}"] = 1
				cnt = cnt + 1
			end
			par.flock(File::LOCK_UN)
			par.close
	    end
	  rescue
	  end
	  return parent,parent_year_month_day,parentid
	end
	
	#**********************************************************************
	#	
	#	@logic.RightFreeExec(cgi)
	#	右入力欄実行処理
	#	
	#**********************************************************************
	def RightFreeExec(cgi)
		begin
	    
		    File.open(@yaml['RightFreeInputFile'],"w") do |file|
		    	file.flock(File::LOCK_EX)
			    file.puts cgi['article']
			    file.flock(File::LOCK_UN)
			    file.close
		    end
	  
	  	rescue
	  		@cont.nomal_error('右自由入力欄ファイルに書き込みが出来ませんでした。')
	  	end
	end
	
	#**********************************************************************
	# 
	# 右サイドの自由入力欄の読み込み
	# 呼び方: right_free = RightFreeInputRead
	# left_free = 読み込みデータ全て
	# 
	# 
	#**********************************************************************
	def RightFreeInputRead
	  right = ""
	  begin
	    
	    File.open(@yaml['RightFreeInputFile'],"r") do |file|
	    	file.flock(File::LOCK_SH)
		    while rec = file.gets
		    	right = right , rec
		    end
		    file.flock(File::LOCK_UN)
		    file.close
	    end
	  
	  rescue
	  end
	  return right
	end
	
	#**********************************************************************
	#	
	#	@logic.LeftFreeExec(cgi)
	#	左入力欄実行処理
	#	
	#**********************************************************************
	def LeftFreeExec(cgi)
		begin
	    
		    File.open(@yaml['LeftFreeInputFile'],"w") do |file|
		    	file.flock(File::LOCK_EX)
			    file.puts cgi['article']
			    file.flock(File::LOCK_UN)
			    file.close
		    end
	  
	  	rescue
	  		@cont.nomal_error('左自由入力欄ファイルに書き込みが出来ませんでした。')
	  	end
	end
	#**********************************************************************
	# 
	# 左サイドの自由入力欄の読み込み
	# 呼び方: left_free = LeftFreeInputRead
	# left_free = 読み込みデータ全て
	# 
	# 
	#**********************************************************************
	def LeftFreeInputRead
	  left = ""
	  begin
	    
	    File.open(@yaml['LeftFreeInputFile'],"r") do |file|
	    	file.flock(File::LOCK_SH)
		    while rec = file.gets
		    	left = left , rec
		    end
		    file.flock(File::LOCK_UN)
		    file.close
	    end
	  
	  rescue
	  end
	  return left
	end
	
	#**********************************************************************
	#
	#	@logic.FavoriteWrite(cgi)
	#	お気に入りに書き込む
	#
	#**********************************************************************
	def FavoriteWrite(cgi)
		#引数チェック(削除モード以外)
		if(LoginChk(cgi) == 0)
			@cont.nomal_error('ログインして下さい。');
		end
		data = ""
		for rec in 1..5
			name = cgi["name#{rec}"]
			url = cgi["url#{rec}"]
			if(name != "")
				if(/^(http[s]?\:\/\/[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)$/!~url)
					@cont.nomal_error('URLに間違っているものがあります。')
				end
			end
			data = "#{data}#{rec}\t#{url}\t#{name}\t\n"
		end
		begin
			file = File.open(@yaml['FavoritesFile'],"w")
			file.flock(File::LOCK_EX)
			file.puts data
			file.flock(File::LOCK_UN)
			file.close
			File.chmod(0666,@yaml['FavoritesFile'])
		rescue
			@cont.nomal_error('お気に入りファイルに書き込みが出来ませんでした。')
		end
		return
	end
	#**********************************************************************
	#
	# My Favorites Page を読み込む
	# 呼び方: favorites = FavoritesRead
	# favorites[0]['id'] = 1行目のお気に入りページ(ID)
	# favorites[0]['url'] = 1行目のお気に入りページ(URL)
	# favorites[0]['name'] = 1行目のお気に入りページ(ページ名)
	# .....
	#
	##*********************************************************************
	def FavoritesRead(cgi)
	  favorites = Array.new
	  cnt = 0
	  begin
	    
	    File.open(@yaml['FavoritesFile'],"r") do |file|
	    	file.flock(File::LOCK_SH)
		    while rec = file.gets
		      (id,url,name) = rec.split(/\t/)
		      favorites[cnt] = Hash.new
		      favorites[cnt]['id'] = id
		      favorites[cnt]['url'] = url
		      favorites[cnt]['name'] = name
		      cnt = cnt + 1
		    end
		    file.flock(File::LOCK_UN)
		    file.close
		end
		#入力画面の時は足りないもの(5番まで)も全てNULLで初期化
		if(cnt < 5)
			roop = 5 - cnt
			roop.times do |rec|
				favorites[cnt] = Hash.new
				favorites[cnt]['id'] = (cnt + 1).to_s
				favorites[cnt]['url'] = ""
				favorites[cnt]['name'] = ""
				cnt = cnt + 1
		    end
		end
	  rescue
	  	#入力画面の時は足りないもの(5番まで)も全てNULLで初期化
		if(cnt < 5)
			roop = 5 - cnt
			roop.times do |rec|
				favorites[cnt] = Hash.new
				favorites[cnt]['id'] = (cnt + 1).to_s
				favorites[cnt]['url'] = ""
				favorites[cnt]['name'] = ""
				cnt = cnt + 1
		    end
		end
	  end
	  return favorites
	end
	#**********************************************************************
	#
	# Calender の情報を得る
	# 呼び方: cal = GetCalInfo(year,month)
	# cal['StartWday'] = カレンダー開始の曜日
	# cal['EndMonthDay'] = カレンダーの終了日
	# cal['BackYear'] = 戻るの年
	# cal['BackMonth'] = 戻るの月
	# cal['NextYear'] = 次の年
	# cal['NextMonth'] = 次の月
	#
	#**********************************************************************
	def GetCalInfo(year,month)
	  
	  year = year.to_i
	  month = month.to_i
	  
	  monthdays = [31,28,31,30,31,30,31,31,30,31,30,31]
	  if(((year%4 ==0)&&(year%100 !=0))||(year%400 ==0))
	    monthdays[1] = 29
	  end
	  calinfo = Hash::new
	  calinfo['EndMonthDay'] = monthdays[month-1]
	  
	  cal_year = year.to_i
	  cal_month = month.to_i
	  if(cal_month < 3)
	  	cal_year = cal_year - 1
	  	cal_month = cal_month + 12
	  end
	  
	  calinfo['StartWday'] = (cal_year + (cal_year / 4).to_i - (cal_year / 100).to_i + (cal_year / 400).to_i + ((13 * cal_month + 8) / 5).to_i + 1) %7
	  if(month == 1)
	    calinfo['BackYear'] = year - 1
	    calinfo['BackMonth'] = 12
	  else
	    calinfo['BackYear'] = year
	    calinfo['BackMonth'] = month - 1
	  end
	  if(month == 12)
	    calinfo['NextYear'] = year + 1
	    calinfo['NextMonth'] = 1
	  else
	    calinfo['NextYear'] = year
	    calinfo['NextMonth'] = month + 1
	  end
	
	  return calinfo
	end
	
	#*********************************************************************
	#
	#	曜日を取得する
	#	wday = @logic.GetWday(year,month,day)
	#	wday:曜日番号
	#
	#*********************************************************************
	def GetWday(year,month,day)
		year = year.to_i
		month = month.to_i
		day = day.to_i
		if(month < 3)
			year = year - 1
			month = month + 12
		end
		return (year + (year / 4).to_i - (year / 100).to_i + (year / 400).to_i + ((13 * month + 8) / 5).to_i + day) %7
	end
	
	#記事書き込み時タイトル用escape
	def TabCrlfEscape(str)
		return str.to_s.gsub(/\r\n|\r|\n|\t/, "")
	end
	
	#記事書き込み時内容用convert
	def TabCrlfConvert(str)
		str = str.to_s.gsub(/\r\n|\r|\n/, "<br>")
		return str.to_s.gsub(/\t/, "")
	end
	
	#タイトル表示用convert
	def SubjectConvert(str)
		str = html_escape(str.to_s)
		str = str.to_s.gsub(/\r\n|\r|\n|\t/, "")
		return str.to_s.gsub(/\"/, "&quot;")
	end
	
	#親記事表示用convert
	def ParentArticleConvert(str)
		str = str.to_s.gsub(/<br>/, "\tbr\t")
		str = html_escape(str.to_s)
		str = str.to_s.gsub(/&amp;/, "&")
		str = str.to_s.gsub(/\tbr\t/, "<br>")
		str = str.to_s.gsub(/\r\n|\r|\n/, "<br>")
		str = str.to_s.gsub(/\"/, "&quot;")
		str = str.to_s.gsub(/ /,"&nbsp;")
		
		#font color + size処理
		str = str.to_s.gsub(/\{font_size\:(\d+)\}/) do
			"<font size=\"#{$1}\">"
		end
		str = str.to_s.gsub(/\{font_color\:(\#\w\w\w\w\w\w)\}/) do
			"<font color=\"#{$1}\">"
		end
		
		str = str.to_s.gsub(/\{font_end\}/,"</font>")
		
		#画像処理
		str = str.to_s.gsub(/\{image_id\:(\d+\.)(jpg|png|gif)&nbsp;w=(\d+)&nbsp;h=(\d+)\}/) do
			"<a href=\"#{@yaml['ImageFileUrl']}#{$1}#{$2}\"><img src=\"#{@yaml['ImageFileUrl']}#{$1}#{$2}\" width=\"#{$3}\" height=\"#{$4}\" border=\"0\"></a>"
		end
		
		#youtube動画処理
		str = str.to_s.gsub(/\{movie_url\:http\:\/\/\w+\.youtube\.com\/watch\?v\=([\w\-]+)\}/) do
			"<object width=\"425\" height=\"344\"><param name=\"movie\" value=\"http://www.youtube.com/v/#{$1}&hl=ja&fs=1\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowscriptaccess\" value=\"always\"></param><embed src=\"http://www.youtube.com/v/#{$1}&hl=ja&fs=1\" type=\"application/x-shockwave-flash\" allowscriptaccess=\"always\" allowfullscreen=\"true\" width=\"425\" height=\"344\"></embed></object>"

		end
		
		str = str.to_s.gsub(/\{movie_url\:http\:\/\/\w+\.youtube\.com\/watch\?v\=([\w\-]+)&feature\=[\w_]+\}/) do
			"<object width=\"425\" height=\"344\"><param name=\"movie\" value=\"http://www.youtube.com/v/#{$1}&hl=ja&fs=1\"></param><param name=\"allowFullScreen\" value=\"true\"></param><param name=\"allowscriptaccess\" value=\"always\"></param><embed src=\"http://www.youtube.com/v/#{$1}&hl=ja&fs=1\" type=\"application/x-shockwave-flash\" allowscriptaccess=\"always\" allowfullscreen=\"true\" width=\"425\" height=\"344\"></embed></object>"

		end
		
		#リンク処理
		str = str.to_s.gsub(/\{url\:(http[s]?\:\/\/[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)\}/) do
			"<a href=\"#{$1}\" target=\"_blank\">#{$1}</a>"
		end
		
		#h3, table タグの処理
		data = ""
		#tableの開始と終了に使う
		table_check = 0
		str.to_s.split(/<br>/).each do |rec|
			if(/^\{table\}/=~rec)
				rec = rec.gsub(/^\{table\}/,"")
				rec = h_tagu(rec)
				#table作成
				data = "#{data}<table id\"center_table\"><tr><td id=\"center_table_td\">#{rec}"
				table_check = 1
			elsif(/^\{end_table\}/=~rec)
				#table終了処理
				rec = rec.gsub(/^\{end_table\}/,"")
				rec = h_tagu(rec)
				data = "#{data}</td></tr></table>#{rec}"
				table_check = 0
			else
				#tableの処理が無い場合
				rec = h_tagu(rec)
				data = "#{data}#{rec}"
			end
		end
		#table閉じ忘れ防止
		if(table_check == 1)
			data = "#{data}</td></tr></table>"
		end
		
		if(data != "")
			str = data
		end
		
		str = str.to_s.gsub(/\t/, "")
		return str
	end
	
	#hタグ変換を返す(マッチしたら)
	def h_tagu(str)
		if(/^\{h[1-3]\}/=~str.to_s)
			#hタグ作成
			str = str.to_s.gsub(/^\{h([1-3])\}/,"")
			str = "<h#{$1}>#{str}</h#{$1}>"
		else
			str = "#{str}<br>"
		end
		return str
	end
	
	#返信記事 TrackBack用view convert(親記事も管理画面内の一部で利用)
	def ResArticleConvert(str)
		str = str.to_s.gsub(/\r\n|\r|\n/, "<br>")
		str = str.to_s.gsub(/<br>/, "\tbr\t")
		str = html_escape(str.to_s)
		str = str.to_s.gsub(/\tbr\t/, "<br>")
		return str.to_s.gsub(/\"/, "&quot;")
	end
	
	#Profile一言表示用convert
	def ProfileConvert(str)
		str = html_escape(str.to_s)
		str = str.to_s.gsub(/\r\n|\r|\n/, "<br>")
		str = str.to_s.gsub(/\t/, "")
		return str.to_s.gsub(/\"/, "&quot;")
	end
	
	#form Article内容表示用convert
	def FormArticleConvert(str)
		return str.to_s.gsub(/<br>/, "\n")
	end
	
	#文字列を指定した数にする
	def StrCut(str,cut)
		cut = cut - 1
		str = str.to_s.gsub(/<br>/, "")
		if(str.to_s.split(//u).length > cut)
			str = str.to_s.split(//u)[0..cut],'...'
		end
		return str
	end
end
