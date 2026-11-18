program p
implicit none
character(*),parameter::fmt='(*(g0))'
integer::i
character(2),allocatable::x(:)
allocate(x(32769));x='ab'
print fmt,x
end program
