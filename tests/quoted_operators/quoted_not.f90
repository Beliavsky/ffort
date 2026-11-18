program p
implicit none
character(6)::c
c='.not.'//'x'
if(c/='.not.x') error stop 1
print *, 'quoted not' 
end program
