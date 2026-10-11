let s:marks = []
let s:popups = []
let s:used = {}
let s:ns_bufs = []
let s:nvim_ns = -1

function! s:link_highlights() abort"{{{
  highlight default link ImJumpShade Comment
  highlight default link ImJumpMatch Search
  highlight default link ImJumpLabel IncSearch
  highlight default link ImJumpPrompt Question
endfunction"}}}

augroup ImJumpHighlight
  autocmd!
  autocmd ColorScheme * call s:link_highlights()
augroup END

let s:plugin_root = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h')

let s:file_loaded = 0

function! s:ensure() abort"{{{
  if s:file_loaded
    return 1
  endif
  let path = s:plugin_root . '/data/pinyin_table.vim'
  if !filereadable(path)
    return 0
  endif
  try
    execute 'source ' . fnameescape(path)
  catch
    return 0
  endtry
  if type(get(g:, 'im_base_table', {})) != v:t_dict
        \ || empty(g:im_base_table)
    return 0
  endif
  let s:file_loaded = 1
  return 1
endfunction"}}}

function! s:class(key) abort"{{{
  if !s:ensure()
    return ''
  endif
  if strchars(a:key) != 1
    return ''
  endif

  let mode = get(g:, 'im_jump_mode', 'quanpin')
  if mode ==# 'flypy'
    let refs = g:im_flypy_map
  else
    let refs = g:im_quanpin_map
  endif

  if has_key(refs, a:key) && type(refs[a:key]) == v:t_string && !empty(refs[a:key])
    return '[' . escape(a:key . refs[a:key], ']\^-\\') . ']'
  endif

  if has_key(refs, a:key) && type(refs[a:key]) == v:t_list && !empty(refs[a:key])
    let base = g:im_base_table
    let ext = ''
    for b in refs[a:key]
      if type(b) != v:t_string || !has_key(base, b)
            \ || type(base[b]) != v:t_string
        return ''
      endif
      let ext .= base[b]
    endfor
    return '[' . escape(a:key . ext, ']\^-\\') . ']'
  endif
  return '[' . escape(a:key, ']\^-\\') . ']'
endfunction"}}}

function! s:build(pattern) abort"{{{
  if a:pattern ==# ''
    return ''
  endif
  let out = get(g:, 'im_jump_ignore_case', 0) ? '\c' : '\C'
  for i in range(strchars(a:pattern))
    let frag = s:class(strcharpart(a:pattern, i, 1))
    if frag ==# ''
      return ''
    endif
    let out .= frag
  endfor
  return out
endfunction"}}}

function! s:windows(multi) abort"{{{
  let cur = win_getid()
  if !a:multi
    return [{'winid': cur, 'bufnr': bufnr('%')}]
  endif
  let wins = [{'winid': cur, 'bufnr': winbufnr(winnr())}]
  for n in range(1, winnr('$'))
    let wid = win_getid(n)
    if wid <= 0 || wid == cur
      continue
    endif
    if win_gettype(wid) !=# ''
      continue
    endif
    if getwinvar(n, '&previewwindow')
      continue
    endif
    if exists('*nvim_win_get_config')
      try
        if !get(nvim_win_get_config(wid), 'focusable', 1)
          continue
        endif
      catch
      endtry
    endif
    call add(wins, {'winid': wid, 'bufnr': winbufnr(n)})
  endfor
  return wins
endfunction"}}}

function! s:fold_end(wid, lnum) abort"{{{
  if a:wid == win_getid()
    return foldclosedend(a:lnum)
  endif
  try
    return str2nr(trim(win_execute(a:wid, 'echo foldclosedend(' . a:lnum . ')')))
  catch
    return -1
  endtry
endfunction"}}}

function! s:is_visible(wid, info, lnum, col) abort"{{{
  let winnr = win_id2win(a:wid)
  if winnr <= 0
    return 0
  endif
  if getwinvar(winnr, '&wrap')
    return 1
  endif
  let win_width = get(a:info, 'width', 0) - get(a:info, 'textoff', 0)
  if win_width < 1
    return 0
  endif
  try
    let vc = virtcol([a:lnum, a:col], 0, a:wid)
  catch
    return 1
  endtry
  if vc <= 0
    return 0
  endif
  let left = get(a:info, 'leftcol', 0)
  return left < vc && vc <= left + win_width
