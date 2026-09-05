let s:plugin_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')
let s:build_output = []

function! s:norm(path) abort
  return (has('win32') || has('win64')) ? substitute(a:path, '/', '\', 'g') : a:path
endfunction

function! s:finish_build(output, exit_code) abort"{{{
  let qf_items = []
  for line in a:output
    let m = matchlist(line, '^\(.*\):\(\d\+\):\(\d\+\):\s*\(error\|warning\):\s*\(.*\)$')
    if !empty(m)
      call add(qf_items, {
            \ 'filename': m[1],
            \ 'lnum': str2nr(m[2]),
            \ 'col': str2nr(m[3]),
            \ 'type': m[4][0],
            \ 'text': m[5],
            \ })
    endif
  endfor

  if !empty(qf_items)
    call setqflist(qf_items, 'r')
    copen
    echohl ErrorMsg | echo '[IMBuild] 编译失败，已填充 quickfix (' . len(qf_items) . ' 个错误)' | echohl None
  elseif a:exit_code != 0
    botright new
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nonumber norelativenumber nowrap
    call setline(1, a:output)
    setlocal nomodifiable
    echohl ErrorMsg | echo '[IMBuild] 编译失败 (exit: ' . a:exit_code . ')' | echohl None
  else
    echohl Title | echo '[IMBuild] 编译成功' | echohl None
  endif
endfunction"}}}

function! im#build#check() abort"{{{
  let inc = get(g:, 'im_build_rime_include', '')
  let lib = get(g:, 'im_build_rime_lib', '')
  let bin = s:plugin_root . '/cpp/build/' . ((has('win32') || has('win64')) ? 'rime-query.exe' : 'rime-query')

  let lines = ['[OK] 编译器: ' . get(g:, 'im_build_compiler', 'clang++'),
        \ '[OK] 编译参数: ' . get(g:, 'im_build_flags', '-std=c++17 -O2 -Wall')]
  call add(lines, empty(inc) ? '[FAIL] g:im_build_rime_include 未配置' : '[OK] g:im_build_rime_include: ' . s:norm(inc))
  call add(lines, empty(lib) ? '[FAIL] g:im_build_rime_lib 未配置' : '[OK] g:im_build_rime_lib: ' . s:norm(lib))
  call add(lines, (filereadable(bin) ? '[OK] 已编译: ' : '[INFO] 未编译: ') . s:norm(bin))

  if has('win32') || has('win64')
    let dll = expand(get(g:, 'im_build_rime_dll', ''))
    if empty(dll)
      call add(lines, '[FAIL] g:im_build_rime_dll 未配置（Windows 必需）')
    elseif !filereadable(dll)
      call add(lines, '[FAIL] rime.dll 不存在: ' . s:norm(dll))
    else
      call add(lines, '[OK] g:im_build_rime_dll: ' . s:norm(dll))
    endif
    let dll_target = fnamemodify(bin, ':h') . '/rime.dll'
    call add(lines, (filereadable(dll_target) ? '[OK] 已就位: ' : '[FAIL] 未拷贝: ') . s:norm(dll_target))
  endif

  if exists('s:check_bufnr') && bufexists(s:check_bufnr)
    let w = bufwinnr(s:check_bufnr)
    if w != -1
      execute w . 'wincmd w'
    else
      execute 'botright sbuffer ' . s:check_bufnr
    endif
  else
    botright new
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nonumber norelativenumber nowrap
    silent file [IMCheck]
    let s:check_bufnr = bufnr('%')
  endif
  setlocal modifiable
  silent %delete _
  call setline(1, lines)
  setlocal nomodifiable
endfunction"}}}

function! im#build#build() abort"{{{
  let inc = get(g:, 'im_build_rime_include', '')
  let lib = get(g:, 'im_build_rime_lib', '')

  if empty(inc) || empty(lib)
    echohl ErrorMsg | echo '[IMBuild] 请先配置 g:im_build_rime_include 和 g:im_build_rime_lib' | echohl None
    return
  endif

  let dll = expand(get(g:, 'im_build_rime_dll', ''))
  if has('win32') || has('win64')
    if empty(dll)
      echohl ErrorMsg | echo '[IMBuild] Windows 下请先配置 g:im_build_rime_dll（rime.dll 路径）' | echohl None
      return
    endif
    if !filereadable(dll)
      echohl ErrorMsg | echo '[IMBuild] rime.dll 不存在: ' . s:norm(dll) | echohl None
      return
    endif
  endif

  let out_dir = s:plugin_root . '/cpp/build'
  if !isdirectory(out_dir)
    call mkdir(out_dir, 'p')
  endif

  if has('win32') || has('win64')
    let cmd = ['powershell', '-ExecutionPolicy', 'Bypass', '-File',
          \ s:plugin_root . '/scripts/build-query.ps1',
          \ '-Compiler', get(g:, 'im_build_compiler', 'clang++'),
          \ '-Flags', get(g:, 'im_build_flags', '-std=c++17 -O2 -Wall'),
          \ '-IncludeDir', inc, '-LibDir', lib, '-OutputDir', out_dir,
          \ '-DllPath', dll]
  else
    let cmd = [s:plugin_root . '/scripts/build-query.sh',
          \ get(g:, 'im_build_compiler', 'clang++'),
          \ get(g:, 'im_build_flags', '-std=c++17 -O2 -Wall'),
          \ inc, lib, out_dir, dll]
  endif
  let s:build_output = []

  if has('nvim')
    if jobstart(cmd, {
          \ 'on_stdout': {id, data, event -> extend(s:build_output, filter(copy(data), 'v:val !=# ""'))},
          \ 'on_stderr': {id, data, event -> extend(s:build_output, filter(copy(data), 'v:val !=# ""'))},
          \ 'on_exit': {id, code, event -> s:finish_build(s:build_output, code)},
          \ }) <= 0
      echohl ErrorMsg | echo '[IMBuild] 启动编译失败' | echohl None
    endif
  else
    call job_start(cmd, {
          \ 'out_cb': {ch, data -> extend(s:build_output, [data])},
          \ 'err_cb': {ch, data -> extend(s:build_output, [data])},
          \ 'exit_cb': {ch, status -> s:finish_build(s:build_output, status)},
          \ })
  endif
endfunction"}}}

function! im#build#clean() abort"{{{
  let dir = s:plugin_root . '/cpp/build'

  if !isdirectory(dir)
    echo '[IMBuild] 无需清理，build 目录不存在'
    return
  endif

  if has('win32') || has('win64')
    call system(['cmd', '/c', 'rmdir', '/s', '/q', substitute(dir, '/', '\', 'g')])
  else
    call system(['rm', '-rf', dir])
  endif

  if v:shell_error == 0
    echohl Title | echo '[IMBuild] 已清理: ' . s:norm(dir) | echohl None
  else
    echohl ErrorMsg | echo '[IMBuild] 清理失败' | echohl None
  endif
endfunction"}}}
