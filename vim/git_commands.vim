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

command! -nargs=* Gitstatus               !cd %:h; git status %:t <args>
command! -nargs=* Gitst                   :Gitstatus <args>
command! -nargs=* Gs                      :Gitstatus <args>

command! -nargs=* Gitdiff                 !cd %:h; git diff <args> -- %:t
command! -nargs=* Gitdi                   :Gitdiff <args>
command! -nargs=* Gd                      :Gitdiff <args>

command! -nargs=* Gitdiffcached           !cd %:h; git add %; git diff --cached %:t <args>
command! -nargs=* Gdc                     :Gitdiffcached <args>

command! -nargs=* Gitlog                  !cd %:h; git log %:t <args>
command! -nargs=* Gl                      :Gitlog <args>

command! -nargs=* Glp                     !cd %:h; git log --patch-with-stat %:t <args>

command! -nargs=* Glh                     !cd %:h; git log %:t <args> | head -n30

command! -range=% -nargs=* Gitshowmaster  !git cat % <args> | lines <line1> <line2>
command! -range=% -nargs=* Gitcat         :<line1>,<line2>Gitshowmaster

"----

command! -nargs=* Gitadd                  !cd %:h; git add %:t <args>
command! -nargs=* Ga                      :Gitadd <args>

command! -nargs=* Gitunadd                !cd %:h; git rm --cached %:t <args>
command! -nargs=* Gua                     :Gitunadd <args>

command! -nargs=* Gitreset                !cd %:h; git reset %:t <args>
command! -nargs=* Gitunstage              :Gitreset <args>
command! -nargs=* Gus                     :Gitreset <args>

command! -nargs=* Gitcheckout             !cd %:h; git checkout %:t <args>
command! -nargs=* Gitco                   :Gitcheckout <args>

command! -nargs=* Gitremove               !cd %:h; git rm %:t <args>
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

"command! -nargs=* Tig                     !cd %:h; tig %:t <args>
command! -nargs=* Tig                     !cd %:h; tig <args> -- --patch-with-stat %:t

command! -nargs=* Gitcommit               !cd %:h; git commit -v %:t <args>

" The previous version had the problem that special characters (to vim) like #
" get expanded (see help expand for a list of such characters). It appears
" that this only happens when using !, not when calling system. (Although I
" don't know if there are any other side effects/differences between the two
" methods... I assumed that 'echo'ing the return value of system was at least
" close enough to the way ! prints the output from the command.)
"command! -nargs=* Gitcommit               :echo system("cd " . expand("%:h") . "; git commit -v " . expand("%:t") . " " . <q-args>)
" The problem with this version is I get this error:
"Vim: Warning: Output is not to a terminal
"Vim: Warning: Input is not from a terminal

command! -nargs=* Gitci                   :Gitcommit <args>
command! -nargs=* Gci                     :Gitcommit <args>


" command! -nargs=* Gitmove               !git move --force %:p %:p:h/<args>
" Notes:
"   Be sure to escape things that need to be escaped:
"     Gitmv example_of_trees_\(with_leaves\)
command! -nargs=1 -complete=custom,CurrentFileName Gitmove call GitMove(<q-args>)
function! GitMove(targetFileName)
  "let newPath =  expand("%:h") . "/" . a:targetFileName
  let newPath =  a:targetFileName
  echomsg "!cd " . expand("%:h") . "; git mv " . expand("%:t") . " " . newPath
  execute "!cd " . expand("%:h") . "; git mv " . expand("%:t") . " " . newPath
  execute "bd"             | " Delete the buffer (since that file won't exist anymore)
  " Reload the new file...
  " In case they had split windows, use split instead of e...
  execute "sp " . expand("%:h") . "/" . newPath
endfunction
command! -nargs=1 -complete=custom,CurrentFileName Gitmv   :Gitmove <args>

command! -nargs=1 -complete=custom,CurrentFileName Gitcopy call GitCopy(<q-args>)
function! GitCopy(targetFileName)
  let newPath =  expand("%:p:h") . "/" . a:targetFileName
  execute "!git cp " . expand("%:p") . " " . newPath
  execute "sp " . newPath
endfunction
command! -nargs=1 -complete=custom,CurrentFileName Gitcp  :Gitcopy <args>

command! -range=% -nargs=* Gitblame       !cd %:h; git blame %:t      <args> | lines <line1> <line2>
command! -range=% -nargs=* Gitblamehead   !cd %:h; git blame %:t HEAD <args> | lines <line1> <line2>


command! -nargs=* Gitvimdiff              !cd %:h; git show master:%:t <args> > %.base ; vimdiff %:t %.base ; rm %.base
" To do: The rm doesn't seem to ever get executed? So it leaves that temporary
" file lying around.

" Hint:
"   % gets the full path of %. 
"   %:h gets the full path of % with the last path component removed (that is, the full path of the directory that *contains* %).
command! Gitstatusdir                     !cd %:h; git status .
command! Gitdiffdir                       !cd %:h; git diff .
command! -nargs=* Gitcommitdir            !cd %:h; git commit . <args>
command! -nargs=* Gitcidir                :Gitcommit <args>



"------------------------------------

function! Trim(input)
  " Strip off trailing newline 
  return substitute(a:input, "\\s*\\n$", "", "") 
endfunction

function! CurrentFileName(ArgLead,CmdLine,CursorPos)
    return expand("%:p:t")
endfun


