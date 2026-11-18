program p
implicit none
real(8)::x(3)
logical::y(3)
integer::i
x=[-1d0,0d0,4d0]
y=.true.
forall(i=1:3,x(i)>=0d0) y(i)=isnan(sqrt(x(i)))
print *,y
end program
