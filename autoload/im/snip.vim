let s:snip = {'active': 0, 'engine': '', 'input': '', 'keyword': '', 'items': []}
let s:engines = {}

function! s:prefix() abort"{{{
  let p = get(g:, 'im_snip_prefix', 'S')
  if type(p) != v:t_string || empty(p)
    return 'S'
  endif
  return p
endfunction"}}}

function! s:enabled() abort"{{{
  return get(g:, 'im_snip_enabled', 0)
endfunction"}}}

function! s:engine_name() abort"{{{
  let p = get(g:, 'im_snip_engine', 'luasnip')
  if type(p) != v:t_string
    return ''
  endif
  if !has_key(s:engines, p)
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
  let s:snip.engine = get(a:found, 'engine', '')
  let s:snip.input = a:input
  let s:snip.keyword = a:keyword
  let s:snip.items = copy(a:found.items)
endfunction"}}}

function! im#snip#deactivate() abort"{{{
  let s:snip = {'active': 0, 'engine': '', 'input': '', 'keyword': '', 'items': []}
  call im#opt#use_im()
endfunction"}}}

function! im#snip#register_engine(name, impl) abort"{{{
  if type(a:name) != v:t_string || empty(a:name)
    return 0
  endif
  if type(a:impl) != v:t_dict
        \ || type(get(a:impl, 'query', 0)) != v:t_func
        \ || type(get(a:impl, 'expand', 0)) != v:t_func
    return 0
  endif
  let s:engines[a:name] = {'query': a:impl.query,
        \                  'expand': a:impl.expand}
  return 1
endfunction"}}}

function! im#snip#register_builtin_engines() abort"{{{
  call im#snip#register_engine('luasnip',
        \ {'query': function('im#snip#luasnip#query'),
        \  'expand': function('im#snip#luasnip#expand')})
  call im#snip#register_engine('ultisnips',
        \ {'query': function('im#snip#ultisnips#query'),
        \  'expand': function('im#snip#ultisnips#expand')})
endfunction"}}}

function! s:query(keyword) abort"{{{
  let name = s:engine_name()
  if empty(name)
    return {'items': [], 'engine': ''}
  endif
  let impl = get(s:engines, name, {})
  if empty(impl)
    return {'items': [], 'engine': ''}
  endif
  try
    let items = impl.query(a:keyword)
  catch /^Vim(let):\|^Vim\%((\a\+)\)\=:E\d\+:/
    let items = []
  endtry
  if empty(items)
    return {'items': [], 'engine': ''}
  endif
  return {'items': items, 'engine': name}
endfunction"}}}

function! s:expand(item, engine_name) abort"{{{
  call im#view#commit_text('')
  call im#view#clean_hl()
  call im#state#reset_frontend()
  call im#state#emit(im#state#reset_backend())
  " silent! doautocmd User RimeIMCommit
  let impl = get(s:engines, a:engine_name, {})
  let word = get(a:item, 'word', '')
  if !empty(word)
    let lnum = line('.')
    let col = col('.')
    let cur = getline(lnum)
    call setline(lnum, strpart(cur, 0, col - 1) . word . strpart(cur, col - 1))
    call cursor(lnum, col + strlen(word))
  endif
  call impl.expand()
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
  let engine_name = s:snip.engine
  call im#snip#deactivate()
  call s:expand(item, engine_name)
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
  if !s:enabled() || empty(s:engine_name())
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
  if !empty(found.items) && !empty(found.engine)
    call im#snip#activate(found, a:input, kw)
    call im#view#render_snip(a:input, found.items, a:ctx)
    return 1
  endif
  call im#snip#deactivate()
  return 0
endfunction"}}}
