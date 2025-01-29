extern fn MyAlloc(size:u32) ?Handle;
extern fn MyFree(noalias addr:Handle) void;
extern fn MyNotEqualAligned8(a:usize,noalias b:[*]const u8,size:u32) bool;
extern fn MyNotEqual(noalias a:[*]const u8,noalias b:[*]const u8,size:u32) bool;
extern fn IsNarHeader(noalias a:*const[21]u8) u32;

const WcxError=enum(u32){
	E_SUCCESS=          0,       //Success
	E_END_ARCHIVE=     10,       //No more files in archive
	E_NO_MEMORY=       11,       //Not enough memory
	E_BAD_DATA=        12,       //Data is bad
	E_BAD_ARCHIVE=     13,       //CRC error in archive data
	E_UNKNOWN_FORMAT=  14,       //Archive format unknown
	E_EOPEN=           15,       //Cannot open existing file
	E_ECREATE=         16,       //Cannot create file
	E_ECLOSE=          17,       //Error closing file
	E_EREAD=           18,       //Error reading from file
	E_EWRITE=          19,       //Error writing to file
	E_SMALL_BUF=       20,       //Buffer too small
	E_EABORTED=        21,       //Function aborted by user
	E_NO_FILES=        22,       //No files found
	E_TOO_MANY_FILES=  23,       //Too many files to pack
	E_NOT_SUPPORTED=   24,       //Function not supported
};

const WcxErrorCap:comptime_int=25;

const OneError=error{e};

//https://syscalls.mebeim.net/?table=x86%2F64%2Fx64%2Flatest

inline fn OpenFileReadOnly(noalias path:[*:0]const u8) u32{
	var rcx:usize=undefined;
	var r11:usize=undefined;
	return asm volatile(
		"syscall"
		:
		[a]"={rax}"(->u32),
		[b]"={rcx}"(rcx),
		[c]"={r11}"(r11)
		:
		[d]"{rax}"(@as(u32,2)),//open syscall number
		[e]"{rdi}"(path),
		[f]"{rsi}"(@as(u32,524288))//O_CLOEXEC|O_RDONLY
	);
}

inline fn OpenFileWriteOnly(noalias path:[*:0]const u8,mode:u16) u32{
	var rcx:usize=undefined;
	var r11:usize=undefined;
	return asm volatile(
		"syscall"
		:
		[a]"={rax}"(->u32),
		[b]"={rcx}"(rcx),
		[c]"={r11}"(r11)
		:
		[d]"{rax}"(@as(u32,2)),//open syscall number
		[e]"{rdi}"(path),
		[f]"{rsi}"(@as(u32,524481)),//O_CLOEXEC|O_CREAT|O_EXCL|O_WRONLY
		[g]"{rdx}"(mode)
	);
}

inline fn close(fd:u32) u32{
	var rcx:usize=undefined;
	var r11:usize=undefined;
	return asm volatile(
		"syscall"
		:
		[a]"={rax}"(->u32),
		[b]"={rcx}"(rcx),
		[c]"={r11}"(r11)
		:
		[d]"{rax}"(@as(u32,3)),//close syscall number
		[e]"{rdi}"(fd)
	);
}

//treating return value as 32bit because never read more than ReadBufSize
inline fn pread64(fd:u32,noalias buf:[*]u8,count:usize,pos:u64) u32{
	var rcx:usize=undefined;
	var r11:usize=undefined;
	return asm volatile(
		"syscall"
		:
		[a]"={rax}"(->u32),
		[b]"={rcx}"(rcx),
		[c]"={r11}"(r11)
		:
		[d]"{rax}"(@as(u32,17)),//pread64 syscall number
		[e]"{rdi}"(fd),
		[f]"{rsi}"(buf),
		[g]"{rdx}"(count),
		[h]"{r10}"(pos)
	);
}

inline fn unlink(noalias path:[*:0]const u8) u32{
	var rcx:usize=undefined;
	var r11:usize=undefined;
	return asm volatile(
		"syscall"
		:
		[a]"={rax}"(->u32),
		[b]"={rcx}"(rcx),
		[c]"={r11}"(r11)
		:
		[d]"{rax}"(@as(u32,87)),//unlink syscall number
		[e]"{rdi}"(path)
	);
}

