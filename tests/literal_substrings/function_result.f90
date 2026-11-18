program p
implicit none
if(pick(3)/='c') error stop 1
print *, 'function result'
contains
pure function pick(i) result(c)
integer,intent(in)::i
character::c
c='abc'(i:i)
end function
end program
