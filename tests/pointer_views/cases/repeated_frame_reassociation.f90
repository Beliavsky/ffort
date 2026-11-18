module m
contains
subroutine pick(x,p)
integer,target,intent(in)::x(:)
integer,pointer,intent(out)::p(:)
p=>x
end subroutine
end module
program main
use m
integer,target::a(2),b(3)
integer,pointer::p(:)
integer::i
a=0
b=0
do i=1,12
call pick(a,p)
p=i
if(any(a/=[i,i])) error stop 1
call pick(b,p)
p=i+10
if(any(b/=[i+10,i+10,i+10])) error stop 2
end do
if(size(p)/=3) error stop 3
print *,1
end
