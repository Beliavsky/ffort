program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
nullify(p)
print *,associated(p,a(1:9))
end program
