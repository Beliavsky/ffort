program p
implicit none
character(1)::c
if(iachar(new_line(c))/=10)error stop 1
print *,iachar(new_line(c)),len(new_line(c)),kind(new_line(c))
end program
