program p
implicit none
character::s(3)
integer::i
forall(i=1:3) s(i)='abc'(i:i)
if(any(s/=['a','b','c'])) error stop 1
print *, 'forall' 
end program
