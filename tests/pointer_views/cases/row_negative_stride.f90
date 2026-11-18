program main
implicit none
integer,target::a(2,3)
integer,pointer::p(:)
a=0
a(2,:)=[3,4,5]
p=>a(2,3:1:-1)
if(any(p/=[5,4,3])) error stop 1
p(2)=9
if(a(2,2)/=9.or.lbound(p,1)/=1) error stop 2
print *,1
end program
