# High-level overview

1. Linearize the source main branch, using rebase -i to replace merge commits with a linear history
   This will make the following steps easier, especially the splitting of commits.
2. Classify which files/commits are common vs. specific, and split any resulting "mixed" commits into
   separate "common" and "specific" commits.
3. Do a rebase to split out and "transplant" all the common commits into a new "common" branch
   (which can be later become a separate common _repo_), while keeping the specific commits in a
   branch that will become the new "main" branch.
   - The common commits will be merged into the main branch as we go, so that the resulting main
     branch will be a combination of both all the common and all the specific commits.
4. Coordinating with the team, safely replace the existing "main" branch with the new rewritten main
   branch, in a way that reduces the chances that anyone will accidentally base anything on the old
   commits or reintroduce any commits at all from the old, obsolute history.

Goals:
1. Although the commits themselves will be different, the final result (the tree "contents" of the
   tip of the branch) should be identical compared to the un-rewritten branch.
   - At _any_ time throughout this process, we confirm this by running `git diff new-main-equiv new-main`

## General tips to keep in mind

It is important to try to be careful with each step along the way, because if you're not careful,
it's very easy to make subtle mistakes, which you may not even notice until hours of conflict
resolution later (which in some cases could have been avoided if you rebased onto the right commit
instead of onto the wrong commit). Any mistake is possible to fix with Git, but it can be a lot more
work to fix it after the fact than to just get it right the first time. :)

Fortunately, it's easy to double-check at any time that your rewritten commits that you haven't
diverged, that they contain the identical content as the corresponding original commit. It is
recommended to do this frequently, as often as your workflow actually produces a commit that should
correspond exactly in content to an original commit. In the case of the `split-branch` workflow,
since, you can't actually check it after _every_ `pick` commit if it's a split commit, because those
commits only contain half of the original commit. You can only diff against the source branch after
both "halves" of the original commit have been applied, which means _can_ double-check  after every
_merge_ commit, and also after every all-specific commit. Your history tree should will converged again every time there is a merge.

To make it harder to forget to check, the `git-rebase-seq-split-branch-by-specificity` tool even
_automatically_ adds in a `git diff` check for you as often as it thinks you're at a convergent point.



# 0. Prereq config

This config makes it only try to show this note when you use one-line `git log` — and not show other
(possibly long, multi-line) notes you may have:

```toml
[notes]
displayRef = refs/notes/specificity
```

Comment out or remove this config while using `git-rebase-seq-split-branch-by-specificity` or using
any other sequences that copy notes as you go:

```toml
rewriteRef = refs/notes/*
```

## `rebase.instructionFormat`

`git-rebase-seq-split-branch-by-specificity` and `git-rebase-seq-add-specificity` automatically
change your `rebase.instructionFormat` to this:

```toml
instructionFormat = "[%N] %s [%as %an]" # %N is notes  
```

This allows you to see the note (`%N`) for the specificity classification in the list of rebase
instructions. But `%N` is not actually supported for instructionFormat (only for `log` format
strings), you have either be using `git-rebase-seq-split-branch-by-specificity` or (if seeing these
is the _only_ thing you need a sequence editor for)
`GIT_SEQUENCE_EDITOR=git-rebase-seq-add-specificity`.

They attempt to reset this config back to how it was before, as part of the last `exec` command in
the rebase. 

# 1. Linearize the main branch

We will call our new branch `new-main` to avoid conflicting with existing `main`.

We can do this in several iterations over time, which is important because in the meantime, the
old/remote `main` will continue to receive new commits.

I just mark where I left off in the upstream `main` branch by tagging it with `new-main-equiv`:
```sh
git tag -f new-main-equiv <commit_in_main>
```

It is helpful to keep this tag up-to-date as you go so that it's always pointing to whatever
commit in `main` is equivalent to the rewritten commit that is at the tip of `new main`.


# 2.a. Classify which files/commits are common vs. specific

Start out by classifying the specificity of all the files in your current tree, by running:

```sh
git-ls-files-specificity --detect
```

Manually classify any files that the detection got wrong or was unable to detect.

Refine your `.git/file_specificity/specific_patterns` so that it is better able
to automatically detect file specificity going forward.

This won't handle every single case, nor every single file (such as those that
existed in earlier commits but not in current tree), but it will help make the
next step more seamless so that you can mostly focus on the splitting of
_commits_ next and not so much on classifying individual _files_.


Later, to list all files in your _current_ tree and check what specifity they currently have
recorded, run

```sh
git-ls-files-specificity
```

To check how it was for all files in the repo as of a certain _past_ commit, run:

