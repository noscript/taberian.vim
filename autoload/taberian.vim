function! s:create_tab(bufnr)
  let tab = #{
    \ bufnr: -1,
  \ }
  let tab.bufnr = a:bufnr
  return tab
endfunction

function! s:clamp(value, min, max)
  if a:value < a:min
    return a:min
  elseif a:value > a:max
    return a:max
  else
    return a:value
  endif
endfunction

function! s:winbar_width(tabs)
  return strdisplaywidth(join(a:tabs, '    ')) + 4 " + left\right padding
endfunction

function! s:underscored(str)
  return a:str->str2list()->map({_, val -> list2str([val, 818])})->join('')
endfunction

function! s:bufname(bufnr)
  let bufname = bufname(a:bufnr)->fnamemodify(':t')
  if empty(bufname)
    return '[No Name]'
  endif
  return bufname
endfunction

" tab indexing is zero based
function! s:init_once()
  if !exists('w:taberian')
    let w:taberian = #{
      \ tabs: [],
      \ curr_nr: -1,
      \ prev_nr: -1,
    \ }
  endif
endfunction
call s:init_once()

function! taberian#update_current_window()
  call s:init_once()
  if len(w:taberian.tabs) < 2 || w:taberian.curr_nr == -1
    return
  endif
  let w:taberian.tabs[w:taberian.curr_nr].bufnr = bufnr('%')

  call taberian#render_current_window()
endfunction

function! taberian#create_tab()
  if len(w:taberian.tabs) < 2
    let w:taberian.curr_nr = 0
    let w:taberian.tabs = [s:create_tab(bufnr('%'))]
  endif

  let w:taberian.curr_nr += 1
  call insert(w:taberian.tabs, s:create_tab(bufnr('%')), w:taberian.curr_nr)

  doautocmd User TaberianChanged
endfunction

function! taberian#goto_tab_nr(nr)
  if a:nr == -1 || a:nr >= len(w:taberian.tabs) || w:taberian.curr_nr == a:nr
    return
  endif

  let w:taberian.prev_nr = w:taberian.curr_nr
  let w:taberian.curr_nr = a:nr
  execute 'silent buffer ' . w:taberian.tabs[w:taberian.curr_nr].bufnr

  doautocmd User TaberianChanged
endfunction

function! taberian#goto_tab_offset(offset)
  let nr = s:clamp(w:taberian.curr_nr + a:offset, 0, len(w:taberian.tabs) - 1)
  call taberian#goto_tab_nr(nr)
endfunction

function! taberian#goto_previous_tab()
  call taberian#goto_tab_nr(w:taberian.prev_nr)
endfunction

function! taberian#move_current_tab_offset(offset)
  let nr = w:taberian.curr_nr + a:offset
  if nr < 0 || nr >= len(w:taberian.tabs)
    return
  endif
  let tab = w:taberian.tabs[w:taberian.curr_nr]->deepcopy()
  call remove(w:taberian.tabs, w:taberian.curr_nr)
  call insert(w:taberian.tabs, tab, nr)
  if w:taberian.prev_nr == nr
    let w:taberian.prev_nr = w:taberian.curr_nr
  endif
  let w:taberian.curr_nr = nr
  doautocmd User TaberianChanged
endfunction

function! taberian#close_current_tab()
  if len(w:taberian.tabs) < 2 || w:taberian.curr_nr == -1
    return
  endif

  let old_curr = w:taberian.curr_nr

  if w:taberian.curr_nr > 0
    call taberian#goto_tab_offset(-1)
  else
    call taberian#goto_tab_offset(+1)
  endif

  call remove(w:taberian.tabs, old_curr)
  if len(w:taberian.tabs) < 2
    let w:taberian.tabs = []
    let w:taberian.curr_nr = -1
  endif
  doautocmd User TaberianChanged
endfunction

function! taberian#render_current_window()
  function! s:tab_prototyperim(str, max, remainder)
    let max = a:max
    let elipsis = ''
    let len = strdisplaywidth(a:str)
    if len > max
      if a:remainder.value > 0
        let max += 1
        let a:remainder.value -= 1
      endif
    elseif len < max
      let a:remainder.value += max - len
    endif
    if len > max
      let elipsis = '…'
      let max -= 1
    endif
    return strcharpart(a:str, 0, max) . elipsis
  endfunction

  call s:init_once()
  aunmenu WinBar
  let tabs = gettabwinvar(tabpagenr(), winnr(), 'taberian').tabs->deepcopy()
  let ts_count = len(tabs)
  if ts_count < 2 " render only if more than 1 tab
    return
  endif

  " convert bufnr to tab name:
  call map(tabs, {key, tab -> printf('%d %s ᴮ%d', key + 1, s:bufname(tab.bufnr), tab.bufnr)})

  " make sure there is enough room:
  let win_width = winwidth(0)
  if win_width < 2 " there is a maximized window
    " create empty WinBar:
    execute 'amenu WinBar.\  \ '
    return
  endif
  let min_win_width = tabs->len() * (7 + 2 + 4) + 4 " 7: tab nr (2) + space + tab name (3 chars + '…')
  if win_width < min_win_width
    execute 'vertical resize ' . min_win_width
  endif

  if s:winbar_width(tabs) > win_width
    " drop bufnr
    call map(tabs, {_, tab_name -> substitute(tab_name, '\(.*\) ᴮ.*', '\1', '')})
  endif

  let max_bonus = 10
  while s:winbar_width(tabs) > win_width
    " trim the end
    let max_len = win_width / ts_count
    let remainder = #{value: win_width - max_len * ts_count}
    call map(tabs, {_, tab_name -> s:tab_prototyperim(tab_name, max_len - 4 + max_bonus, remainder)}) " - padding
    let max_bonus -= 1
  endwhile

  " mark current tab:
  let tabs[w:taberian.curr_nr] = s:underscored(tabs[w:taberian.curr_nr])
  " escape whitespace and dots (including Unicode underscored):
  call map(tabs, {_, tab_name -> substitute(tab_name, '[ ̲.̲]', '\\&', 'g')})

  let nr = 0
  for tab in tabs
    execute 'amenu <silent> WinBar.' . tab . ' <Cmd>call taberian#goto_tab_nr(' . nr . ')<CR>'
    let nr += 1
  endfor
endfunction

function! taberian#render_all_windows()
  let winids = gettabinfo(tabpagenr())[0].windows
  for winid in winids
    call win_execute(winid, 'call taberian#update_current_window()')
  endfor
endfunction

function! taberian#confirm_window_close()
  if len(w:taberian.tabs) > 1
    echo 'This window has ' . len(w:taberian.tabs) . ' tabs open: '
    echo w:taberian.tabs->deepcopy()->map({_, tab -> fnamemodify(bufname(tab.bufnr), ':t')})->string()
    echo 'Are you sure you wish to close the window (yN):'
    let choice = nr2char(getchar())
    redraw
    if choice !=# 'y'
      return
    endif
  endif
  close
endfunction
