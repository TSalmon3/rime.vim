
let s:state = {
      \ 'started'         : 0,
      \ 'enabled'         : 0,
      \ 'candidate_count' : 0,
      \ 'boundary'        : -1,
      \ 'preedit'         : '',
      \ 'preedit_len'     : 0,
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
      \ 'locked'          : 0,
      \ 'schema'          : '',
      \ 'last_commit'     : '',
      \ 'ns_id'           : 0,
      \ 'mark_id'         : 0,
      \ 'match_id'        : 0,
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
  let s:state.cursor_pos     = 0
  let s:state.sel_start      = 0
  let s:state.sel_end        = 0
  let s:state.has_more       = v:false
  let s:state.last_candidates = []
  let s:state.last_preedit    = ''
  let s:state.last_hl         = 0
  let s:state.last_commit     = ''
  let s:state.mark_id        = 0
  let s:state.match_id       = 0

  if has('nvim') && s:state.ns_id == 0
    let s:state.ns_id = nvim_create_namespace("im_nvim")
  endif

  let s:state.ascii_mode = im#rime#get_option('ascii_mode')
  let s:state.ascii_punct = im#rime#get_option('ascii_punct')
  let s:state.traditional = im#rime#get_option('traditionalization')
endfunction

" Reset per-composition fields; called whenever the current composition
" ends, one way or another (confirmed, cancelled, or interrupted).
function! im#state#reset_input() abort
  let s:state.boundary        = -1
  let s:state.candidate_count = 0
  let s:state.preedit         = ''
  let s:state.preedit_len     = 0
  let s:state.cursor_pos      = 0
  let s:state.sel_start       = 0
  let s:state.sel_end         = 0
  let s:state.last_candidates = []
  let s:state.last_preedit    = ''
  let s:state.last_hl         = 0
  call im#rime#reset()
endfunction
