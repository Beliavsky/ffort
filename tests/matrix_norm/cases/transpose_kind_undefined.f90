program p
implicit none
real(8)::a(2,3)
if(kind(transpose(a))/=8) error stop 1
end program
