program main
implicit none
integer,target::a(-1:1,0:2)
integer,pointer::p(:)
a=0
a(:,1)=[2,3,4]
p=>a(:,1)
p=p+2
if(any(a(:,1)/=[4,5,6])) error stop 1
if(lbound(p,1)/=1.or.ubound(p,1)/=3) error stop 2
print *,1
end program
