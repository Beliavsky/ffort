program main
implicit none
integer::i
real(8),parameter::a(3)=[(0.25_8*i,i=1,3)]
print *,a
end program
