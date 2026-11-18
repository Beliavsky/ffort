program p
implicit none
integer::transpose(2)
transpose=[7,9]
if(transpose(2)/=9) error stop 1
end program
