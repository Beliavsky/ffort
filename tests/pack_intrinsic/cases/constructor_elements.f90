program main
implicit none
integer :: a(3)=[1,2,3]
print *, [0,pack(a,a>1),4]
end program
