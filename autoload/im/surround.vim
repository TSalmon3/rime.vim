let s:key_active = 0  " 映射挂载状态
let s:saved_maps = {} " 被覆盖的用户映射快照

function! s:probe(key) abort"{{{
  let config = im#surround#config#lookup(a:key)
  if empty(config) || type(config.find) != v:t_func
    return {}
  endif
  let result = call(config.find, [a:key])
  if type(result) != v:t_dict || !has_key(result, 'first_pos') || !has_key(result, 'last_pos')
    return {}
  endif
  return result
endfunction"}}}

function! s:pos_le(p1, p2) abort"{{{
  return a:p1[0] < a:p2[0] || (a:p1[0] == a:p2[0] && a:p1[1] <= a:p2[1])
endfunction"}}}

function! s:inside(pos, t) abort"{{{
  return s:pos_le(a:t.first_pos, a:pos) && s:pos_le(a:pos, a:t.last_pos)
endfunction"}}}

function! s:nearest(keys) abort"{{{
  let cur = getpos('.')[1:2]
  let best = [{}, '']
  for c in a:keys
    let r = s:probe(c)
    if empty(r)
      continue
    endif
    if empty(best[0])
      let best = [r, c]
    elseif s:inside(cur, best[0])
      if s:inside(cur, r)
            \ && s:pos_le(best[0].first_pos, r.first_pos)
            \ && s:pos_le(r.last_pos, best[0].last_pos)
        let best = [r, c]
      endif
    elseif s:pos_le(cur, best[0].first_pos)
      if s:inside(cur, r)
            \ || (s:pos_le(cur, r.first_pos) && s:pos_le(r.first_pos, best[0].first_pos))
        let best = [r, c]
      endif
    else
      if s:inside(cur, r) || s:pos_le(best[0].last_pos, r.last_pos)
        let best = [r, c]
      endif
    endif
  endfor
  call cursor(cur[0], cur[1])
  return best
endfunction"}}}

function! im#surround#unwrap(target) abort"{{{
  let [fl, fc] = a:target.first_pos
  let [ll, lc] = a:target.last_pos
  let open_len  = get(a:target, 'open_len', 0)
  let close_len = get(a:target, 'close_len', 0)

  if fl == ll
    let line = getline(fl)
    let head = strpart(line, 0, fc - 1)
    let bstart = fc - 1 + open_len
    let body = strpart(line, bstart, max([lc - close_len - bstart, 0]))
    let tail = strpart(line, lc)
    call setline(fl, head . body . tail)
  else
    let first = getline(fl)
    let last  = getline(ll)
    call setline(fl, strpart(first, 0, fc - 1)
          \ . strpart(first, fc - 1 + open_len))
    call setline(ll, strpart(last, 0, lc - close_len)
          \ . strpart(last, lc))
  endif
endfunction"}}}

function! im#surround#replace(target, left, right) abort"{{{
  let [fl, fc] = a:target.first_pos
  let [ll, lc] = a:target.last_pos
  let open_len  = get(a:target, 'open_len', 0)
  let close_len = get(a:target, 'close_len', 0)

  if fl == ll
    let line = getline(fl)
    let head = strpart(line, 0, fc - 1)
    let bstart = fc - 1 + open_len
    let body = strpart(line, bstart, max([lc - close_len - bstart, 0]))
    let tail = strpart(line, lc)
    call setline(fl, head . a:left . body . a:right . tail)
  else
    let left = substitute(a:left, '\s\+$', '', '')
    let right = substitute(a:right, '^\s\+', '', '')
    let last = getline(ll)
    call setline(ll, strpart(last, 0, lc - close_len)
          \ . right . strpart(last, lc))
    let first = getline(fl)
    call setline(fl, strpart(first, 0, fc - 1)
          \ . left . strpart(first, fc - 1 + open_len))
  endif
endfunction"}}}

