program main
implicit none
integer,target::a(3)
integer,pointer::p(:)
p=>a(3:1)
if(.not.associated(p)) error stop 1
if(size(p)/=0.or.lbound(p,1)/=1.or.ubound(p,1)/=0) error stop 2
p=5
print *,1
end program