inline fn symlink(noalias content:[*:0]const u8,noalias path:[*:0]const u8) u32{
	var rcx:usize=undefined;
	var r11:usize=undefined;
	return asm volatile(
		"syscall"
		:
		[a]"={rax}"(->u32),
		[b]"={rcx}"(rcx),
		[c]"={r11}"(r11)
		:
		[d]"{rax}"(@as(u32,88)),//symlink syscall number
		[e]"{rdi}"(content),
		[f]"{rsi}"(path)
	);
}

//treating return value as 32bit is fine because never copy more than (1<<31)-1
inline fn copy_file_range(fd_in:u32,noalias off_in:?*u64,fd_out:u32,noalias off_out:?*u64,len:usize,flags:u32) u32{
	var rcx:usize=undefined;
	var r11:usize=undefined;
	return asm volatile(
		"syscall"
		:
		[a]"={rax}"(->u32),
		[b]"={rcx}"(rcx),
		[c]"={r11}"(r11)
		:
		[d]"{rax}"(@as(u32,326)),//copy_file_range syscall number
		[e]"{rdi}"(fd_in),
		[f]"{rsi}"(off_in),
		[g]"{rdx}"(fd_out),
		[h]"{r10}"(off_out),
		[i]"{r8}"(len),
		[j]"{r9}"(flags)
	);
}

//treating return value as 32bit is fine because never copy more than (1<<31)-1
inline fn sendfile(out_fd:u32,in_fd:u32,noalias offset:?*u64,count:usize) u32{
	var rcx:usize=undefined;
	var r11:usize=undefined;
	return asm volatile(
		"syscall"
		:
		[a]"={rax}"(->u32),
		[b]"={rcx}"(rcx),
		[c]"={r11}"(r11)
		:
		[d]"{rax}"(@as(u32,40)),//sendfile64 syscall number
		[e]"{rdi}"(out_fd),
		[f]"{rsi}"(in_fd),
		[g]"{rdx}"(offset),
		[h]"{r10}"(count)
	);
}

fn CheckStruct(s:type) void{
	var offset:comptime_int=0;
	for(@typeInfo(s).@"struct".fields)|f|{
		if(offset%@sizeOf(f.type)!=0)@compileError("misaligned field");
		if(offset!=@offsetOf(s,f.name))@compileError("inner padding");
		offset=offset+@sizeOf(f.type);
	}
	if(offset!=@sizeOf(s))@compileError("tail padding");
}

fn NextPowerOf2(num:comptime_int) comptime_int{
	var r:comptime_int=1;
	while(r<=num)r=r<<1;
	return r;
}

const ReadBufSize:comptime_int=1024;

const tProcessDataProc=*const fn(noalias FileName:?[*:0]const u8,Size:u32) callconv(.c) u32;

const HandleData=extern struct{
	ReadBuf:[ReadBufSize]u8,
	PathBuf:[1024]u8,
	ReadBufValidBytes:u16,
	PathBufValidBytes:u16,
	fd:u32 align(2),
	ReadBufOffsetInFile:u64 align(2),
	OffsetInFile:u64 align(2),
	ProcessDataProc:tProcessDataProc align(2),
	FileSize:u64 align(2),
	FileType:enum(u16){folder,symlink,file=0o644,xfile=0o755}
};

comptime{CheckStruct(HandleData);}

const Handle=*align(16) HandleData;

noinline fn GetFileRangeInternal(noalias handle:Handle,offset:u64,size:u32) usize{
	if(offset<handle.ReadBufOffsetInFile)unreachable;
	if(offset&7!=0)unreachable;
	if(handle.ReadBufValidBytes>ReadBufSize)unreachable;
	if(size==0)unreachable;
	if(size>ReadBufSize)unreachable;
	const OffsetInReadBuf:u64=offset-handle.ReadBufOffsetInFile;
	if(OffsetInReadBuf+size<=handle.ReadBufValidBytes)return @intFromPtr(handle.ReadBuf[OffsetInReadBuf..].ptr);
	const fd:u32=handle.fd;
	var ReadTotal:u32=0;
	while(ReadTotal<size){
		const ReadResult:u32=pread64(fd,handle.ReadBuf[ReadTotal..].ptr,ReadBufSize-ReadTotal,offset+ReadTotal);
		switch(ReadResult){
			1...(1<<31)-1=>ReadTotal=ReadTotal+ReadResult,
			0=>return @intFromEnum(WcxError.E_BAD_DATA),//end of file
			1<<31...(1<<32)-1=>return @intFromEnum(WcxError.E_EREAD)
		}
	}
	handle.ReadBufValidBytes=@intCast(ReadTotal);
	handle.ReadBufOffsetInFile=offset;
	return @intFromPtr(&handle.ReadBuf);
}