function! s:wrap_lines(sl, el, left, right) abort"{{{
  let left = substitute(a:left, '\s\+$', '', '')
  let right = substitute(a:right, '^\s\+', '', '')
  let indent1 = matchstr(getline(a:sl), '^\s*')
  let indent2 = matchstr(getline(a:el), '^\s*')
  call append(a:el, indent2 . right)
  call append(a:sl - 1, indent1 . left)
endfunction"}}}

function! s:wrap_inline(sl, sc, el, ec, left, right) abort"{{{
  if a:sl == a:el
    let line = getline(a:sl)
    call setline(a:sl, strpart(line, 0, a:sc - 1) . a:left
          \ . strpart(line, a:sc - 1, a:ec - a:sc + 1) . a:right . strpart(line, a:ec))
  else
    let first = getline(a:sl)
    let last = getline(a:el)
    call setline(a:sl, strpart(first, 0, a:sc - 1) . a:left . strpart(first, a:sc - 1))
    call setline(a:el, strpart(last, 0, a:ec) . a:right . strpart(last, a:ec))
  endif
endfunction"}}}

function! s:wrap_block(sl, sc, el, ec, left, right) abort"{{{
  for lnum in range(a:sl, a:el)
    let line = getline(lnum)
    if empty(line)
      continue
    endif
    let cs = min([max([charidx(line, a:sc - 1), 0]), strchars(line)])
    let ce = min([charidx(line, a:ec - 1), strchars(line) - 1])
    if ce < cs
      continue
    endif
    let head = strcharpart(line, 0, cs)
    let mid  = strcharpart(line, cs, ce - cs + 1)
    let tail = strcharpart(line, ce + 1)
    call setline(lnum, head . a:left . mid . a:right . tail)
  endfor
endfunction"}}}

function! s:reindent(sl, el) abort"{{{
  if !s:opt('indent', 1)
    return
  endif
  if empty(&equalprg) && empty(&indentexpr) && !&cindent && !&smartindent && !&lisp
    return
  endif
  let view = winsaveview()
  try
    execute 'silent ' . a:sl . ',' . a:el . 'normal! =='
  finally
    call winrestview(view)
  endtry
endfunction"}}}

function! s:highlight_show(t, scope) abort"{{{
  if !hlexists('ImSurroundHighlight')
    highlight default link ImSurroundHighlight Visual
  endif
  let [fl, fc] = a:t.first_pos
  let [ll, lc] = a:t.last_pos
  let pos = []
  if a:scope ==# 'buns'
    let open_len = get(a:t, 'open_len', 0)
    let close_len = get(a:t, 'close_len', 0)
    if type(open_len) == v:t_number && type(close_len) == v:t_number
          \ && open_len > 0 && close_len > 0
      let pos = [[fl, fc, open_len], [ll, max([lc - close_len + 1, 1]), close_len]]
    endif
  endif
  if empty(pos)
    if fl == ll
      call add(pos, [fl, fc, lc - fc + 1])
    else
      call add(pos, [fl, fc, col([fl, '$']) - fc + 1])
      let lnum = fl + 1
      while lnum < ll
        call add(pos, [lnum])
        let lnum += 1
      endwhile
      call add(pos, [ll, 1, lc])
    endif
  endif
  let id = matchaddpos('ImSurroundHighlight', pos)
  redraw
  return id
endfunction"}}}

function! s:highlight_clear(id) abort"{{{
  silent! call matchdelete(a:id)
endfunction"}}}

function! s:highlight_flash(t, scope) abort"{{{
  let ms = s:opt('flash_ms', 120)
  if type(ms) != v:t_number || ms <= 0
    return
  endif
  let hid = s:highlight_show(a:t, a:scope)
  try
    execute 'sleep ' . ms . 'm'
  finally
    call s:highlight_clear(hid)
  endtry
  redraw
endfunction"}}}

