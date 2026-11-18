program p
implicit none
character::a,b
a=char(128)
b=char(255)
print *,iachar(max(a,b)),iachar(max(a,'z'))
end program
