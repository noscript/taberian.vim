vim9script

def S__create_tab(bufnr__a: number): dict<any>
  var tab = {
    bufnr: -1,
  }
  tab.bufnr = bufnr__a
  return tab
enddef

def S__clamp(value__a: number, min__a: number, max__a: number): number
  if value__a < min__a
    return min__a
  elseif value__a > max__a
    return max__a
  else
    return value__a
  endif
enddef

def S__winbar_width(tabs__a: list<any>): number
  return strdisplaywidth(join(tabs__a, '    ')) + 4 # + left\right padding
enddef

def S__underscored(str__a: string): string
  return str__a->str2list()->map((_, val) => list2str([val, 0x0332]))->join('')
enddef

def S__bufname(bufnr__a: number): string
  var bufname = bufname(bufnr__a)->fnamemodify(':t')
  if empty(bufname)
    return '[No Name]'
  endif
  return bufname
enddef

# tab indexing is zero based
def S__init_once()
  if !exists('w:taberian')
    w:taberian = {
      tabs: [],
      curr_nr: -1,
      prev_nr: -1,
    }
  endif
enddef
S__init_once()

def S__update_current_window()
  S__init_once()
  if len(w:taberian.tabs) < 2 || w:taberian.curr_nr == -1
    return
  endif
  w:taberian.tabs[w:taberian.curr_nr].bufnr = bufnr('%')

  Render_current_window()
enddef

export def Create_tab()
  if len(w:taberian.tabs) < 2
    w:taberian.curr_nr = 0
    w:taberian.tabs = [S__create_tab(bufnr('%'))]
  endif

  ++w:taberian.curr_nr
  insert(w:taberian.tabs, S__create_tab(bufnr('%')), w:taberian.curr_nr)

  doautocmd User TaberianChanged
enddef

export def Goto_tab_nr(nr__a: number)
  if nr__a == -1 || nr__a >= len(w:taberian.tabs) || w:taberian.curr_nr == nr__a
    return
  endif

  w:taberian.prev_nr = w:taberian.curr_nr
  w:taberian.curr_nr = nr__a
  execute 'silent buffer ' .. w:taberian.tabs[w:taberian.curr_nr].bufnr

  doautocmd User TaberianChanged
enddef

export def Goto_tab_offset(offset__a: number)
  var nr = S__clamp(w:taberian.curr_nr + offset__a, 0, len(w:taberian.tabs) - 1)
  Goto_tab_nr(nr)
enddef

export def Goto_previous_tab()
  Goto_tab_nr(w:taberian.prev_nr)
enddef

export def Move_current_tab_offset(offset__a: number)
  var nr = w:taberian.curr_nr + offset__a
  if nr < 0 || nr >= len(w:taberian.tabs)
    return
  endif
  var tab = w:taberian.tabs[w:taberian.curr_nr]->deepcopy()
  remove(w:taberian.tabs, w:taberian.curr_nr)
  insert(w:taberian.tabs, tab, nr)
  if w:taberian.prev_nr == nr
    w:taberian.prev_nr = w:taberian.curr_nr
  endif
  w:taberian.curr_nr = nr
  doautocmd User TaberianChanged
enddef

export def Close_current_tab()
  if len(w:taberian.tabs) < 2 || w:taberian.curr_nr == -1
    return
  endif

  var old_curr = w:taberian.curr_nr

  if w:taberian.curr_nr > 0
    Goto_tab_offset(-1)
  else
    Goto_tab_offset(+1)
  endif

  remove(w:taberian.tabs, old_curr)
  if len(w:taberian.tabs) < 2
    w:taberian.tabs = []
    w:taberian.curr_nr = -1
  endif
  doautocmd User TaberianChanged
enddef

def S__tab_prototyperim(str__a: string, max__a: number, remainder__a: dict<number>): string
  var max = max__a
  var elipsis = ''
  var len = strdisplaywidth(str__a)
  if len > max
    if remainder__a.value > 0
      ++max
      --remainder__a.value
    endif
  elseif len < max
    remainder__a.value += max - len
  endif
  if len > max
    elipsis = '…'
    --max
  endif
  return strcharpart(str__a, 0, max) .. elipsis
enddef