function! s:getchar() abort "{{{
  try
    let c = getchar()
  catch /^Vim:Interrupt$/
    return ''
  endtry

  " 可打印字符/控制字符(不可打印字符)
  if type(c) == v:t_number
    let c = nr2char(c)
    if c ==# "\<Esc>" || c ==# "\<C-c>"
      return ''
    endif
    if c !~# '[[:punct:]]'
      return c
    endif
    let ctx = im#rime#key(char2nr(c), 0)
    let out = (ctx.accepted && !empty(get(ctx, 'committed', ''))) ? ctx.committed : c
    call im#rime#reset()
    return out
  endif

  " 特殊键/组合按键/鼠标事件，
  return c
endfunction "}}}

function! s:resolve_delims(ch, ...) abort"{{{
  let cnt = a:0 >= 1 && type(a:1) == v:t_number ? a:1 : 1
  let key = a:ch
  let tlist = im#surround#config#alias_targets(a:ch)
  if type(tlist) == v:t_list && len(tlist) == 1
        \ && type(tlist[0]) == v:t_string && !empty(tlist[0])
    let key = tlist[0]
  endif
  let delim = []
  let cfg = im#surround#config#lookup(key)
  if !empty(cfg)
    let Add = cfg.add
    if type(Add) == v:t_func
      let delim = call(Add, [key])
    elseif type(Add) == v:t_list && len(Add) == 2
      let delim = [Add[0], Add[1]]
    endif
  endif
  if cnt > 1 && !empty(delim)
    let delim = [repeat(delim[0], cnt), repeat(delim[1], cnt)]
  endif
  return delim
endfunction"}}}

function! s:resolve_replacement(key, t) abort"{{{
  let cfg = im#surround#config#lookup(a:key)
  let Rep = empty(cfg) ? v:null : cfg.replace
  if type(Rep) == v:t_func
    let rep = call(Rep, [])
    return type(rep) == v:t_list ? rep : []
  endif
  let hid = s:highlight_show(a:t, 'buns')
  try
    let rep = s:resolve_delims(s:getchar())
  finally
    call s:highlight_clear(hid)
  endtry
  return rep
endfunction"}}}

function! s:step_outside(first_pos) abort"{{{
  call cursor(a:first_pos[0], a:first_pos[1])
  let before = getpos('.')[1:2]
  silent! normal! h
  if getpos('.')[1:2] != before
    return 1
  endif
  if a:first_pos[0] > 1
    call cursor(a:first_pos[0] - 1, col([a:first_pos[0] - 1, '$']))
    return 1
  endif
  return 0
endfunction"}}}

function! s:acquire_target(ch, cnt) abort"{{{
  let keys = im#surround#config#candidate_keys(a:ch)
  let orig = getpos('.')[1:2]
  let t = {}
  let found_key = a:ch
  let total = a:cnt < 1 ? 1 : a:cnt
  try
    for i in range(1, total)          " count 即第 N 层：找最近→跳外→再找
      let [cur_t, cur_key] = s:nearest(keys)
      if empty(cur_t)
        let t = {}
        break
      endif
      let t = cur_t
      let found_key = cur_key
      if i < total && !s:step_outside(t.first_pos)
        let t = {}
        break
      endif
    endfor
  finally
    call cursor(orig[0], orig[1])
  endtry
  return {'target': t, 'found_key': found_key}
endfunction"}}}

