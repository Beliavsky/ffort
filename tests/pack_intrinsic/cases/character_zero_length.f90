program main
implicit none
character(0) :: a(2),b(3)
a=''
b=pack(a,.true.,['','',''])
print *, size(b),size(pack(a,.false.))
end program
