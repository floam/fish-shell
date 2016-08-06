function __fish_print_help --description 'Print help message for the specified fish function or builtin'
    # builtin_help_get() used to give us --tty-width, avoid by picking last argument
    # support source builtin as '.'
    set -l item (string replace '.' 'source' -- $argv[-1])
    set -l manpage (string escape "$__fish_datadir")/man/man1/$item.1

    # Do nothing if file or file.gz does not exist
    if not test -e "$manpage" -o -e "$manpage.gz"
        return 5
    end

    # save 4 columns for margin on right
    set -l rLL -rLL=(math $COLUMNS - 4)n
    nroff -c -man -t $rLL "$manpage" -Tutf8 ^/dev/null | ul | cat -s | read -z help
    or gunzip -c "$manpage.gz" ^/dev/null | nroff -c -man -t $rLL -Tutf8 ^/dev/null | ul | cat -s | read -z help
    or return 6

    set help (string replace -r -a "\n\n\n" '\n' -- (string replace -r -a '\n\n    ' '\n    ' -- $help))
    set help (string split -- $help | string match -v -r '^[\S]+')

    test -z "$help[ 1]"; and set -e help[ 1]
    test -z "$help[-1]"; and set -e help[-1]
    
    # "Synopsis" and "Description" section headers aren't really adding anything in this context, except height
    string replace -r -a "^[\s]{5}|^[\s]{2}|" '' $help | string match -r -v 'Description|Synopsis[\e]?.*[\s]*$'
end
