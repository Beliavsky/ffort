program p
implicit none
integer::i
do i=0,127
print *,iachar(achar(i),8)
end do
end program
