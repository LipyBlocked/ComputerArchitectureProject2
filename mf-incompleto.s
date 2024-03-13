DESC_SIZE = 24
OFF_NEXT = 8 
OFF_SIZE = 0
OFF_FREE = 16
.section .text
.global myMalloc, myFree
.extern extend_heap
.extern head

find_block:
# rdi  block size (1st input parameter)

	push %rbp
	mov  %rsp, %rbp
	
	mov %rdi, %rax
	mov %rsp, %rbx
	
	mov head(%rip), %rcx
	mov %rcx, %rbp
	
	
	mov $0, rdx
loop:
	cmp $OFF_SIZE, (%rbp)
	je end_loop
	
	cmp $0,OFF_NEXT(%rbp)
	je free_block
	
	mov (%rbp), %rbp
	jmp loop
	
free_block:
	cmp %rbp,OFF_FREE(%rbp)
	jb not_suitable_block
	mov %rbp,  (%rax)
	mov %rbp, %rax
	jmp end_loop
	
not_suitable_block:
	mov OFF_NEXT(%rbp), %rbp
	jmp loop
end_loop:	

	mov %rbp, %rsp
	pop %rbp
	ret


myMalloc:
#  rdi: size
	push %rbp
	mov  %rsp, %rbp
	sub $16, %rsp
	
	movq %rdi, -OFF_NEXT(%rbp)
	call align4
	movq %rax, -OFF_FREE(%rbp)
	
	movq head,%rdi
	movq -16(%rbp), %rsi
	call find_block
	movq %rax, -DESC_SIZE(%rbp)
	
	cmpq $OFF_SIZE, -24(%rbp)
	jne found_block
	
found_block:
	movq -DESC_SIZE(%rbp), %rax
	movq (%rax), %rdx
	sub -OFF_FREE(%rbp), %rdx
	cmpq $32, %rdx
	jb dont_split
	
	movq -DESC_SIZE(%rbp),%rdi
	movq -OFF_FREE(%rbp), %rsi
	addq $32, %rsi
	call split_block
	jmp block_allocated
	
dont_split:
	movb $O,
	 (%rax)
	
block_allocated:
	movq -DESC_SIZE(%rbp), %rax 
	addq $32, %rax
	jmp return 
	
return:
	addq $16, %rsp
	popq %rbp
	ret
	
error_return:
	movq $0, %rax	



myFree:
# rdi: address of block user area
	push %rbp
	mov  %rsp, %rbp
	
	movq %rdi, %rbx
	
	movq %rbx, %rdi
	call valid_addr
	testq %rax, %rax
	jz .L1
	
	movq %rbx, %rdi
	call get_block
	movq %rax, %rbx
	
	movb $1, (%rbx)
	
	movq (%rbx), %rdi
	movq(%rbx),%rdi
	jz .L2
	
	movq %rdi, %rbx
	movb (%rbx), %al
	cmpb $1, %al
	jne .L2
	
	movq %rbx, %rdi
	call fusion
	
.L2:
	movq %rdi, %rbx
	movq (%rbx), %rdi
	testq %rdi, %rdi
	jz .L3
	
	movq %rbx, %rdi
	call fusion

L3:
	movq(%rbx), %rdi
	teste %rdi, %rdi
	jnz .L4
	
	movq $0, head
	call brk	

	mov %rbp, %rsp
	pop %rbp
	ret

