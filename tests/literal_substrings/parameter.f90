program p
implicit none
integer,parameter::lo=2,hi=4
character(*),parameter::s='abcdef'(lo:hi)
character(len(s))::t
t=s
if(t/='bcd'.or.len(t)/=3) error stop 1
print *, 'parameter' 
end program
