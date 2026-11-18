program main
implicit none
integer,allocatable::i
integer::a(3)
a=[(i,i=1,3)]
print *,a,allocated(i)
end program
