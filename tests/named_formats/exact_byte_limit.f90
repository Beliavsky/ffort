program p
implicit none
character(*),parameter::fmt='(*(g0))'
character(1)::x(65536)
x='x'
print fmt,x
end program
