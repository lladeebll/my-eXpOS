#!/usr/bin/env
# Will have to source this in shell rc file

osPath=$HOME/myexpos

xfsi() {
    local currentDir=$PWD
    cd $osPath/xfs-interface
    ./xfs-interface
    cd $currentDir
}

xsm() {
    local currentDir=$PWD
    cd $osPath/xsm
    ./xsm $@
    cd $currentDir
}

spl() {
    local currentDir=$PWD
    for filename in "$@"
    do
        local filePath=$(readlink -f $filename)
        cd $osPath/spl
        op=$(./spl $filePath 2>&1)
        if [[ ! -z $op ]]
        then
            echo "Error compiling $filename"
            echo "$op" | xargs
            echo
        fi
        cd $currentDir
    done
}

expl() {
    local currentDir=$PWD
    for filename in "$@"
    do
        local filePath=$(readlink -f $filename)
        cd $osPath/expl
        op=$(./expl $filePath 2>&1)
        if [[ ! -z $op ]]
        then
            echo "Error compiling $filename"
            echo "$op" | xargs
            echo
        fi
        cd $currentDir
    done
}

load() {
    local currentDir=$PWD
    if [[ -z $1 ]]
    then
        cd $osPath/spl/spl_progs
        spl *.spl

        if [[ -d $osPath/expl/kernel_progs ]]
        then
            cd $osPath/expl/kernel_progs    # need to have kernel_progs dir in expl which contains all kernel processes like init, idle etc
        else
            cd $osPath/expl/expl_progs
        fi
        expl *.expl

        if [[ -d $osPath/expl/shell_progs ]]
        then
            cd $osPath/expl/shell_progs
            expl *.expl

            : > /tmp/loadCommand
            for fileName in *.expl
            do
                local filePath=$(readlink -f $fileName)
                echo "rm ${fileName%.expl}.xsm" >> /tmp/loadCommand
                echo "load --exec ${filePath%.expl}.xsm" >> /tmp/loadCommand
            done

            cd $osPath/xfs-interface
            ./xfs-interface run /tmp/loadCommand > /dev/null 2>&1
        fi

        cd $osPath/xfs-interface
        ./xfs-interface run ../tools/load

    elif [[ $1 == "-e" ]]
    then
        : > /tmp/loadCommand
        for fileName in "${@:2}"
        do
            local filePath=$(readlink -f $fileName)
            expl $fileName
            echo "rm ${fileName%.expl}.xsm" >> /tmp/loadCommand
            echo "load --exec ${filePath%.expl}.xsm" >> /tmp/loadCommand
        done

        cd $osPath/xfs-interface
        ./xfs-interface run /tmp/loadCommand > /dev/null 2>&1

    elif [[ $1 == "-d" ]]
    then
        : > /tmp/loadCommand
        for fileName in "${@:2}"
        do
            echo "rm ${fileName}" >> /tmp/loadCommand
            echo "load --data $(readlink -f $fileName)" >> /tmp/loadCommand
        done

        cd $osPath/xfs-interface
        ./xfs-interface run /tmp/loadCommand > /dev/null 2>&1

    elif [[ $1 == "-a" ]]
    then
        cd $osPath/expl/expl_progs
        expl *.expl

        : > /tmp/loadCommand
        for fileName in *.expl
        do
            local filePath=$(readlink -f $fileName)
            echo "rm ${fileName%.expl}.xsm" >> /tmp/loadCommand
            echo "load --exec ${filePath%.expl}.xsm" >> /tmp/loadCommand
        done

        cd $osPath/xfs-interface
        ./xfs-interface run /tmp/loadCommand > /dev/null 2>&1

    else
        echo "Not completed"
    fi
    cd $currentDir
}
