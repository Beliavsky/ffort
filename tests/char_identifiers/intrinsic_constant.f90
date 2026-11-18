program p
implicit none
character(1),parameter::letter=char(100)
if(letter/="d") error stop 1
print *,letter
end program
