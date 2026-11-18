program main
implicit none
logical :: a(4)=[.true.,.false.,.false.,.true.]
print *, pack(a,[.true.,.false.,.true.,.false.],[.false.,.false.,.true.])
end program