function! s:try_delete_standalone_lines(t, do_flash) abort"{{{
  let [fl, fc] = a:t.first_pos
  let [ll, lc] = a:t.last_pos
  if fl == ll
    return 0
  endif
  let open_len  = get(a:t, 'open_len', 0)
  let close_len = get(a:t, 'close_len', 0)
  if open_len <= 0 || close_len <= 0 || fl < 1 || ll > line('$')
    return 0
  endif
  let first = getline(fl)
  let last = getline(ll)
  if strpart(first, 0, fc - 1) =~# '^\s*$'
        \ && strpart(first, fc - 1 + open_len) =~# '^\s*$'
        \ && strpart(last, 0, lc - close_len) =~# '^\s*$'
        \ && strpart(last, lc) =~# '^\s*$'
        \ && matchstr(first, '^\s*\zs.\{-}\ze\s*$') !=# ''
        \ && matchstr(last, '^\s*\zs.\{-}\ze\s*$') !=# ''
    if a:do_flash
      call s:highlight_flash(a:t, 'buns')
    endif
    execute ll . 'delete _'
    execute fl . 'delete _'
    call cursor(fl, 1)
    return 1
  endif
  return 0
endfunction"}}}

function! s:delete_with(ch, cnt, do_flash) abort"{{{
  let ac = s:acquire_target(a:ch, a:cnt)
  if empty(ac.target)
    return 0
  endif
  if s:try_delete_standalone_lines(ac.target, a:do_flash)
    return 1
  endif
  if a:do_flash
    call s:highlight_flash(ac.target, 'buns')
  endif
  call im#surround#unwrap(ac.target)
  if ac.target.first_pos[0] != ac.target.last_pos[0]
    call s:reindent(ac.target.first_pos[0], ac.target.last_pos[0])
  endif
  call cursor(ac.target.first_pos[0], ac.target.first_pos[1])
  return 1
endfunction"}}}

function! im#surround#delete_setup() abort"{{{
  let cnt = v:count1
  call im#surround#repeat#pending('delete')
  call im#surround#repeat#save('delete', {'count': cnt < 1 ? 1 : cnt})
  set opfunc=im#surround#delete_apply
  return "\<Esc>g@l"
endfunction"}}}

function! im#surround#delete_apply(...) abort"{{{
  let fresh = im#surround#repeat#consume('delete')
  let rep = im#surround#repeat#load('delete')
  if empty(rep)
    return
  endif
  if fresh || !has_key(rep, 'ch')
    let ch = s:getchar()
    if ch ==# ''
      call im#surround#repeat#clear('delete')
      return
    endif
    let rep.ch = ch
    call im#surround#repeat#save('delete', rep)
  endif
  let ok = s:delete_with(rep.ch, get(rep, 'count', 1), fresh)
  if !ok && fresh
    call im#surround#repeat#clear('delete')
  endif
endfunction"}}}

function! s:split_single_to_lines(t, left, right) abort"{{{
  let [fl, fc] = a:t.first_pos
  let [ll, lc] = a:t.last_pos
  let open_len  = get(a:t, 'open_len', 0)
  let close_len = get(a:t, 'close_len', 0)
  let line = getline(fl)
  let head = strpart(line, 0, fc - 1)
  let body = strpart(line, fc - 1 + open_len, max([lc - close_len - (fc - 1) - open_len, 0]))
  let tail = strpart(line, lc)
  call setline(fl, head . a:left)
  call append(fl, body)
  call append(fl + 1, a:right . tail)
  call cursor(fl + 1, 1)
endfunction"}}}

function! s:change_apply_target(t, rep, line_mode) abort"{{{
  let [left, right] = a:rep
  if a:line_mode && a:t.first_pos[0] == a:t.last_pos[0]
    call s:split_single_to_lines(a:t, left, right)
    call s:reindent(a:t.first_pos[0], a:t.first_pos[0] + 2)
    return
  endif
  call im#surround#replace(a:t, left, right)
  if a:t.first_pos[0] != a:t.last_pos[0]
    call s:reindent(a:t.first_pos[0], a:t.last_pos[0])
  endif
  call cursor(a:t.first_pos[0], a:t.first_pos[1])
endfunction"}}}

function! im#surround#change_setup(line_mode) abort"{{{
  let cnt = v:count1
  call im#surround#repeat#pending('change')
  call im#surround#repeat#save('change',
        \ {'count': cnt < 1 ? 1 : cnt, 'line_mode': a:line_mode})
  set opfunc=im#surround#change_apply
  return "\<Esc>g@l"
