program main
implicit none
integer :: a(0),b(0,3)
logical :: m(0,3)
print *, size(pack(a,.true.)),size(pack(b,m)),size(pack(a,.false.,a))
print *, pack(a,.true.,[5,6])
end program
