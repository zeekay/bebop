Bebop
=====
A tool for rapid web development which serves as static file server, websocket server for client-side reloading/bi-directional communcation and file watcher.

Usage
-----
Check `bebop --help` for usage.

Installation
------------
To take advantage of the client-side reloading you need a WebSocket enabled browser and a bit of javascript. You can use the provided Django middleware:

    INSTALLED_APPS = (
        ...,
        'bebop',
    )
    MIDDLEWARE_CLASSES = (
        ...,
        'bebop.middleware.ReloaderMiddleware',
    )

...or simply link to [bebop.js](https://raw.github.com/zeekay/bebop/master/bebop/bebop.js) in your project:

    <script src="https://raw.github.com/zeekay/bebop/master/bebop/bebop.js" type="text/javascript"></script>

Vim
---
If you use a version of Vim with Python compiled in you can use Bebop for both completion and javascript evaluation. Try adding the following to your vimrc:

    if executable('bebop') && has('python')
        " Use Bebop javascript completion and eval
        py import bebop.vimbop, vim

        function! BebopComplete(findstart, base)
            if a:findstart
                return a:findstart-1
            else
                py completions = bebop.vimbop.complete(vim.eval('a:base'))
                py vim.command('let res = ' + completions)
                return res
            endif
        endfunction

        au FileType javascript setlocal omnifunc=BebopComplete
        au FileType javascript command! -nargs=* BebopEval     py bebop.vimbop.eval_js(<f-args>)
        au FileType javascript command! -nargs=0 BebopEvalLine   py bebop.vimbop.eval_line()
        au FileType javascript command! -nargs=0 BebopEvalBuffer py bebop.vimbop.eval_buffer()
        au FileType javascript nnoremap <leader>ee :BebopEval<space>
        au FileType javascript nnoremap <leader>el :BebopEvalLine<cr>
        au FileType javascript vnoremap <leader>er :py bebop.vimbop.eval_range()<cr>
        au FileType javascript nnoremap <leader>eb :BebopEvalBuffer<cr>
        au FileType javascript nnoremap <leader>ef :BebopEvalBuffer<cr>
    endif
