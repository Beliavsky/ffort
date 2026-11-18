program p
implicit none
integer,allocatable::a(:)
integer,parameter::s(1)=shape(a)
print *,s
end program
