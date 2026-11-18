program p
implicit none
character::a(5),c
a=new_line(c)
if(any(iachar(a)/=10))error stop 1
print *,iachar(a)
end program
