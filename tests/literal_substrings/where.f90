program p
implicit none
character::s(3)
s='z'
where([.true.,.false.,.true.]) s='abc'(2:2)
if(any(s/=['b','z','b'])) error stop 1
print *, 'where' 
end program
