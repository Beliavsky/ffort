program p
implicit none
real(4)::x(3),a(3)
integer::i
x=-3.0_4
do i=1,4
a=rrspacing(x)
enddo
print *,i,a
end program
