program p
implicit none
character::a,b
a=char(128)
b=char(255)
print *,iachar(min(a,b)),iachar(min(a,'z'))
end program
