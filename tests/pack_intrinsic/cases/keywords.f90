program main
implicit none
integer :: a(3)=[1,2,3]
print *, pack(vector=[9,8,7,6],mask=a>1,array=a)
print *, pack(mask=a<3,array=a)
end program
