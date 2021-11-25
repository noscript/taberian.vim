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
  return a:str->str2list()->map({_, val -> list2str([val, 0x0332])})->join('')
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

function! taberian#state_export() abort
  let state = []
  for tabinfo in gettabinfo()
    let tab = #{
      \ tabnr: tabinfo.tabnr,
      \ windows: [],
    \ }
    for winid in tabinfo.windows
      let win = gettabwinvar(tab.tabnr, winid, 'taberian', {})->deepcopy()
      if empty(win) || len(win.tabs) < 2 " only save if more than 1 tab
        continue
      endif

      " convert bufnrs to file paths:
      for tab in win.tabs
        let tab.buffer = fnamemodify(bufname(tab.bufnr), ':~:.')
        unlet tab.bufnr
      endfor

      let win.winnr = win_id2tabwin(winid)[1]
      unlet win.prev_nr

      call add(tab.windows, win)
    endfor
    if !empty(tab.windows)
      call add(state, tab)
    endif
  endfor
  return state
endfunction

function! taberian#state_import(state)
  for tabinfo in gettabinfo()
    let tabnr = tabinfo.tabnr
    let tabs = a:state->deepcopy()->filter({_, val -> val.tabnr == tabnr})
    if empty(tabs)
      continue
    endif
    let tab = tabs[0]

    for winid in tabinfo.windows
      let [_, winnr] = win_id2tabwin(winid)
      let wins = tab.windows->deepcopy()->filter({_, val -> val.winnr == winnr})
      if empty(wins)
        continue
      endif
      let win = wins[0]

      unlet win.winnr

      " convert file paths to bufnrs:
      for tab in win.tabs
        execute 'badd ' . tab.buffer
        let tab.bufnr = bufnr(tab.buffer)
        unlet tab.buffer
      endfor

      let old_win = gettabwinvar(tabnr, winid, 'taberian', {})
      call extend(old_win, win)
      call settabwinvar(tabnr, winid, 'taberian', old_win)
      call win_execute(winid, 'buffer ' . old_win.tabs[old_win.curr_nr].bufnr)
    endfor
  endfor
endfunction