//offset should be divisible by 8
//offset should be in range [ offset from previous call with same handle ; (1<<63)-ReadBufSize ]
//size should be in range [ 1 ; ReadBufSize ]
//returns address of data
inline fn GetFileRange(noalias handle:Handle,noalias outerr:*WcxError,offset:u64,size:u32) OneError!usize{
	const r:usize=GetFileRangeInternal(handle,offset,size);
	if(r<WcxErrorCap){
		outerr.*=@enumFromInt(r);
		return OneError.e;
	}
	return r;
}

const NarStr=extern struct{
	ptr:usize,
	len:u32
};

//this does not check offset before calling GetFileRange
noinline fn GetNarStrInternal(noalias handle:Handle) callconv(.c) NarStr{
	const offset:u64=handle.OffsetInFile;
	const r1:usize=GetFileRangeInternal(handle,offset,8);
	if(r1<WcxErrorCap)return NarStr{.ptr=r1,.len=undefined};
	const NarStrSize64:u64=@as(*u64,@ptrFromInt(r1)).*;
	switch(NarStrSize64){
		ReadBufSize+1...(1<<64)-1=>return NarStr{.ptr=@intFromEnum(WcxError.E_SMALL_BUF),.len=undefined},
		0=>return NarStr{.ptr=@intFromEnum(WcxError.E_BAD_DATA),.len=undefined},
		1...ReadBufSize=>{},
	}
	const NarStrSize32:u32=@intCast(NarStrSize64);
	handle.OffsetInFile=offset+((NarStrSize32+15)&(NextPowerOf2(ReadBufSize+15)-8));
	return NarStr{.ptr=GetFileRangeInternal(handle,offset+8,NarStrSize32),.len=NarStrSize32};
}

inline fn GetNarStr(noalias handle:Handle,noalias outerr:*WcxError) OneError!NarStr{
	const r:NarStr=GetNarStrInternal(handle);
	if(r.ptr<WcxErrorCap){
		outerr.*=@enumFromInt(r.ptr);
		return OneError.e;
	}
	return r;
}

//this does not check offset before calling GetFileRange
inline fn ExpectNarStr(noalias handle:Handle,noalias outerr:*WcxError,noalias str:[]const u8) OneError!void{
	const len:comptime_int=str.len+8;
	const offset1:u64=handle.OffsetInFile;
	const r:usize=GetFileRangeInternal(handle,offset1,len);
	if(r<WcxErrorCap){
		outerr.*=@enumFromInt(r);
		return OneError.e;
	}
	if(MyNotEqualAligned8(r,[8]u8{str.len,0,0,0,0,0,0,0}++str,len)){
		outerr.*=WcxError.E_BAD_DATA;
		return OneError.e;
	}
	handle.OffsetInFile=offset1+((len+7)&-8);
}

const OffsetInfo=struct{
	used:comptime_int,
	needed:comptime_int
};

fn OffsetInfoGetNarStr(noalias LongestStr:[]const u8) OffsetInfo{
	return OffsetInfo{
		.used=@as(comptime_int,LongestStr.len+15)&-8,
		.needed=ReadBufSize+8
	};
}

const OffsetInfoGetNarStrFull:OffsetInfo=OffsetInfo{
	.used=ReadBufSize+8,
	.needed=ReadBufSize+8
};

fn OffsetInfoExpectNarStr(noalias Str:[]const u8) OffsetInfo{
	return OffsetInfo{
		.used=@as(comptime_int,Str.len+15)&-8,
		.needed=ReadBufSize
	};
}

//OffsetInfoSkipNarStr should be last thing in OffsetCap tuple if if exists
const OffsetInfoSkipNarStr:OffsetInfo=OffsetInfo{
	.used=0,//don't know at compile time
	.needed=ReadBufSize
};

