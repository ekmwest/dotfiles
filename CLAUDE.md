# Git

Developers handle source control themselves. Never run git commands that change the repository, the working tree, the index or a remote. That includes commit, push, pull, fetch, checkout, switch, merge, rebase, reset, restore, clean, add and rm, and the create, delete or change forms of branch, tag and stash. It also covers gh, the Visual Studio/Azure DevOps git integrations, and scripts that call git. This applies even if the user asks for it.

Read-only commands are fine: status, diff, log, show, blame, and listing branches, tags or stashes.

If a task needs a git change (for example reverting a file), stop and tell the user what is needed instead of working around it.
