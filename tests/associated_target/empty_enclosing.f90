program main
implicit none
integer,target::a(4)
integer,pointer::p(:)
logical::z(0)
p=>a
print *,z.and.associated(p,a)
print *,"done"
end program
