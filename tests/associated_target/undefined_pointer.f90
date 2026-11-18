program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
print *,associated(p,a)
end program
