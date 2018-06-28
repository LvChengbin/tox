# Tox

`tox` is a command line tool for helping you to switch in multiple directories more faster and more convenient. It is more powerful than the native `cd` command.

## Usage

```
source ./tox.sh
```

The `tox` has two command, `toxc` and `tox`. The `toxc` is used to manage `tox` points, and `tox` is used to switch between points or directories.

For example, there is a directory named `workspace`

```
# to create a point in workspace dir named @ws
workspace % toxc init @ws
tox: point @ws has been created.
```
then, by using `tox @ws`, you can switch to point @ws no matter where you are.

You can also specify a dir name after the point name:

```
tox [master●●] % tox @ws project
1: @ws/XVim2/XVim2.xcodeproj/project.xcworkspace
2: @ws/projects
choose the dir with index: (empty means the first one)
```
If there is only one dir can match the name, tox will switch to the dir directly:

```
workspace % tox @ws projects
tox: switch to /Users/NS/workspace/projects
```

If you just want to switch dir in current tox point, you don't need to specify the point name then:

```
workspace % tox project
1: XVim2/XVim2.xcodeproj/project.xcworkspace
2: projects
choose the dir with index: (empty means the first one)2
tox: switch to /Users/NS/workspace/projects
```

Using `tox` without any arguments, the dir will be switched to the home of current point:

```
projects % tox
tox: switch to /Users/NS/workspace
```

You can add more names for one tox point with `toxc add-name @xxx` or remove a name with `toxc remove-name @xxx`.

Different points can have same name, then when you want to switch to the point with it's name, tox will ask you to select one of them:

```
tox @ws
1: /Users/NS/workspace
2: /Users/NS/another-workspace
choose the point with index: (empty means the first one)
tox: switch to /Users/NS/workspace
```

and try go to a dir in @ws point, tox will ask you to select the point and then the matching dir:

```
% tox @ws project
1: /Users/NS/workspace
2: /Users/NS/another-workspace
choose the point with index: (empty means the first one)1
1: @ws/XVim2/XVim2.xcodeproj/project.xcworkspace
2: @ws/projects
choose the dir with index: (empty means the first one)2
tox: switch to /Users/NS/workspace/projects
```

### toxc

> toxc is used to manage tox points.

- toxc: show info of tox
- toxc status: show infomation of current point
- toxc init @name: to make a dir be a tox point with it's name and points can be anonymous.
- toxc add-name @xx: add a name to current point
- toxc remove-name @xx: delete a name from current point
- toxc uninit: revoke current point
- toxc map: to show the points map. while running this command, toxc will try to reindex the map, but it will only remove all non-exist points, it will scan all points not indexed.

### tox

> tox is used to switch between points and directories

- tox: go to the home dir of current point
- tox @xx: go to the dir of the point named @xx
- tox aa: go to the dir named aa in current point
- tox @xx aa: go to the dir named aa in @xx point
- tox -: go to the last dir
- tox ~: go to the home dir
- tox . abc: to find dir abc from current dir
- tox .. abc: to find dir abc from the parent dir of current dir

### toxe

> toxe is used to open a file with specified editor quickly, `toxe` has same features with `tox` command.

### config

> each tox point has a `.toxrc` as it's config file, it supports some simple config item:

- point: point name of current point, multiple names should be separated with comma(,)
- ignore: a directory list which would be ignored while seach files or directories, separated with comma(,) 
- editor: the editor while using `toxe`, only can be set in ~/.toxrc file
