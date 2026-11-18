program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
p=>a;q=>a
print *,associated(p,a+1)
end program
