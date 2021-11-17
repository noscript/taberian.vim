if exists("g:taberian_loaded")
  finish
endif
const g:taberian_loaded = v:true

let &guiligatures = list2str(range(32, 126))

augroup Taberian
  autocmd!
  autocmd WinEnter,BufEnter,VimResized,SessionLoadPost * call taberian#render_all_windows()
  autocmd User TaberianChanged call taberian#render_current_window()
augroup END

command! -nargs=0 TaberianNewTab              :call taberian#create_tab()
command! -nargs=0 TaberianCloseCurrentTab     :call taberian#close_current_tab()
command! -nargs=0 TaberianGotoLeftTab         :call taberian#goto_tab_offset(-1)
command! -nargs=0 TaberianGotoRightTab        :call taberian#goto_tab_offset(+1)
command! -nargs=0 TaberianMoveCurrentTabLeft  :call taberian#move_current_tab_offset(-1)
command! -nargs=0 TaberianMoveCurrentTabRight :call taberian#move_current_tab_offset(+1)
command! -nargs=0 TaberianConfirmWindowClose  :call taberian#confirm_window_close()
command! -nargs=1 TaberianGoToTabNr           :call taberian#goto_tab_nr(<q-args>)
command! -nargs=0 TaberianGoToPreviousTab     :call taberian#goto_previous_tab()

if !exists('g:taberian_no_default_mappings') || !g:taberian_no_default_mappings
  map <silent> <C-W>t  <Cmd>TaberianNewTab<CR>
  map <silent> <C-W>x  <Cmd>TaberianCloseCurrentTab<CR>
  map <silent> <C-W>m  <Cmd>TaberianGotoLeftTab<CR>
  map <silent> <C-W>,  <Cmd>TaberianGotoRightTab<CR>
  map <silent> <C-W>.  <Cmd>TaberianMoveCurrentTabLeft<CR>
  map <silent> <C-W>/  <Cmd>TaberianMoveCurrentTabRight<CR>
  map <silent> <C-W>c  <Cmd>TaberianConfirmWindowClose<CR>
  map <silent> <A-1>   <Cmd>TaberianGoToTabNr 0<CR>
  map <silent> <A-2>   <Cmd>TaberianGoToTabNr 1<CR>
  map <silent> <A-3>   <Cmd>TaberianGoToTabNr 2<CR>
  map <silent> <A-4>   <Cmd>TaberianGoToTabNr 3<CR>
  map <silent> <A-5>   <Cmd>TaberianGoToTabNr 4<CR>
  map <silent> <A-6>   <Cmd>TaberianGoToTabNr 5<CR>
  map <silent> <A-7>   <Cmd>TaberianGoToTabNr 6<CR>
  map <silent> <A-8>   <Cmd>TaberianGoToTabNr 7<CR>
  map <silent> <A-9>   <Cmd>TaberianGoToTabNr 8<CR>
  map <silent> <C-Tab> <Cmd>TaberianGoToPreviousTab<CR>
  map <silent> <A-0>   <Cmd>TaberianGoToPreviousTab<CR>
endif
