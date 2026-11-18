program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
integer,target::z(0)
p=>a(1:0);q=>a(2:1)
print *,associated(p),associated(q),associated(p,q),associated(p,a(1:0))
p=>z;q=>z
print *,associated(p),associated(p,q),associated(p,z)
end program
