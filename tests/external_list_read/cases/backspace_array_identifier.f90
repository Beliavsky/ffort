program p
implicit none
integer::u
integer::backspace(2),a
u=27
backspace(1)=27
backspace(2)=28
u=backspace(1)
read(u,*)a
backspace u
read(u,*)a
print *,a,backspace
end program
