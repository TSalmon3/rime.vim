let s:default_pairs = [
      \ {'open': '(',  'close': ')'},
      \ {'open': '[',  'close': ']'},
      \ {'open': '{',  'close': '}'},
      \ {'open': '<',  'close': '>'},
      \ {'open': '（', 'close': '）'},
      \ {'open': '【', 'close': '】'},
      \ {'open': '「', 'close': '」'},
      \ {'open': '『', 'close': '』'},
      \ {'open': '《', 'close': '》'},
      \ {'open': '＜', 'close': '＞'},
      \ {'open': '‘', 'close': '’'},
      \ {'open': '“', 'close': '”'},
      \ {'open': '〈', 'close': '〉'},
      \ {'open': '〔', 'close': '〕'},
      \ {'open': '〖', 'close': '〗'},
      \ {'open': '［', 'close': '］'},
      \ {'open': '｛', 'close': '｝'},
      \ ]

let s:default_quotes = ['"', "'", '`']

let s:default_separators = [
      \ ',', '.', ';', ':', '!', '?',
      \ '-', '/', '|', '*', '_',
      \ '，', '。', '；', '：', '！', '？', '、',
      \ ]

let s:default_aliases = {
      \ 'b': [')'],
      \ 'B': ['}'],
      \ 'r': [']'],
      \ 'q': ['"', "'"],
      \ }

function! s:opt(name, default) abort"{{{
  let name = 'im_textobj_' . a:name
  if has_key(b:, name)
    return b:[name]
  endif
  if has_key(g:, name)
    return g:[name]
  endif
  return a:default
endfunction"}}}

function! im#textobj#config#default_pairs() abort"{{{
  return deepcopy(s:default_pairs)
endfunction"}}}

function! im#textobj#config#default_quotes() abort"{{{
  return deepcopy(s:default_quotes)
endfunction"}}}

function! im#textobj#config#default_separators() abort"{{{
  return deepcopy(s:default_separators)
endfunction"}}}

function! im#textobj#config#default_aliases() abort"{{{
  return deepcopy(s:default_aliases)
endfunction"}}}

function! s:single_char(raw) abort"{{{
  return type(a:raw) == v:t_string && strchars(a:raw) == 1 ? a:raw : ''
endfunction"}}}

function! s:normalize_pair(raw) abort"{{{
  if type(a:raw) != v:t_dict
    return {}
  endif
  let open = s:single_char(get(a:raw, 'open', ''))
  let close = s:single_char(get(a:raw, 'close', ''))
  if empty(open) || empty(close) || open ==# close
    return {}
  endif
  return {'kind': 'pair', 'open': open, 'close': close}
endfunction"}}}

function! s:normalize_quote(raw) abort"{{{
  let quote = s:single_char(a:raw)
  return empty(quote) ? {} : {'kind': 'quote', 'quote': quote}
endfunction"}}}

function! s:normalize_separator(raw) abort"{{{
  let sep = s:single_char(a:raw)
  return empty(sep) ? {} : {'kind': 'separator', 'sep': sep}
endfunction"}}}

function! s:list_of(value, default) abort"{{{
  if type(a:value) == v:t_list
    return copy(a:value)
  endif
  return copy(a:default)
endfunction"}}}

function! s:pairs() abort"{{{
  let out = []
  for raw in s:list_of(s:opt('pairs', s:default_pairs), s:default_pairs)
    let spec = s:normalize_pair(raw)
    if !empty(spec)
      call add(out, spec)
    endif
  endfor
  return out
endfunction"}}}

function! s:quotes() abort"{{{
  let out = []
  for raw in s:list_of(s:opt('quotes', s:default_quotes), s:default_quotes)
    let spec = s:normalize_quote(raw)
    if !empty(spec)
      call add(out, spec)
    endif
  endfor
  return out
endfunction"}}}

function! s:separators() abort"{{{
  let out = []
  for raw in s:list_of(s:opt('separators', s:default_separators), s:default_separators)
    let spec = s:normalize_separator(raw)
    if !empty(spec)
      call add(out, spec)
    endif
  endfor
  return out
endfunction"}}}

function! s:dedupe_specs(specs) abort"{{{
  let claimed = {}
  let out = []
  for spec in a:specs
    if spec.kind ==# 'pair'
      let chars = [spec.open, spec.close]
    elseif spec.kind ==# 'quote'
      let chars = [spec.quote]
    else
      let chars = [spec.sep]
    endif

    let conflict = 0
    for char in chars
      if has_key(claimed, char)
        let conflict = 1
        break
      endif
    endfor
    if conflict
      continue
    endif

    for char in chars
      let claimed[char] = 1
    endfor
    call add(out, spec)
  endfor
  return out
endfunction"}}}

function! s:normalize_alias_entry(key, targets) abort"{{{
  let key = s:single_char(a:key)
  if empty(key) || type(a:targets) != v:t_list
    return {}
  endif
  let targets = filter(copy(a:targets), 'type(v:val) == v:t_string && !empty(v:val)')
  return empty(targets) ? {} : {'key': key, 'targets': targets}
endfunction"}}}

function! s:aliases() abort"{{{
  let raw = s:opt('aliases', s:default_aliases)
  if type(raw) != v:t_dict
    return []
  endif
  let out = []
  for key in keys(raw)
    let entry = s:normalize_alias_entry(key, raw[key])
    if !empty(entry)
      call add(out, entry)
    endif
  endfor
  return out
endfunction"}}}

function! s:matches(spec, char) abort"{{{
  if a:spec.kind ==# 'pair'
    return a:char ==# a:spec.open || a:char ==# a:spec.close
  elseif a:spec.kind ==# 'quote'
    return a:char ==# a:spec.quote
  elseif a:spec.kind ==# 'separator'
    return a:char ==# a:spec.sep
  endif
  return 0
endfunction"}}}

function! im#textobj#config#candidates(char) abort"{{{
  for alias in s:aliases()
    if alias.key ==# a:char
      return copy(alias.targets)
    endif
  endfor
  return [a:char]
endfunction"}}}

function! im#textobj#config#specifications(typed, translated) abort"{{{
  let char = type(a:translated) == v:t_string && !empty(a:translated)
        \ ? a:translated
        \ : a:typed
  if type(char) != v:t_string || empty(char)
    return []
  endif

  let specs = s:dedupe_specs(s:pairs() + s:quotes() + s:separators())
  let out = []
  let seen = {}
  for candidate in im#textobj#config#candidates(char)
    for spec in specs
      if s:matches(spec, candidate)
        let id = string(spec)
        if !has_key(seen, id)
          let seen[id] = 1
          call add(out, spec)
        endif
        break
      endif
    endfor
  endfor
  return out
endfunction"}}}
