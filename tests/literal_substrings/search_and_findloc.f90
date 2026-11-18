program p
implicit none
integer::i
character(2)::a(3)
i=2
a=['ab','bc','cd']
if(findloc(a,'abcd'(i:i+1),dim=1)/=2) error stop 1
if(index('xabc','abcdef'(1:3))/=2) error stop 2
print *, 'intrinsic composition' 
end program
