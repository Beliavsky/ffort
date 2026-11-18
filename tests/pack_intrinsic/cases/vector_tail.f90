program main
implicit none
integer :: a(4)=[10,20,30,40]
print *, pack(a,[.false.,.true.,.false.,.true.],[5,6,7,8,9])
end program
