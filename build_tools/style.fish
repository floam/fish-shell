#!/usr/bin/env fish
#
# This is meant to be run by "make style" or "make style-all". It is not meant to
# be run directly from a shell prompt although it can be.
#
# This runs C++ files and fish scripts (*.fish) through their respective code
# formatting programs.
#
set git_clang_format no
set c_files
set f_files
set all no
set cleanmark (set_color green)✓(set_color normal)
set reformatmark (set_color bryellow)✖(set_color normal)

if test "$argv[1]" = "--all"
    set all yes
    set -e argv[1]
end

if set -q argv[1]
    echo "Unexpected arguments: '$argv'"
    exit 1
end

if test $all = yes
    set files (git status --porcelain --short --untracked-files=all | string replace -r '^ *[^ ]* *' '')
    if set -q files[1]
        echo "Cannot proceed with style-all."
        echo "Commit or stash uncommited/untracked files:"
        set_color normal
        git status --porcelain --short --untracked-files=all 
        exit 2
    end
    #set c_files {src,osx,build_tools,share}/{***.h,***.c,***.cpp,***.f,***.js}
    set c_files set c_files src/*.h src/*.cpp
    set f_files share/***.fish
else
    # We haven't been asked to reformat all the source. If there are uncommitted changes reformat
    # those using `git clang-format`. Else reformat the files in the most recent commit.
    # Select (cached files) (modified but not cached, and untracked files)
    set files (git diff-index --cached HEAD --name-only) (git ls-files --exclude-standard --others --modified)
    if set -q files[1]
        set git_clang_format yes
        echo "Using git-clang-format"
    else
        echo "No pending changes; reformatting files in most recent commit"
        set files (git diff-tree --no-commit-id --name-only -r HEAD)
    end

    # Extract just the C/C++ files that exist.
    set c_files
    for file in (string match -ri '^.*\.(?:c|cpp|h)$' -- $files)
        test -f $file
        and set c_files $c_files $file
    end
    # Extract just the fish files.
    set f_files (string match -r '^.*\.fish$' -- $files)
end

# Run the git-clang-format if we have any C++ files.
if set -q c_files[1]
    if test $git_clang_format = yes
        if type -q git-clang-format
            set_color --bold
            echo \n- Running git-clang-format -\n
            git add $c_files
            git-clang-format
        else
            echo (set_color --bold)'Warning: git-clang-format not installed or not in $PATH.'(set_color normal)
            echo "C++ reformatting skipped"
        end
    else if type -q clang-format
        set_color --bold
        echo \n- Running clang-format -\n
        for file in $c_files
            cp $file $file.new # preserves mode bits
            clang-format $file >$file.new
            if cmp --quiet $file $file.new
                echo $cleanmark $file
                rm $file.new
            else
                echo $reformatmark (set_color --underline)$file(set_color normal) is being reformatted
                mv $file.new $file
            end
        end
    else
        echo 'Warning: Cannot find clang-format command'
    end
end

# Run the fish reformatter if we have any fish files.
if set -q f_files[1]
    if not type -q fish_indent
        make fish_indent
        set PATH . $PATH
    end
    set_color --bold
    echo \n- Running fish_indent -\n
    for file in $f_files
        cp $file $file.new # preserves mode bits
        fish_indent <$file >$file.new
        if cmp --quiet $file $file.new
            echo $cleanmark $file
            rm $file.new
        else
            echo $reformatmark (set_color --underline)$file(set_color normal) is being reformatted
            mv $file.new $file
        end
    end
end