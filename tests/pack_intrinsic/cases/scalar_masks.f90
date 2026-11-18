program main
implicit none
integer :: a(3)=[2,4,6]
print *, pack(a,.true.)
print *, size(pack(a,.false.))
end program
