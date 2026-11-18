program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
integer::j
j=2;p=>a(j:8:2)
j=4
print *,associated(p,a(2:8:2)),associated(p,a(j:8:2))
end program
