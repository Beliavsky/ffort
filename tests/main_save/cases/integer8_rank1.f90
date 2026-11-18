program p
implicit none
integer(8),save :: a(-1:0)=9007199254740993_8
a=a+2_8
print *, all(a==9007199254740995_8)
end program
