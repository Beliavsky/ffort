program p
implicit none
integer::i,j,n
do concurrent(i=1:3)
n=i
end do
end program
