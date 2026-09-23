function! s:first_char(s) abort"{{{
  return a:s ==# '' ? '' : strcharpart(a:s, 0, 1)
endfunction"}}}

function! s:last_char(s) abort"{{{
  let n = strchars(a:s)
  return n == 0 ? '' : strcharpart(a:s, n - 1, 1)
endfunction"}}}

function! s:is_cjk(ch) abort"{{{
  return a:ch !=# '' && a:ch =~# '^[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]$'
endfunction"}}}

function! s:is_alnum(ch) abort"{{{
  return a:ch !=# '' && a:ch =~# '^[A-Za-z0-9]$'
endfunction"}}}

function! s:protect_ignored(s) abort"{{{
  let words = get(g:, 'im_typeset_ignore_words', [])
  let words = type(words) == v:t_list ? words : []
  if empty(words)
    return [a:s, []]
  endif
  let s = a:s
  let saved = []
  let i = 0
  for w in words
    if type(w) != v:t_string || w ==# '' || strchars(w) <= 1 || stridx(s, w) < 0
      continue
    endif
    " 单字无内部可冻，已在上行守卫跳过；首尾字保留作边界判定，内部用占位符冻结
    let proxy = strcharpart(w, 0, 1) . "\x01" . i . "\x02"
            \ . strcharpart(w, strchars(w) - 1, 1)
    call add(saved, [proxy, w])
    let s = substitute(s, '\V' . escape(w, '\'), escape(proxy, '\&'), 'g')
    let i += 1
  endfor
  return [s, saved]
endfunction"}}}

function! s:restore_ignored(s, saved) abort"{{{
  let s = a:s
  for [proxy, w] in a:saved
    let s = substitute(s, '\V' . escape(proxy, '\'), escape(w, '\&'), 'g')
  endfor
  return s
endfunction"}}}

function! im#typeset#rule#invisible_spaces(ctx, s) abort"{{{
  let s = a:s
  let s = substitute(s, '[\u200b\u200c\u200d\u202c\u2060\u2061\u2062\u2063\u2064\ufeff]', '', 'g')
  if a:ctx.right_char ==# ''
    let s = substitute(s, '\s\+$', '', '')
  endif
  return s
endfunction"}}}

function! im#typeset#rule#halfwidth_word(ctx, s) abort"{{{
  return substitute(a:s, '[Ａ-Ｚａ-ｚ０-９]',
        \ '\=nr2char(char2nr(submatch(0)) - 65248)', 'g')
endfunction"}}}

function! s:fullwidth_special(s, C, hw, fw) abort"{{{
  let s = a:s
  let prev = ''
  while s !=# prev
    let prev = s
    let s = substitute(s, '\(' . a:C . '\)' . a:hw . '\s*\(' . a:C . '\)', '\1' . a:fw . '\2', 'g')
  endwhile
  return substitute(s, '\(' . a:C . '\)' . a:hw . '\s*\(["'']\?\)$', '\1' . a:fw . '\2', '')
endfunction"}}}

function! im#typeset#rule#fullwidth_punctuation(ctx, s) abort"{{{
  let s = a:s
  let C = '[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]'
  let s = s:fullwidth_special(s, C, '\.', '。')
  let s = substitute(s, '\(' . C . '\),\s*', '\1，', 'g')
  let s = substitute(s, '\(' . C . '\);\s*', '\1；', 'g')
  let s = s:fullwidth_special(s, C, '!', '！')
  let s = s:fullwidth_special(s, C, ':', '：')
  let s = substitute(s, '\(' . C . '\)?\s*', '\1？', 'g')
  let s = substitute(s, '\(' . C . '\)\\\s*', '\1、', 'g')
  let s = substitute(s, '(\(' . C . '[^()]*\|[^()]*' . C . '\))', '（\1）', 'g')
  let s = substitute(s, '(\(' . C . '\)', '（\1', 'g')
  let s = substitute(s, '\(' . C . '\))', '\1）', 'g')
  if a:ctx.filetype !=# 'html'
    let s = substitute(s, '<\(' . C . '[^<>]*\|[^<>]*' . C . '\)>', '《\1》', 'g')
    let s = substitute(s, '<\(' . C . '\)', '《\1', 'g')
    let s = substitute(s, '\(' . C . '\)>', '\1》', 'g')
    let s = substitute(s, '<《', '《', 'g')
    let s = substitute(s, '》>', '》', 'g')
  endif
  return s
endfunction"}}}

function! im#typeset#rule#halfwidth_punctuation(ctx, s) abort"{{{
  if a:s =~# '[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]'
    return a:s
  endif
  let s = a:s
  for [fw, hw] in [
        \ ['，', ','], ['。', '.'], ['；', ';'], ['：', ':'],
        \ ['？', '?'], ['！', '!'], ['“', '"'], ['”', '"'],
        \ ['‘', "'"], ['’', "'"], ['（', '('], ['）', ')'],
        \ ['【', '['], ['】', ']'], ['《', '<'], ['》', '>'],
        \ ]
    let s = substitute(s, '\V' . fw, hw, 'g')
  endfor
  let s = substitute(s, '\([,;]\)\([^ ,;]\)', '\1 \2', 'g')
  let s = substitute(s, '\([?!]\)\([^= ]\)', '\1 \2', 'g')
  let s = substitute(s, '\([^A-Za-z0-9\s]\)\(:\)\([A-Za-z0-9]\)', '\1\2 \3', 'g')
  return s
endfunction"}}}

function! im#typeset#rule#no_space_fullwidth(ctx, s) abort"{{{
  let s = a:s
  let W = '\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af\u3001-\u303f\uff00-\uffef'
  let s = substitute(s, '\([' . W . ']\)\s\+\([' . W . ']\)', '\1\2', 'g')
  let s = substitute(s, '\(\w\)\s\+\([，。、！？：；（）「」《》【】“”‘’]\)', '\1\2', 'g')
  let s = substitute(s, '\([“”‘’]\)\s\+\(\w\)', '\1\2', 'g')
  let s = substitute(s, '\([“”‘’]\)\s\+\([' . W . ']\)', '\1\2', 'g')
  let s = substitute(s, '\([' . W . ']\)\s\+\([“”‘’]\)', '\1\2', 'g')
  return s
endfunction"}}}

function! im#typeset#rule#space_word(ctx, s) abort"{{{
  let [s, saved] = s:protect_ignored(a:s)
  let C = '[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]'
  let A = '[A-Za-z0-9]'
  let s = substitute(s, '\(' . C . '\)\(' . A . '\)', '\1 \2', 'g')
  let s = substitute(s, '\(' . A . '\)\(' . C . '\)', '\1 \2', 'g')
  return s:restore_ignored(s, saved)
endfunction"}}}

function! im#typeset#rule#space_bracket(ctx, s) abort"{{{
  let [s, saved] = s:protect_ignored(a:s)
  let C = '[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]'
  let s = substitute(s, '\(' . C . '\)\([(\[]\)', '\1 \2', 'g')
  let s = substitute(s, '\([)\]]\)\(' . C . '\)', '\1 \2', 'g')
  return s:restore_ignored(s, saved)
endfunction"}}}

function! im#typeset#rule#space_number_affix(ctx, s) abort"{{{
  let [s, saved] = s:protect_ignored(a:s)
  let C = '[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]'
  let s = substitute(s, '\(' . C . '\)\([+-][0-9]\+\)', '\1 \2', 'g')
  let s = substitute(s, '\([+-][0-9]\+\)\(' . C . '\)', '\1 \2', 'g')
  let s = substitute(s, '\([0-9]%\)\(' . C . '\)', '\1 \2', 'g')
  let s = substitute(s, '\([A-Za-z0-9][+#]\+\)\(' . C . '\)', '\1 \2', 'g')
  return s:restore_ignored(s, saved)
endfunction"}}}

function! im#typeset#rule#space_punctuation(ctx, s) abort"{{{
  let [s, saved] = s:protect_ignored(a:s)
  let C = '[\u4e00-\u9fff\u3400-\u4dbf\uf900-\ufaff\u3040-\u30ff\uac00-\ud7af]'
  let s = substitute(s, '\(!\)\(' . C . '\)', '\1 \2', 'g')
  return s:restore_ignored(s, saved)
endfunction"}}}

function! im#typeset#rule#repeated_punct(ctx, s) abort"{{{
  let s = a:s
  let s = substitute(s, '。\{3,}', '······', 'g')
  let s = substitute(s, '\([！？]\)\1\{3,}', '\1\1\1', 'g')
  let s = substitute(s, '\([，。；：、“”【】《》]\)\1\+', '\1', 'g')
  return s
endfunction"}}}

function! im#typeset#rule#markdown_space_at_bounds(ctx, s) abort"{{{
  if a:ctx.filetype !=# 'markdown'
    return a:s
  endif
  let s = a:s
  let f = s:first_char(s)
  let l = s:last_char(s)
  if (s:is_cjk(f) || s:is_alnum(f))
        \ && (a:ctx.left_char ==# '`' || a:ctx.left_char ==# '$'
        \ || a:ctx.left_char ==# ')' || a:ctx.right_char ==# ']')
    let s = ' ' . s
  endif
  if (s:is_cjk(l) || s:is_alnum(l))
        \ && (a:ctx.right_char ==# '`' || a:ctx.right_char ==# '$'
        \ || a:ctx.right_char ==# '!' || a:ctx.right_char ==# '[')
    let s = s . ' '
  endif
  return s
endfunction"}}}

function! im#typeset#rule#default_rules() abort"{{{
  return [
        \ function('im#typeset#rule#invisible_spaces'),
        \ function('im#typeset#rule#halfwidth_word'),
        \ function('im#typeset#rule#fullwidth_punctuation'),
        \ function('im#typeset#rule#halfwidth_punctuation'),
        \ function('im#typeset#rule#no_space_fullwidth'),
        \ function('im#typeset#rule#space_word'),
        \ function('im#typeset#rule#space_bracket'),
        \ function('im#typeset#rule#space_number_affix'),
        \ function('im#typeset#rule#space_punctuation'),
        \ function('im#typeset#rule#repeated_punct'),
        \ ]
endfunction"}}}
