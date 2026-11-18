program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
p=>a(2:8:2);q=>a(2:8:2)
print *,associated(p,q),associated(p,a(2:8:2)),associated(p,a(2:5))
q=>a(2:5)
print *,associated(p,q)
p=>a(8:2:-2);q=>a(8:2:-2)
print *,associated(p,q),associated(p,a(2:8:2)),associated(p,a(8:2:-2))
end program
