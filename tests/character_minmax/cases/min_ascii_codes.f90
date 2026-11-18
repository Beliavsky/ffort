program p
implicit none
character::a,b
a=char(0)
b=char(127)
print *,iachar(min(a,b)),iachar(min(a,'z'))
end program
