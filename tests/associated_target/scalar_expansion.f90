program main
implicit none
integer,target::a(4)
integer,pointer::p(:)
logical::z(2)=[.true.,.false.]
p=>a
print *,z.and.associated(p,a)
end program
