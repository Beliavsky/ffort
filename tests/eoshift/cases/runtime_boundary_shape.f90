program p
implicit none
integer,allocatable::b(:)
integer::a(2,2)
allocate(b(3));b=1;a=1
write(*,*)eoshift(a,1,b)
end program
