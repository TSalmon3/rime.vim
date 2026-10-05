
let s:state = {
      \ 'started'         : 0,
      \ 'enabled'         : 0,
      \ 'ready'           : 0,
      \ 'candidate_count' : 0,
      \ 'boundary'        : -1,
      \ 'preedit'         : '',
      \ 'preedit_len'     : 0,
      \ 'vpad'            : 0,
      \ 'cursor_pos'      : 0,
      \ 'sel_start'       : 0,
      \ 'sel_end'         : 0,
      \ 'has_more'        : v:false,
      \ 'switches'        : {},
      \ 'schema_id'       : '',
      \ 'schema_name'     : '',
      \ 'last_commit'     : '',
      \ 'last_fallback'   : '',
      \ }

" 单次组合的前端快照默认值；init/reset_frontend 同源，避免三处重复。
let s:frontend_defaults = {
      \ 'candidate_count' : 0,
      \ 'boundary'        : -1,
      \ 'preedit'         : '',
      \ 'preedit_len'     : 0,
      \ 'vpad'            : 0,
      \ 'cursor_pos'      : 0,
      \ 'sel_start'       : 0,
      \ 'sel_end'         : 0,
      \ 'has_more'        : v:false,
      \ }

function! im#state#get() abort"{{{
  return s:state
endfunction"}}}

" 是否正处在一次未上屏的组合中间。
function! im#state#composing() abort"{{{
  return s:state.boundary >= 0
endfunction"}}}

" (Re)initialize the full state dict to its default values.
function! im#state#init() abort"{{{
  call im#state#reset_frontend()
  let s:state.enabled = 0
  let s:state.last_commit = ''
  let s:state.last_fallback = ''

  if exists('g:im_option_ascii_mode')
    call im#rime#set_option('ascii_mode', get(g:, 'im_option_ascii_mode', 0))
  endif

  if exists('g:im_option_ascii_punct')
    call im#rime#set_option('ascii_punct', get(g:, 'im_option_ascii_punct', 0))
  endif

  if exists('g:im_option_traditional')
    call im#rime#set_option('traditionalization', get(g:, 'im_option_traditional', 0))
  endif

  if exists('g:im_option_emoji')
    call im#rime#set_option('emoji', get(g:, 'im_option_emoji', 0))
  endif

  let names = get(g:, 'im_option_names',
        \ ['ascii_mode', 'ascii_punct', 'traditionalization', 'emoji', 'full_shape'])
  let opt_vals = im#rime#get_options(names)
  if !empty(opt_vals)
    for name in names
      let s:state.switches[name] = get(opt_vals, name, 0) ? 1 : 0
    endfor
  endif

  let schema_info = im#rime#get_schema()
  if !empty(get(schema_info, 'id', ''))
    let s:state.schema_id = schema_info.id
    let s:state.schema_name = get(schema_info, 'name', '')
  endif
endfunction"}}}

function! im#state#sync_notifications(ctx) abort"{{{
  let opt_changed = v:false
  let sch_changed = v:false

  for item in get(a:ctx, 'changed_options', [])
    let name = get(item, 'name', '')
    if empty(name)
      continue
    endif
    if get(s:state.switches, name, -1) != (item.value ? 1 : 0)
      let s:state.switches[name] = item.value ? 1 : 0
      let opt_changed = v:true
    endif
  endfor

  let schema_id = get(a:ctx, 'schema_id', '')
  let schema_dirty = v:false
  if !empty(schema_id) && schema_id !=# s:state.schema_id
    let s:state.schema_id = schema_id
    let s:state.schema_name = get(a:ctx, 'schema_name', '')
    let schema_dirty = v:true
  endif
  if get(a:ctx, 'schema_changed', v:false)
    let sch_changed = v:true
  endif

  return {'opt_changed': opt_changed, 'schema_dirty': schema_dirty, 'sch_changed': sch_changed}
endfunction"}}}

function! im#state#emit(result) abort"{{{
  if get(a:result, 'opt_changed', v:false) || get(a:result, 'schema_dirty', v:false)
    redrawstatus
  endif
  if get(a:result, 'opt_changed', v:false)
    silent! doautocmd User RimeOptionChanged
  endif
  if get(a:result, 'sch_changed', v:false)
    silent! doautocmd User RimeSchemaChanged
  endif
endfunction"}}}

function! im#state#start_composition() abort"{{{
  if im#replace#active() && im#replace#dirty()
    call im#replace#sync()
  endif
  let s:state.boundary = col('.')
  let s:state.vpad = virtcol('.') - 1 - strdisplaywidth(getline('.'))
  if s:state.vpad > 0
    if im#replace#active()
      call im#replace#pad(s:state.vpad)
    endif
    let s:state.boundary = strlen(getline('.')) + s:state.vpad + 1
  else
    let s:state.vpad = 0
  endif
  let s:state.preedit_len = 0
  let s:state.cursor_pos = 0
  let s:state.sel_start = 0
  let s:state.sel_end = 0
endfunction"}}}

function! im#state#reset_frontend() abort"{{{
  for [k, v] in items(s:frontend_defaults)
    let s:state[k] = type(v) == v:t_list ? copy(v) : v
  endfor
  silent! call im#view#reset_cache()
endfunction"}}}

function! im#state#reset_backend() abort"{{{
  let ctx = im#rime#reset()
  return im#state#sync_notifications(ctx)
endfunction"}}}
