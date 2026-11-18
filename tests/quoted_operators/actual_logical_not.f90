program p
implicit none
logical::l
l=.not.(.not.(.true..and..not..false.))
if(.not.l) error stop 1
print *, 'logical not' 
end program
