let s:plugin_state = {}

function! s:scheme_dir() abort"{{{
  return expand(get(g:, 'im_scheme_dir', '~/.local/share/rime-schemes'))
endfunction"}}}

function! s:repo_name(url) abort"{{{
  let name = matchstr(a:url, '[^/]\+\%(\.git\)\?$')
  return substitute(name, '\.git$', '', '')
endfunction"}}}

function! s:on_download_exit_nvim(job_id, exit_code, event) abort"{{{
  call s:finish_download(s:plugin_state, a:exit_code)
endfunction"}}}

function! s:on_download_exit_vim(job, status) abort"{{{
  call s:finish_download(s:plugin_state, a:status)
endfunction"}}}

function! s:finish_download(state, exit_code) abort"{{{
  if a:exit_code == 0
    echohl Title | echo '[IMScheme] 下载成功: ' . a:state.target | echohl None
  else
    echohl ErrorMsg | echo '[IMScheme] 下载失败 (exit: ' . a:exit_code . ')' | echohl None
  endif
endfunction"}}}

function! im#scheme#download(url) abort"{{{
  if empty(a:url)
    echohl ErrorMsg | echo '[IMScheme] 用法: :IMSchemeDownload <git-url>' | echohl None
    return
  endif

  if !executable('git')
    echohl ErrorMsg | echo '[IMScheme] 未找到 git，请先安装' | echohl None
    return
  endif

  let dir = s:scheme_dir()
  if !isdirectory(dir)
    call mkdir(dir, 'p')
  endif

  let name = s:repo_name(a:url)
  if empty(name)
    echohl ErrorMsg | echo '[IMScheme] 无法从 URL 推导目录名: ' . a:url | echohl None
    return
  endif

  let target = dir . '/' . name
  if isdirectory(target) || filereadable(target)
    echohl WarningMsg | echo '[IMScheme] 已存在，跳过下载: ' . target | echohl None
    return
  endif

  let s:plugin_state = {'target': target}
  let cmd = ['git', 'clone', '--depth', '1', a:url, target]

  if has('nvim')
    if jobstart(cmd, {'on_exit': function('s:on_download_exit_nvim')}) <= 0
      echohl ErrorMsg | echo '[IMScheme] 启动下载失败' | echohl None
    else
      echo '[IMScheme] 正在下载: ' . a:url
    endif
  else
    call job_start(cmd, {'exit_cb': function('s:on_download_exit_vim')})
    echo '[IMScheme] 正在下载: ' . a:url
  endif
endfunction"}}}
