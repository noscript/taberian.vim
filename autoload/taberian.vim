vim9script

# defaults:
if !exists('g:taberian#hide_tab_index')
  g:taberian#hide_tab_index = false
endif
if !exists('g:taberian#hide_bufnr')
  g:taberian#hide_bufnr = false
endif
if !exists('g:taberian#separator')
  g:taberian#separator = '▕' # Right One Eighth Block U+2595
endif

var s_sel_prop = 'taberian_sel_prop'
export def On_Colorscheme()
  hlset([
    {name: 'TaberianTab', linksto: 'TabLine'},
    {name: 'TaberianTabSel', linksto: 'TabLineSel'},
  ])
  silent! prop_type_add(s_sel_prop, {highlight: 'TaberianTabSel'})
enddef
On_Colorscheme()

def S__create_tab(bufnr__a: number): dict<any>
  return {
    bufnr: bufnr__a,
    title: '',
    col_in_popup: -1,
  }
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

def S__popup_line(tab_names__a: list<list<string>>): string
  return tab_names__a->flattennew()->join('')
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
      popup_id: -1,
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
  var bufnr = bufnr('%')

  if len(w:taberian.tabs) < 2
    w:taberian.curr_nr = 0
    w:taberian.tabs = [S__create_tab(bufnr)]
  endif

  ++w:taberian.curr_nr
  insert(w:taberian.tabs, S__create_tab(bufnr), w:taberian.curr_nr)

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

export def Close_tab(nr__a = w:taberian.curr_nr)
  if len(w:taberian.tabs) < 2 || w:taberian.curr_nr == -1
    return
  endif

  if w:taberian.curr_nr == nr__a
    if w:taberian.curr_nr > 0
      Goto_tab_offset(-1)
    else
      Goto_tab_offset(+1)
    endif
  endif

  remove(w:taberian.tabs, nr__a)

  if nr__a < w:taberian.curr_nr
    --w:taberian.curr_nr
  endif

  doautocmd User TaberianChanged
enddef

def S__on_popup_killed(popup_id__a: number, res__a: number)
  if res__a != -1 # not force closed with Ctrl-C
    return
  endif

  var winids = gettabinfo(tabpagenr())[0].windows
  for winid in winids
    var w = getwinvar(winid, 'taberian', {})
    if empty(w) || w.popup_id != popup_id__a
      continue
    endif
    w.popup_id = -1

    var winid_bkp = win_getid()
    noautocmd win_gotoid(winid)
    Render_current_window()
    noautocmd win_gotoid(winid_bkp)
  endfor
enddef

export def Render_current_window()
  S__init_once()
  var tabs = gettabwinvar(tabpagenr(), winnr(), 'taberian').tabs
  var tabs_count = len(tabs)
  if tabs_count < 2 # render only if more than 1 tab
    popup_hide(w:taberian.popup_id)
    aunmenu WinBar
    return
  endif

  var wininfo = getwininfo(win_getid())[0]

  # create empty WinBar:
  if !wininfo.winbar
    execute 'amenu WinBar.\  \ '
  endif

  # generate titles:
  var title_items = []
  for nr in range(tabs_count)
    title_items += [[
      ' ',                   # 0: left border
      string(nr + 1),        # 1: tab index (1-based)
      ' ',                   # 2: spacer
      S__bufname(tabs[nr].bufnr), # 3: buffer name
      ' ',                   # 4: spacer
      'ᴮ' .. tabs[nr].bufnr, # 5: buffer number
      g:taberian#separator,  # 6: right border
    ]]
  endfor

  # make sure there is enough room:
  if wininfo.width < 2 # there is a maximized window
    return
  endif
  var min_popup_width = tabs_count * (2 + 4) # 2 for borders, 4 for tab name (3 chars + '…')
  if wininfo.width < min_popup_width
    execute 'vertical resize ' .. min_popup_width
  endif

  if exists('g:taberian#hide_tab_index') && g:taberian#hide_tab_index
    for it in title_items
      it[1] = '' # spacer
      it[2] = '' # buf name
    endfor
  endif

  if exists('g:taberian#hide_bufnr') && g:taberian#hide_bufnr || (S__popup_line(title_items)->strdisplaywidth() > wininfo.width)
    for it in title_items
      it[-3] = '' # spacer
      it[-2] = '' # bufnr
    endfor
  endif

  # if still too long:
  var average_max_len = wininfo.width / tabs_count
  while S__popup_line(title_items)->strdisplaywidth() > wininfo.width
    var repay_chars = wininfo.width - tabs_count * average_max_len # unused chars due to rounding (max 1 char per tab)
    for nr in range(tabs_count)
      var max_len = average_max_len
      if repay_chars > 0
        --repay_chars
        ++max_len
      endif

      var tab_len = strdisplaywidth(title_items[nr]->join(''))
      if tab_len > max_len
        var excess = tab_len - max_len + 1 # + 1 for elipsis
        # buf name is at 3:
        title_items[nr][3] = title_items[nr][3]->strcharpart(0, title_items[nr][3]->strdisplaywidth() - excess) .. '…'
      endif
    endfor
  endwhile

  var titles = []
  var col = 1
  for nr in range(tabs_count)
    tabs[nr].col_in_popup = col

    var title = title_items[nr]->join('')
    titles += [title]
    var len = title->strwidth()
    col += len
  endfor

  if w:taberian.popup_id == -1
    w:taberian.popup_id = popup_create(' ', {
      hidden: true,
      pos: 'topleft',
      wrap: false,
      highlight: 'TaberianTab',
      filter: S__on_click,
      callback: S__on_popup_killed,
    })
  endif

  popup_settext(w:taberian.popup_id, titles->join(''))
  popup_move(w:taberian.popup_id, {
    col: wininfo.wincol,
    line: wininfo.winrow,
  })

  var popup_bufnr = winbufnr(w:taberian.popup_id)
  var cur_tab_title = titles[w:taberian.curr_nr]
  var prop_col = 1
  for i in range(tabs_count)
    if w:taberian.curr_nr == i
      break
    endif
    prop_col += titles[i]->len() # in bytes
  endfor
  var prop_len = cur_tab_title->len() # in bytes
  prop_add(1, prop_col, {bufnr: popup_bufnr, length: prop_len, type: s_sel_prop})

  popup_show(w:taberian.popup_id)
