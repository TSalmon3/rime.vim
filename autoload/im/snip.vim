let s:snip = {'active': 0, 'preset': '', 'input': '', 'keyword': '', 'items': []}
let s:backends = {}

function! s:prefix() abort"{{{
  let p = get(g:, 'im_snip_prefix', 'S')
  if type(p) != v:t_string || empty(p)
    return 'S'
  endif
  return p
endfunction"}}}

function! s:enabled() abort"{{{
  return get(g:, 'im_snip_enabled', 1)
endfunction"}}}

function! s:preset() abort"{{{
  let p = get(g:, 'im_snip_preset', 'luasnip')
  if type(p) != v:t_string
    return ''
  endif
  if index(['luasnip', 'ultisnips'], p) < 0
    return ''
  endif
  return p
endfunction"}}}

function! im#snip#active() abort"{{{
  return s:snip.active
endfunction"}}}

function! im#snip#activate(found, input, keyword) abort"{{{
  call im#opt#use_snip()
  let s:snip.active = 1
  let s:snip.preset = get(a:found, 'preset', '')
  let s:snip.input = a:input
  let s:snip.keyword = a:keyword
  let s:snip.items = copy(a:found.items)
endfunction"}}}

function! im#snip#deactivate() abort"{{{
  let s:snip = {'active': 0, 'preset': '', 'input': '', 'keyword': '', 'items': []}
  call im#opt#use_im()
endfunction"}}}

function! im#snip#register_backends() abort"{{{
  let s:backends.luasnip = {'query': function('im#snip#luasnip#query'),
        \                   'expand': function('im#snip#luasnip#expand')}
  let s:backends.ultisnips = {'query': function('im#snip#ultisnips#query'),
        \                     'expand': function('im#snip#ultisnips#expand')}
endfunction"}}}

function! s:query(keyword) abort"{{{
  let name = s:preset()
  if empty(name)
    return {'items': [], 'preset': ''}
  endif
  let backend = get(s:backends, name, {})
  if empty(backend)
    return {'items': [], 'preset': ''}
  endif
  try
    let items = backend.query(a:keyword)
  catch /^Vim(let):\|^Vim\%((\a\+)\)\=:E\d\+:/
    let items = []
  endtry
  if empty(items)
    return {'items': [], 'preset': ''}
  endif
  return {'items': items, 'preset': name}
endfunction"}}}

function! s:expand(item, preset) abort"{{{
  call im#view#commit_text('')
  call im#view#clean_hl()
  call im#state#reset_frontend()
  call im#state#emit(im#state#reset_backend())
  " silent! doautocmd User RimeIMCommit
  let backend = get(s:backends, a:preset, {})
  let word = get(a:item, 'word', '')
  if !empty(word)
    let lnum = line('.')
    let col = col('.')
    let cur = getline(lnum)
    call setline(lnum, strpart(cur, 0, col - 1) . word . strpart(cur, col - 1))
    call cursor(lnum, col + strlen(word))
  endif
  call backend.expand()
  call im#snip#deactivate()
endfunction"}}}

function! s:commit(text) abort"{{{
  call im#view#commit_text(a:text)
  call im#view#clean_hl()
  call im#state#reset_frontend()
  call im#state#emit(im#state#reset_backend())
  " silent! doautocmd User RimeIMCommit
  call im#snip#deactivate()
endfunction"}}}

function! s:accept(idx) abort"{{{
  if a:idx < 0 || a:idx >= len(s:snip.items)
    return 0
  endif
  let item = s:snip.items[a:idx]
  let preset = s:snip.preset
  call im#snip#deactivate()
  call s:expand(item, preset)
  return 1
endfunction"}}}

function! im#snip#cr() abort"{{{
  let sel = get(complete_info(['selected']), 'selected', -1)
  if sel >= 0
    call s:accept(sel)
  else
    call s:commit(s:snip.input)
  endif
endfunction"}}}

function! s:parse(input) abort"{{{
  if !s:enabled() || empty(s:preset())
    return v:null
  endif
  let p = s:prefix()
  let n = strlen(p)
  if strpart(a:input, 0, n) !=# p
    return v:null
  endif
  return strpart(a:input, n)
endfunction"}}}

function! im#snip#switch_inline_ascii(input) abort"{{{
  if s:parse(a:input) is v:null
    return {}
  endif
  if get(im#state#get().switches, 'ascii_mode', 0)
    return {}
  endif
  let ctx = im#rime#switch_ascii_mode('inline_ascii')
  if !get(ctx, 'composing', v:false)
    return {}
  endif
  return ctx
endfunction"}}}

function! im#snip#takeover(input, ctx) abort"{{{
  let kw = s:parse(a:input)
  if kw is v:null
    if im#snip#active()
      call im#snip#deactivate()
    endif
    return 0
  endif
  let found = s:query(kw)
  if !empty(found.items) && !empty(found.preset)
    call im#snip#activate(found, a:input, kw)
    call im#view#render_snip(a:input, found.items, a:ctx)
    return 1
  endif
  call im#snip#deactivate()
  return 0
endfunction"}}}
