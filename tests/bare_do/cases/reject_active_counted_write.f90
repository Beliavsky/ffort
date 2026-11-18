program p
implicit none
integer::i
do i=1,3
do
i=9
exit
end do
end do
end program
