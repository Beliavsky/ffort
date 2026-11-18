program p
implicit none
character(*),parameter::fmt='(g0)'
real(8)::x
x=huge(1.0d0)
print fmt,x
end program
