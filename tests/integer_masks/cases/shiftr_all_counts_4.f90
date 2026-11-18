program p
implicit none
integer::n
integer(4)::i
i=(-huge(0_4)-1_4)
do n=0,32
print *,shiftr(i,n)
end do
i=-1_4
do n=0,32
print *,shiftr(i,n)
end do
i=0_4
do n=0,32
print *,shiftr(i,n)
end do
i=1_4
do n=0,32
print *,shiftr(i,n)
end do
i=2147483647_4
do n=0,32
print *,shiftr(i,n)
end do
end program
