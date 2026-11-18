program main
implicit none
integer::i,a(3)
do i=1,2
a=[(i,i=1,3)]
print *,a,i
end do
print *,i
end program
