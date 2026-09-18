let s:cache = {}
let s:pending = ''

function! im#surround#repeat#pending(action) abort
  let s:pending = a:action
  if has_key(s:cache, a:action)
    call remove(s:cache, a:action)
  endif
endfunction

function! im#surround#repeat#consume(action) abort
  if s:pending ==# a:action
    let s:pending = ''
    return 1
  endif
  return 0
endfunction

function! im#surround#repeat#save(action, data) abort
  let s:cache[a:action] = deepcopy(a:data)
endfunction

function! im#surround#repeat#load(action) abort
  return deepcopy(get(s:cache, a:action, {}))
endfunction

function! im#surround#repeat#clear(...) abort
  if a:0 == 0
    let s:cache = {}
    let s:pending = ''
  else
    if has_key(s:cache, a:1)
      call remove(s:cache, a:1)
    endif
    if s:pending ==# a:1
      let s:pending = ''
    endif
  endif
endfunction
