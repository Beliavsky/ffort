program p
implicit none
integer::n
integer(8)::i
i=(-huge(0_8)-1_8)
do n=0,64
print *,shiftr(i,n)
end do
i=-1_8
do n=0,64
print *,shiftr(i,n)
end do
i=0_8
do n=0,64
print *,shiftr(i,n)
end do
i=1_8
do n=0,64
print *,shiftr(i,n)
end do
i=9223372036854775807_8
do n=0,64
print *,shiftr(i,n)
end do
end program
