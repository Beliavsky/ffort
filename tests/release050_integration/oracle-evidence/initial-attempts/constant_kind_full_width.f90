program p

implicit none
integer(8)::v(3)
character(2)::s(3)
integer::i
v=shiftr(maskl([0,1,64],kind=int(8,8)),[0_8,63_8,64_8])
do i=1,3
write(s(i),'(i0)')v(i)
end do
print '(a)',s
print '(i0)',kind(maskr(1,kind=int(8,8)))
end program
