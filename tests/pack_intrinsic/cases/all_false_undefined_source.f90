program main
implicit none
integer :: a(3)
print *, size(pack(a,[.false.,.false.,.false.]))
end program