endfunction"}}}

function! im#surround#change_apply(...) abort"{{{
  let fresh = im#surround#repeat#consume('change')
  let rep = im#surround#repeat#load('change')
  if empty(rep)
    return
  endif
  if fresh || !has_key(rep, 'ch')
    let ch = s:getchar()
    if ch ==# ''
      call im#surround#repeat#clear('change')
      return
    endif
    let rep.ch = ch
  endif
  let ac = s:acquire_target(rep.ch, get(rep, 'count', 1))
  if empty(ac.target)
    if fresh
      call im#surround#repeat#clear('change')
    else
      call im#surround#repeat#save('change', rep)
    endif
    return
  endif
  if fresh || empty(get(rep, 'rep', []))
    let newrep = s:resolve_replacement(ac.found_key, ac.target)
    if empty(newrep)
      call im#surround#repeat#clear('change')
      return
    endif
    let rep.rep = newrep
  endif
  call im#surround#repeat#save('change', rep)
  call s:change_apply_target(ac.target, rep.rep, get(rep, 'line_mode', 0))
endfunction"}}}

function! im#surround#add_setup(line_mode) abort"{{{
  let cnt = v:count1
  call im#surround#repeat#pending('add')
  call im#surround#repeat#save('add',
        \ {'line_mode': a:line_mode, 'count': cnt < 1 ? 1 : cnt})
  set opfunc=im#surround#add_apply
  return "\<Esc>g@"
endfunction"}}}

function! im#surround#add_apply(...) abort"{{{
  let fresh = im#surround#repeat#consume('add')
  let rep = im#surround#repeat#load('add')
  if empty(rep)
    return
  endif
  let cnt = get(rep, 'count', 1)
  let [sl, sc] = [line("'["), col("'[")]
  let [el, ec] = [line("']"), col("']")]
  if fresh || empty(get(rep, 'delim', []))
    let hid = s:highlight_show({'first_pos': [sl, sc], 'last_pos': [el, ec]}, 'full')
    let delim = s:resolve_delims(s:getchar(), cnt)
    call s:highlight_clear(hid)
    if empty(delim)
      call im#surround#repeat#clear('add')
      return
    endif
    let rep.delim = delim
    call im#surround#repeat#save('add', rep)
  else
    let delim = rep.delim
  endif

  if get(rep, 'line_mode', 0)
    call s:wrap_lines(sl, el, delim[0], delim[1])
    call s:reindent(sl, el + 2)
    call cursor(sl + 1, 1)
    return
  endif

  call s:wrap_inline(sl, sc, el, ec, delim[0], delim[1])
  call cursor(sl, sc)
endfunction"}}}

function! s:add_current_with(line_mode, delim) abort"{{{
  if a:line_mode
    if empty(getline('.'))
      return 0
    endif
    let lnum = line('.')
    call s:wrap_lines(lnum, lnum, a:delim[0], a:delim[1])
    call s:reindent(lnum, lnum + 2)
    return 1
  endif
  let text = getline('.')
  let indent = matchstr(text, '^\s*')
  let body = matchstr(text, '^\s*\zs.\{-}\ze\s*$')
  if empty(body)
    return 0
  endif
  let tail_ws = strpart(text, strlen(indent) + strlen(body))
  call setline('.', indent . a:delim[0] . body . a:delim[1] . tail_ws)
  return 1
endfunction"}}}

function! im#surround#add_current_setup(line_mode) abort"{{{
  let cnt = v:count1
  call im#surround#repeat#pending('add_cur')
  call im#surround#repeat#save('add_cur',
        \ {'count': cnt < 1 ? 1 : cnt, 'line_mode': a:line_mode})
  set opfunc=im#surround#add_current_apply
  return "\<Esc>g@l"
endfunction"}}}

