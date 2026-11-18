program p
implicit none
real(8)::x(3),a(3)
integer::i
x=-3.0_8
do i=1,4
a=rrspacing(x)
enddo
print *,i,a
end program
