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


" Problem: :p:h doesn't work as shell argument for certain paths:
":!ls %:p
"ls: cannot access /home/tyler/Web: No such file or directory
"ls: cannot access sites: No such file or directory
"
":!ls "%:p"
"/home/tyler/Web sites
"
"But what if filename actually contains a "?
"> touch temp\"
"
":e temp\"
":!ls "%:p"
"/bin/bash: -c: line 0: unexpected EOF while looking for matching `"'
"/bin/bash: -c: line 1: syntax error: unexpected end of file
"
"We can't simply change our delimiters from " to ' because we will have the
"same problem when the filename contains ' characters.
"
"What's the solution?
":execute "!ls " . fnameescape(expand("%:p"))
"/home/tyler/Web sites/temp'
"
"Which is much uglier than the original !ls %:p ... but it works, and that
"concern must come first, even, unfortunately, at the expense of prettiness
"and readability.
"
" Now that I know how to safely allow any path as an argument to a shell
" command, I changed my git_commands.vim file accordingly: 
"-command! -nargs=* Gitdiff                 !cd %:p:h; git diff <args> -- "%:p:t"
"+command! -nargs=* Gitdiff                 :execute "!cd " . fnameescape(expand("%:p:h")) . "; git diff " . <q-args> . " -- "  . fnameescape(expand("%:p:t"))"
"
"It now works perfectly! But it's so ... UGLY .
"
" Proposed solution: add :e modifier to vim that causes path to be expanded
" the same as fnameescape(), so you could use it in normal ! without having to
" build the command string and then calling execute on the string.

command! -complete=file -nargs=+ Git      !cd %:p:h; git <args>

command! -nargs=* Gitstatus               !cd %:p:h; git status "%:p:t" <args>
command! -nargs=* Gitst                   :Gitstatus <args>
command! -nargs=* Gs                      :Gitstatus <args>

"command! -nargs=* Gitdiff                 !cd %:p:h; cd `git rev-parse --show-cdup`; git diff %:p <args>
command! -nargs=* Gitdiff                 :execute "!cd " . fnameescape(expand("%:p:h")) . "; git diff " . <q-args> . " -- "  . fnameescape(expand("%:p:t"))
command! -nargs=* Gitdi                   :Gitdiff <args>
command! -nargs=* Gd                      :Gitdiff <args>
command! -nargs=* Gdw                     :Gitdiff --color-words <args>

command! -nargs=* Gitdiffcached           !cd %:p:h; git add %; git diff --cached "%:p:t" <args>
command! -nargs=* Gds                     :Gitdiffcached <args>
command! -nargs=* Gdc                     :Gitdiffcached <args>

command! -nargs=* Gitlog                  !cd %:p:h; git log <args> "%:p:t"
command! -nargs=* Gl                      :Gitlog --color <args>
command! -nargs=* Gll                     :Gitlog --color --numstat --graph <args>
command! -nargs=* Gllfulldiff             :Gitlog --color --numstat --graph --full-diff <args>

"command! -nargs=* Glp                     !cd "$(dirname "$(cd %:p:h; git rev-parse --show-toplevel)")"; git log -p --numstat --ignore-all-space --follow             <args> "%"
command! -nargs=* Glp                     !cd %:p:h; git log -p --numstat --ignore-all-space --follow             <args> "%:p:t"
command! -nargs=* Glpword                 !cd %:p:h; git log -p --numstat --ignore-all-space --follow --word-diff=color <args> "%:p:t"
command! -nargs=* Glpfulldiff             !cd %:p:h; git log -p --numstat --ignore-all-space --full-diff <args> "%:p:t"

command! -nargs=* Glh                     !cd %:p:h; git log <args> "%:p:t" | head -n30

command! -range=% -nargs=* Gitshowhead  !cd "$(dirname "$(cd %:p:h; git rev-parse --git-dir)")"; git cat "%" <args> | lines <line1> <line2>
command! -range=% -nargs=* Gitcat         :<line1>,<line2>Gitshowhead

