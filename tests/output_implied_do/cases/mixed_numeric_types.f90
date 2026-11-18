program main
implicit none
integer::i
integer(8)::big
real::r
real(8)::d
logical::t
big=9223372036854775805_8
r=-0.0
d=0.125_8
t=.true.
print *, (big+i,r,d*i,t,i=0,2)
end program
