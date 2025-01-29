#!/usr/bin/gmake -f

zig?=zig
zig:=$(zig)

debug_mode:=0

ifeq '$(debug_mode)' '1'
optimization_args_build_lib:=-ODebug
optimization_args_cc:=-O0
optimization_args_cc_linking:=
else
optimization_args_build_lib:=-OReleaseFast -fomit-frame-pointer
optimization_args_cc:=-O3 -fomit-frame-pointer
optimization_args_cc_linking:=-s
endif

source_folder:=$(dir $(MAKEFILE_LIST))

.PHONY:clean

.ONESHELL:

nix-archive-doublecmd-linux-amd64.wcx:main.o imports.o $(source_folder)nix-archive-doublecmd-linux-amd64.wcx.version-script
	$(zig) cc -target x86_64-linux-gnu -shared -nostdlib -flto=full -Xlinker -hash-style -Xlinker gnu -Xlinker -version-script -Xlinker $(source_folder)nix-archive-doublecmd-linux-amd64.wcx.version-script -onix-archive-doublecmd-linux-amd64.wcx $(optimization_args_cc) $(optimization_args_cc_linking) main.o imports.o

main.o:$(source_folder)main.zig
	$(zig) build-obj -target x86_64-linux-gnu -flto $(optimization_args_build_lib) $(source_folder)main.zig

imports.o:$(source_folder)imports.c
	$(zig) cc -target x86_64-linux-gnu -c -nostdlib -flto=full -fno-plt $(optimization_args_cc) $(source_folder)imports.c

clean:
	$(RM) main.o.o main.o imports.o nix-archive-doublecmd-linux-amd64.wcx