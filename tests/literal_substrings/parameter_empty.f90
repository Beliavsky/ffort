program p
implicit none
character(*),parameter::s='abc'(5:4)
if(len(s)/=0) error stop 1
print *, 'empty parameter' 
end program