```sh
git-ls-files-specificity <commit>
```

Or to check the specificity just for the files _changed_ by a certain commit, run:

```sh
git-diff-tree-specificity <commit>
```



# 2.b. `split-commit`: Split mixed commits into separate common and specific commits

Go through all commits and classify their specificity, then split any mixed commits.

This can be automated somewhat by using...

## If you're just starting out...

If the root commit also needs to be split (and likely it does if it contains the project name
anywhere in any file, such as `package.json`), then you would run something like this to actually
replace the old root with a new root commit:

```sh
git rebase -i -v --root --exec git-split-commit-by-specificity
```

When you are done with this, you can label your root commit with a branch/tag named `root` to make
it easy to target with future rebases.

## If you need to pull in new commits from `main`

Since the old `main` is a bit of a moving target, you may need to repeat this process on any new
commits that are added to the old `main`.

First, you'll want to mark your progress so you can easily find where you left off.

Label the tip of the work that is done with `split-commit` as branch/tag `split-commit-done`.
Then you can safely pull in new commits from main onto this branch and know up to which point you
have completed this split-commit process.

(The `git-split-commit-by-specificity` script also marks the commits it is done with with a note
under `--ref=split-commit-status` that says "done", which helps to track completion state for
individual commits _within_ your working commit range, especially if you end up with commits in the
middle that didn't get completely done for whatever reason.)

To pull in all new commits (`new-main-equiv..main`) and transplant them onto your new branch should
— assuming you you've kept `new-main-equiv` up-to-date — be as simple as:

```sh
git switch new-main
git rebase-from -i new-main-equiv main

# Keep this up-to-date while you're at it
git tag -f new-main-equiv main
```

## To continue where you left off

The simplest is to simply rebase onto the root commit:

```sh
git rebase -i -v --exec git-split-commit-by-specificity split-commit-done
```

though you could target a more specific onto target if you want.




# 3. `split-branch`: Interleave common and specific commits; create common-only branch/repo

Now we're going to take the "common" commits we just split out and transplant them, one at a time
using a rebase script, onto the common _branch_. As part of that same script (but it could also be
done as a later separate step), we'll merge common into new-main at various points while rewriting
the main branch, making sure to always merge in the common "half" of a split commit before replaying
on top of it the specific "half" of the same split commit.

## To be safe

This will automatically create backups of your current `new-main` and `common` branches before
starting, and output these backup refs, so that you can always reset these branches if anything goes
wrong.

It's also recommended to keep a `git log-oneline-graph-notes` around from before the rebase so that
you can compare the structure of your rewritten history with your "before" version to see what
changed (and be able to reset more easily if anything got messed up).

## If you're just starting out...

TODO: Figure out which instructions belong here and which belong in `git-rebase-seq-split-branch-by-specificity --help`

...

## If you ran into merge conflicts

Due to the way we split the commits above, for each conflict, it seems that usually the
remote/bottom option of the conflict marker (which is the version of the commit that you are
currently `pick`ing) is the correct resolution. 

And then when it attempts to `merge` the common side back into new-main, it usually has a conflict on
those same hunks, and the resolution is usually the opposite: You want to accept the top option of
the conflict, which is the specific version, rather than the common option that you accepted in the
previous (`pick`) operation.

## If you've addded more new commits to the tip 

Label the tip of the history that has been split into branches with a tag/branch named `split-branch-done`.

To resume where you left off, you can just run:

```sh
GIT_SEQUENCE_EDITOR=git-rebase-seq-split-branch-by-specificity \
  git rebase -i -v --rebase-merges --onto split-branch-done split-branch-done new-main
```

This will generate a planned sequence of rebase commands, and should open this list in your editor
to confirm.

Double-check that it looks like the sequence will accurately continue from where we left off,
starting with the very next un-split-branch commit.  Make absolutely sure that the first `pick`
command is for the commit that is directly after `split-branch-done` (or the perhaps first "common"
commit after that) and that there are no commits being missed.

If your `split-branch-done` tag was pointed to a later commit than it should be, then it will cause
needless conflict pain. I did this once, and was stumped by how big of a conflict mess there was,
until I realized this was because it was trying to apply this `pick` commit onto a history that was
missing that was actually _missing_ the commit that this commit was based on!

The top of the sequence should thus look like this:

```
reset common
pick 0a67d6f [common] Title
```

It always starts with the "side line" commits (which in this case is `common`) before working on the
"main line" where it depends on and will merge in those common commits at various points.

Example:

Before continuing the `split-branch` rebase, `new-main` looked like this:

```
* c7dc7d2 2025-04-01 updated qs.parse to figure out arrays. fixed getPosts specific
* 6baca24 2025-04-01 updated qs.parse to figure out arrays. common
* a2f6014 2025-04-01 Initial code for InfiniteScroll specific
* 0a67d6f 2025-04-01 Initial code for InfiniteScroll common
*   7e4e958 2025-04-23 (tag: split-branch-done) Merge from common: - Merge branch 'fix_tests_to_run_concurrently' into 'master'
|\
| * a39b432 2025-04-23 (tag: backup/2025-05-22T23-03-34-common, common) Merge branch 'fix_tests_to_run_concurrently' into 'master' common
| * 188b538 2025-04-08 Fix typo common
| * 3123731 2025-04-08 Fix svelte-check warnings: Unknown at rule @apply (css) common
```


I confirmed (this time) that thes equence started with the first commit after split-branch-done,
which is:

```
reset common
pick 0a67d6f [common] Initial code for InfiniteScroll [2025-04-01]
```

(when I made my stake before, it was trying to start with this pick instead:
```
pick 6baca24 [common] updated qs.parse to figure out arrays. [2025-04-01]
```
)

If everything looks good, close the editor and let it do its thing.
It will stop if there are any conflicts for you to resolve.

## If you want to "stop early", save your progress, and pick up where left off later

Don't use `git rebase --abort` as that would make you _lose_ all your progress.

...


## Help! If you make a mistake

Don't worry, you can fix anything with git.

Example: The built-in `git diff --exit-code` command that double-checks your work after a merge
exited with failure and interrupted the rebase sequence. It outputted what the difference from your
original commit was and now you want to fix up a previous commit to include this patch.

## If you notice the mistake while in the middle of a rebase

First, figure out which commit needs to be amended. Which commit _should_ have included this
content? If it's the tip commit, then it's as easy as:
1. Change and stage the file
2. Run `git commit --amend && git-rebase-i-amend-head`

If it's a commit _prior_ to the tip commit, it's a bit harder, but still doable. You have 2 choices:
1. Create a `fixup` commit that you can use to semi-automatically amend the bad commit by doing a
   2nd rebase sequence after the conclusion of the rebase that you're currently in the middle of.
   (See next section: "How to rebase an already rewritten branch..."). Or,
2. Rewind. Reset the appropriate refs that the rebase was tracking, directly amend the commit, then
   let `rebase` replay the commands that you just rewound back from.

### [Advanced] Rewinding while in the middle of a rebase, fixing, then continuing rebase

<details>

<summary>This section will describe the latter option, "Rewind"</summary>

Example: You noticed this failure:

```diff
Executing: git diff --exit-code 4387f65 HEAD && echo 'Diff is clean compared to 4387f65'
diff --git a/src/lib/components/icons/icon-config.ts b/src/lib/components/icons/icon-config.ts
index 620c4b3..2ff565f 100644
--- a/src/lib/components/icons/icon-config.ts
+++ b/src/lib/components/icons/icon-config.ts
@@ -18,6 +18,9 @@ export const IconConfig = {
 	editor_italic: 'heroicons/italic.svg',
 	editor_bulleted_list: 'heroicons/list-bullet.svg',
 	editor_numbered_list: 'heroicons/numbered-list.svg',
+	editor_text_left_align: 'hugeicons/text-align-left.svg',
+	editor_text_center_align: 'hugeicons/text-align-center.svg',
+	editor_text_right_align: 'hugeicons/text-align-right.svg',
 };
```

, indicating that your local HEAD has these extra lines that weren't present in the original commit,
4387f65. You can confirm whether those lines were removed in that very commit, or in a parent or
ancestor that commit by running `git log -p 4387f65 src/lib/components/icons/icon-config.ts`. It
shows this, confirming that indeed those lines were removed in that "common" commit:

```diff
commit 4387f655e74c5a5ff3c6d88d9c78993f673ac571

    Added linking and profanity checking

Notes (specificity):
    common

diff --git a/src/lib/components/icons/icon-config.ts b/src/lib/components/icons/icon-config.ts
index 7ff1351..620c4b3 100644
--- a/src/lib/components/icons/icon-config.ts
+++ b/src/lib/components/icons/icon-config.ts
@@ -16,15 +16,8 @@ export const IconConfig = {
  // Editor tool icons
  editor_bold: 'heroicons/bold.svg',
  editor_italic: 'heroicons/italic.svg',
- editor_underline: 'heroicons/underline.svg',
- editor_h1: 'heroicons/h1.svg',
- editor_h2: 'heroicons/h2.svg',
- editor_h3: 'heroicons/h3.svg',
  editor_bulleted_list: 'heroicons/list-bullet.svg',
  editor_numbered_list: 'heroicons/numbered-list.svg',
- editor_text_left_align: 'hugeicons/text-align-left.svg',
- editor_text_center_align: 'hugeicons/text-align-center.svg',
- editor_text_right_align: 'hugeicons/text-align-right.svg',
 };
...

1. Find where the commit that needs to be fixed is in your rewritten history.

```sh
⟫ git log-oneline-graph-notes -3 @
*   b2393ec 2025-05-01 (HEAD) Merge from common: - Added linking and profanity checking
|\
| * 04f21bc 2025-05-02 Added linking and profanity checking common
* | 6a270aa 2025-05-02 Merge branch 'fix_lint_errors' into 'master' specific
```

In my case, the last merge had completed without any conflicts. But if there had been any merge
conflicts, and this patch had been something that we should have included as _part_ of the conflict
resolution, then the correct commit to amend would have been the merge commit itself, which is our
tip commit in this example. But since this line deletion should have been included in the rewritten
commit `04f21bc` that is the equivalent of original commit `4387f65`, then we need to amend _that_
commit instead.

2. Find the instructions where we first picked `4387f65`

Look in `.git/rebase-merge/done` and find the context where we first picked that commit, up until
the end:

```gitrebase
reset common
pick 4387f65 [common] Added linking and profanity checking [2025-05-02]
exec sh -c 'git-rebase-i-amend-head; git log-oneline-notes-graph -1'
label common
update-ref refs/heads/common
exec git log-oneline-graph -n10 refs/rewritten/common

reset new-main
merge common # Merge common into new-main
exec git-rebase-i-amend-head # ↑
exec git diff --exit-code 4387f65 HEAD && echo 'Diff is clean compared to 4387f65'
```

You will need to refer to this for the next 2 steps.

2. Manually reset the appropriate refs to go back to the beginning of that excerpted sequence above; directly amend the commit

We need to:
- rewind the `common` "branch"* to the commit that we need to amend (alternatively, you
   could reset to just _before_ that commit, and then `cherry-pick` it to replay the `pick` and
   re-resolve any conflicts that come up)
- and rewind the `new-main` "branch" to just before the merge.

(* During a rebase, it doesn't actually use real branches because it doesn't want to leave any
permanent changes until the end, in case you decide to `git rebase --abort`. Instead its `label` and
`reset` commands update some internal "rewritten" refs that work kind of like branches (though their
use in the script is more analogous to lightweight tags). They are also what we are using to track
what the _real_ branches will be reset to at the conclusion of the sequence, so we need to keep them
updated correctly.)

```sh
# Reset HEAD to the commit from _our_ rewritten history that we need to amend
git reset --hard 04f21bc

# Fix the file in editor, stage it, then amend the commit with the new contents. Or if the
# correct contents are exactly what was in the original commit (and we don't have to take into
# account changes from any other commits), then it's as simple as this:
git checkout 4387f65 src/lib/components/icons/icon-config.ts
git commit --amend --no-edit --no-verify
git-rebase-i-amend-head 4387f65
# Double-check the metadata looks correct
git log --format=fuller -1

# label common
git update-ref refs/rewritten/common @
# update-ref refs/heads/common
git update-ref refs/heads/common @

# Reset new-main label to just before the merge (parent 1)
git update-ref refs/rewritten/new-main b2393ec^1
```

3. Let `rebase` replay the commands that you "undid", not incuding the ones you just manually
   "redid".

Modify the first lines and then copy these lines from `.git/rebase-merge/done`:
```gitrebase
reset new-main
merge common # Merge common into new-main
exec git-rebase-i-amend-head # ↑
exec git diff --exit-code 4387f65 HEAD && echo 'Diff is clean compared to 4387f65'
```

and add them to the top of `.git/rebase-merge/git-rebase-todo` as the next commands to run.

Confirm that `git status` is showing the correct next commands. But note that `git status` actually
has a bug, where if you reference a bare ref name like `reset new-main`, it will incorectly show the
hash of `refs/heads/new-main` (since that's usually how a bare ref is interpreted in git) instead of
correctly showing the hash of `refs/rewritten/new-main` here, which is how git rebase will interpret
bare ref names (as "labels").

</details>

## How to rebase and amend a commit in an already rewritten branch

If you want ever need to rebase your already-once-rewritten history, for example in order to apply a
`fixup` to an earlier commit or to manually amend a commit, then don't worry, you can.

Even though it's a bit more complicated-looking than rebasing over a completely linear history, git
rebase has great support for rebasing across merge commits too these days, in the form of
`--rebase-merges`.

So all you have to do, for example, is this:
```sh
git rebase -i --rebase-merges <parent-of-first-commit-to-fix>
```

If your fix is something that should apply cleanly to the older commit even if you generate the
patch based on the current `HEAD`, then the simplest solution is to just fix it in the tip of your
branch, then create a fix-up commit:
```sh
git commit --fixup 080da6a
```

and then "send that commit back" to the commit on which it should operate with:
```sh
git rebase -i --rebase-merges --autosquash 080da6a^
```

If you would rather amend the commit back at the commit itself (or if the `--fixup` approach
wouldn't work well), then you can just change the `pick` line that you want to amend to `edit` and
it will stop at that commit and let you amend it.

How you do it is really no different than rebasing a normal linear branch. 

If you want to preserve the original committer, remember to add this line after the commit you
ammended and any later commit that have it as an ancestor:
```gitrebase
exec git-rebase-i-amend-head
```

```sh
GIT_SEQUENCE_EDITOR=git-rebase-seq-add-specificity \
  git rebase -i --rebase-merges --exec git-rebase-i-amend-head <parent-of-first-commit-to-fix>
```

### Git rebases starting at your root commit even if you specify an onto commit

Unfortunately, when your rebasing to get to a commit that touches 2 "lines", then even though it
starts you right at your "onto" commit for the one line (let's say the "common" line if you're
trying to amend a commit there), in order to reconstruct the state of the _other_ line (the
"specific" line or main line in our example) it will construct a sequence starting all the way back
at the root commit and replay the _entire_ history of commits from there up to the

This is technically not necessary, and you _could_ fairly easily manually adjust things so that it
_won't_ do that. (How? Just delete the unneeded `pick` commands and add a `reset` command that
resets to the same commit that the commands you removed would have brought you up to.)

But considering git's excellent ability to detect if it's replaying unchanged history and
fast-forwarding if nothing was actually changed, it's usually not worth the extra efort to manually
edit things just to aviod this _seemingly_ unnecessary history rewriting: It should be harmless and
okay to just _let_ it do this and you even end up with the exact same, unrewritten commit hashes for
that history line that you didn't touch!




## If you accidentally modified the commit timestamp or need to copy metadata from original commits for whatever reason

As long as you still have a branch (or can recover it from your reflog) containing your
post-split-commit work that contains commits that easily map one-to-one with all but the merge
commits of your rewritten `new-main` branch, then you can simply generate a commit mapping and copy
the metadata from the "original" commit to the new commit.

1. If you intend on copying any metadata over from the original commits, then you can
   first do this, to make copying in a later step easier.

   Record mapping from linear to rewritten main branch.
   ```sh
   git-map-rewritten-commits work-from main --short --show-match-method --pretty | nc > .git/split-branch/rewritten-linear
   ```

   If the metadata is already all correct, and all you want to do is `commit --amend` the contents
   of a commit, then this step is not necessary, as you can simply copy it from the
   already-rewritten commit that you are now rewriting again.

   This allows us to do 2 and 3 below...

2. Copy over any notes that got lost during the rebase (which shouldn't happen any more, but did at
   first before I added real-time copying of notes to my script).

   ```sh
   git-notes-copy-all -f --stdin < .git/split-branch/rewritten-linear
   ```

   If this is all you needed to do, this actually doesn't require us to do another rebase, because
   the notes are tracked in a separate "ref" and not embedded within the commits themselves. But if
   you need to change either the content of any commit or the metadata (such as committer name or
   date) that comprises the identity of the commit itself, then you must do a rebase to "go back" in
   history to the commit you want to amend.

3. Copy anything else over from the original commit, during a rebase, such as the original committer info/dates.

   ```sh
   export GIT_COPY_SOURCE_COMMIT_MAP=.git/split-branch/rewritten-master-main
   
   GIT_SEQUENCE_EDITOR=git-rebase-seq-add-specificity git rebase -i --rebase-merges --exec git-rebase-i-amend-head <parent-of-first-commit-to-fix>
   ```







# 4. Publishing new `main` and getting everyone on team to use it

1. Make it easy to identify if your branch is based on the right base. You can add a commit like
   this so that it's obvious just by looking in the history if you're on this new base or not.

```sh
git commit --allow-empty -m 'You are on the right base!' -m "All commits below this have been rewritten from the previous 'master' branch."
```

2. Rebase all existing remote branches onto new base.

3. Delete anything pointing to old history to make it not easy to accidentally use it for anything.
   (It should be considered "read-only" going forward.)




