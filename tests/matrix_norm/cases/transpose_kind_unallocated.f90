program p
implicit none
real,allocatable::a(:,:)
if(kind(transpose(a))/=4) error stop 1
end program