"----

command! -nargs=* Gitadd                  !cd %:p:h; git add <args> "%:p:t"
command! -nargs=* Ga                      :Gitadd <args>
command! -nargs=* Gap                     :Gitadd -p <args>
command! -nargs=* Gau                     :Gitadd -u <args>

" Useful for staging only part of the current file.
" You still have to type 'p', '1', 'Enter', however, unfortunately. I wish
" there were a way to specify all that on the command line.
command! -nargs=* Gai                     :Gitadd -i <args>

command! -nargs=* Gitunadd                !cd %:p:h; git rm --cached "%:p:t" <args>
command! -nargs=* Gua                     :Gitunadd <args>

command! -nargs=* Gitreset                !cd %:p:h; git reset "%:p:t" <args>
command! -nargs=* Gitunstage              :Gitreset <args>
command! -nargs=* Gus                     :Gitreset <args>

command! -nargs=* Gitcheckout             !cd %:p:h; git checkout "%:p:t" <args>
command! -nargs=* Gitco                   :Gitcheckout <args>

command! -nargs=* Gdisc                   !cd %:p:h; git checkout HEAD "%:p:t"

" TODO: add git_rm_flags option so you can choose between '-f', '--cached', or ''
" also an option of whether to close buffer/window or not: I like having it
" not close it because then I have one last chance to recover it if I change
" my mind about having removed it
"command! -nargs=* Gitremove               !cd %:p:h; git rm -f "%:p:t" <args>
command! -nargs=* Gitremove               call GitRemove(<q-args>)
command! -nargs=* Gitrm                   call GitRemove(<q-args>)
function! GitRemove(args)
  "!cd %:p:h; git rm -f "%:p:t" <args>
  execute "!cd " . expand("%:p:h") . "; git rm -f " . expand("%:p:t") . " " . a:args
  q
endfunction




"---------------------------------------------------------------

function! GitBaseDir()
  "let output = system("$(dirname "$(cd %:p:h; git rev-parse --git-dir)")")
  let output = system("git-base-dir")
  return output
endfunction

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

" passes commit as arg1
command! -nargs=1 Gcifrb                  !cd %:p:h; git commit-fixup-rebase <args> "%:p:t"

" Note: We must include the filename when doing git commit --amend or else it will include *all*
" currently stashed changes into the amended commit. We want it to only add/include the file you are
" editing into the amended commit, and leave all other changes that may be staged *still* staged (to
" be committed in another future commit).
command! -nargs=* Gitcommitamend         !cd %:p:h; git commit -v --amend "%:p:t" <args>
command! -nargs=* Gcia                    :Gitcommitamend <args>


