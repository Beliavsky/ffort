program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
real,target::t(8)
p=>a
print *,associated(p,t)
end program
