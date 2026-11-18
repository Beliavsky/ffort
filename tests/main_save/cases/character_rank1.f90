program p
implicit none
character(len=3),save :: a(-1:0)='A'
a='xy'
print *, all(a=='xy ')
end program
