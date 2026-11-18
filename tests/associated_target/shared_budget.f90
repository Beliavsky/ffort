program main
implicit none
integer,target::a(1000)
integer,pointer::p(:)
p=>a
print *,associated(p,a)
end program
