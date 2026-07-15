    if test (count $argv) -eq 0
        echo "usage: copy <file>"
        return 1
    end
    cat $argv | wl-copy
end
