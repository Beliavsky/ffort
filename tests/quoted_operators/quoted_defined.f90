program p
implicit none
character(7)::c
c='.flip.'//'x'
if(c/='.flip.x') error stop 1
print *, 'quoted defined' 
end program