endfunction"}}}

function! s:scan(regex, wins, cfg) abort"{{{
  let res = []
  if a:regex ==# ''
    return res
  endif
  let max = get(g:, 'im_jump_max_matches', 60)
  if max <= 0
    return res
  endif
  let single = !get(a:cfg, 'wrap', 1)
  if single
    let cur = getpos('.')
    let cl = cur[1]
    let cc = cur[2]
    let forward = get(a:cfg, 'forward', 1)
  endif
  for w in a:wins
    let wi = getwininfo(w.winid)
    if empty(wi)
      continue
    endif
    let info = wi[0]
    let top = info.topline
    let bot = info.botline
    let lnum = top
    while lnum <= bot
      if single && (forward ? lnum < cl : lnum > cl)
        let lnum += 1
        continue
      endif
      let fend = s:fold_end(w.winid, lnum)
      if fend != -1
        let lnum = fend + 1
        continue
      endif
      let lines = getbufline(w.bufnr, lnum)
      if empty(lines)
        let lnum += 1
        continue
      endif
      let line = lines[0]
      if line ==# ''
        let lnum += 1
        continue
      endif
      let start = 0
      while start < strlen(line)
        let m = matchstrpos(line, a:regex, start)
        if m[1] < 0
          break
        endif
        let col = m[1] + 1
        if (!single || lnum != cl || (forward ? col >= cc : col <= cc))
              \ && s:is_visible(w.winid, info, lnum, col)
          call add(res, {'winid': w.winid, 'bufnr': w.bufnr,
                \ 'lnum': lnum, 'col': col, 'len': m[2] - m[1], 'text': m[0]})
          if len(res) >= max
            return res
          endif
        endif
        let ch = matchstr(line[m[1]:], '^.')
        let start = m[1] + (ch ==# '' ? 1 : strlen(ch))
      endwhile
      let lnum += 1
    endwhile
  endfor
  return res
endfunction"}}}

function! s:skip(labels, matches, capped, ic) abort"{{{
  if empty(a:labels)
    return []
  endif
  if a:capped
    return copy(a:labels)
  endif
  let extras = {}
  for m in a:matches
    let bl = getbufline(get(m, 'bufnr', bufnr('%')), m.lnum)
    if empty(bl)
      continue
    endif
    let nx = matchstr(bl[0][m.col - 1 + m.len :], '^.')
    if nx !=# ''
      let extras[nx] = 1
    endif
  endfor
  if empty(extras)
    return copy(a:labels)
  endif
  let out = []
  for c in a:labels
    let frag = s:class(c)
    if frag ==# ''
      continue
    endif
    let cont = 0
    for x in keys(extras)
      if a:ic ? x =~? '^' . frag . '$' : x =~# '^' . frag . '$'
        let cont = 1
        break
      endif
    endfor
    if !cont
      call add(out, c)
    endif
  endfor
  return out
endfunction"}}}

function! s:dedupe(matches) abort"{{{
  let seen = {}
  let uniq = []
  for m in a:matches
    let id = s:pos_id(m)
    if !has_key(seen, id)
      let seen[id] = 1
      call add(uniq, m)
    endif
  endfor
  call remove(a:matches, 0, -1)
  call extend(a:matches, uniq)
endfunction"}}}

function! s:assign(matches, pattern, cfg) abort"{{{
  if empty(a:matches)
    return a:matches
  endif
  call s:dedupe(a:matches)
  let pool = split(get(g:, 'im_jump_labels', 'asdfghjklqwertyuiopzxcvbnmASDFGHJKLQWERTYUIOPZXCVBNM'), '\zs')
  let maxlen = get(g:, 'im_jump_max_length', 0)
  let pool = s:skip(pool, a:matches, maxlen > 0 && strchars(a:pattern) >= maxlen, get(g:, 'im_jump_ignore_case', 0))
  let cur = getpos('.')
  let curwin = win_getid()
  let cl = cur[1]
  let cc = cur[2]
  let forward = get(a:cfg, 'forward', 1)
  let wrap = get(a:cfg, 'wrap', 1)
  if !wrap
    if forward
      call sort(a:matches, {x, y -> x.lnum == y.lnum ? x.col - y.col : x.lnum - y.lnum})
    else
      call sort(a:matches, {x, y -> x.lnum == y.lnum ? y.col - x.col : y.lnum - x.lnum})
    endif
  else
    call sort(a:matches, {x, y ->
          \ (x.winid == y.winid
          \   ? (x.winid == curwin
          \     ? (abs(x.lnum - cl) == abs(y.lnum - cl)
          \       ? abs(x.col - cc) - abs(y.col - cc)
          \       : abs(x.lnum - cl) - abs(y.lnum - cl))
          \     : (x.lnum == y.lnum ? x.col - y.col : x.lnum - y.lnum))
          \   : ((x.winid == curwin ? 0 : x.winid) - (y.winid == curwin ? 0 : y.winid)))})
  endif
  let avail = copy(pool)
  for m in a:matches
    let id = s:pos_id(m)
    let old = get(s:used, id, '')
    if old !=# '' && old ==# tolower(old) && index(avail, old) >= 0
      let m.label = old
      call filter(avail, 'v:val !=# old')
    endif
  endfor
  for m in a:matches
    if has_key(m, 'label')
      continue
    endif
    if empty(avail)
      let m.label = ''
      continue
    endif
    let m.label = remove(avail, 0)
    if m.label ==# tolower(m.label)
      let s:used[s:pos_id(m)] = m.label
    endif
  endfor
  return a:matches
endfunction"}}}

function! s:check(new, matches) abort"{{{
  let tail = strcharpart(a:new, strchars(a:new) - 1, 1)
  for m in a:matches
    if get(m, 'label', '') ==# tail
      return m
    endif
  endfor
  return {}
endfunction"}}}

function! s:pos_id(m) abort"{{{
  return get(a:m, 'bufnr', bufnr('%')) . ':' . a:m.lnum . ':' . a:m.col
endfunction"}}}

function! s:label_anchor(m, label_pos, info) abort"{{{
  " label 字节列锚点：start=首字母，end=尾字母，after=尾字母后一字（默认）
  if a:label_pos ==# 'start'
    return a:m.col
  endif
  if a:label_pos ==# 'end'
    let last = matchstr(a:m.text, '.$')
    let end = a:m.col + a:m.len - strlen(last)
    " nowrap 下尾部出窗时左钳到最后一个完全可见字符
    let wid = get(a:m, 'winid', win_getid())
    let winnr = win_id2win(wid)
    if winnr > 0 && !getwinvar(winnr, '&wrap')
      let win_width = get(a:info, 'width', 0) - get(a:info, 'textoff', 0)
      if win_width >= 1
        let right = get(a:info, 'leftcol', 0) + win_width
        try
          while end > a:m.col
            let vc = virtcol([a:m.lnum, end], 0, wid)
            if vc > 0 && vc <= right
              break
            endif
            let prev = matchstr(strpart(a:m.text, 0, end - a:m.col), '.$')
            let end -= strlen(prev)
          endwhile
        catch
        endtry
      endif
    endif
    return end
  endif
  return a:m.col + a:m.len
endfunction"}}}

function! s:label_text(m, anchor) abort"{{{
  " label 显示文本：按锚点下底字宽补空格，整块盖住（中文 2 列时补 1 空格）
  let lines = getbufline(a:m.bufnr, a:m.lnum)
  let w = 1
  if !empty(lines)
    let ch = matchstr(strpart(lines[0], a:anchor - 1), '^.')
    if ch !=# ''
      let w = strdisplaywidth(ch)
    endif
  endif
  return a:m.label . repeat(' ', max([0, w - strdisplaywidth(a:m.label)]))
endfunction"}}}

function! s:show_label(m, label_pos, info) abort"{{{
  if a:m.label ==# ''
    return
  endif
  let anchor = s:label_anchor(a:m, a:label_pos, a:info)
  let text = s:label_text(a:m, anchor)
  if has('nvim') && exists('*nvim_buf_set_extmark')
    if s:nvim_ns < 0 && exists('*nvim_create_namespace')
      let s:nvim_ns = nvim_create_namespace('im_jump')
    endif
    call nvim_buf_set_extmark(a:m.bufnr, s:nvim_ns, a:m.lnum - 1, anchor - 1,
          \ {'virt_text': [[text, 'ImJumpLabel']], 'virt_text_pos': 'overlay', 'strict': v:false})
    if index(s:ns_bufs, a:m.bufnr) < 0
      call add(s:ns_bufs, a:m.bufnr)
    endif
  elseif exists('*popup_create')
    let sp = screenpos(get(a:m, 'winid', win_getid()), a:m.lnum, anchor)
    if empty(sp) || get(sp, 'row', 0) == 0
      return
    endif
    let w = strdisplaywidth(text)
    let id = popup_create(text, {
          \ 'line': sp.row, 'col': sp.col,
          \ 'minwidth': w, 'maxwidth': w,
          \ 'padding': [0, 0, 0, 0],
          \ 'highlight': 'ImJumpLabel',
          \ })
    call add(s:popups, id)
  endif
endfunction"}}}

function! s:win_matchadd(wid, expr) abort"{{{
  try
    call win_execute(a:wid, 'let g:_im_jump_mid = ' . a:expr)
  catch
    return -1
  endtry
  let id = get(g:, '_im_jump_mid', -1)
  unlet! g:_im_jump_mid
  return type(id) == v:t_number && id > 0 ? id : -1
endfunction"}}}

function! s:render(matches, cfg) abort"{{{
  call s:clear_render()
  if empty(a:matches)
    return
  endif
  call s:link_highlights()
  let label_pos = get(a:cfg, 'label_pos', 'end')
  let by_win = {}
  for m in a:matches
    let wid = get(m, 'winid', win_getid())
    if !has_key(by_win, wid)
      let by_win[wid] = []
    endif
    call add(by_win[wid], [m.lnum, m.col, m.len])
  endfor
  let winfos = {}
  for [wkey, locs] in items(by_win)
    let wid = str2nr(wkey)
    let id = s:win_matchadd(wid, "matchaddpos('ImJumpMatch', " . string(locs) . ', 999)')
    if id > 0
      call add(s:marks, [wid, id])
    endif
    let wi = getwininfo(wid)
    let winfos[wid] = empty(wi) ? {} : wi[0]
  endfor
  for m in a:matches
    call s:show_label(m, label_pos, get(winfos, get(m, 'winid', win_getid()), {}))
  endfor
endfunction"}}}

function! s:clear_render() abort"{{{
  for ent in s:marks
    silent! call win_execute(ent[0], 'call matchdelete(' . ent[1] . ')')
  endfor
  let s:marks = []
  if has('nvim') && s:nvim_ns >= 0 && exists('*nvim_buf_clear_namespace')
    for b in s:ns_bufs
      if bufexists(b)
        silent! call nvim_buf_clear_namespace(b, s:nvim_ns, 0, -1)
      endif
    endfor
  endif
  let s:ns_bufs = []
  if exists('*popup_close')
    for id in s:popups
      silent! call popup_close(id)
    endfor
  endif
  let s:popups = []
endfunction"}}}

function! s:clear_session(shades) abort"{{{
  call s:shade_clear(a:shades)
  call s:clear_render()
  let s:used = {}
endfunction"}}}

function! s:prompt(pattern, matches) abort"{{{
  if !get(g:, 'im_jump_echo', 1)
    return
  endif
  echohl ImJumpPrompt
  echon '> ' . a:pattern
  echohl None
  echon ' (' . len(a:matches) . ')'
endfunction"}}}

function! s:getkey() abort"{{{
  while 1
    try
      let c = getchar()
    catch /^Vim:Interrupt$/
      return "\<Esc>"
    endtry
    if type(c) == v:t_string && c ==# "\x80\xfd`"
      continue
    endif
    return type(c) == v:t_number ? nr2char(c) : c
  endwhile
endfunction"}}}

function! s:update(pattern, wins, cfg) abort"{{{
  if a:pattern ==# ''
    return []
  endif
  let regex = s:build(a:pattern)
  if regex ==# ''
    return []
  endif
  return s:assign(s:scan(regex, a:wins, a:cfg), a:pattern, a:cfg)
endfunction"}}}

function! s:jump(m, cfg) abort"{{{
  if get(a:cfg, 'jump_pos', 'start') ==# 'end'
    let [lnum, col] = [a:m.lnum, a:m.col + a:m.len - strlen(matchstr(a:m.text, '.$'))]
  else
    let [lnum, col] = [a:m.lnum, a:m.col]
  endif
  let wid = get(a:m, 'winid', win_getid())
  if wid != win_getid()
    if wid <= 0 || !win_gotoid(wid)
      call cursor(lnum, col)
      return
    endif
    if get(a:m, 'bufnr', bufnr('%')) != bufnr('%')
      silent! normal! m'
    endif
  endif
  let cur = getpos('.')
  let pat = '\%' . a:m.lnum . 'l\%' . a:m.col . 'c.'
  if lnum > cur[1] || (lnum == cur[1] && col > cur[2])
    call searchpos(pat, 'sW')
  else
    call searchpos(pat, 'sbW')
  endif
  if &foldopen =~# '\<\%(all\|hor\)\>'
    while foldclosed(lnum) >= 0
      foldopen
    endwhile
  endif
  call cursor(lnum, col)
  if get(a:cfg, 'op', 0) && !get(a:cfg, 'inclusive', 1)
    let al = get(get(a:cfg, 'anchor', []), 1, cur[1])
    let ac = get(get(a:cfg, 'anchor', []), 2, cur[2])
    if lnum > al || (lnum == al && col > ac)
      silent! normal! h
    elseif lnum < al || (lnum == al && col < ac)
      silent! normal! l
    endif
  endif
endfunction"}}}

function! s:label_pos(v) abort"{{{
  return a:v ==# 'start' || a:v ==# 'after' ? a:v : 'end'
endfunction"}}}

function! s:parse_cfg(o) abort"{{{
  let cfg = {
        \ 'forward': get(a:o, 'forward', 1) ? 1 : 0,
        \ 'wrap': get(a:o, 'wrap', 1) ? 1 : 0,
        \ 'multi_window': get(a:o, 'multi_window', 0) ? 1 : 0,
        \ 'jump_pos': get(a:o, 'jump_pos', 'start') ==# 'end' ? 'end' : 'start',
        \ 'inclusive': get(a:o, 'inclusive', 1) ? 1 : 0,
        \ 'label_pos': s:label_pos(get(a:o, 'label_pos', get(g:, 'im_jump_label_pos', 'end'))),
        \ 'op': mode(1) =~# '^no',
        \ }
  if cfg.op
    let cfg.anchor = getpos('.')
  endif
  if mode(1) !=# 'n'
    let cfg.multi_window = 0
  endif
  if !cfg.wrap
    let cfg.multi_window = 0
  endif
  return cfg
endfunction"}}}

function! s:shade_pattern(top, bot, cl, cc, cfg) abort"{{{
  " cl/cc：光标行/列（cc 为字节列）
  let top = a:top
  let bot = a:bot
  let single = !get(a:cfg, 'wrap', 1)
  if single
    if get(a:cfg, 'forward', 1)
      let top = max([top, a:cl])
    else
      let bot = min([bot, a:cl])
    endif
  endif
  if top > bot
    return ''
  endif
  if !single
    return '\%>' . (top - 1) . 'l\%<' . (bot + 1) . 'l.*'
  endif
  if get(a:cfg, 'forward', 1)
    let pat = '\%' . a:cl . 'l\%>' . (a:cc - 1) . 'c.*'
    if a:cl < bot
      let pat .= '\|\%>' . a:cl . 'l\%<' . (bot + 1) . 'l.*'
    endif
    return pat
  endif
  let pat = '\%' . a:cl . 'l.*\%<' . (a:cc + 1) . 'c'
  if top < a:cl
    let pat = '\%>' . (top - 1) . 'l\%<' . a:cl . 'l.*\|' . pat
  endif
  return pat
endfunction"}}}

function! s:shade_add(wins, cl, cc, cfg) abort"{{{
  let shades = []
  if !get(g:, 'im_jump_shade', 1)
    return shades
  endif
  for w in a:wins
    let info = getwininfo(w.winid)
    if empty(info)
      continue
    endif
    let pat = s:shade_pattern(info[0].topline, info[0].botline, a:cl, a:cc, a:cfg)
    if pat ==# ''
      continue
    endif
    let sid = s:win_matchadd(w.winid, "matchadd('ImJumpShade', " . string(pat) . ', 999)')
    if sid > 0
      call add(shades, [w.winid, sid])
    endif
  endfor
  return shades
endfunction"}}}

function! s:shade_clear(shades) abort"{{{
  for ent in a:shades
    silent! call win_execute(ent[0], 'call matchdelete(' . ent[1] . ')')
  endfor
endfunction"}}}

function! s:loop(wins, cfg) abort"{{{
  let pattern = ''
  let matches = []
  while 1
    let k = s:getkey()
    if k ==# "\<Esc>" || k ==# "\<C-c>"
      return 0
    elseif k ==# "\<BS>" || k ==# "\x7f"
      if pattern ==# ''
        return 0
      endif
      let pattern = strcharpart(pattern, 0, strchars(pattern) - 1)
    elseif k ==# "\<CR>"
      if !empty(matches)
        call s:jump(matches[0], a:cfg)
        return 1
      endif
      return 0
    else
      let n = char2nr(k)
      if n < 32 || n > 126 || strchars(k) != 1
        continue
      endif
      let new = pattern . k
      let hit = s:check(new, matches)
      if !empty(hit)
        call s:jump(hit, a:cfg)
        return 1
      endif
      let maxlen = get(g:, 'im_jump_max_length', 0)
      if maxlen > 0 && strchars(new) > maxlen
        if empty(matches)
          call feedkeys(k)
          return 0
        endif
        call s:jump(matches[0], a:cfg)
        call feedkeys(k)
        return 1
      endif
      let pattern = new
    endif
    let matches = s:update(pattern, a:wins, a:cfg)
    if pattern !=# '' && empty(matches)
      return 0
    endif
    call s:render(matches, a:cfg)
    redraw
    call s:prompt(pattern, matches)
  endwhile
endfunction"}}}

function! s:conceal_save(wins) abort"{{{
  let saved = {}
  for w in a:wins
    let winnr = win_id2win(w.winid)
    if winnr <= 0
      continue
    endif
    try
      let saved[w.winid] = getwinvar(winnr, '&conceallevel')
      call setwinvar(winnr, '&conceallevel', 0)
    catch
    endtry
  endfor
  return saved
endfunction"}}}

function! s:conceal_restore(saved) abort"{{{
  for [wkey, level] in items(a:saved)
    let wid = str2nr(wkey)
    try
      if win_id2win(wid) > 0
        call setwinvar(win_id2win(wid), '&conceallevel', level)
      endif
    catch
    endtry
  endfor
endfunction"}}}

function! im#jump#s(...) abort"{{{
  let cfg = s:parse_cfg(a:0 && type(a:1) == v:t_dict ? a:1 : {})
  let wins = s:windows(cfg.multi_window)
  let shades = []
  let concealed = {}
  try
    let concealed = s:conceal_save(wins)
    call s:link_highlights()
    let cur = getpos('.')
    let shades = s:shade_add(wins, cur[1], cur[2], cfg)
    redraw
    call s:prompt('', [])
    return s:loop(wins, cfg)
  finally
    call s:conceal_restore(concealed)
    call s:clear_session(shades)
    if get(g:, 'im_jump_echo', 1)
      echo ''
    endif
    redraw
  endtry
endfunction"}}}
