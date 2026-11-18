program p
implicit none
character(*),parameter::fmt='(*(i0))'
real,allocatable::x(:)
allocate(x(1));x=1.0
print fmt,x
end program