fn OffsetCap(OffsetInfos:anytype) comptime_int{
	var used:comptime_int=0;
	var needed:comptime_int=0;
	for(OffsetInfos)|i|{
		needed=@max(needed,used+i.needed);
		used=used+i.used;
	}
	return (1<<63)-needed;
}

inline fn NarStrIs(a:NarStr,noalias b:[]const u8) bool{
	return a.len==@as(comptime_int,b.len) and !MyNotEqualAligned8(a.ptr,b.ptr,@as(comptime_int,b.len));
}

inline fn CopyBytes(noalias from:[*]const u8,noalias to:[*]u8,count:usize) void{
	var rcx:usize=undefined;
	var rsi:[*]const u8=undefined;
	var rdi:[*]u8=undefined;
	asm volatile(
		"rep movsb"
		:
		[a]"={rcx}"(rcx),
		[b]"={rsi}"(rsi),
		[c]"={rdi}"(rdi)
		:
		[d]"{rcx}"(count),
		[e]"{rsi}"(from),
		[f]"{rdi}"(to)
	);
	if(rcx!=0)unreachable;
	if(rsi!=from+count)unreachable;
	if(rdi!=to+count)unreachable;
}

fn fake_ProcessDataProc(noalias FileName:?[*:0]const u8,Size:u32) callconv(.c) u32{
	_=FileName;
	_=Size;
	return 1;
}

inline fn OpenArchiveInternal(noalias path:[*:0]const u8,noalias outerr:*WcxError) OneError!Handle {
	const handle:Handle=MyAlloc(@sizeOf(HandleData)) orelse {
		outerr.*=WcxError.E_NO_MEMORY;
		return OneError.e;
	};
	errdefer MyFree(handle);
	const fd:u32=OpenFileReadOnly(path);
	if(fd>=1<<31){
		outerr.*=WcxError.E_EOPEN;
		return OneError.e;
	}
	errdefer _=close(fd);
	handle.ReadBufValidBytes=0;
	handle.PathBufValidBytes=0;
	handle.fd=fd;
	handle.ReadBufOffsetInFile=0;
	handle.OffsetInFile=0;
	handle.ProcessDataProc=fake_ProcessDataProc;
	try ExpectNarStr(handle,outerr,"nix-archive-1");
	try ExpectNarStr(handle,outerr,"(");
	try ExpectNarStr(handle,outerr,"type");
	try ExpectNarStr(handle,outerr,"directory");
	return handle;
}

const tOpenArchiveData=extern struct{
	ArcName:[*:0]const u8,
	OpenMode:u32,
	OpenResult:WcxError
	//don't care about Cmt* stuff
};

export fn OpenArchive(noalias ArchiveData:*tOpenArchiveData) ?Handle{
	return OpenArchiveInternal(ArchiveData.ArcName,&ArchiveData.OpenResult) catch null;
}

export fn ReadHeader(noalias handle:Handle,HeaderData:usize) WcxError{
	_=handle;
	_=HeaderData;
	return WcxError.E_NOT_SUPPORTED;
}

const tHeaderDataEx=extern struct{
	ArcName:[1024]u8,
	FileName:[1024]u8,
	Flags:u32,
	PackSize64:u64 align(4),
	UnpSize64:u64 align(4),
	HostOS:u32,
	FileCRC:u32,
	FileTime:u32,
	UnpVer:u32,
	Method:u32,
	FileAttr:u32,
	CmtBuf:usize,
	CmtBufSize:u32,
	CmtSize:u32,
	CmtState:u32,
	Reserved:[1024]u8
};

