program main
implicit none
integer :: a(6)=[3,-2,8,0,-5,9]
print *, pack(a,a>0)
end program
