vim9script

if exists('g:taberian_loaded')
  finish
endif
g:taberian_loaded = true

import autoload 'taberian.vim'

augroup Taberian
  autocmd!
  autocmd WinEnter,BufEnter,VimResized,SessionLoadPost * taberian#Render_all_windows()
  autocmd WinResized * taberian#Render_all_windows(v:event.windows)
  autocmd WinClosed * taberian#On_WinClosed(expand('<amatch>')->str2nr())
  autocmd ColorScheme * taberian#On_Colorscheme()
  autocmd User TaberianChanged taberian#Render_current_window()
augroup END

command! -nargs=0 TaberianNewTab              taberian#Create_tab()
command! -nargs=0 TaberianCloseCurrentTab     taberian#Close_tab()
command! -nargs=0 TaberianGotoLeftTab         taberian#Goto_tab_offset(-1)
command! -nargs=0 TaberianGotoRightTab        taberian#Goto_tab_offset(+1)
command! -nargs=0 TaberianMoveCurrentTabLeft  taberian#Move_current_tab_offset(-1)
command! -nargs=0 TaberianMoveCurrentTabRight taberian#Move_current_tab_offset(+1)
command! -nargs=0 TaberianConfirmWindowClose  taberian#Confirm_window_close()
command! -nargs=1 TaberianGoToTabNr           taberian#Goto_tab_nr(<args>)
command! -nargs=0 TaberianGoToPreviousTab     taberian#Goto_previous_tab()

if !exists('g:taberian_no_default_mappings') || !g:taberian_no_default_mappings
  map <silent> <C-W>t  <ScriptCmd>TaberianNewTab<CR>
  map <silent> <C-W>x  <ScriptCmd>TaberianCloseCurrentTab<CR>
  map <silent> <C-W>m  <ScriptCmd>TaberianGotoLeftTab<CR>
  map <silent> <C-W>,  <ScriptCmd>TaberianGotoRightTab<CR>
  map <silent> <C-W>.  <ScriptCmd>TaberianMoveCurrentTabLeft<CR>
  map <silent> <C-W>/  <ScriptCmd>TaberianMoveCurrentTabRight<CR>
  map <silent> <C-W>c  <ScriptCmd>TaberianConfirmWindowClose<CR>
  map <silent> <A-1>   <ScriptCmd>TaberianGoToTabNr 0<CR>
  map <silent> <A-2>   <ScriptCmd>TaberianGoToTabNr 1<CR>
  map <silent> <A-3>   <ScriptCmd>TaberianGoToTabNr 2<CR>
  map <silent> <A-4>   <ScriptCmd>TaberianGoToTabNr 3<CR>
  map <silent> <A-5>   <ScriptCmd>TaberianGoToTabNr 4<CR>
  map <silent> <A-6>   <ScriptCmd>TaberianGoToTabNr 5<CR>
  map <silent> <A-7>   <ScriptCmd>TaberianGoToTabNr 6<CR>
  map <silent> <A-8>   <ScriptCmd>TaberianGoToTabNr 7<CR>
  map <silent> <A-9>   <ScriptCmd>TaberianGoToTabNr 8<CR>
  map <silent> <C-Tab> <ScriptCmd>TaberianGoToPreviousTab<CR>
  map <silent> <A-0>   <ScriptCmd>TaberianGoToPreviousTab<CR>
endif
