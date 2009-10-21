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

command! -complete=file -nargs=+ Git      !cd %:p:h; git <args>

command! -nargs=* Gitstatus               !cd %:p:h; git status "%:p:t" <args>
command! -nargs=* Gitst                   :Gitstatus <args>
command! -nargs=* Gs                      :Gitstatus <args>

"command! -nargs=* Gitdiff                 !cd %:p:h; cd `git rev-parse --show-cdup`; git diff %:p <args>
command! -nargs=* Gitdiff                 !cd %:p:h; git diff <args> -- "%:p:t"
command! -nargs=* Gitdi                   :Gitdiff <args>
command! -nargs=* Gd                      :Gitdiff <args>

command! -nargs=* Gitdiffcached           !cd %:p:h; git add %; git diff --cached "%:p:t" <args>
command! -nargs=* Gds                     :Gitdiffcached <args>
command! -nargs=* Gdc                     :Gitdiffcached <args>

command! -nargs=* Gitlog                  !cd %:p:h; git log "%:p:t" <args>
command! -nargs=* Gl                      :Gitlog <args>

command! -nargs=* Glp                     !cd %:p:h; git log -p --numstat --ignore-all-space <args> "%:p:t"

command! -nargs=* Glh                     !cd %:p:h; git log <args> "%:p:t" | head -n30

command! -range=% -nargs=* Gitshowmaster  !git cat % <args> | lines <line1> <line2>
command! -range=% -nargs=* Gitcat         :<line1>,<line2>Gitshowmaster

"----

command! -nargs=* Gitadd                  !cd %:p:h; git add "%:p:t" <args>
command! -nargs=* Ga                      :Gitadd <args>

command! -nargs=* Gitunadd                !cd %:p:h; git rm --cached "%:p:t" <args>
command! -nargs=* Gua                     :Gitunadd <args>

command! -nargs=* Gitreset                !cd %:p:h; git reset "%:p:t" <args>
command! -nargs=* Gitunstage              :Gitreset <args>
command! -nargs=* Gus                     :Gitreset <args>

command! -nargs=* Gitcheckout             !cd %:p:h; git checkout "%:p:t" <args>
command! -nargs=* Gitco                   :Gitcheckout <args>

command! -nargs=* Gitremove               !cd %:p:h; git rm "%:p:t" <args>
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

"command! -nargs=* Tig                     !cd %:p:h; tig "%:p:t" <args>
command! -nargs=* Tig                     !cd %:p:h; tig <args> -- --patch-with-stat "%:p:t"

command! -nargs=* Gitcommit               !cd %:p:h; git commit -v "%:p:t" <args>

" The previous version had the problem that special characters (to vim) like #
" get expanded (see help expand for a list of such characters). It appears
" that this only happens when using !, not when calling system. (Although I
" don't know if there are any other side effects/differences between the two
" methods... I assumed that 'echo'ing the return value of system was at least
" close enough to the way ! prints the output from the command.)
"command! -nargs=* Gitcommit               :echo system("cd " . expand("%:p:h") . "; git commit -v " . expand("%:p:t") . " " . <q-args>)
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
  "let newPath =  expand("%:p:h") . "/" . a:targetFileName
  let newPath =  a:targetFileName
  echomsg "!cd " . expand("%:p:h") . "; git mv " . expand("%:p:t") . " " . newPath
  execute "!cd " . expand("%:p:h") . "; git mv " . expand("%:p:t") . " " . newPath
  execute "bd"             | " Delete the buffer (since that file won't exist anymore)
  " Reload the new file...
  " In case they had split windows, use split instead of e...
  execute "sp " . expand("%:p:h") . "/" . newPath
endfunction
command! -nargs=1 -complete=custom,CurrentFileName Gitmv   :Gitmove <args>

command! -nargs=1 -complete=custom,CurrentFileName Gitcopy call GitCopy(<q-args>)
function! GitCopy(targetFileName)
  let newPath =  expand("%:p:h") . "/" . a:targetFileName
  execute "!git cp " . expand("%:p") . " " . newPath
  execute "sp " . newPath
endfunction
command! -nargs=1 -complete=custom,CurrentFileName Gitcp  :Gitcopy <args>

command! -range=% -nargs=* Gitblame       !cd %:p:h; git blame "%:p:t"      <args> | lines <line1> <line2>
command! -range=% -nargs=* Gitblamehead   !cd %:p:h; git blame "%:p:t" HEAD <args> | lines <line1> <line2>


command! -nargs=* Gitvimdiff              !cd %:p:h; git show master:"%:p:t" <args> > %.base ; vimdiff "%:p:t" %.base ; rm %.base
" To do: The rm doesn't seem to ever get executed? So it leaves that temporary
" file lying around.

" Hint:
"   % gets the full path of %. 
"   %:p:h gets the full path of % with the last path component removed (that is, the full path of the directory that *contains* %).
command! Gitstatusdir                     !cd %:p:h; git status .
command! Gitdiffdir                       !cd %:p:h; git diff .
command! -nargs=* Gitcommitdir            !cd %:p:h; git commit . <args>
command! -nargs=* Gitcidir                :Gitcommit <args>



"------------------------------------

function! Trim(input)
  " Strip off trailing newline 
  return substitute(a:input, "\\s*\\n$", "", "") 
endfunction

function! CurrentFileName(ArgLead,CmdLine,CursorPos)
    return expand("%:p:t")
endfun


