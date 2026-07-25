"12行分の大きさでファイルを開く
:12sp /home/petabit-user/safe_rsync/gen_excfile_usage.txt
:set nomodifiable    "変更を禁止する
"下のバッファにカーソル移動
:execute "wincmd j"


"デフォルト除外指定ファイル
"これは外部から指定される
":let DefaultExcludeFile = 
"今回の除外指定ファイル
"これは外部から指定される
":let ExcludeFile = 

"除外指定ファイルマーカー
:let s:ExcludeMarker = "<<exclude>> "
"除外指定ファイルマーカーがある行を目立たせる
:syntax match ExcludeMarkLine "^<<exclude>> .*$" display containedin=ALL
:highlight ExcludeMarkLine term=underline ctermbg=Blue guibg=Blue

:set nomodifiable    "変更を禁止する

"除外指定ファイルマーカー付きの行をdefaultExcludeFileに書き出す
:function WriteExcludePatternFile()
    :set modifiable    "変更禁止を解除する。

    "カレントバッファの全行を得る
    :let filebuf = getline(0, line("$"))

    "行頭にmarkerがある行以外を空行に
    :call map( filebuf, "substitute( v:val, '^[^(".s:ExcludeMarker.")].*$','', '' )" )
    "空行を消す
    :call filter( filebuf, "v:val =~ '^".s:ExcludeMarker."'" )
    "行頭のmarkerを消す
    :call map( filebuf, "substitute( v:val, '^".s:ExcludeMarker."', '', '' )" )

    "デフォルトファイルを読み込んで
"    :let orgfilebuf = readfile(g:DefaultExcludeFile)
    :let orgfilebuf = readfile(g:ExcludeFile)
    "上で作ったリストと合わせて
    :let filebuf = orgfilebuf + filebuf
    "今回のファイルとして書き込む
    :call writefile( filebuf, g:ExcludeFile )

    :set nomodifiable    "変更を禁止する
:endfunction

"除外指定ファイルマーカーをディレクトリにつける
:function SetExcludeDirectory()

    "ディレクトリの/をエスケープする
    :let dir = substitute( getline("."), '/', '\\/', 'g' )
    "バッファ全部のdirをmarker dirの形に置換する
    :let cmd = '%substitute/^\(' . dir . '\)/' . s:ExcludeMarker . '\1/'
    :silent execute cmd

:endfunction

"ディレクトリから除外指定ファイルマーカーを消す
:function ResetExcludeDirectory()

    "ディレクトリの前のmarkerを消す
    :let dir = substitute( getline("."), '^'.s:ExcludeMarker, '', '' )
    "ディレクトリの/をエスケープする
    :let dir = substitute( dir, '/', '\\/', 'g' )
    "バッファ全部のmarker dirをdirの形に置換する
    :let cmd = '%substitute/^' . s:ExcludeMarker . '\(' . dir . '\)' . '/\1/'
    :silent execute cmd

:endfunction

"除外指定ファイルマーカーをカーソル行につける
:function SetToExcludePattern()
    :set modifiable    "変更禁止を解除する。
    :let pos = line(".")
    :let line = getline(".")

    :let save_cursor = getpos(".")    "カーソル位置を保存して

    :if line =~ "^deleting" "deleting行は無視する
        :echo "ファイルまたはディレクトリでは無いです。"
    :elseif line =~ "^".s:ExcludeMarker  "行頭のmarkerを確認
        :echo "既に除外対象です。"
    :else
        :if line =~ "^.*/$"
            "/で終わる行はディレクトリ
            :call SetExcludeDirectory()
            :echo "このディレクトリはアップロードしません。"
        :else
            "カレント行の行頭をmarkerに置き換える
            :call setline( pos, substitute( line, '\(^\)', s:ExcludeMarker.'\1', '' ) )
            :echo "このファイルはアップロードしません。"
        :endif
    :endif

    :call setpos( '.', save_cursor )    "カーソル位置を復帰する
    :set nomodifiable    "変更を禁止する
:endfunction

"カーソル行から除外指定ファイルマーカーを消す
:function ResetToExcludePattern()
    :set modifiable    "変更禁止を解除する。
    :let pos = line(".")
    :let line = getline(".")

    :let save_cursor = getpos(".")    "カーソル位置を保存して

    :if line =~ "^deleting" "deleting行は無視する
        :echo "ファイルまたはディレクトリでは無いです。"
        :call setpos( '.', save_cursor )    "カーソル位置を復帰する
        :set nomodifiable    "変更を禁止する
        :return
    :elseif line =~ "^.*/$"
        "/で終わる行はディレクトリ
        :call ResetExcludeDirectory()
        :echo "このディレクトリをアップロード対象に戻します。"
    :else
        "カレント行のmarkerを削る
        :call setline( pos, substitute( line, '^'.s:ExcludeMarker, '', '' ) )
        :echo "このファイルをアップロード対象に戻します。"
    :endif

    "親ディレクトリの除外指定ファイルマーカーを消す
    "ディレクトリの要素を分解してリストに入れる
    :let lToken = split( getline(pos), '/' )
    "len==0つまり'/'ディレクトリは処理しない
    :if len(lToken) >= 0 
        "最終要素は上で消したところなので、処理する必要なし
        :call remove( lToken, len(lToken) - 1 )
 
        "後ろの要素（自分のディレクトリあるいは親）から先頭に向かって処理する
        :while len(lToken) > 0
            "ディレクトリの要素をエスケープ処理して組み立ててディレクトリ名にする
            :let rexp = join( lToken, "\\/" ) . "\\/"
            "マーカー付きのディレクトリからマーカーを消す
            :let cmd = '%substitute/^' . s:ExcludeMarker . '\(' . rexp . '\)' . '$/\1/'
            "マーカー付きのディレクトリが無い時のエラーを無視するためのtry/catch
            :try
                :silent execute cmd
            :catch
            :endtry
            "処理済みの最終要素を取り除く
            :call remove( lToken, len(lToken) - 1 )
        :endwhile
    :endif

    :call setpos( '.', save_cursor )    "カーソル位置を復帰する
    :set nomodifiable    "変更を禁止する
:endfunction

:nmap - : call SetToExcludePattern()<CR>
:nmap + : call ResetToExcludePattern()<CR>
:autocmd BufWritePost * call WriteExcludePatternFile()
