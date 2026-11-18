program main
implicit none
integer :: a(2)=[7,8],v(4)
v(3:4)=[9,10]
print *, pack(a,.true.,v)
end program