enddef

def S__on_click(popup_id__a: number, key__a: string): bool
  if key__a != "\<LeftMouse>" && key__a != "\<MiddleMouse>"
    return false
  endif

  var mousepos = getmousepos()
  if mousepos.winid != popup_id__a
    return false
  endif

  var winids = gettabinfo(tabpagenr())[0].windows
  for winid in winids
    var w = getwinvar(winid, 'taberian', {})
    if empty(w) || w.popup_id != popup_id__a
      continue
    endif

    for nr in range(w.tabs->len())->reverse()
      if w.tabs[nr].col_in_popup < mousepos.wincol
        if key__a == "\<LeftMouse>"
          win_gotoid(winid)
          Goto_tab_nr(nr)
        elseif key__a == "\<MiddleMouse>"
          var winid_bkp = win_getid()
          noautocmd win_gotoid(winid)
          Close_tab(nr)
          noautocmd win_gotoid(winid_bkp)
        endif
        return true
      endif
    endfor
  endfor

  return false
enddef

export def Render_all_windows(winids__a = gettabinfo(tabpagenr())[0].windows)
  for winid in winids__a
    win_execute(winid, 'S__update_current_window()')
  endfor
enddef

export def Confirm_window_close()
  if len(w:taberian.tabs) > 1
    echo 'This window has ' .. len(w:taberian.tabs) .. ' tabs open: '
    echo w:taberian.tabs->deepcopy()->map((_, tab) => fnamemodify(bufname(tab.bufnr), ':t'))->string()
    echo 'Close the window (yN):'
    var choice = nr2char(getchar())
    redraw
    if choice != 'y'
      return
    endif
  endif
  close
enddef

export def On_WinClosed(winid__a: number)
  var w = getwinvar(winid__a, 'taberian', {})
  if empty(w)
    return
  endif
  popup_close(w.popup_id)
enddef

export def State_export(): list<any>
  var state = []
  for tabinfo in gettabinfo()
    var t = {
      tabnr: tabinfo.tabnr,
      windows: [],
    }
    for winid in tabinfo.windows
      var win = gettabwinvar(t.tabnr, winid, 'taberian', {})->deepcopy()
      if empty(win) || len(win.tabs) < 2 # only save if more than 1 tab
        continue
      endif

      for tab in win.tabs
        # convert bufnrs to file paths:
        tab.buffer = fnamemodify(bufname(tab.bufnr), ':~:.')
        unlet tab.bufnr
        unlet tab.col_in_popup
        unlet tab.title
      endfor

      win.winnr = win_id2tabwin(winid)[1]
      unlet win.prev_nr
      unlet win.popup_id

      add(t.windows, win)
    endfor
    if !empty(t.windows)
      add(state, t)
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
    var t = tabs[0]

    for winid in tabinfo.windows
      var [_, winnr] = win_id2tabwin(winid)
      var wins = t.windows->deepcopy()->filter((_, val) => val.winnr == winnr)
      if empty(wins)
        continue
      endif
      var win = wins[0]

      unlet win.winnr
      win.prev_nr = -1
      win.popup_id = -1

      # convert file paths to bufnrs:
      for tab in win.tabs
        execute 'badd ' .. tab.buffer
        extend(tab, S__create_tab(bufnr(tab.buffer)))
        unlet tab.buffer
      endfor

      var old_win = gettabwinvar(tabnr, winid, 'taberian', {})
      extend(old_win, win)
      settabwinvar(tabnr, winid, 'taberian', old_win)
      win_execute(winid, 'buffer ' .. old_win.tabs[old_win.curr_nr].bufnr)
    endfor
  endfor
enddef
