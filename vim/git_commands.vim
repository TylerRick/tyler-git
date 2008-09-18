"===================================================================================================
" Git commands
"===================================================================================================
"
" These commands let you do Git commands from vim as if they were
" native vim commands. They operate on the file that is open in the active
" buffer, so you don't even have to type the filename.
"
"   Vim command                 Comment / Equivalent shell command
"   -----------                 ----------------------------------
"   :Git args                   git {args}
" Commands that operate on {current_file}:
"   :Gitadd [extra_args]        git add {current_file} {extra_args}
"   :Gitstatus [extra_args]     git status {current_file} {extra_args}
"   :Gitdiff [extra_args]       git diff {current_file} {extra_args}
"   :Gitblame [extra_args]      git blame {current_file} {extra_args}
"   :Gitmove [destFile] [extra_args]  git move {current_file} {destFile} {extra_args}
"   :Gitcommit [extra_args]     git commit {current_file} {extra_args}
"   :Gitremove [extra_args]     git remove {current_file} {extra_args}
"   :Gitlog [extra_args]        git log {current_file} {extra_args}
"
" Note: {current_dir} refers to the directory that {current_file} is in. This is
" not necessarily the same directory that :pwd will show you. {current_file}
" is, of course, the file that is currently open in the active buffer.
"
" The following command aliases are available, in case you're used to the
" shortened subcommands that git has ("git ci" instead of "git commit"):
"
" Alias                Equivalent to
" -----------          -------------
" :Gitst               :Gitstatus
" :Gitci               :Gitcommit

command! -complete=file -nargs=+ Git      !cd %:h; git <args>

command! -nargs=* Gitstatus               !cd %:h; git status % <args>
command! -nargs=* Gitst                   :Gitstatus <args>
command! -nargs=* Gs                      :Gitstatus <args>

command! -nargs=* Gitdiff                 !cd %:h; git diff % <args>
command! -nargs=* Gitdi                   :Gitdiff <args>
command! -nargs=* Gd                      :Gitdiff <args>

command! -nargs=* Gitdiffcached           !cd %:h; git add %; git diff --cached % <args>
command! -nargs=* Gdc                     :Gitdiffcached <args>

command! -nargs=* Gitlog                  !cd %:h; git log % <args>
command! -nargs=* Gl                      :Gitlog <args>

command! -nargs=* Glp                     !cd %:h; git log --patch-with-stat % <args>

command! -nargs=* Glh                     !cd %:h; git log % <args> | head -n30

command! -nargs=* Gitshowmaster           !cd %:h; git show master:% <args>
command! -nargs=* Gitcat                  :Gitshowmaster

"----

command! -nargs=* Gitadd                  !cd %:h; git add % <args>
command! -nargs=* Ga                      :Gitadd <args>

command! -nargs=* Gitunadd                !cd %:h; git rm --cached % <args>
command! -nargs=* Gua                     :Gitunadd <args>

command! -nargs=* Gitreset                !cd %:h; git reset % <args>
command! -nargs=* Gitunstage              :Gitreset <args>
command! -nargs=* Gus                     :Gitreset <args>

command! -nargs=* Gitcheckout             !cd %:h; git checkout % <args>
command! -nargs=* Gitco                   :Gitcheckout <args>

command! -nargs=* Gitremove               !cd %:h; git rm % <args>
command! -nargs=* Gitrm                   :Gitremove <args>






"---------------------------------------------------------------
" unfinished/untested:

command! -nargs=0 Gitdiffprev             :Gitdiff HEAD~1

command! -nargs=* Gitvimcat               call GitVimCat(<q-args>)
function! GitVimCat(args)
  let path = expand("%:p")
  let fileName = expand("%:p:t")
  new
  execute ".!git cat " . path  . " -r " . a:args
  execute "w! /tmp/" . fileName . "." . a:args . "." . fnamemodify(fileName, ":e")    
  " This is so that it will get nice syntax highlighting
endfunction

"command! -nargs=* Tig                     !cd %:h; tig % <args>
command! -nargs=* Tig                     !cd %:h; tig <args> -- --patch-with-stat %

command! -nargs=* Gitcommit               !cd %:h; git commit -v % <args>
command! -nargs=* Gitci                   :Gitcommit <args>
command! -nargs=* Gci                     :Gitcommit <args>


" command! -nargs=* Gitmove               !git move --force %:p %:p:h/<args>
" Notes:
"   Be sure to escape things that need to be escaped:
"     Gitmv example_of_trees_\(with_leaves\)
command! -nargs=1 -complete=custom,CurrentFileName Gitmove call GitMove(<q-args>)
function! GitMove(targetFileName)
  let newPath =  expand("%:h") . "/" . a:targetFileName
  execute "!git mv " . expand("%") . " " . newPath
  execute "bd"             | " Delete the buffer (since that file won't exist anymore)
  " Reload the new file...
  " In case they had split windows, use split instead of e...
  execute "sp " . newPath
endfunction
command! -nargs=1 -complete=custom,CurrentFileName Gitmv   :Gitmove <args>

command! -nargs=1 -complete=custom,CurrentFileName Gitcopy call GitCopy(<q-args>)
function! GitCopy(targetFileName)
  let newPath =  expand("%:p:h") . "/" . a:targetFileName
  execute "!git cp " . expand("%:p") . " " . newPath
  execute "sp " . newPath
endfunction
command! -nargs=1 -complete=custom,CurrentFileName Gitcp  :Gitcopy <args>

command! -nargs=* Gitblame                !cd %:h; git blame % <args>
command! -nargs=* Gitblamehead            !cd %:h; git blame % HEAD <args>


command! -nargs=* Gitvimdiff              !cd %:h; git show master:% <args> > %.base ; vimdiff % %.base ; rm %.base
" To do: The rm doesn't seem to ever get executed? So it leaves that temporary
" file lying around.

" Hint:
"   % gets the full path of %. 
"   %:h gets the full path of % with the last path component removed (that is, the full path of the directory that *contains* %).
command! Gitstatusdir                     !cd %:h; git status %:h
command! Gitdiffdir                       !cd %:h; git status %:h
command! -nargs=* Gitcommitdir            !cd %:h; git commit %:h <args>
command! -nargs=* Gitcidir                :Gitcommit <args>



"------------------------------------

function! Trim(input)
  " Strip off trailing newline 
  return substitute(a:input, "\\s*\\n$", "", "") 
endfunction

function! CurrentFileName(ArgLead,CmdLine,CursorPos)
    return expand("%:p:t")
endfun