" command! -nargs=* Gitmove               !git move --force %:p %:p:h/<args>
" Notes:
"   Be sure to escape things that need to be escaped:
"     Gitmv example_of_trees_\(with_leaves\)
command! -nargs=1 -complete=custom,CurrentFilePath Gitmove call GitMove(<q-args>)
command! -nargs=1 -complete=custom,CurrentFilePath Gitmv       :Gitmove <args>
"function! GitMove(targetFileName)
"  "let newPath =  expand("%:p:h") . "/" . a:targetFileName
"  let newPath =  a:targetFileName
"  #GitBaseDir()
"  echomsg "!cd " . expand("%:p:h") . "; git mv " . expand("%:p:t") . " " . newPath
"  execute "!cd " . expand("%:p:h") . "; git mv " . expand("%:p:t") . " " . newPath
"  execute "bd"             | " Delete the buffer (since that file won't exist anymore)
"  " Reload the new file...
"  " In case they had split windows, use split instead of e...
"  execute "sp " . expand("%:p:h") . "/" . newPath
"endfunction
function! GitMove(new_path)
  let old_path = expand("%")
  "execute "!cd " . GitBaseDir() . "; git mv ..."
  echomsg "!git mv " . old_path . " " . a:new_path
  execute "!git mv " . old_path . " " . a:new_path
  if v:shell_error > 0
    return
  end

  " Reload the new file...
	execute "edit " . escape(a:new_path, ' \')
	execute "bdelete ".old_path | " Delete the buffer (since that file won't exist anymore)
endfunction

command! -nargs=1 -complete=custom,CurrentFilePath Gitcopy call GitCopy(<q-args>)
command! -nargs=1 -complete=custom,CurrentFilePath Gitcp  :Gitcopy <args>
"function! GitCopy(targetFileName)
"  let newPath =  expand("%:p:h") . "/" . a:targetFileName
"  execute "!git cp " . expand("%:p") . " " . newPath
"  execute "sp " . newPath
"endfunction
function! GitCopy(new_path)
  echoerr "not rewritten yet"
  return
endfunction

" Reminder: fugitive's Gblame is cooler
command! -range=% -nargs=* Gitblame       !cd %:p:h; git blame "%:p:t"      <args> -L <line1>,<line2>
command! -range=% -nargs=* Gitblamehead   !cd %:p:h; git blame "%:p:t" HEAD <args> -L <line1>,<line2>


"command! -nargs=* Gitvimdiff              !cd %:p:h; git show HEAD:"%:p:t" <args> > "%.base" ; vimdiff "%:p:t" "%.base" ; rm "%.base"
command! -nargs=* Gitvimdiff              !cd %:p:h; git show   HEAD:"%" <args> > "%:p:t.tmp" ; vimdiff "%:p:t" "%:p:t.tmp" ; rm "%:p:t.tmp"
command! -nargs=* Gitvimdiff1             !cd %:p:h; git show HEAD~1:"%" <args> > "%:p:t.tmp" ; vimdiff "%:p:t" "%:p:t.tmp" ; rm "%:p:t.tmp"
command! -nargs=* Gitvimdiff2             !cd %:p:h; git show HEAD~2:"%" <args> > "%:p:t.tmp" ; vimdiff "%:p:t" "%:p:t.tmp" ; rm "%:p:t.tmp"
command! -nargs=* Gitvimdiff3             !cd %:p:h; git show HEAD~3:"%" <args> > "%:p:t.tmp" ; vimdiff "%:p:t" "%:p:t.tmp" ; rm "%:p:t.tmp"
command! -nargs=* Gitvimdiff4             !cd %:p:h; git show HEAD~4:"%" <args> > "%:p:t.tmp" ; vimdiff "%:p:t" "%:p:t.tmp" ; rm "%:p:t.tmp"
command! -nargs=* Gitvimdiff5             !cd %:p:h; git show HEAD~5:"%" <args> > "%:p:t.tmp" ; vimdiff "%:p:t" "%:p:t.tmp" ; rm "%:p:t.tmp"
command! -nargs=* Gitvimdiffrev           !cd %:p:h; git show <args>:"%"        > "%:p:t.tmp" ; vimdiff "%:p:t" "%:p:t.tmp" ; rm "%:p:t.tmp"

" Hint:
"   % gets the full path of %. 
"   %:p:h gets the full path of % with the last path component removed (that is, the full path of the directory that *contains* %).
command! Gitstatusdir                     !cd %:p:h; git status .
command! Gitdiffdir                       !cd %:p:h; git diff .
command! -nargs=* Gitcommitdir            !cd %:p:h; git commit . <args>
command! -nargs=* Gitcidir                :Gitcommit <args>

"------------------------------------
command! Gituselocal                     !cd %:p:h; uselocal "%:p:t"
command! Gituseremote                     !cd %:p:h; useremote "%:p:t"



"------------------------------------

function! Trim(input)
  " Strip off trailing newline 
  return substitute(a:input, "\\s*\\n$", "", "") 
endfunction

function! CurrentFileName(ArgLead,CmdLine,CursorPos)
    return expand("%:p:t")
endfun


