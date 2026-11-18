program integration_main
implicit none
integer,target::a(3)
integer,pointer::p(:)
p=>a
print *,associated(p,cshift(a,1))
end program
