program p
implicit none
integer::norm2(2)
norm2=[7,9]
if(norm2(2)/=9) error stop 1
end program