function! im#surround#add_current_apply(...) abort"{{{
  let fresh = im#surround#repeat#consume('add_cur')
  let rep = im#surround#repeat#load('add_cur')
  if empty(rep)
    return
  endif
  if fresh || empty(get(rep, 'delim', []))
    let lnum = line('.')
    let hid = s:highlight_show({'first_pos': [lnum, 1], 'last_pos': [lnum, col([lnum, '$'])]}, 'full')
    let ch = s:getchar()
    call s:highlight_clear(hid)
    let delim = s:resolve_delims(ch, get(rep, 'count', 1))
    if empty(delim)
      call im#surround#repeat#clear('add_cur')
      return
    endif
    let rep.delim = delim
    call im#surround#repeat#save('add_cur', rep)
  endif
  let ok = s:add_current_with(get(rep, 'line_mode', 0), rep.delim)
  if !ok && fresh
    call im#surround#repeat#clear('add_cur')
  endif
endfunction"}}}

function! im#surround#visual(line_mode, ...) abort"{{{
  let cnt = a:0 >= 1 && type(a:1) == v:t_number ? a:1 : 1
  let ch = s:getchar()
  if ch ==# ''
    return
  endif
  let vm = visualmode()
  let [sl, sc] = [line("'<"), col("'<")]
  let [el, ec] = [line("'>"), col("'>")]
  let delim = s:resolve_delims(ch, cnt)
  if empty(delim)
    return
  endif
  call im#surround#repeat#save('visual',
        \ {'delim': delim, 'count': cnt, 'line_mode': a:line_mode, 'vm': vm})

  if vm ==# "\<C-v>"
    call s:wrap_block(sl, sc, el, ec, delim[0], delim[1])
    call cursor(sl, sc)
  elseif vm ==# 'V' || a:line_mode
    call s:wrap_lines(sl, el, delim[0], delim[1])
    call s:reindent(sl, el + 2)
    call cursor(sl + 1, 1)
  else
    call s:wrap_inline(sl, sc, el, ec, delim[0], delim[1])
    call cursor(sl, sc)
  endif
endfunction"}}}

function! im#surround#insert(line_mode) abort"{{{
  if im#state#composing()
    return
  endif
  let delim = s:resolve_delims(s:getchar())
  if empty(delim)
    return
  endif
  if a:line_mode
    let left = substitute(delim[0], '\s\+$', '', '')
    let right = substitute(delim[1], '^\s\+', '', '')
    let keys = left . "\<CR>" . "\<End>\<CR>" . right
          \ . repeat("\<Left>", strchars(right)) . "\<Up>"
  else
    let keys = delim[0] . delim[1] . repeat("\<Left>", strchars(delim[1]))
  endif
  call feedkeys(keys, 'ni')
endfunction"}}}

function! s:key_config() abort"{{{
  return [
        \ ['n', s:opt('add_key', 'ys'),                '<Plug>(im-surround-add)'],
        \ ['n', s:opt('add_linewise_key', 'yS'),       '<Plug>(im-surround-add-linewise)'],
        \ ['n', s:opt('add_cur_key', 'yss'),           '<Plug>(im-surround-add-cur)'],
        \ ['n', s:opt('add_cur_linewise_key', 'ySS'),  '<Plug>(im-surround-add-cur-linewise)'],
        \ ['n', s:opt('delete_key', 'ds'),             '<Plug>(im-surround-delete)'],
        \ ['n', s:opt('change_key', 'cs'),             '<Plug>(im-surround-change)'],
        \ ['n', s:opt('change_linewise_key', 'cS'),    '<Plug>(im-surround-change-linewise)'],
        \ ['x', s:opt('visual_key', 'S'),              '<Plug>(im-surround-visual)'],
        \ ['x', s:opt('visual_linewise_key', 'gS'),    '<Plug>(im-surround-visual-linewise)'],
        \ ['i', s:opt('insert_key', '<c-g>s'),         '<Plug>(im-surround-insert)'],
        \ ['i', s:opt('insert_linewise_key', '<c-g>S'),'<Plug>(im-surround-insert-linewise)'],
        \ ]
