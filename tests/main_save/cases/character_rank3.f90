program p
implicit none
character(len=3),save :: a(-1:0,2:3,-2:-1)='A'
a='xy'
print *, a=='xy '
end program
