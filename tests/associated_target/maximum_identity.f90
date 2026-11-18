program main
implicit none
integer,target::a(131072)
integer,pointer::p(:)
p=>a
print *,associated(p,a)
end program
