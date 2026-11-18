program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
p=>a(3:3);q=>a(3:3:-2)
print *,associated(p,q),associated(p,a(3:3:2)),associated(p,a(3:3:-2))
q=>a(4:4)
print *,associated(p,q)
end program
