program main
implicit none
integer,target::a(0,2)
integer,pointer::p(:)
p=>a(:,2)
if(.not.associated(p).or.size(p)/=0) error stop 1
print *,1
end program
