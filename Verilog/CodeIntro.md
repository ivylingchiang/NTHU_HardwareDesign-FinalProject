# Note

## git command 
***Git commit***
```
git status // modified, untracked, staged change => commit

git add .
git commit -m "{update info}"


// update local file
git fetch
git log HEAD..origin/{branchName}

git pull --ff-only
git pull --rebase // need to fix conflict
git rebase --continue // fixed and continue
git rebase --abort // back to origin state
```


```
git branch

git checkout {branchName} // switch branch
git checkout -b {newBranchName} // create new branch
```

* Update Main branch's content
```
git checkout main
git pull --ff-only

// switch to local branch
git checkout {localBranch}
git merge main

// conflict state
{fix the conflict file}

```

## code setting