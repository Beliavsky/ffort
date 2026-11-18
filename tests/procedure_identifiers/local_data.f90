program p
implicit none
integer::procedure
procedure=4
if(procedure/=4) error stop 1
print *, 'local data' 
end program
