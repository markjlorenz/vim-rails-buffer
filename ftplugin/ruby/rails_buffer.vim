" Maintainer:  Mark J. Lorenz <markjlorenz@gmail.com>
" URL:
" License:     MIT
" ThankYou:    This scrip is basically a hacked verions of
"              [vim-coffee-script](http://github.com/kchmck/vim-coffee-script)
"              by Mick Koch <kchmck@gmail.com>.  I don't even
"              really know how it works.

" Reset the CoffeeCompile variables for the current buffer.
function! s:RubyCompileResetVars()
  " Compiled output buffer
  let b:ruby_compile_buf = -1
  let b:ruby_compile_pos = []
endfunction

" Clean things up in the source buffer.
function! s:RubyCompileClose()
  exec bufwinnr(b:ruby_compile_src_buf) 'wincmd w'
  call s:RubyCompileResetVars()
endfunction

" Don't overwrite the CoffeeCompile variables.
if !exists('b:ruby_compile_buf')
  call s:RubyCompileResetVars()
endif

" Check here too in case the compiler above isn't loaded.
if !exists('ruby_compiler')
  " let ruby_compiler = 'ruby'
  let temp_file     = ' rails-buffer-tmpfile '
  let wait          = ' & wait; '
  let cat_temp      = ' cat - >> '.temp_file.wait
  let rails         = 'rails'
  let rails_r       = ' '.rails.' r '.temp_file.wait
  let rm_temp       = ' rm '.temp_file
  let ruby_compiler = cat_temp.rails_r.rm_temp
endif

" Update the CoffeeCompile buffer given some input lines.
function! s:RubyCompileUpdate(startline, endline)
  let input = join(getline(a:startline, a:endline), "\n")

  " Move to the CoffeeCompile buffer.
  exec bufwinnr(b:ruby_compile_buf) 'wincmd w'

  " Coffee doesn't like empty input.
  if !len(input)
    return
  endif

  " Compile input.
  let output = system(g:ruby_compiler, "p ->{\n".input."\n}.call")

  " Be sure we're in the CoffeeCompile buffer before overwriting.
  if exists('b:ruby_compile_buf')
    echoerr 'Ruby buffers are messed up'
    return
  endif

  " Replace buffer contents with new output and delete the last empty line.
  setlocal modifiable
    exec '% delete _'
    put! =output
    exec '$ delete _'
  setlocal nomodifiable

  setlocal filetype=

  call setpos('.', b:ruby_compile_pos)
endfunction

" Peek at compiled CoffeeScript in a scratch buffer. We handle ranges like this
" to prevent the cursor from being moved (and its position saved) before the
" function is called.
function! s:RubyCompile(startline, endline, args)
  if !executable(g:rails)
    echoerr "Can't find Ruby `" . g:rails . "`"
    return
  endif

  " If in the RubyCompile buffer, switch back to the source buffer and
  " continue.
  if !exists('b:ruby_compile_buf')
    exec bufwinnr(b:ruby_compile_src_buf) 'wincmd w'
  endif

  " Parse arguments.
  let watch = a:args =~ '\<watch\>'
  let unwatch = a:args =~ '\<unwatch\>'
  let size = str2nr(matchstr(a:args, '\<\d\+\>'))

  " Determine default split direction.
  if exists('g:ruby_compile_vert')
    let vert = 1
  else
    let vert = a:args =~ '\<vert\%[ical]\>'
  endif

  let b:ruby_compile_watch = 1

  " Build the RubyCompile buffer if it doesn't exist.
  if bufwinnr(b:ruby_compile_buf) == -1
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

    autocmd BufWipeout <buffer> call s:RubyCompileClose()
    " Save the cursor when leaving the CoffeeCompile buffer.
    autocmd BufLeave <buffer> let b:ruby_compile_pos = getpos('.')

    nnoremap <buffer> <silent> q :hide<CR>

    let b:ruby_compile_src_buf = src_buf
    let buf = bufnr('%')

    " Go back to the source buffer and set it up.
    exec bufwinnr(b:ruby_compile_src_buf) 'wincmd w'
    let b:ruby_compile_buf = buf
  endif

  call s:RubyCompileUpdate(a:startline, a:endline)
endfunction

" Peek at compiled CoffeeScript.
command! -range=%  -bar -nargs=* -complete=customlist,
\        RubyBuffer call s:RubyCompile(<line1>, <line2>, <q-args>)
