module m
implicit none
contains
subroutine probe(a)
integer,allocatable,intent(inout)::a(:)
character(len=size(a))::word
word="abcd"
deallocate(a)
allocate(a(1))
if(len(word)/=4.or.word/="abcd") error stop 1
end subroutine
end module
program main
use m
implicit none
integer,allocatable::a(:)
allocate(a(4))

call probe(a)

print *,1
end
