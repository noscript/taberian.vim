# taberian.vim

Clickable tabs per VIM window.

[![screenshot](/taberian.png)](https://user-images.githubusercontent.com/717109/131985507-4877c889-a2ef-4d41-90f9-b770b8912e65.mp4)

Taberian applies the concept of tabs to VIM windows. Each VIM window (split)
may contain a number of tabs, so user can switch between them, rearrange,
close etc.

Taberian works out of the box and does not require any configuration. If there
are less than two tabs then Taberian will not display anything. To start, create
a new tab via `<C-W>t`.

Default mappings:

| Mapping | Description |
| --- | --- |
| `<C-W>t` | Create a new tab by cloning the current tab. |
| `<C-W>x` | Close the current tab. |
| `<C-W>m` | Go to tab on the left. |
| `<C-W>,` | Go to tab on the right. |
| `<C-W>.` | Move the current tab one position to the left. |
| `<C-W>/` | Move the current tab one position to the right. |
| `<C-W>c` | Check if there are any taberian tabs present and ask user to confirm closing the window. |
| `<A-1>`  | Go to tab 1. |
| `<A-2>`  | Go to tab 2. |
| `<A-3>`  | Go to tab 3. |
| `<A-4>`  | Go to tab 4. |
| `<A-5>`  | Go to tab 5. |
| `<A-6>`  | Go to tab 6. |
| `<A-7>`  | Go to tab 7. |
| `<A-8>`  | Go to tab 8. |
| `<A-9>`  | Go to tab 9. |
| `<C-Tab>` or `<A-0>` | Go to previous tab, useful to switch between two recent tabs. |


If you wish to not use the default mappings, disable them by defining
`g:taberian_no_default_mappings` variable:

```vim
g:taberian_no_default_mappings = true
```

You can define your own mapping using this example:

```vim
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
```
