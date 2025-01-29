void *MyAlloc(unsigned size){
	return __builtin_malloc(size);
}
void MyFree(void *restrict addr){
	__builtin_free(addr);
}
_Bool MyNotEqualAligned8(const void *restrict a,const void *restrict b,unsigned size){
	return __builtin_memcmp(__builtin_assume_aligned(a,8),b,size);
}
unsigned IsNarHeader(const void *restrict a){
	return !__builtin_memcmp(a,"\x0D\x00\x00\x00\x00\x00\x00\x00nix-archive-1",21);
}