program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
integer,target::t(2,4)
p=>a
print *,associated(p,t)
end program
