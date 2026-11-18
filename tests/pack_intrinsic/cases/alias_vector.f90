program main
implicit none
integer :: a(4)=[1,2,3,4]
a=pack(a,a>2,a)
print *, a
end program
