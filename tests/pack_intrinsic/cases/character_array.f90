program main
implicit none
character(2) :: a(3)=['ab','cd','ef']
print *, pack(a,[.true.,.false.,.true.],['uv','wx','yz'])
end program
