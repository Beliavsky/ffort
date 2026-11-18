program p
implicit none
integer::procedure(3)
procedure=[3,4,5]
procedure(2)=7
if(any(procedure/=[3,7,5])) error stop 1
print *, 'array data' 
end program
