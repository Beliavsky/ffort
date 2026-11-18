program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
integer,target::t(2,2,2)
p=>a
print *,associated(p,t(:,1,1))
end program
