program p
implicit none
integer,parameter::k=kind('abc'(1:2))
integer,parameter::n=len('abcdef'(2:4))
if(k/=1.or.n/=3) error stop 1
print *, 'constant inquiry' 
end program