inline fn ReadHeaderExInternal(noalias handle:Handle,noalias outerr:*WcxError,noalias HeaderDataEx:*tHeaderDataEx) OneError{
	if(handle.OffsetInFile>OffsetCap(.{
		OffsetInfo{
			//get out of max possible number of folders
			.used=(handle.PathBuf.len+1)/2*2*16,
			.needed=((handle.PathBuf.len+1)/2*2-1)*16+ReadBufSize
		},
		OffsetInfoGetNarStr("entry"),
		OffsetInfoExpectNarStr("("),
		OffsetInfoExpectNarStr("name"),
		OffsetInfoGetNarStrFull,
		OffsetInfoExpectNarStr("node"),
		OffsetInfoExpectNarStr("("),
		OffsetInfoExpectNarStr("type"),
		OffsetInfoGetNarStr("regular"),
		OffsetInfoGetNarStr("executable"),
		OffsetInfoExpectNarStr(""),
		OffsetInfoExpectNarStr("contents"),
		OffsetInfo{.used=8,.needed=ReadBufSize}
	}) or !NarStrIs(while(true){
		const str:NarStr=try GetNarStr(handle,outerr);
		if(!NarStrIs(str,")"))break str;
		var PathBufValidBytes:usize=handle.PathBufValidBytes;
		if(PathBufValidBytes==0){
			outerr.*=WcxError.E_END_ARCHIVE;
			return OneError.e;
		}
		while(true){
			PathBufValidBytes=PathBufValidBytes-1;
			if(PathBufValidBytes==0 or handle.PathBuf[PathBufValidBytes]==0x2F)break;
		}
		handle.PathBufValidBytes=@intCast(PathBufValidBytes);
		try ExpectNarStr(handle,outerr,")");
	},"entry")){
		outerr.*=WcxError.E_BAD_DATA;
		return OneError.e;
	}
	try ExpectNarStr(handle,outerr,"(");
	try ExpectNarStr(handle,outerr,"name");
	const name:NarStr=try GetNarStr(handle,outerr);
	if(//name.len==0 causes E_BAD_DATA inside GetNarStr
		(name.len==1 and @as(*u8,@ptrFromInt(name.ptr)).*==0x2E)
		or (name.len==2 and @as(*u16,@ptrFromInt(name.ptr)).*==0x2E2E)
	){
		outerr.*=WcxError.E_BAD_DATA;
		return OneError.e;
	}
	{
		var i:usize=name.ptr+name.len;
		while(i>name.ptr){
			i=i-1;
			const c:u8=@as(*u8,@ptrFromInt(i)).*;
			if(c==0 or c==0x2F){
				outerr.*=WcxError.E_BAD_DATA;
				return OneError.e;
			}
		}
	}
	comptime if(handle.PathBuf.len!=HeaderDataEx.FileName.len)@compileError("different size path buffers");
	const PathBufValidBytes:u32=handle.PathBufValidBytes;
	if(PathBufValidBytes!=0){
		if(PathBufValidBytes+name.len>@as(comptime_int,HeaderDataEx.FileName.len-1)){
			outerr.*=WcxError.E_SMALL_BUF;
			return OneError.e;
		}
		CopyBytes(&handle.PathBuf,&HeaderDataEx.FileName,PathBufValidBytes);
		HeaderDataEx.FileName[PathBufValidBytes]=0x2F;
		CopyBytes(@ptrFromInt(name.ptr),HeaderDataEx.FileName[PathBufValidBytes+@as(usize,1)..].ptr,name.len);
	}else{
		comptime if(ReadBufSize>HeaderDataEx.FileName.len)@compileError("need run time check here");
		CopyBytes(@ptrFromInt(name.ptr),&HeaderDataEx.FileName,name.len);
	}
	try ExpectNarStr(handle,outerr,"node");
	try ExpectNarStr(handle,outerr,"(");
	try ExpectNarStr(handle,outerr,"type");
	const TypeStr:NarStr=try GetNarStr(handle,outerr);
	if(NarStrIs(TypeStr,"directory")){
		HeaderDataEx.FileAttr=0o40755;
		const AppendLen:u32=name.len+@intFromBool(PathBufValidBytes!=0);
		CopyBytes(HeaderDataEx.FileName[PathBufValidBytes..].ptr,handle.PathBuf[PathBufValidBytes..].ptr,AppendLen);
		handle.PathBufValidBytes=@intCast(PathBufValidBytes+AppendLen);
		handle.FileType=.folder;
	}else{
		if(NarStrIs(TypeStr,"regular")){
			const AfterTypeStr:NarStr=try GetNarStr(handle,outerr);
			if(NarStrIs(AfterTypeStr,"executable")){
				try ExpectNarStr(handle,outerr,"");
				try ExpectNarStr(handle,outerr,"contents");
				HeaderDataEx.FileAttr=0o100755;
				handle.FileType=.xfile;
			}else if(NarStrIs(AfterTypeStr,"contents")){
				HeaderDataEx.FileAttr=0o100644;
				handle.FileType=.file;
			}else{
				outerr.*=WcxError.E_BAD_DATA;
				return OneError.e;
			}
		}else if(NarStrIs(TypeStr,"symlink")){
			try ExpectNarStr(handle,outerr,"target");
			HeaderDataEx.FileAttr=0o120777;
			handle.FileType=.symlink;
		}else{
			outerr.*=WcxError.E_BAD_DATA;
			return OneError.e;
		}
		const offset1:u64=handle.OffsetInFile;
		const FileSize:u64=@as(*u64,@ptrFromInt(try GetFileRange(handle,outerr,offset1,8))).*;
		HeaderDataEx.PackSize64=FileSize;
		HeaderDataEx.UnpSize64=FileSize;
		handle.FileSize=FileSize;
		handle.OffsetInFile=offset1+8;
	}
	return OneError.e;
}

