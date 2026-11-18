program main
implicit none
integer :: a(-1:0,4:6)
a(:,4)=[1,2]
a(:,5)=[3,4]
a(:,6)=[5,6]
print *, pack(a(0:-1:-1,6:4:-1),a(0:-1:-1,6:4:-1)>2)
end program
