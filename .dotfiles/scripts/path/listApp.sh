function listApp() {
    echo "\n# /Applications\n"
    ls /Applications
    echo "\n# ~/Applications\n"
    ls $HOME/Applications
    echo "\n# brew\n"
    brew list
}

dt=$(date '+%Y-%m-%d')

cd $HOME/Downloads
pathName="apps ($dt).md"

listApp >$pathName
