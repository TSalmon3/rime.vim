let s:user = {}

function! im#opt#save() abort"{{{
  if !empty(s:user)
    return
  endif
  let s:user = {'completeopt': &completeopt, 'pumheight': &pumheight}
endfunction"}}}

function! im#opt#use_im() abort"{{{
  if empty(s:user)
    return
  endif
  set completeopt=menuone,noinsert
  let &pumheight = get(g:, 'im_pumheight', 9)
endfunction"}}}

function! im#opt#use_snip() abort"{{{
  if empty(s:user)
    return
  endif
  set completeopt=menuone,noinsert,noselect
  let &pumheight = 9
endfunction"}}}

function! im#opt#use_user() abort"{{{
  if empty(s:user)
    return
  endif
  let &completeopt = s:user.completeopt
  let &pumheight   = s:user.pumheight
endfunction"}}}

function! im#opt#restore() abort"{{{
  call im#opt#use_user()
  let s:user = {}
endfunction"}}}