export fn ReadHeaderEx(noalias handle:Handle,noalias HeaderDataEx:*tHeaderDataEx) WcxError{
	var r:WcxError=WcxError.E_SUCCESS;
	ReadHeaderExInternal(handle,&r,HeaderDataEx) catch {};
	return r;
}

inline fn ProcessFileInternal(noalias handle:Handle,noalias outerr:*WcxError,extract:bool,noalias DestName:[*:0]const u8) OneError{
	const FileType=handle.FileType;
	if(FileType==.folder)return OneError.e;//do nothing for folders
	var offset:u64=handle.OffsetInFile;
	const FileSize64:u64=handle.FileSize;
	const OffsetAfterFile:u64=offset+|FileSize64;
	{
		const oc:comptime_int=OffsetCap(.{
			OffsetInfo{.used=ReadBufSize,.needed=ReadBufSize},
			OffsetInfoExpectNarStr(")"),
			OffsetInfoExpectNarStr(")")
		});
		if(OffsetAfterFile>oc-7){
			outerr.*=WcxError.E_BAD_DATA;
			return OneError.e;
		}
		handle.OffsetInFile=(OffsetAfterFile+7)&(NextPowerOf2(oc)-8);
	}
	if(extract)switch(FileType){
		.folder=>unreachable,//handled before
		.symlink=>switch(FileSize64){//symlink
			0=>{
				outerr.*=WcxError.E_BAD_DATA;
				return OneError.e;
			},
			ReadBufSize+1...(1<<64)-1=>{
				outerr.*=WcxError.E_SMALL_BUF;
				return OneError.e;
			},
			1...ReadBufSize=>{
				const FileSize32:u32=@intCast(FileSize64);
				const content:usize=try GetFileRange(handle,outerr,offset,FileSize32);
				{
					var i:usize=content+FileSize32;
					while(i>content){
						i=i-1;
						if(@as(*u8,@ptrFromInt(i)).*==0){
							outerr.*=WcxError.E_BAD_DATA;
							return OneError.e;
						}
					}
				}
				//for(0..FileSize32,content)|_,c|if(c==0)return WcxError.E_BAD_DATA;
				comptime if(@offsetOf(HandleData,"ReadBuf")+ReadBufSize>=@sizeOf(HandleData))@compileError("can't safely access after ReadBuf");
				const TerminatorAddr:*u8=@ptrFromInt(content+FileSize32);
				const OldTerminator:u8=TerminatorAddr.*;
				TerminatorAddr.*=0;//linux syscalls use 0 byte teminated strings
				const res:u32=symlink(@ptrFromInt(content),DestName);
				//17 is EEXIST
				if(res!=0 and !(res==(1<<32)-17 and unlink(DestName)==0 and symlink(@ptrFromInt(content),DestName)==0)){
					outerr.*=WcxError.E_ECREATE;
					return OneError.e;
				}
				TerminatorAddr.*=OldTerminator;
			}
		},
		.file,.xfile=>{
			const fd_out:u32=b:{
				const res1:u32=OpenFileWriteOnly(DestName,@intFromEnum(FileType));
				if(res1<1<<31)break :b res1;
				//17 is EEXIST
				if(res1==(1<<32)-17 and unlink(DestName)==0){
					const res2:u32=OpenFileWriteOnly(DestName,@intFromEnum(FileType));
					if(res2<1<<31)break :b res2;
				}
				outerr.*=WcxError.E_ECREATE;
				return OneError.e;
			};
			if(OffsetAfterFile-offset!=FileSize64)unreachable;
			if(FileSize64!=0){
				errdefer{//will only get executed by `return OneError.e;` inside this block
					_=close(fd_out);
					_=unlink(DestName);
				}
				const fd_in:u32=handle.fd;
				const ProcessDataProc:tProcessDataProc=handle.ProcessDataProc;
				var res:u32=copy_file_range(fd_in,&offset,fd_out,null,@min(OffsetAfterFile-offset,(1<<31)-1),0);
				switch(res){
					0=>{//end of file
						outerr.*=WcxError.E_BAD_DATA;
						return OneError.e;
					},
					1...(1<<31)-1=>//copy_file_range worked, use copy_file_range for remaining data
					while(offset<OffsetAfterFile){
						if(ProcessDataProc(null,res)==0){
							outerr.*=WcxError.E_EABORTED;
							return OneError.e;
						}
						res=copy_file_range(fd_in,&offset,fd_out,null,@min(OffsetAfterFile-offset,(1<<31)-1),0);
						switch(res){
							0=>{//end of input file
								outerr.*=WcxError.E_BAD_DATA;
								return OneError.e;
							},
							1<<31...(1<<32)-1=>{
								outerr.*=WcxError.E_EWRITE;
								return OneError.e;
							},
							1...(1<<31)-1=>{}
						}
					},
					1<<31...(1<<32)-1=>//copy_file_range didn't work, use sendfile for all data
					while(true){
						res=sendfile(fd_out,fd_in,&offset,@min(OffsetAfterFile-offset,(1<<31)-1));
						switch(res){
							0=>{//end of input file
								outerr.*=WcxError.E_BAD_DATA;
								return OneError.e;
							},
							1<<31...(1<<32)-1=>{
								outerr.*=WcxError.E_EWRITE;
								return OneError.e;
							},
							1...(1<<31)-1=>{}
						}
						if(offset>=OffsetAfterFile)break;
						if(ProcessDataProc(null,res)==0){
							outerr.*=WcxError.E_EABORTED;
							return OneError.e;
						}
					}
				}
			}
			if(close(fd_out)!=0){
				outerr.*=WcxError.E_ECLOSE;
				return OneError.e;
			}
		}
	};
	try ExpectNarStr(handle,outerr,")");
	try ExpectNarStr(handle,outerr,")");
	return OneError.e;
}

