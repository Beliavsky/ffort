program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
nullify(p)
print *,associated(p,q)
end program