endfunction"}}}

function! s:opt(name, default) abort"{{{
  let bname = 'im_surround_' . a:name
  if has_key(b:, bname)
    return b:[bname]
  endif
  let gname = 'im_surround_' . a:name
  if has_key(g:, gname)
    return g:[gname]
  endif
  return a:default
endfunction"}}}

function! s:define_plugs() abort"{{{
  nnoremap <expr>   <silent> <Plug>(im-surround-add)              im#surround#add_setup(0)
  nnoremap <expr>   <silent> <Plug>(im-surround-add-linewise)     im#surround#add_setup(1)
  nnoremap <expr>   <silent> <Plug>(im-surround-add-cur)          im#surround#add_current_setup(0)
  nnoremap <expr>   <silent> <Plug>(im-surround-add-cur-linewise) im#surround#add_current_setup(1)
  nnoremap <expr>   <silent> <Plug>(im-surround-delete)           im#surround#delete_setup()
  nnoremap <expr>   <silent> <Plug>(im-surround-change)           im#surround#change_setup(0)
  nnoremap <expr>   <silent> <Plug>(im-surround-change-linewise)  im#surround#change_setup(1)
  xnoremap <silent> <Plug>(im-surround-visual)                    :<C-u>call im#surround#visual(0, v:count1)<CR>
  xnoremap <silent> <Plug>(im-surround-visual-linewise)           :<C-u>call im#surround#visual(1, v:count1)<CR>
  inoremap <silent> <Plug>(im-surround-insert)                    <Cmd>call im#surround#insert(0)<CR>
  inoremap <silent> <Plug>(im-surround-insert-linewise)           <Cmd>call im#surround#insert(1)<CR>
endfunction"}}}

function! s:restore_map(mode, key, mdict) abort"{{{
  let cmd = a:mode
  if a:mdict.noremap
    let cmd .= 'noremap'
  else
    let cmd .= 'map'
  endif
  if get(a:mdict, 'buffer', 0) | let cmd .= ' <buffer>' | endif
  if get(a:mdict, 'nowait', 0) | let cmd .= ' <nowait>' | endif
  if get(a:mdict, 'silent', 0) | let cmd .= ' <silent>' | endif
  if get(a:mdict, 'expr', 0)   | let cmd .= ' <expr>'   | endif
  let rhs = substitute(a:mdict.rhs, "\n", '\\<NL>', 'g')
  execute 'silent! ' . cmd . ' ' . a:key . ' ' . rhs
endfunction"}}}

function! im#surround#enable() abort"{{{
  if !get(g:, 'im_surround_enable', 0) || s:key_active
    return
  endif
  call s:define_plugs()
  let s:saved_maps = {}
  for [mode, key, rhs] in s:key_config()
    if key ==# ''
      continue
    endif
    let sid = mode . ':' . key
    let old = maparg(key, mode, 0, 1)
    execute mode . 'map <silent> ' . key . ' ' . rhs
    let s:saved_maps[sid] = {'mode': mode, 'key': key,
          \ 'map': old, 'rhs': maparg(key, mode)}
  endfor
  let s:key_active = 1
endfunction"}}}

function! im#surround#disable() abort"{{{
  if !s:key_active
    return
  endif
  for sid in keys(s:saved_maps)
    let snap = s:saved_maps[sid]
    if maparg(snap.key, snap.mode) !=# snap.rhs
      continue
    endif
    silent! execute snap.mode . 'unmap ' . snap.key
    if !empty(snap.map)
      call s:restore_map(snap.mode, snap.key, snap.map)
    endif
  endfor
  let s:saved_maps = {}
  let s:key_active = 0
endfunction"}}}
