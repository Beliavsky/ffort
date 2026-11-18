program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
print *,kind(associated(p,a)),kind(associated(p,q))
end program
