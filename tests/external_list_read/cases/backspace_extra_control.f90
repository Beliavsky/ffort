program p
implicit none
integer::u
integer::s
u=27
backspace(u,iostat=s,err=10)
10 continue
end program