export fn ProcessFile(noalias handle:Handle,operation:u32,DestPath:usize,noalias DestName:[*:0]const u8) WcxError{
	_=DestPath;//cpio plugin just ignores DestPath https://github.com/doublecmd/doublecmd/blob/1db3bb54e43651a29ec90c334650c47574bcc710/plugins/wcx/cpio/src/cpio_archive.pas#L169
	var r:WcxError=WcxError.E_SUCCESS;
	ProcessFileInternal(handle,&r,operation==2,DestName) catch {};
	return r;
}

export fn SetProcessDataProc(noalias handle:Handle,noalias ProcessDataProc:tProcessDataProc) void{
	handle.ProcessDataProc=ProcessDataProc;
}

export fn CloseArchive(noalias handle:Handle) WcxError{
	const fd:u32=handle.fd;
	MyFree(handle);
	return if(close(fd)!=0)WcxError.E_ECLOSE else WcxError.E_SUCCESS;
}

export fn GetPackerCaps() u32{
	return 68;//PK_CAPS_MULTIPLE|PK_CAPS_BY_CONTENT
}

export fn GetBackgroundFlags() u32{
	return 1;//BACKGROUND_UNPACK
}

export fn CanYouHandleThisFile(noalias path:[*:0]const u8) u32{
	const fd:u32=OpenFileReadOnly(path);
	if(fd>=1<<31)return 0;
	var a:[21]u8=undefined;
	var remaining:u32=21;
	while(remaining!=0){
		const res:u32=pread64(fd,@as([*]u8,&a)+21-remaining,remaining,21-remaining);
		if(res>=1<<31 or res==0){
			_=close(fd);
			return 0;
		}
		remaining=remaining-res;
	}
	_=close(fd);
	return IsNarHeader(&a);
}