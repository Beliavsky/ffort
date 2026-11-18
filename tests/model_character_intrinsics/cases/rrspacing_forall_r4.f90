program p
implicit none
real(4)::x(3),a(3)
integer::i
x=-3.0_4
a=-1
forall(i=1:3)a(i)=rrspacing(x(i))
print *,a
end program
