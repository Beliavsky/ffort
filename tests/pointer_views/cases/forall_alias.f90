program main
implicit none
integer,target::a(4)
integer,pointer::p(:)
integer::i
a=0
p=>a
forall(i=1:4) p(i)=i*2
if(any(a/=[2,4,6,8])) error stop 1
print *,1
end program
