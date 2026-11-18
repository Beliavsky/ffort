program p
implicit none
character::s(3)
s=pick([3,1,2])
if(any(s/=['c','a','b'])) error stop 1
print *, 'elemental'
contains
elemental function pick(i) result(c)
integer,intent(in)::i
character::c
c='abc'(i:i)
end function
end program
