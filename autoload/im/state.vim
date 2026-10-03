
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
      \ 'last_candidates' : [],
      \ 'last_preedit'    : '',
      \ 'last_hl'         : 0,
      \ 'ascii_mode'      : 0,
      \ 'ascii_punct'     : 0,
      \ 'emoji'           : 0,
      \ 'full_shape'      : 0,
      \ 'traditional'     : 0,
      \ 'schema_id'       : '',
      \ 'schema_name'     : '',
      \ 'last_commit'     : '',
      \ 'last_fallback'   : '',
      \ 'ns_id'           : 0,
      \ 'mark_id'         : 0,
      \ 'match_id'        : 0,
      \ 'repl_active'     : 0,
      \ 'base_line'       : '',
      \ 'base_cidx'       : 0,
      \ 'repl_text'       : '',
      \ 'repl_len'        : 0,
      \ }

function! im#state#get() abort
  return s:state
endfunction

" 是否正处在一次未上屏的组合中间。
function! im#state#composing() abort
  return s:state.boundary >= 0
endfunction

" (Re)initialize the full state dict to its default values.
function! im#state#init() abort
  let s:state.enabled        = 0
  let s:state.candidate_count = 0
  let s:state.boundary       = -1
  let s:state.preedit        = ''
  let s:state.preedit_len    = 0
  let s:state.vpad           = 0
  let s:state.cursor_pos     = 0
  let s:state.sel_start      = 0
  let s:state.sel_end        = 0
  let s:state.has_more       = v:false
  let s:state.last_candidates = []
  let s:state.last_preedit    = ''
  let s:state.last_hl         = 0
  let s:state.last_commit     = ''
  let s:state.last_fallback   = ''
  let s:state.mark_id        = 0
  let s:state.match_id       = 0
  let s:state.repl_active      = 0
  let s:state.base_line      = ''
  let s:state.base_cidx      = 0
  let s:state.repl_text      = ''
  let s:state.repl_len       = 0

  if has('nvim') && s:state.ns_id == 0
    let s:state.ns_id = nvim_create_namespace("im_nvim")
  endif

  let opt_vals = im#rime#get_options(['ascii_mode', 'ascii_punct', 'traditionalization', 'emoji'])
  let s:state.ascii_mode = get(opt_vals, 'ascii_mode', 0) ? 1 : 0
  let s:state.ascii_punct = get(opt_vals, 'ascii_punct', 0) ? 1 : 0
  let s:state.traditional = get(opt_vals, 'traditionalization', 0) ? 1 : 0
  let s:state.emoji = get(opt_vals, 'emoji', 0) ? 1 : 0

  let schema_info = im#rime#get_schema()
  if !empty(get(schema_info, 'id', ''))
    let s:state.schema_id = schema_info.id
    let s:state.schema_name = get(schema_info, 'name', '')
  endif
endfunction

function! im#state#sync_notifications(ctx) abort"{{{
  let opt_changed = v:false
  let sch_changed = v:false

  let field_map = {
        \ 'ascii_mode'         : 'ascii_mode',
        \ 'ascii_punct'        : 'ascii_punct',
        \ 'traditionalization' : 'traditional',
        \ 'emoji'              : 'emoji',
        \ 'full_shape'         : 'full_shape',
        \ }
  for item in get(a:ctx, 'changed_options', [])
    let field = get(field_map, get(item, 'name', ''), '')
    if !empty(field) && get(s:state, field, -1) != (item.value ? 1 : 0)
      let s:state[field] = item.value ? 1 : 0
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

  if opt_changed || schema_dirty
    redrawstatus
  endif
  if opt_changed
    silent! doautocmd User RimeOptionChanged
  endif
  if sch_changed
    silent! doautocmd User RimeSchemaChanged
  endif
endfunction"}}}

function! im#state#start_composition() abort"{{{
  let state = im#state#get()
  if im#replace#active() && im#replace#dirty()
    call im#replace#sync()
  endif
  let state.boundary    = col('.')
  let state.vpad        = virtcol('.') - 1 - strdisplaywidth(getline('.'))
  if state.vpad > 0
    if im#replace#active()
      let state.base_line = state.base_line . repeat(' ', state.vpad)
      let state.base_cidx = state.base_cidx + state.vpad
    endif
    let state.boundary  = strlen(getline('.')) + state.vpad + 1
  else
    let state.vpad      = 0
  endif
  let state.preedit_len = 0
  let state.cursor_pos  = 0
  let state.sel_start   = 0
  let state.sel_end     = 0
endfunction"}}}

function! im#state#reset_frontend() abort
  let s:state.boundary        = -1
  let s:state.candidate_count = 0
  let s:state.preedit         = ''
  let s:state.preedit_len     = 0
  let s:state.vpad            = 0
  let s:state.cursor_pos      = 0
  let s:state.sel_start       = 0
  let s:state.sel_end         = 0
  let s:state.last_candidates = []
  let s:state.last_preedit    = ''
  let s:state.last_hl         = 0
endfunction

function! im#state#reset_backend() abort
  let ctx = im#rime#reset()
  call im#state#sync_notifications(ctx)
endfunction

function! im#state#reset_replace() abort
  let s:state.repl_active = 0
  let s:state.base_line = ''
  let s:state.base_cidx = 0
  let s:state.repl_text = ''
  let s:state.repl_len  = 0
endfunction
