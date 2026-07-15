    if test (count $argv) -eq 0
        echo "usage: copyfile <file...>"
        return 1
    end
    set -l uris
    for f in $argv
        set -a uris "file://"(realpath $f)
    end
    printf "%s\n" $uris | wl-copy -t text/uri-list
end
