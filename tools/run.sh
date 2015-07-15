if [ $1 ]; then
    ENTRY="-entry $1"
fi
open runtime/mac/princess\ Mac.app --args -workdir /Users/ntotani/Documents/cocos/princess -debugger codeide $ENTRY

