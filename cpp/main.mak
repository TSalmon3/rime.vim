mode: exe
int: build

flag: -O2 -Wall

inc: ./3rd

# macOS (homebrew)
darwin/inc: /opt/homebrew/include
darwin/lib: /opt/homebrew/lib

# WSL
linux/inc: /usr/include
linux/lib: /usr/lib/x86_64-linux-gnu

# win64
llm/inc: d:/Library/librime/include
llm/lib: d:/Library/librime/lib

link: rime
llm/link: ws2_32

src: rime-query.cc

out: build/rime-query

# vim: ft=emake
