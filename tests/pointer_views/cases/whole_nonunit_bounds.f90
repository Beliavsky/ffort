program main
implicit none
integer,target::a(-2:1)
integer,pointer::p(:)
a=[1,2,3,4]
p=>a
if(lbound(p,1)/=-2.or.ubound(p,1)/=1) error stop 1
p(-1)=9
if(a(-1)/=9) error stop 2
a(1)=8
if(p(1)/=8) error stop 3
print *,1
end program