export def Render_current_window()
  S__init_once()
  aunmenu WinBar
  var tabs = gettabwinvar(tabpagenr(), winnr(), 'taberian').tabs->deepcopy()
  var ts_count = len(tabs)
  if ts_count < 2 # render only if more than 1 tab
    return
  endif

  # convert bufnr to tab name:
  map(tabs, (key, tab) => printf('%d %s ᴮ%d', key + 1, S__bufname(tab.bufnr), tab.bufnr))

  # make sure there is enough room:
  var win_width = winwidth(0)
  if win_width < 2 # there is a maximized window
    # create empty WinBar:
    execute 'amenu WinBar.\  \ '
    return
  endif
  var min_win_width = tabs->len() * (7 + 2 + 4) + 4 # 7: tab nr (2) + space + tab name (3 chars + '…')
  if win_width < min_win_width
    execute 'vertical resize ' .. min_win_width
  endif

  if S__winbar_width(tabs) > win_width
    # drop bufnr:
    map(tabs, (_, tab_name) => substitute(tab_name, '\(.*\) ᴮ.*', '\1', ''))
  endif

  var max_bonus = 10
  while S__winbar_width(tabs) > win_width
    # trim the end:
    var max_len = win_width / ts_count
    var remainder = {value: win_width - max_len * ts_count}
    map(tabs, (_, tab_name) => S__tab_prototyperim(tab_name, max_len - 4 + max_bonus, remainder)) # - padding
    --max_bonus
  endwhile

  # mark current tab:
  tabs[w:taberian.curr_nr] = S__underscored(tabs[w:taberian.curr_nr])
  # escape whitespace and dots (including Unicode underscored):
  map(tabs, (_, tab_name) => substitute(tab_name, '[ ̲.̲]', '\\&', 'g'))

  var nr = 0
  for tab in tabs
    execute 'amenu <silent> WinBar.' .. tab .. ' <ScriptCmd>taberian#Goto_tab_nr(' .. nr .. ')<CR>'
    ++nr
  endfor
enddef

export def Render_all_windows()
  var winids = gettabinfo(tabpagenr())[0].windows
  for winid in winids
    win_execute(winid, 'S__update_current_window()')
  endfor
enddef

export def Confirm_window_close()
  if len(w:taberian.tabs) > 1
    echo 'This window has ' .. len(w:taberian.tabs) .. ' tabs open: '
    echo w:taberian.tabs->deepcopy()->map((_, tab) => fnamemodify(bufname(tab.bufnr), ':t'))->string()
    echo 'Are you sure you wish to close the window (yN):'
    var choice = nr2char(getchar())
    redraw
    if choice != 'y'
      return
    endif
  endif
  close
enddef

export def State_export(): list<any>
  var state = []
  for tabinfo in gettabinfo()
    var tab = {
      tabnr: tabinfo.tabnr,
      windows: [],
    }
    for winid in tabinfo.windows
      var win = gettabwinvar(tab.tabnr, winid, 'taberian', {})->deepcopy()
      if empty(win) || len(win.tabs) < 2 # only save if more than 1 tab
        continue
      endif

      # convert bufnrs to file paths:
      for tab in win.tabs
        tab.buffer = fnamemodify(bufname(tab.bufnr), ':~:.')
        unlet tab.bufnr
      endfor

      win.winnr = win_id2tabwin(winid)[1]
      unlet win.prev_nr

      add(tab.windows, win)
    endfor
    if !empty(tab.windows)
      add(state, tab)
    endif
  endfor
  return state
enddef

export def State_import(state__a: list<any>)
  for tabinfo in gettabinfo()
    var tabnr = tabinfo.tabnr
    var tabs = state__a->deepcopy()->filter((_, val) => val.tabnr == tabnr)
    if empty(tabs)
      continue
    endif
    var tab = tabs[0]

    for winid in tabinfo.windows
      var [_, winnr] = win_id2tabwin(winid)
      var wins = tab.windows->deepcopy()->filter((_, val) => val.winnr == winnr)
      if empty(wins)
        continue
      endif
      var win = wins[0]

      unlet win.winnr

      # convert file paths to bufnrs:
      for tab in win.tabs
        execute 'badd ' .. tab.buffer
        tab.bufnr = bufnr(tab.buffer)
        unlet tab.buffer
      endfor

      var old_win = gettabwinvar(tabnr, winid, 'taberian', {})
      extend(old_win, win)
      settabwinvar(tabnr, winid, 'taberian', old_win)
      win_execute(winid, 'buffer ' .. old_win.tabs[old_win.curr_nr].bufnr)
    endfor
  endfor
enddef
