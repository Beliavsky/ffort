program main
implicit none
integer,allocatable::i
integer::a(3)
allocate(i)
i=99
a=[(i,i=1,3)]
print *,a,i
end program
