program p
implicit none
character(5)::procedure
procedure='abcde'
procedure(2:3)='X'
if(procedure/='aX de') error stop 1
print *, 'character substring' 
end program
