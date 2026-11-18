program main
implicit none
integer :: a(2,3)
a(:,1)=[1,2]
a(:,2)=[3,4]
a(:,3)=[5,6]
print *, pack(a,mod(a,2)==0)
end program
