let s:default_surrounds = [
      \ {'key': '(',  'add': ['( ', ' )'], 'find': function('im#surround#find#matchpair')},
      \ {'key': ')',  'add': ['(', ')'],   'find': function('im#surround#find#matchpair')},
      \ {'key': '[',  'add': ['[ ', ' ]'], 'find': function('im#surround#find#matchpair')},
      \ {'key': ']',  'add': ['[', ']'],   'find': function('im#surround#find#matchpair')},
      \ {'key': '{',  'add': ['{ ', ' }'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '}',  'add': ['{', '}'],   'find': function('im#surround#find#matchpair')},
      \ {'key': '<',  'add': ['< ', ' >'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '>',  'add': ['<', '>'],   'find': function('im#surround#find#matchpair')},
      \ {"key": "'",  'add': ["'", "'"],   'find': function('im#surround#find#quote')},
      \ {'key': '"',  'add': ['"', '"'],   'find': function('im#surround#find#quote')},
      \ {'key': '`',  'add': ['`', '`'],   'find': function('im#surround#find#quote')},
      \ {'key': 't',  'add': function('im#surround#add#tag'),     'find': function('im#surround#find#tag'),       'replace': function('im#surround#change#tag')},
      \ {'key': 'T',  'add': function('im#surround#add#tag'),     'find': function('im#surround#find#tag'),       'replace': function('im#surround#change#tag_full')},
      \ {'key': 'f',  'add': function('im#surround#add#func'),    'find': function('im#surround#find#func'),      'replace': function('im#surround#change#func')},
      \ {'key': 'i',  'add': function('im#surround#add#input')},
      \ {'key': '‘', 'add': ['‘', '’'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '’', 'add': ['‘', '’'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '“', 'add': ['“', '”'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '”', 'add': ['“', '”'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '（', 'add': ['（', '）'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '）', 'add': ['（', '）'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '【', 'add': ['【', '】'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '】', 'add': ['【', '】'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '「', 'add': ['「', '」'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '」', 'add': ['「', '」'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '『', 'add': ['『', '』'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '』', 'add': ['『', '』'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '《', 'add': ['《', '》'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '》', 'add': ['《', '》'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '＜', 'add': ['＜', '＞'], 'find': function('im#surround#find#matchpair')},
      \ {'key': '＞', 'add': ['＜', '＞'], 'find': function('im#surround#find#matchpair')},
      \ {'key': 'invalid_key_behavior', 'add': function('im#surround#add#invalid'), 'find': function('im#surround#find#invalid')},
      \ ]

let s:default_aliases = [
      \ {'key': 'q', 'targets': ['"', "'"]},
      \ {'key': 'r', 'targets': [']']},
      \ {'key': 'b', 'targets': [')']},
      \ {'key': 'B', 'targets': ['}']},
      \ ]

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

function! im#surround#config#default_surrounds() abort
  return deepcopy(s:default_surrounds)
endfunction

function! im#surround#config#default_aliases() abort
  return deepcopy(s:default_aliases)
endfunction

function! im#surround#config#surrounds() abort"{{{
  return deepcopy(s:opt('surrounds', s:default_surrounds))
endfunction"}}}

function! s:is_single_printable(ch) abort"{{{
  if type(a:ch) != v:t_string || strchars(a:ch) != 1
    return 0
  endif
  return a:ch !~# '[\x00-\x1f\x7f]'
endfunction"}}}

function! s:normalize_entry(entry) abort"{{{
  if type(a:entry) != v:t_dict || empty(a:entry)
    return {}
  endif
  let Key = get(a:entry, 'key', '')
  if type(Key) != v:t_string || empty(Key)
    return {}
  endif
  let Add = get(a:entry, 'add', v:null)
  if type(Add) == v:t_func
  elseif type(Add) == v:t_list && len(Add) == 2
        \ && type(Add[0]) == v:t_string && type(Add[1]) == v:t_string
  else
    let Add = v:null
  endif
  let Find = get(a:entry, 'find', v:null)
  if type(Find) != v:t_func
    let Find = v:null
  endif
  let Replace = get(a:entry, 'replace', v:null)
  if type(Replace) != v:t_func
    let Replace = v:null
  endif
  return {'key': Key, 'add': Add, 'find': Find, 'replace': Replace}
endfunction"}}}

function! s:fallback_entry(char, all) abort"{{{
  for entry in a:all
    if type(entry) == v:t_dict && get(entry, 'key', '') ==# 'invalid_key_behavior'
      let norm = s:normalize_entry(entry)
      if !empty(norm)
        let norm.key = a:char
        if norm.add is v:null
          let norm.add = function('im#surround#add#invalid')
        endif
        if norm.find is v:null
          let norm.find = function('im#surround#find#invalid')
        endif
        return norm
      endif
      break
    endif
  endfor
  return {'key': a:char, 'add': function('im#surround#add#invalid'),
        \ 'find': function('im#surround#find#invalid'), 'replace': v:null}
endfunction"}}}

function! im#surround#config#lookup(char) abort"{{{
  let all = im#surround#config#surrounds()
  if type(all) != v:t_list
    let all = []
  endif
  for entry in all
    if type(entry) == v:t_dict && get(entry, 'key', '') ==# a:char
      return s:normalize_entry(entry)
    endif
  endfor
  if !s:is_single_printable(a:char)
    return {}
  endif
  return s:fallback_entry(a:char, all)
endfunction"}}}

function! im#surround#config#alias_targets(char) abort"{{{
  for entry in deepcopy(s:opt('aliases', s:default_aliases))
    if get(entry, 'key', '') ==# a:char
      return copy(get(entry, 'targets', []))
    endif
  endfor
  return []
endfunction"}}}
