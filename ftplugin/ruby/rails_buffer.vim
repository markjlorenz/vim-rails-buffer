" Maintainer:  Mark J. Lorenz <markjlorenz@gmail.com>
" URL:
" License:     MIT
" ThankYou:    This scrip is basically a hacked verions of
"              [vim-coffee-script](http://github.com/kchmck/vim-coffee-script)
"              by Mick Koch <kchmck@gmail.com>.  I don't even
"              really know how it works.

" Reset the CoffeeCompile variables for the current buffer.
function! s:RailsCompileResetVars()
  " Compiled output buffer
  let b:rails_compile_buf = -1
  let b:rails_compile_pos = []
endfunction

" Clean things up in the source buffer.
function! s:RailsCompileClose()
  exec bufwinnr(b:rails_compile_src_buf) 'wincmd w'
  call s:RailsCompileResetVars()
endfunction

" Don't overwrite the CoffeeCompile variables.
if !exists('b:rails_compile_buf')
  call s:RailsCompileResetVars()
endif

" Check here too in case the compiler above isn't loaded.
function! s:LoadRailsCompiler()
" if !exists('rails_compiler')
  if !exists('g:rails_buffer_helper')
    let g:rails_buffer_helper=''
  endif

  let temp_file     = ' rails-buffer-tmpfile '
  let wait          = ' & wait; '
  let cat_temp      = ' cat - >> '.temp_file.wait
  let g:rails_bin   = 'rails'
  let fork_helper   = ' '.g:rails_buffer_helper.' '
  let rails_r       = ' '.g:rails_bin.' r '.temp_file.wait
  let rm_temp       = ' rm '.temp_file
  let g:rails_compiler = cat_temp.fork_helper.rails_r.rm_temp
" endif
endfunction

" Update the CoffeeCompile buffer given some input lines.
function! s:RailsCompileUpdate(startline, endline)
  let input = join(getline(a:startline, a:endline), "\n")

  " Move to the CoffeeCompile buffer.
  exec bufwinnr(b:rails_compile_buf) 'wincmd w'

  " Coffee doesn't like empty input.
  if !len(input)
    return
  endif

  " Compile input.
  let output = system(g:rails_compiler, "p ->{\n".input."\n}.call")

  " Be sure we're in the CoffeeCompile buffer before overwriting.
  if exists('b:rails_compile_buf')
    echoerr 'Rails buffers are messed up'
    return
  endif

  " Replace buffer contents with new output and delete the last empty line.
  setlocal modifiable
    exec '% delete _'
    put! =output
    exec '$ delete _'
  setlocal nomodifiable

  setlocal filetype=

  call setpos('.', b:rails_compile_pos)
endfunction

" Peek at compiled CoffeeScript in a scratch buffer. We handle ranges like this
" to prevent the cursor from being moved (and its position saved) before the
" function is called.
function! s:RailsCompile(startline, endline, args)
  call s:LoadRailsCompiler()
  if !executable(g:rails_bin)
    echoerr "Can't find Rails `" . g:rails_bin . "`"
    return
  endif

  " If in the RailsCompile buffer, switch back to the source buffer and
  " continue.
  if !exists('b:rails_compile_buf')
    exec bufwinnr(b:rails_compile_src_buf) 'wincmd w'
  endif

  " Parse arguments.
  let watch = a:args =~ '\<watch\>'
  let unwatch = a:args =~ '\<unwatch\>'
  let size = str2nr(matchstr(a:args, '\<\d\+\>'))

  " Determine default split direction.
  if exists('g:rails_compile_vert')
    let vert = 1
  else
    let vert = a:args =~ '\<vert\%[ical]\>'
  endif

  let b:rails_compile_watch = 1

  " Build the RailsCompile buffer if it doesn't exist.
  if bufwinnr(b:rails_compile_buf) == -1
    let src_buf = bufnr('%')
    let src_win = bufwinnr(src_buf)

    " Create the new window and resize it.
    if vert
      let width = size ? size : winwidth(src_win) / 2

      belowright vertical new
      exec 'vertical resize' width
    else
      " Try to guess the compiled output's height.
      let height = size ? size : min([winheight(src_win) / 2,
      \                               a:endline - a:startline + 2])

      belowright new
      exec 'resize' height
    endif

    " We're now in the scratch buffer, so set it up.
    setlocal bufhidden=wipe buftype=nofile
    setlocal nobuflisted nomodifiable noswapfile nowrap

    autocmd BufWipeout <buffer> call s:RailsCompileClose()
    " Save the cursor when leaving the CoffeeCompile buffer.
    autocmd BufLeave <buffer> let b:rails_compile_pos = getpos('.')

    nnoremap <buffer> <silent> q :hide<CR>

    let b:rails_compile_src_buf = src_buf
    let buf = bufnr('%')

    " Go back to the source buffer and set it up.
    exec bufwinnr(b:rails_compile_src_buf) 'wincmd w'
    let b:rails_compile_buf = buf
  endif

  call s:RailsCompileUpdate(a:startline, a:endline)
endfunction

" Peek at compiled CoffeeScript.
command! -range=%  -bar -nargs=* -complete=customlist,
\        RailsBuffer call s:RailsCompile(<line1>, <line2>, <q-args>)
