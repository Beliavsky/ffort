program p
implicit none
character::a,b
a=char(0)
b=char(127)
print *,iachar(max(a,b)),iachar(max(a,'z'))
end program
