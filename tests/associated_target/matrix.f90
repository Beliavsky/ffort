program main
implicit none
integer,target::a(-1:2,5:9),b(4,5)
integer,pointer::p(:),q(:)
p=>a(0,9:5:-2);q=>a(0,9:5:-2)
print *,associated(p,q),associated(p,a(0,9:5:-2)),associated(p,a(0,5:9:2))
p=>a(-1:2,7)
print *,associated(p,a(:,7)),associated(p,a(:,8))
p=>a(-1:2:2,7);q=>a(-1:1:2,7)
print *,associated(p,q),associated(p,a(-1:1:2,7))
end program
