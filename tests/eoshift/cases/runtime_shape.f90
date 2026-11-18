program p
implicit none
integer,allocatable::s(:)
integer::a(2,2)
allocate(s(3));s=1;a=1
write(*,*)eoshift(a,s)
end program
